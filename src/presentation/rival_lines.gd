extends RefCounted
## What a rival says (owner, 2026-11-19: "a bigger library of things for rivals and
## bosses to say"). A rival's lines for a mood are its signature line (the League
## file's `reactions`) plus the library in content/rival_lines.json. One is
## picked at random each time, never the same one twice in a row for that rival
## and mood. Presentation only: no RNG stream of a run is touched, nothing is saved.
const PATH := "res://content/rival_lines.json"
const MOODS := ["entrance", "confident", "impressed", "threatened", "defeated", "victorious"]
const MIN_PER_MOOD := 6 # signature included, for a League's rivals (qa.py content)
const MAX_LENGTH := 72 # characters: a line fits the reaction bubble on a phone

static var _library: Dictionary = {}
static var _last: Dictionary = {} # "rival|mood" -> the line shown last
static var rng := RandomNumberGenerator.new()
static var _seeded := false

static func library() -> Dictionary:
	if _library.is_empty() and FileAccess.file_exists(PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_library = data.get("lines", {}) if data is Dictionary else {}
	return _library

## Every line this rival can say in a mood: its signature first, then the library's.
static func candidates(rival: Dictionary, mood: String) -> Array:
	var out: Array = []
	var signature := String(rival.get("reactions", {}).get(mood, ""))
	if not signature.is_empty(): out.append(signature)
	for line in library().get(String(rival.get("id", "")), {}).get(mood, []):
		if line is String and not line.is_empty() and line not in out: out.append(line)
	return out

## A line for this moment, uniformly from the candidates except the one just shown.
static func line(rival: Dictionary, mood: String) -> String:
	var options := candidates(rival, mood)
	if options.is_empty(): return ""
	if not _seeded:
		rng.randomize()
		_seeded = true
	var key := "%s|%s" % [rival.get("id", ""), mood]
	var pool: Array = options.filter(func(l): return l != _last.get(key, "")) if options.size() > 1 else options
	var chosen: String = pool[rng.randi_range(0, pool.size() - 1)]
	_last[key] = chosen
	return chosen

## What a League's rivals lack: at least MIN_PER_MOOD lines per mood, each short
## enough for the bubble (qa.py content).
static func gaps(rivals: Array) -> Array[String]:
	var out: Array[String] = []
	for rival in rivals:
		for mood in MOODS:
			var options := candidates(rival, mood)
			if options.size() < MIN_PER_MOOD:
				out.append("%s: %d of at least %d %s lines" % [rival.get("id", "?"), options.size(), MIN_PER_MOOD, mood])
			for l in options:
				if String(l).length() > MAX_LENGTH: out.append("%s %s line too long: %s" % [rival.get("id", "?"), mood, l])
	return out
