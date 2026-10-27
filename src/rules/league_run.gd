extends RefCounted
## One League attempt as a chain of Divisions (E13, ADR 008): each Division is a
## DivisionRun (opener, feature, boss); beating a boss that is not the last moves
## the attempt on to the next Division's opener, and beating the last boss wins the
## attempt. Losing any match ends it. It answers the same questions as a
## DivisionRun, so the lab, HUD and saves drive either one; the specs are in the
## DivisionRun format (E14's seeded generator produces more of them). Practice
## plays the first Division's target-free schedule forever. Pure and
## JSON-serializable for saves.
const Division = preload("res://src/rules/division_run.gd")
const RivalRules = preload("res://src/rules/rival_rules.gd")
const SCHEMA_VERSION := 1

var specs: Array = []
var index := 0 # the Division being played (0-based)
var active: RefCounted # the DivisionRun being played
var done: Array = [] # finished Divisions' DivisionRun dicts, in order
var practice := false

var spec: Dictionary:
	get: return active.spec
var match_score: int:
	get: return active.match_score
var frames_played: int:
	get: return active.frames_played
var started: int:
	get: return active.started
var match_index: int:
	get: return active.match_index
## Every match result of the attempt, earlier Divisions first, each with its Division.
var results: Array:
	get:
		var out: Array = []
		for i in done.size():
			for r in done[i].results:
				out.append(r.merged({"division": i + 1}))
		for r in active.results:
			out.append(r.merged({"division": index + 1}))
		return out
## "", "won" (the last boss defeated) or "lost".
var outcome: String:
	get:
		if active.outcome == "won" and index < specs.size() - 1:
			return ""
		return active.outcome

static func create(division_specs: Array, practice_mode: bool = false) -> RefCounted:
	var league = load("res://src/rules/league_run.gd").new()
	league.specs = division_specs
	league.practice = practice_mode
	league.active = Division.create(division_specs[0], practice_mode)
	return league

## A League spec: {schema_version, id, name, divisions: [DivisionRun specs]}.
## Each Division must be valid on its own, numbered 1..n in order, with targets
## that keep rising. No boss (rival) repeats within the attempt (design §15) unless
## its Division is explicitly a championship (`championship: true`, E14), which may
## bring back a rival already met. Distinct rivals may share a rule.
static func validate(data: Variant, catalogue: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary or int(data.get("schema_version", 0)) != SCHEMA_VERSION:
		errors.append("league spec needs schema_version 1")
		return errors
	var divisions: Array = data.get("divisions", [])
	if divisions.is_empty():
		errors.append("a League needs at least one Division")
	var previous := 0
	var rivals := {}
	for i in divisions.size():
		var d: Variant = divisions[i]
		for e in Division.validate_spec(d, catalogue):
			errors.append("Division %d: %s" % [i + 1, e])
		if not d is Dictionary:
			continue
		if int(d.get("division", 0)) != i + 1:
			errors.append("Division %d is numbered %s" % [i + 1, str(d.get("division"))])
		for m in d.get("matches", []):
			if int(m.get("target", 0)) <= previous:
				errors.append("targets must rise across Divisions: %s" % m.get("id", "?"))
			previous = int(m.get("target", 0))
		var championship: bool = d.get("championship", false) == true
		for r in d.get("rivals", []):
			if rivals.has(r.get("id", "")) and not championship:
				errors.append("boss repeated within the attempt: %s" % r.get("id", ""))
			rivals[r.get("id", "")] = true
			errors.append_array(RivalRules.unknown([r.get("rule", "")]))
	return errors

func division_number() -> int:
	return index + 1

func division_count() -> int:
	return specs.size()

func frames_per_match() -> int:
	return active.frames_per_match()

func current_match() -> Dictionary:
	return active.current()

## DivisionRun's names, so callers can hold either.
func current() -> Dictionary:
	return active.current()

func target() -> int:
	return active.target()

func is_boss() -> bool:
	return active.is_boss()

func rival() -> Dictionary:
	return active.rival()

func rival_for(m: Dictionary) -> Dictionary:
	return active.rival_for(m)

func boss() -> Dictionary:
	return active.boss()

func rules() -> Array:
	return active.rules()

func frames_left() -> int:
	return active.frames_left()

func match_over() -> bool:
	return active.match_over()

func record_frame(banked: int) -> Dictionary:
	return active.record_frame(banked)

func is_finished() -> bool:
	return outcome != ""

## A boss defeated whose Division is not the last: the attempt continues.
func division_cleared() -> bool:
	return active.outcome == "won" and index < specs.size() - 1

## The next Division's spec, once this one is cleared (else {}).
func next_division() -> Dictionary:
	return specs[index + 1] if index + 1 < specs.size() else {}

## What the next match will be, for previews before shop decisions:
## {match, rival (or {}), boss, boss_rival, division}. {} when nothing follows.
func upcoming() -> Dictionary:
	if practice:
		return {}
	var spec_next: Dictionary = spec
	var m_index := match_index + 1
	var number := index + 1
	if division_cleared():
		spec_next = next_division()
		m_index = 0
		number += 1
	if spec_next.is_empty() or m_index >= spec_next.matches.size():
		return {}
	var m: Dictionary = spec_next.matches[m_index]
	var boss_match: Dictionary = spec_next.matches.filter(func(x): return x.kind == "boss")[0]
	var find := func(match_dict: Dictionary) -> Dictionary:
		for r in spec_next.get("rivals", []):
			if r.id == match_dict.get("rival", ""):
				return r
		return {}
	return {"match": m, "rival": find.call(m), "boss": boss_match, "boss_rival": find.call(boss_match), "division": number}

## After a won match: the next match, or the next Division's opener after a boss.
func next_match() -> Array[String]:
	if division_cleared():
		done.append(active.to_dict())
		index += 1
		active = Division.create(specs[index], practice)
		return [] as Array[String]
	return active.next_match()

func to_dict() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "index": index, "practice": practice, "done": done.duplicate(true), "current": active.to_dict()}

static func from_dict(data: Dictionary, division_specs: Array) -> RefCounted:
	var league = create(division_specs, bool(data.practice))
	league.index = int(data.index)
	# Through DivisionRun so JSON numbers come back as ints.
	for i in data.done.size():
		league.done.append(Division.from_dict(data.done[i], division_specs[i]).to_dict())
	league.active = Division.from_dict(data.current, division_specs[league.index])
	return league
