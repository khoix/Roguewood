extends RefCounted
## E10 persistence: the save store (atomic replace, backup, checksum, quarantine,
## versions and migrations), attempt snapshots (round trip, validation, content
## changes), the Career profile, and the frozen v1 golden saves.
const Store = preload("res://src/persistence/save_store.gd")
const Snapshot = preload("res://src/persistence/attempt_snapshot.gd")
const Career = preload("res://src/persistence/career_profile.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
const Shop = preload("res://src/rules/shop.gd")
const Deck = preload("res://src/rules/card_deck.gd")
const Direct = preload("res://src/rules/direct_loadout.gd")
const Division = preload("res://src/rules/division_run.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const DIVISION := "res://content/fixtures/lab_division.json"
const GOLDEN := "res://tests/fixtures/saves/v1"
const ROOT := "user://save_test"

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = Contracts.read_json(Builder.LAB_CATALOGUE)
	var spec: Dictionary = Contracts.read_json(DIVISION)
	_store_basics(failures)
	_corruption(failures)
	_versions(failures)
	_snapshots(catalogue, spec, failures)
	_golden(catalogue, spec, failures)
	_career(spec, failures)
	return failures

static func _dir(name: String) -> String:
	var path := ProjectSettings.globalize_path(ROOT).path_join(name)
	DirAccess.make_dir_recursive_absolute(path)
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	return path

static func _store_basics(failures: Array[String]) -> void:
	var store = Store.create(_dir("basics"))
	_expect(not store.read("attempt").ok and store.read("attempt").notice.is_empty(), "no save: nothing to report", failures)
	_expect(store.write("attempt", {"n": 1, "x": 0.1234567890123}).is_empty(), "write", failures)
	var first: Dictionary = store.read("attempt")
	_expect(first.ok and first.source == "main" and first.sequence == 1 and first.payload.x == 0.1234567890123, "read back with full precision", failures)
	store.write("attempt", {"n": 2})
	var second: Dictionary = store.read("attempt")
	_expect(second.payload.n == 2 and second.sequence == 2, "a newer write replaces the save", failures)
	_expect(FileAccess.file_exists(store.path("attempt", ".bak")) and not FileAccess.file_exists(store.path("attempt", ".tmp")), "the previous save is kept as a backup; no temp file left", failures)
	_expect(not store.write("mystery", {}).is_empty(), "unknown kinds are refused", failures)
	# A crash after writing the temporary file but before the replace: the old state stands.
	var tmp := FileAccess.open(store.path("attempt", ".tmp"), FileAccess.WRITE)
	tmp.store_string("{\"half\": ")
	tmp.close()
	_expect(store.read("attempt").payload.n == 2, "an interrupted write leaves the last complete save", failures)
	_expect(store.write("attempt", {"n": 3}).is_empty() and store.read("attempt").payload.n == 3, "the next write replaces a stale temporary file", failures)

static func _corrupt_main(store, how: String) -> void:
	var path: String = store.path("attempt")
	var text := FileAccess.get_file_as_string(path)
	match how:
		"truncate": text = text.substr(0, floori(text.length() / 2.0))
		"flip": text = text.replace("\\\"n\\\":5", "\\\"n\\\":6")
		"garbage": text = "not json at all"
		"kind": text = text.replace("\"kind\":\"attempt\"", "\"kind\":\"career\"")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

static func _corruption(failures: Array[String]) -> void:
	for how in ["truncate", "flip", "garbage", "kind"]:
		var store = Store.create(_dir("corrupt_" + how))
		store.write("attempt", {"n": 4})
		store.write("attempt", {"n": 5})
		_corrupt_main(store, how)
		var r: Dictionary = store.read("attempt")
		_expect(r.ok and r.source == "backup" and r.payload.n == 4 and not r.notice.is_empty(), "%s: falls back to the previous checkpoint" % how, failures)
		_expect(FileAccess.file_exists(store.path("attempt", ".corrupt")) and not FileAccess.file_exists(store.path("attempt")), "%s: the unreadable file is quarantined, not deleted" % how, failures)
		_expect(store.write("attempt", {"n": 6}).is_empty() and store.read("attempt").payload.n == 6 and store.read("attempt").sequence == 2, "%s: saving resumes after a fallback" % how, failures)
	var both = Store.create(_dir("corrupt_both"))
	both.write("attempt", {"n": 1})
	both.write("attempt", {"n": 2})
	for suffix in ["", ".bak"]:
		var file := FileAccess.open(both.path("attempt", suffix), FileAccess.WRITE)
		file.store_string("{}")
		file.close()
	var none: Dictionary = both.read("attempt")
	_expect(not none.ok and none.notice.contains("could not be read"), "no usable checkpoint is reported, not crashed on", failures)
	var flipped = Store.create(_dir("checksum"))
	flipped.write("attempt", {"n": 5})
	_corrupt_main(flipped, "flip")
	_expect(flipped.read("attempt").error == "checksum mismatch", "an edited payload fails its checksum", failures)

static func _versions(failures: Array[String]) -> void:
	var store = Store.create(_dir("versions"))
	_expect(store.migrate("attempt", 3, {}).error.contains("newer version"), "a newer save is refused", failures)
	_expect(not store.migrate("attempt", 0, {}).ok, "version 0 is refused", failures)
	_expect(store.migrate("attempt", 2, {"a": 1}).ok and store.migrate("attempt", 2, {"a": 1}).payload == {"a": 1}, "the current version needs no migration", failures)
	# The game's own v1 -> v2 step (ADR 008): lab content, one Division as a League.
	var migrated: Dictionary = store.migrate("attempt", 1, {"division": {"practice": false, "match_index": 1}})
	_expect(migrated.ok and migrated.payload.content_set == "lab" and migrated.payload.division.index == 0 and migrated.payload.division.current.match_index == 1,
		"attempt v1 migrates to v2 (lab content, a one-Division League)", failures)
	# A future v3 game with migrations from v1 and v2 loads a v1 save step by step.
	var future = Store.create(_dir("future"))
	future.versions = {"attempt": 1, "career": 1}
	future.write("attempt", {"money": 5})
	future.versions = {"attempt": 3, "career": 1}
	future.migrations = {"attempt": {1: func(p): return p.merged({"wallet": p.money}), 2: func(p): p.erase("money"); return p}}
	var r: Dictionary = future.read("attempt")
	_expect(r.ok and r.payload.get("wallet") == 5 and not r.payload.has("money"), "migrations run in order from the saved version", failures)
	future.migrations = {"attempt": {1: func(p): return p}}
	_expect(not future.read("attempt").ok, "a gap in the migration chain is refused", failures)

static func _parts(catalogue: Dictionary, spec: Dictionary, model: String) -> Dictionary:
	var wood: Array = []
	wood.resize(10)
	wood.fill("pin.wood")
	var run = Inventory.create(catalogue, wood, ["ball.lab_value", "ball.lab_mult", "ball.lab_coin", "consumable.lab_focus"])
	var shop = Shop.create(catalogue, 42)
	shop.open_visit(run, 1)
	var division = Division.create(spec)
	division.record_frame(100)
	var equipment = Deck.create_with(run.deck_cards(), 9) if model == "deck" else Direct.create(["ball.lab_value"], ["consumable.lab_focus"], ["card-4"])
	equipment.start_frame()
	var lab := {"frame_number": 1, "roll_index": 2, "match_number": 1, "match_frame": 1, "total_score": 0, "launch_serial": 1,
		"rack": Lane.fresh_rack(), "frame_reports": [], "frame_tactics": {2: ["consumable.lab_focus"]}, "frame_mods": {},
		"kept_last_frame": "", "equipment_model": model, "settlement": {}, "last_scored": null, "pending": null, "result": null}
	return {"attempt": 2, "seed": 2, "phase": "aim", "lab": lab, "run": run, "shop": shop, "division": division, "equipment": equipment}

static func _snapshots(catalogue: Dictionary, spec: Dictionary, failures: Array[String]) -> void:
	var content := Snapshot.content_hashes(Builder.LAB_CATALOGUE, DIVISION)
	for model in ["deck", "direct"]:
		var parts := _parts(catalogue, spec, model)
		var payload: Dictionary = JSON.parse_string(JSON.stringify(Snapshot.build(parts, content), "", true, true))
		_expect(Snapshot.validate(payload, catalogue).is_empty(), "%s snapshot validates" % model, failures)
		var back := Snapshot.restore(payload, catalogue, spec, content)
		for key in ["run", "shop", "division", "equipment"]:
			var before: Dictionary = parts[key].to_dict()
			if key == "division": # a lone Division comes back as a one-Division League (ADR 008)
				before = Snapshot.league_dict(before)
			_expect(JSON.stringify(back[key].to_dict(), "", true) == JSON.stringify(before, "", true), "%s %s survives a save" % [model, key], failures)
		_expect(back.lab.frame_tactics.has(2) and back.lab.roll_index == 2 and back.warnings.is_empty(), "%s lab state comes back typed" % model, failures)
		# Restored randomness continues exactly: the shop rerolls and the deck draws as before.
		parts.shop.reroll(parts.run)
		back.shop.reroll(back.run)
		_expect(back.shop.offers == parts.shop.offers and back.run.money == parts.run.money, "%s shop rerolls identically after a load" % model, failures)
		if model == "deck":
			parts.equipment.start_frame()
			back.equipment.start_frame()
			_expect(back.equipment.hand == parts.equipment.hand and back.equipment.draw_pile == parts.equipment.draw_pile, "the deck draws identically after a load", failures)
	var payload: Dictionary = JSON.parse_string(JSON.stringify(Snapshot.build(_parts(catalogue, spec, "deck"), content), "", true, true))
	var unknown: Dictionary = payload.duplicate(true)
	unknown.run.charms.append({"item_id": "charm.retired", "paid": 4, "mod": "", "mod_paid": 0})
	_expect(Snapshot.validate(unknown, catalogue).has("item no longer exists: charm.retired"), "a save naming a removed item is refused", failures)
	var phase: Dictionary = payload.duplicate(true)
	phase.phase = "dancing"
	_expect(not Snapshot.validate(phase, catalogue).is_empty(), "unknown phases are refused", failures)
	var committed: Dictionary = payload.duplicate(true)
	committed.phase = "committed"
	_expect(not Snapshot.validate(committed, catalogue).is_empty(), "a committed phase needs its launch", failures)
	var changed: Dictionary = payload.duplicate(true)
	changed.content.catalogue = "older"
	_expect(Snapshot.restore(changed, catalogue, spec, content).warnings.size() == 1, "changed content is reported, not fatal, when every item still exists", failures)

## The frozen v1 saves must keep loading in every later version (via migrations).
static func _golden(catalogue: Dictionary, spec: Dictionary, failures: Array[String]) -> void:
	var dir := _dir("golden")
	for kind in ["attempt", "career"]:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(GOLDEN).path_join(kind + ".json"), dir.path_join(kind + ".json"))
	var store = Store.create(dir)
	var read: Dictionary = store.read("attempt")
	_expect(read.ok and read.schema_version == 1, "golden v1 attempt loads: %s" % read.get("error", ""), failures)
	if not read.ok:
		return
	_expect(Snapshot.validate(read.payload, catalogue).is_empty(), "golden v1 attempt validates", failures)
	var back := Snapshot.restore(read.payload, catalogue, spec, Snapshot.content_hashes(Builder.LAB_CATALOGUE, DIVISION))
	var lab: Dictionary = back.lab
	_expect(read.payload.phase == "committed" and lab.pending.launch.launch_id == "t-2-3" and lab.pending.launch.roll_index == 2, "golden: a committed second roll", failures)
	_expect(back.run.money == 7 and back.run.cards.size() == 8 and back.run.ledger.map(func(r): return r.kind) == ["start", "item_income", "interest", "payout", "purchase", "reroll"],
		"golden: wallet $7, eight cards, the ledger in order", failures)
	_expect(back.equipment.hand == ["card-8", "card-4", "card-6"] and back.equipment.cycled, "golden: the cycled hand", failures)
	_expect(back.shop.rerolls == 1 and back.shop.reroll_cost() == 3 and back.shop.offers.size() == 5, "golden: one reroll paid this visit", failures)
	_expect(back.division.current().kind == "feature" and back.division.match_score == 240 and back.division.results.size() == 1, "golden: the feature in progress", failures)
	var expected_x: float = Lane.spot(1).x + 0.0123456789
	_expect(lab.rack.standing[0].x == expected_x and lab.frame_tactics.has(1) and lab.frame_reports[0].roll_result.roll_index == 1, "golden: rack positions exact; keys and counts typed", failures)
	var career: Dictionary = store.read("career")
	_expect(career.ok and career.payload.first_clears.has("rival.lab_custodian") and "gate.lab_rival" in career.payload.unlocked, "golden v1 Career loads", failures)

static func _career(spec: Dictionary, failures: Array[String]) -> void:
	var career := Career.fresh()
	var rival: Dictionary = spec.rivals[0]
	_expect(Career.record_first_clear(career, rival, 1) and career.unlocked == ["gate.lab_rival"], "a first clear banks its unlock", failures)
	_expect(not Career.record_first_clear(career, rival, 2) and career.unlocked.size() == 1 and career.first_clears[rival.id].attempt == 1, "a repeat clear changes nothing", failures)
	_expect(Career.normalized({"first_clears": {"x": true}, "junk": 1}).has("unlocked") and not Career.normalized({"junk": 1}).has("junk"), "older or odd records are normalized", failures)
	var store = Store.create(_dir("career"))
	store.write("career", career)
	var back: Dictionary = store.read("career")
	_expect(back.ok and Career.validate(back.payload).is_empty() and back.payload.first_clears.has(rival.id), "the Career profile round-trips separately", failures)
	_expect(not store.read("attempt").ok, "Career and attempt saves are separate files", failures)

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition: failures.append(label)
