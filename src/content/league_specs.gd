extends RefCounted
## E17-L League specs (content/leagues/<league>.json) and the rival roster
## (content/leagues/rivals.json), written ahead of their integration (E22-Lxx).
##
## The roster names one rival per boss rule (20 in all) and assigns each to one of
## the six Leagues, in the counts docs/ROADMAP.md sets. A League spec holds eight
## Divisions in the slice's Division format (DivisionRun.validate_spec), each boss
## with its compatible lane conditions, the League's lane pool, its kits and its
## championship. Division 8's boss is the League champion: one of the League's own
## rivals (`of`) with its rule and one or more `extra_rules` from the same League.
##
## Specs are checked against a prospective catalogue (the shipped catalogue plus the
## authored batches), because their rules, lanes and kits land in E18 later.
const Contracts = preload("res://src/contracts/contracts.gd")
const Division = preload("res://src/rules/division_run.gd")
const DIRECTORY := "res://content/leagues/"
const ROSTER := "res://content/leagues/rivals.json"
const DIVISIONS := 8
## Rivals per League (docs/ROADMAP.md, "How the remaining content is split").
const PER_LEAGUE := {"league.house": 4, "league.neon": 3, "league.salvage": 3, "league.royal": 3, "league.spectral": 3, "league.foundry": 4}
const REACTIONS := ["entrance", "confident", "impressed", "threatened", "defeated", "victorious"]

static func roster() -> Dictionary:
	return Contracts.read_json(ROSTER)

## Every League spec file, sorted by name: [{path, data}].
static func load_all(directory: String = DIRECTORY) -> Array:
	var out: Array = []
	var names := Array(DirAccess.get_files_at(directory)).filter(func(n): return String(n).ends_with(".json") and n != ROSTER.get_file())
	names.sort()
	for file_name in names:
		out.append({"path": directory.path_join(file_name), "data": Contracts.read_json(directory.path_join(file_name))})
	return out

static func _items(catalogue: Dictionary) -> Dictionary:
	var out := {}
	for item in catalogue.get("items", []):
		out[item.id] = item
	return out

## Errors for the roster against a prospective catalogue: one rival per boss rule.
static func validate_roster(data: Variant, catalogue: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary or int(data.get("schema_version", 0)) != 1 or not data.get("rivals") is Array:
		errors.append("rivals.json: needs schema_version 1 and a rivals list")
		return errors
	var items := _items(catalogue)
	var ids := {}
	var rules := {}
	var per_league := {}
	for rival in data.rivals:
		var id: String = str(rival.get("id", ""))
		if not id.begins_with("rival.") or ids.has(id):
			errors.append("rivals.json: rival ids are unique rival.* ids: %s" % id)
		ids[id] = true
		var rule: String = str(rival.get("rule", ""))
		if items.get(rule, {}).get("category", "") != "boss_rule":
			errors.append("rivals.json: %s needs a boss rule in the catalogue or a batch: %s" % [id, rule])
		if rules.has(rule):
			errors.append("rivals.json: %s and %s share %s (one rival per rule)" % [rules[rule], id, rule])
		rules[rule] = id
		var league: String = str(rival.get("league", ""))
		if not PER_LEAGUE.has(league):
			errors.append("rivals.json: %s names an unknown League %s" % [id, league])
		per_league[league] = int(per_league.get(league, 0)) + 1
		for key in ["name", "initials", "signature"]:
			if String(rival.get(key, "")).is_empty():
				errors.append("rivals.json: %s needs %s" % [id, key])
	for item in catalogue.get("items", []):
		if item.category == "boss_rule" and not rules.has(item.id):
			errors.append("rivals.json: boss rule %s has no rival" % item.id)
	for league in PER_LEAGUE:
		if int(per_league.get(league, 0)) != PER_LEAGUE[league]:
			errors.append("rivals.json: %s has %d rivals, the plan sets %d" % [league, int(per_league.get(league, 0)), PER_LEAGUE[league]])
	return errors

## Errors for one League spec against the roster and a prospective catalogue.
static func validate_spec(spec: Variant, roster_data: Dictionary, catalogue: Dictionary, label: String) -> Array[String]:
	var errors: Array[String] = []
	if not spec is Dictionary or int(spec.get("schema_version", 0)) != 1:
		errors.append(label + ": needs schema_version 1")
		return errors
	var items := _items(catalogue)
	var league: String = str(spec.get("id", ""))
	var mine := {}
	for rival in roster_data.get("rivals", []):
		if rival.get("league") == league:
			mine[rival.id] = rival
	if not PER_LEAGUE.has(league) or mine.is_empty():
		errors.append("%s: %s is not a roster League" % [label, league])
		return errors
	var pool: Array = spec.get("lanes", [])
	for lane in pool:
		if items.get(lane, {}).get("category", "") != "lane_condition":
			errors.append("%s: lane %s is not a lane condition" % [label, lane])
	var divisions: Array = spec.get("divisions", [])
	if divisions.size() != DIVISIONS:
		errors.append("%s: a League has %d Divisions (found %d)" % [label, DIVISIONS, divisions.size()])
	var met := {}
	var last_target := 0
	for i in divisions.size():
		var division: Dictionary = divisions[i]
		var where := "%s Division %d" % [label, i + 1]
		if int(division.get("division", 0)) != i + 1:
			errors.append(where + ": Divisions are numbered 1 to 8 in order")
		for e in Division.validate_spec(division, catalogue):
			errors.append("%s: %s" % [where, e])
		var matches: Array = division.get("matches", [])
		if matches.size() != 3:
			continue
		var boss: Dictionary = matches[2]
		if int(matches[0].get("target", 0)) <= last_target:
			errors.append(where + ": every match target rises across the League (LeagueRun)")
		last_target = int(boss.get("target", 0))
		var lanes: Array = boss.get("lanes", [])
		if lanes.is_empty() or not lanes.all(func(l): return l in pool):
			errors.append(where + ": the boss lists at least one lane from the League's pool")
		var rival := {}
		for r in division.get("rivals", []):
			if r.get("id") == boss.get("rival"):
				rival = r
		errors.append_array(_rival(rival, mine, i + 1 == DIVISIONS, where))
		met[rival.get("of", rival.get("id", ""))] = true
	for id in mine:
		if not met.has(id):
			errors.append("%s: roster rival %s never appears as a boss" % [label, id])
	for kit in spec.get("kits", []):
		errors.append_array(_kit(kit, items, label))
	if spec.get("kits", []).is_empty():
		errors.append(label + ": a League lists its kits")
	var championship: Dictionary = spec.get("championship", {})
	if championship.get("gates", []).is_empty():
		errors.append(label + ": the championship names its gates")
	if championship.has("opens") and not PER_LEAGUE.has(championship.opens):
		errors.append(label + ": the championship opens a roster League")
	return errors

static func _rival(rival: Dictionary, mine: Dictionary, final: bool, where: String) -> Array[String]:
	var errors: Array[String] = []
	if rival.is_empty():
		errors.append(where + ": the boss names a rival defined in the Division")
		return errors
	var base: String = str(rival.get("of", rival.get("id", "")))
	if not mine.has(base):
		errors.append("%s: %s is not one of this League's roster rivals" % [where, base])
		return errors
	if rival.get("rule") != mine[base].rule:
		errors.append("%s: %s plays its roster rule %s" % [where, base, mine[base].rule])
	if final:
		var league_rules: Array = mine.values().map(func(r): return r.rule)
		var extra: Array = rival.get("extra_rules", [])
		if not rival.has("of") or extra.is_empty() or not extra.all(func(r): return r in league_rules and r != rival.rule):
			errors.append(where + ": the champion is a League rival (`of`) with extra rules from the same League")
	elif rival.has("of") or rival.has("extra_rules"):
		errors.append(where + ": only Division 8's champion carries extra rules")
	if String(rival.get("intro", "")).length() < 60:
		errors.append(where + ": %s needs an intro naming its rule" % base)
	var reactions: Dictionary = rival.get("reactions", {})
	if not REACTIONS.all(func(k): return not String(reactions.get(k, "")).is_empty()):
		errors.append("%s: %s needs every reaction (%s)" % [where, base, ", ".join(REACTIONS)])
	var first: Dictionary = rival.get("first_clear", {})
	if first.get("unlocks", []).is_empty() or String(first.get("text", "")).is_empty():
		errors.append(where + ": %s names its first-clear gate and text" % base)
	return errors

static func _kit(kit: Dictionary, items: Dictionary, label: String) -> Array[String]:
	var errors: Array[String] = []
	var id: String = str(kit.get("id", ""))
	if items.get(id, {}).get("category", "") != "kit":
		errors.append("%s: kit %s is not a kit item" % [label, id])
	if kit.get("unlock", "") != "initial" and not String(kit.get("unlock", "")).begins_with("gate."):
		errors.append("%s: kit %s is initial or names its unlock gate" % [label, id])
	if kit.has("pins"):
		var pins: Array = kit.pins
		if pins.size() != 10 or not pins.all(func(p): return items.get(p, {}).get("category", "") == "pin"):
			errors.append("%s: kit %s racks ten catalogue pins" % [label, id])
		if not kit.get("deck", []).all(func(b): return items.get(b, {}).get("category", "") == "ball") or int(kit.get("money", -1)) < 0:
			errors.append("%s: kit %s has a deck of catalogue balls and starting money" % [label, id])
	return errors

## A one-line summary for qa.py content.
static func summary(specs: Array, roster_data: Dictionary) -> String:
	var counts := {}
	for rival in roster_data.get("rivals", []):
		counts[rival.league] = int(counts.get(rival.league, 0)) + 1
	return "rivals %d %s; League specs %s" % [roster_data.get("rivals", []).size(), str(counts), str(specs.map(func(s): return "%s (%d Divisions)" % [s.data.get("id", "?"), s.data.get("divisions", []).size()]))]
