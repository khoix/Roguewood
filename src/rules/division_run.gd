extends RefCounted
## One Division of a League attempt (E09, design §4/§18, ADR 006): an opener, a
## feature and a boss match, each a fixed posted target within the frame budget.
## A match is won as soon as the banked total reaches its target (the frame that
## crosses it still resolves fully, then the match ends) and lost when the budget
## runs out first. Winning the boss wins the Division; losing any match ends the
## attempt. Practice mode has no targets: every match plays its whole budget and
## the schedule never ends. Pure and JSON-serializable for saves (E10).
const SCHEMA_VERSION := 1
const KINDS := ["opener", "feature", "boss"]

var spec: Dictionary = {}
var practice := false
var match_index := 0
var match_score := 0
var frames_played := 0
var results: Array = [] # {id, kind, target, score, frames, won}
var outcome := "" # "", "won" (boss defeated) or "lost"
var started := 1 # matches started so far

static func create(division_spec: Dictionary, practice_mode: bool = false) -> RefCounted:
	var run = load("res://src/rules/division_run.gd").new()
	run.spec = division_spec
	run.practice = practice_mode
	return run

## Shape and meaning checks for a Division spec; [] when valid.
static func validate_spec(data: Variant, catalogue: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary or int(data.get("schema_version", 0)) != SCHEMA_VERSION:
		errors.append("division spec needs schema_version 1")
		return errors
	var matches: Array = data.get("matches", [])
	if matches.size() != 3 or matches.map(func(m): return m.get("kind", "")) != KINDS:
		errors.append("a Division is an opener, a feature and a boss, in that order")
	if int(data.get("frames_per_match", 0)) < 1:
		errors.append("frames_per_match must be positive")
	var rivals := {}
	for rival in data.get("rivals", []):
		rivals[rival.get("id", "")] = rival
		var rule := _item(catalogue, rival.get("rule", ""))
		if rule.get("category", "") != "boss_rule":
			errors.append("rival %s needs a catalogue boss_rule" % rival.get("id", "?"))
		for key in ["name", "intro", "reactions", "first_clear"]:
			if not rival.has(key):
				errors.append("rival %s is missing %s" % [rival.get("id", "?"), key])
	var previous := 0
	for m in matches:
		var target := int(m.get("target", 0))
		if target <= previous:
			errors.append("targets must rise: %s" % m.get("id", "?"))
		previous = target
		if m.get("kind", "") == "boss" and not rivals.has(m.get("rival", "")):
			errors.append("the boss match needs a known rival")
		if m.get("kind", "") != "boss" and m.has("rival"):
			errors.append("only the boss has a rival")
	return errors

static func _item(catalogue: Dictionary, item_id: String) -> Dictionary:
	for entry in catalogue.get("items", []):
		if entry.id == item_id:
			return entry
	return {}

func frames_per_match() -> int:
	return int(spec.get("frames_per_match", 2))

## The match being played (practice repeats a target-free match).
func current() -> Dictionary:
	if practice:
		return {"id": "match.practice", "kind": "practice", "name": "Practice", "target": 0}
	return spec.matches[match_index]

func target() -> int:
	return int(current().target)

func is_boss() -> bool:
	return current().kind == "boss"

func rival() -> Dictionary:
	return rival_for(current())

func rival_for(m: Dictionary) -> Dictionary:
	for r in spec.get("rivals", []):
		if r.id == m.get("rival", ""):
			return r
	return {}

## The Division's boss match, for previews before any shop decision.
func boss() -> Dictionary:
	for m in spec.get("matches", []):
		if m.kind == "boss":
			return m
	return {}

## Boss rules in force for the current match.
func rules() -> Array:
	var r := rival()
	return [r.rule] if not r.is_empty() else []

func frames_left() -> int:
	return frames_per_match() - frames_played

## The current match has a result (and the next has not started).
func match_over() -> bool:
	return results.size() == started

## Banks one frame's score. Returns {over, won} for the current match.
func record_frame(banked: int) -> Dictionary:
	if match_over():
		return {"over": true, "won": false, "error": "match already over"}
	match_score += maxi(banked, 0)
	frames_played += 1
	var won: bool = not practice and match_score >= target()
	var over: bool = won or frames_played >= frames_per_match()
	if over:
		var m := current()
		results.append({"id": m.id, "kind": m.kind, "target": target(), "score": match_score, "frames": frames_played, "won": won or practice})
		if not practice:
			if not won:
				outcome = "lost"
			elif is_boss():
				outcome = "won"
	return {"over": over, "won": won}

func is_finished() -> bool:
	return outcome != ""

## Moves to the next match after a won (or practice) match. Refused otherwise.
func next_match() -> Array[String]:
	var errors: Array[String] = []
	if not match_over():
		errors.append("the current match is still being played")
	elif is_finished():
		errors.append("the Division is over")
	if not errors.is_empty():
		return errors
	if not practice:
		match_index += 1
	started += 1
	match_score = 0
	frames_played = 0
	return errors

func to_dict() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "practice": practice, "match_index": match_index, "match_score": match_score,
		"frames_played": frames_played, "results": results.duplicate(true), "outcome": outcome, "started": started}

static func from_dict(data: Dictionary, division_spec: Dictionary) -> RefCounted:
	var run = create(division_spec, bool(data.practice))
	run.match_index = int(data.match_index)
	run.match_score = int(data.match_score)
	run.frames_played = int(data.frames_played)
	run.results = data.results.map(func(r): return {"id": r.id, "kind": r.kind, "target": int(r.target), "score": int(r.score), "frames": int(r.frames), "won": bool(r.won)})
	run.outcome = data.outcome
	run.started = int(data.started)
	return run
