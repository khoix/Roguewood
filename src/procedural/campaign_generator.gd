extends RefCounted
## Pure schedule builder. Caller supplies implemented, eligible rivals/lanes and
## measured target tables. No production content or balance is invented here.
const Streams = preload("res://src/procedural/random_streams.gd")
const Division = preload("res://src/rules/division_run.gd")
const KINDS := ["opener", "feature", "boss"]

## Profile: id, division_template, bosses (rival records with compatible_lanes),
## lanes ({id, text}), targets (8 ascending triples). Championship reuses one
## previously encountered boss rule, explicitly, and only on a compatible lane.
static func generate(seed_value: int, profile: Dictionary, catalogue: Dictionary) -> Dictionary:
	var errors := validate(profile, catalogue)
	if not errors.is_empty():
		return {"errors": errors}
	var rng = Streams.create(seed_value)
	var available: Array = profile.bosses.duplicate(true)
	available.sort_custom(func(a, b): return a.id < b.id)
	var divisions: Array = []
	var seen: Array = []
	for index in range(8):
		var boss: Dictionary
		if index == 7:
			boss = seen[rng.draw("bosses", seen.size())]
		else:
			boss = available.pop_at(rng.draw("bosses", available.size()))
			seen.append(boss)
		divisions.append(_division(index + 1, boss, profile.targets[index], profile, rng, index == 7))
	return {"errors": [], "version": 1, "seed": seed_value, "profile_id": profile.id,
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
	var previous_boss := 0
	for row in profile.targets:
		if not row is Array or row.size() != 3:
			errors.append("each target row needs three values")
			continue
		var within := 0
		var valid_row := true
		for target in row:
			if not (target is int or target is float) or target != int(target) or target <= within or target > 1000000000:
				valid_row = false
				errors.append("targets must be positive increasing integers within score bounds")
			else:
				within = int(target)
		if not valid_row: continue
		if int(row[2]) <= previous_boss:
			errors.append("Division boss targets must increase")
		previous_boss = int(row[2])
		if int(row[0]) <= previous:
			errors.append("Division opener targets must increase")
		previous = int(row[0])
	var lane_ids := {}
	for lane in profile.lanes:
		if not lane is Dictionary or not lane.get("id") is String or not lane.get("text") is String:
			return ["lane needs id and reveal text"]
		if lane_ids.has(lane.id): errors.append("duplicate lane: " + lane.id)
		lane_ids[lane.id] = true
	var boss_ids := {}
	var rule_ids := {}
	for boss in profile.bosses:
		if not boss is Dictionary or not boss.get("id") is String or not boss.get("rule") is String or not boss.get("compatible_lanes") is Array:
			return ["boss needs id, rule and explicit compatible_lanes"]
		if boss_ids.has(boss.id) or rule_ids.has(boss.rule):
			errors.append("standard bosses and rules must be distinct")
		boss_ids[boss.id] = true
		rule_ids[boss.rule] = true
		if boss.compatible_lanes.is_empty(): errors.append("boss has no legal lane: " + boss.id)
		for lane in boss.compatible_lanes:
			if not lane_ids.has(lane): errors.append("unknown compatible lane: " + str(lane))
		var spec: Dictionary = profile.division_template.duplicate(true)
		spec["rivals"] = [boss]
		spec["matches"] = _matches(1, boss.id, [1, 2, 3])
		errors.append_array(Division.validate_spec(spec, catalogue))
	if boss_ids.size() < 7:
		errors.append("seven distinct implemented bosses required before championship")
	return errors

static func _matches(number: int, rival_id: String, targets: Array) -> Array:
	var matches: Array = []
	for i in range(3):
		var match_data := {"id": "match.d%d.%s" % [number, KINDS[i]], "kind": KINDS[i], "name": KINDS[i].capitalize(), "target": int(targets[i])}
		if i == 2: match_data["rival"] = rival_id
		matches.append(match_data)
	return matches

static func _division(number: int, boss: Dictionary, targets: Array, profile: Dictionary, rng: RefCounted, championship: bool) -> Dictionary:
	var legal: Array = boss.compatible_lanes.duplicate()
	legal.sort()
	var spec: Dictionary = profile.division_template.duplicate(true)
	spec["division"] = number
	spec["name"] = "%s · Division %d" % [profile.id, number]
	spec["rivals"] = [boss.duplicate(true)]
	spec["matches"] = _matches(number, boss.id, targets)
	spec["championship"] = championship
	for match_data in spec.matches:
		match_data["lane_condition"] = legal[rng.draw("lanes", legal.size())]
	# An immutable payload for display BEFORE entering this Division's shop.
	spec["preview"] = {"rival": boss.duplicate(true), "matches": spec.matches.duplicate(true), "lanes": profile.lanes.duplicate(true)}
	return spec

## Explicit opt-in only after the consumer records championship victory.
## Targets are caller-authored, never derived from player performance. Passing a
## fresh profile or invalid RNG refuses the extension without mutating schedule.
static func extend_endless(schedule: Dictionary, profile: Dictionary, catalogue: Dictionary, targets: Array, championship_won: bool) -> Dictionary:
	if not championship_won or not validate(profile, catalogue).is_empty():
		return {"errors": ["endless requires championship victory and valid profile"]}
	if schedule.get("profile_id") != profile.id or int(schedule.get("version", 0)) != 1 or not schedule.get("divisions") is Array or schedule.divisions.size() < 8:
		return {"errors": ["invalid saved schedule"]}
	if targets.size() != 3:
		return {"errors": ["endless needs three authored targets"]}
	var previous := int(schedule.divisions.back().matches[0].target)
	for target in targets:
		if not (target is int or target is float) or target != int(target) or target <= previous or target > 1000000000:
			return {"errors": ["invalid endless target curve"]}
		previous = int(target)
	var rng = Streams.restore(schedule.get("rng", {}))
	if rng == null: return {"errors": ["invalid saved RNG"]}
	var result := schedule.duplicate(true)
	var bosses: Array = profile.bosses.duplicate(true)
	bosses.sort_custom(func(a, b): return a.id < b.id)
	var boss: Dictionary = bosses[rng.draw("bosses", bosses.size())]
	result.divisions.append(_division(result.divisions.size() + 1, boss, targets, profile, rng, false))
	result["rng"] = rng.to_dict()
	return result
