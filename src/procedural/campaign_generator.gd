extends RefCounted
## Pure schedule builder. Caller supplies implemented, eligible rivals/lanes and
## authored target tables. No production content or balance is invented here.
const Streams = preload("res://src/procedural/random_streams.gd")
const Division = preload("res://src/rules/division_run.gd")
const VERSION := 2
const MAX_DIVISIONS := 256 # bounded recovery work; extend only with a versioned policy change
const KINDS := ["opener", "feature", "boss"]

## Profile: id, division_template, bosses (rival records with compatible_lanes),
## lanes ({id, text}), targets (8 ascending triples). Reuse for championship
## requires championship_reuses_encountered_rule=true; otherwise eight unique bosses.
static func generate(seed_value: int, profile: Dictionary, catalogue: Dictionary) -> Dictionary:
	var errors := validate(profile, catalogue)
	if not _integer(seed_value, -9007199254740991, 9007199254740991): errors.append("seed must be JSON-exact")
	if not errors.is_empty():
		return {"errors": errors}
	var rng = Streams.create(seed_value)
	var available: Array = profile.bosses.duplicate(true)
	available.sort_custom(func(a, b): return a.id < b.id)
	var divisions: Array = []
	var seen: Array = []
	for index in range(8):
		var boss: Dictionary
		if index == 7 and profile.get("championship_reuses_encountered_rule", false):
			boss = seen[rng.draw("bosses", seen.size())]
		else:
			boss = available.pop_at(rng.draw("bosses", available.size()))
			seen.append(boss)
		divisions.append(_division(index + 1, boss, profile.targets[index], profile, rng, index == 7))
	return {"errors": [], "version": VERSION, "seed": seed_value, "profile_id": profile.id, "profile_digest": _digest(profile),
		"divisions": divisions, "rng": rng.to_dict(), "standard_count": 8}

static func validate(profile: Dictionary, catalogue: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not profile.get("id") is String or not profile.get("division_template") is Dictionary:
		return ["profile needs id and division_template"]
	for key in ["bosses", "lanes", "targets"]:
		if not profile.get(key) is Array:
			return ["profile needs array: " + key]
	if profile.targets.size() != 8:
		errors.append("exactly eight authored target triples required")
	var previous := 0
	for row in profile.targets:
		if not row is Array or row.size() != 3:
			errors.append("each target row needs three values")
			continue
		var within := 0
		var valid_row := true
		for target in row:
			if not _integer(target, within + 1, 1000000000):
				valid_row = false
				errors.append("targets must be positive increasing integers within score bounds")
			else:
				within = int(target)
		if not valid_row: continue
		if int(row[0]) <= previous:
			errors.append("every target must exceed the previous match, including Division boundaries")
		previous = int(row[2])
	if not profile.get("championship_reuses_encountered_rule", false) is bool:
		errors.append("championship reuse policy must be boolean")
	if not _integer(profile.division_template.get("schema_version"), 1, 1) or not _integer(profile.division_template.get("frames_per_match"), 1, 100):
		return ["invalid Division template version/frame budget"]
	var lane_ids := {}
	for lane in profile.lanes:
		if not lane is Dictionary or not lane.get("id") is String or not lane.get("text") is String:
			return ["lane needs id and reveal text"]
		if lane.id.is_empty() or lane.text.is_empty(): errors.append("empty lane id/text")
		if lane_ids.has(lane.id): errors.append("duplicate lane: " + lane.id)
		lane_ids[lane.id] = true
	var boss_ids := {}
	for boss in profile.bosses:
		if not boss is Dictionary or not boss.get("id") is String or not boss.get("rule") is String or not boss.get("compatible_lanes") is Array:
			return ["boss needs id, rule and explicit compatible_lanes"]
		if boss_ids.has(boss.id):
			errors.append("standard boss IDs must be distinct")
		if boss.id.is_empty() or boss.rule.is_empty(): errors.append("empty boss id/rule")
		for key in ["name", "intro"]:
			if not boss.get(key) is String or boss.get(key, "").is_empty(): errors.append("missing rival text: " + key)
		for key in ["reactions", "first_clear"]:
			if not boss.get(key) is Dictionary: errors.append("missing rival data: " + key)
		boss_ids[boss.id] = true
		if boss.compatible_lanes.is_empty(): errors.append("boss has no legal lane: " + boss.id)
		var seen_lanes := {}
		for lane in boss.compatible_lanes:
			if seen_lanes.has(str(lane)): errors.append("duplicate compatible lane")
			seen_lanes[str(lane)] = true
			if not lane is String or not lane_ids.has(lane): errors.append("unknown compatible lane: " + str(lane))
		var spec: Dictionary = {"schema_version": 1, "frames_per_match": int(profile.division_template.frames_per_match)}
		spec["rivals"] = [boss]
		spec["matches"] = _matches(1, boss.id, [1, 2, 3])
		errors.append_array(Division.validate_spec(spec, catalogue))
	var required := 7 if profile.get("championship_reuses_encountered_rule", false) else 8
	if boss_ids.size() < required:
		errors.append("insufficient distinct bosses for authored championship policy")
	return errors

static func _matches(number: int, rival_id: String, targets: Array) -> Array:
	var matches: Array = []
	for i in range(3):
		var match_data := {"id": "match.d%d.%s" % [number, KINDS[i]], "kind": KINDS[i], "name": KINDS[i].capitalize(), "target": int(targets[i])}
		if i == 2: match_data["rival"] = rival_id
		matches.append(match_data)
	return matches

static func _division(number: int, boss: Dictionary, targets: Array, profile: Dictionary, rng: RefCounted, championship: bool) -> Dictionary:
	boss = boss.duplicate(true)
	boss.compatible_lanes.sort()
	var legal: Array = boss.compatible_lanes.duplicate()
	legal.sort()
	var spec: Dictionary = {"schema_version": 1, "frames_per_match": int(profile.division_template.frames_per_match)}
	spec["division"] = number
	spec["name"] = "%s · Division %d" % [profile.id, number]
	spec["rivals"] = [boss.duplicate(true)]
	spec["matches"] = _matches(number, boss.id, targets)
	spec["championship"] = championship
	for match_data in spec.matches:
		match_data["lane_condition"] = legal[rng.draw("lanes", legal.size())]
	# An immutable payload for display BEFORE entering this Division's shop.
	spec["preview"] = {"rival": boss.duplicate(true), "matches": spec.matches.duplicate(true), "lanes": _sorted_lanes(profile.lanes)}
	return spec

## Explicit opt-in only after the consumer records championship victory.
## Targets are caller-authored, never derived from player performance. Passing a
## fresh profile or invalid RNG refuses the extension without mutating schedule.
static func extend_endless(schedule: Dictionary, profile: Dictionary, catalogue: Dictionary, targets: Array, championship_won: bool) -> Dictionary:
	if not championship_won:
		return {"errors": ["endless requires completed victory from the League controller"]}
	var errors := validate_schedule(schedule, profile, catalogue)
	if not errors.is_empty(): return {"errors": errors}
	if schedule.divisions.size() >= MAX_DIVISIONS:
		return {"errors": ["schedule reached versioned Division limit"]}
	if not _valid_targets(targets, int(schedule.divisions.back().matches.back().target)):
		return {"errors": ["endless targets must exceed the previous boss and rise"]}
	var rng = Streams.restore(schedule.rng)
	var result := schedule.duplicate(true)
	var bosses: Array = profile.bosses.duplicate(true)
	bosses.sort_custom(func(a, b): return a.id < b.id)
	var boss: Dictionary = bosses[rng.draw("bosses", bosses.size())]
	result.divisions.append(_division(result.divisions.size() + 1, boss, targets, profile, rng, false))
	result["rng"] = rng.to_dict()
	return result

## Recovery is checked against the seed and frozen profile, not merely shape.
## Other streams may legitimately advance during play; schedule streams may not.
static func validate_schedule(schedule: Dictionary, profile: Dictionary, catalogue: Dictionary) -> Array[String]:
	var errors := validate(profile, catalogue)
	if not errors.is_empty(): return errors
	if not _integer(schedule.get("version"), VERSION, VERSION) or not _integer(schedule.get("seed"), -9007199254740991, 9007199254740991):
		return ["unsupported schedule version or non-exact seed"]
	if schedule.get("profile_id") != profile.id or schedule.get("profile_digest") != _digest(profile) or schedule.get("standard_count") != 8:
		return ["saved schedule profile changed"]
	if not schedule.get("divisions") is Array or schedule.divisions.size() < 8 or schedule.divisions.size() > MAX_DIVISIONS:
		return ["invalid saved Division count"]
	if not schedule.get("rng") is Dictionary or Streams.restore(schedule.rng) == null:
		return ["invalid saved RNG"]
	var expected := generate(int(schedule.seed), profile, catalogue)
	var rng = Streams.restore(expected.rng)
	var bosses: Array = profile.bosses.duplicate(true)
	bosses.sort_custom(func(a, b): return a.id < b.id)
	for i in range(schedule.divisions.size()):
		var spec = schedule.divisions[i]
		if not spec is Dictionary or not spec.get("matches") is Array or spec.matches.size() != 3:
			return ["invalid saved Division"]
		if i >= 8:
			var targets: Array = []
			for m in spec.matches:
				if not m is Dictionary: return ["invalid saved match"]
				targets.append(m.get("target"))
			if not _valid_targets(targets, int(expected.divisions.back().matches.back().target)):
				return ["invalid saved endless targets"]
			var boss: Dictionary = bosses[rng.draw("bosses", bosses.size())]
			expected.divisions.append(_division(i + 1, boss, targets, profile, rng, false))
		if _canonical(spec) != _canonical(expected.divisions[i]):
			return ["saved schedule differs from seeded schedule"]
	for stream in ["bosses", "lanes"]:
		if int(schedule.rng.states[stream]) != int(rng.states[stream]):
			return ["schedule RNG differs from seeded continuation"]
	return []

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum and value == int(value)

static func _valid_targets(targets: Array, previous: int) -> bool:
	if targets.size() != 3: return false
	for target in targets:
		if not _integer(target, previous + 1, 1000000000): return false
		previous = int(target)
	return true

static func _canonical(value: Variant) -> String:
	# JSON numbers are floats on load. Normalize both fresh and restored records.
	return JSON.stringify(JSON.parse_string(JSON.stringify(value, "", true, true)), "", true, true)

static func _sorted_lanes(lanes: Array) -> Array:
	var result := lanes.duplicate(true)
	result.sort_custom(func(a, b): return a.id < b.id)
	return result

static func _digest(profile: Dictionary) -> String:
	var canonical := profile.duplicate(true)
	canonical.bosses.sort_custom(func(a, b): return a.id < b.id)
	for boss in canonical.bosses: boss.compatible_lanes.sort()
	canonical.lanes = _sorted_lanes(canonical.lanes)
	return _canonical(canonical).sha256_text()
