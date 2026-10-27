extends RefCounted
## Durable JSON saves (E10, ADR 007). Each save is one file per kind ("attempt",
## "career") holding a versioned envelope:
##   {format, kind, schema_version, sequence, checksum, payload}
## where payload is the state as canonical JSON text and checksum its SHA-256, so a
## torn or edited file is detected rather than half-loaded.
##
## Writing is atomic: the new envelope goes to <kind>.json.tmp and is read back and
## verified, the current good file is copied to <kind>.json.bak, and only then does
## the temporary file replace <kind>.json. A crash at any point leaves either the
## old state or the new one readable, never a mixture. Reading tries the main file,
## then the backup; an unreadable file is quarantined as <kind>.corrupt.json (never
## silently deleted) and the caller is told what happened.
const FORMAT := "roguewood"
const KINDS := ["attempt", "career"]

var directory := ""
## kind -> {from_version: Callable(payload) -> payload}; each step moves one version up.
var migrations: Dictionary = {}
## kind -> current schema version
var versions: Dictionary = {"attempt": 1, "career": 1}

static func create(dir_path: String) -> RefCounted:
	var store = load("res://src/persistence/save_store.gd").new()
	store.directory = ProjectSettings.globalize_path(dir_path) if dir_path.begins_with("user://") or dir_path.begins_with("res://") else dir_path
	DirAccess.make_dir_recursive_absolute(store.directory)
	return store

func path(kind: String, suffix: String = "") -> String:
	return directory.path_join(kind + ".json" + suffix)

func exists(kind: String) -> bool:
	return FileAccess.file_exists(path(kind)) or FileAccess.file_exists(path(kind, ".bak"))

## Writes payload atomically. Returns [] or the reasons it could not (the previous
## save is then untouched).
func write(kind: String, payload: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if kind not in KINDS:
		errors.append("unknown save kind: " + kind)
		return errors
	var text := JSON.stringify(payload, "", true, true)
	var previous := _peek_sequence(kind)
	var envelope := {"format": FORMAT, "kind": kind, "schema_version": versions[kind], "sequence": previous + 1,
		"checksum": text.sha256_text(), "payload": text}
	var tmp := path(kind, ".tmp")
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		errors.append("cannot open %s: %s" % [tmp, error_string(FileAccess.get_open_error())])
		return errors
	file.store_string(JSON.stringify(envelope))
	file.flush()
	file.close()
	var check := _read_envelope(tmp, kind)
	if not check.ok:
		errors.append("written save failed verification: " + check.error)
		DirAccess.remove_absolute(tmp)
		return errors
	if FileAccess.file_exists(path(kind)) and _read_envelope(path(kind), kind).ok:
		DirAccess.copy_absolute(path(kind), path(kind, ".bak"))
	if DirAccess.rename_absolute(tmp, path(kind)) != OK:
		# Some platforms refuse to rename over an existing file; the backup holds it.
		DirAccess.remove_absolute(path(kind))
		if DirAccess.rename_absolute(tmp, path(kind)) != OK:
			errors.append("cannot replace " + path(kind))
	return errors

## {ok, payload, sequence, source ("main"|"backup"), notice, error}. notice explains
## any fallback or quarantine in player-readable words.
func read(kind: String) -> Dictionary:
	var main := _read_envelope(path(kind), kind)
	if main.ok:
		return main.merged({"source": "main", "notice": ""})
	var main_present := FileAccess.file_exists(path(kind))
	var backup := _read_envelope(path(kind, ".bak"), kind)
	if main_present:
		_quarantine(kind)
	if backup.ok:
		var notice := "The latest %s save could not be read (%s); restored the previous checkpoint." % [kind, main.error] if main_present else ""
		return backup.merged({"source": "backup", "notice": notice})
	if main_present or FileAccess.file_exists(path(kind, ".bak")):
		return {"ok": false, "error": main.error if main_present else backup.error,
			"notice": "The %s save could not be read (%s) and no earlier checkpoint was usable." % [kind, main.error if main_present else backup.error]}
	return {"ok": false, "error": "no save", "notice": ""}

## Removes a kind's saves (for example after an attempt is abandoned on purpose).
func clear(kind: String) -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path(kind, suffix)):
			DirAccess.remove_absolute(path(kind, suffix))

func _quarantine(kind: String) -> void:
	DirAccess.remove_absolute(path(kind, ".corrupt"))
	DirAccess.rename_absolute(path(kind), path(kind, ".corrupt"))

func _peek_sequence(kind: String) -> int:
	var best := 0
	for suffix in ["", ".bak"]:
		var r := _read_envelope(path(kind, suffix), kind)
		if r.ok:
			best = maxi(best, int(r.sequence))
	return best

## Parses and verifies one envelope, then migrates its payload to the current version.
func _read_envelope(file_path: String, kind: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {"ok": false, "error": "missing"}
	var outer = _parse(FileAccess.get_file_as_string(file_path))
	if not outer is Dictionary:
		return {"ok": false, "error": "not a save file"}
	if outer.get("format") != FORMAT or outer.get("kind") != kind:
		return {"ok": false, "error": "wrong file type"}
	if not outer.get("payload") is String or not outer.get("checksum") is String:
		return {"ok": false, "error": "incomplete"}
	if String(outer.payload).sha256_text() != outer.checksum:
		return {"ok": false, "error": "checksum mismatch"}
	var version := int(outer.get("schema_version", 0))
	var payload = _parse(outer.payload)
	if not payload is Dictionary:
		return {"ok": false, "error": "unreadable state"}
	var migrated := migrate(kind, version, payload)
	if not migrated.ok:
		return migrated
	return {"ok": true, "payload": migrated.payload, "sequence": int(outer.get("sequence", 0)), "schema_version": version}

## Quiet parse: a damaged file is an expected case here, not an engine error.
static func _parse(text: String) -> Variant:
	var parser := JSON.new()
	return parser.data if parser.parse(text) == OK else null

## Moves a payload from its saved version to the current one, one step at a time.
## Newer saves are refused (no downgrade); a gap in the chain is refused too.
func migrate(kind: String, version: int, payload: Dictionary) -> Dictionary:
	var current: int = versions.get(kind, 1)
	if version > current:
		return {"ok": false, "error": "made by a newer version (save v%d, game v%d)" % [version, current]}
	if version < 1:
		return {"ok": false, "error": "unknown save version %d" % version}
	var steps: Dictionary = migrations.get(kind, {})
	var data := payload
	while version < current:
		if not steps.has(version):
			return {"ok": false, "error": "no migration from v%d" % version}
		data = steps[version].call(data)
		version += 1
	return {"ok": true, "payload": data}
