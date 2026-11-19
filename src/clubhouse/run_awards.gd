extends RefCounted
## UI-22 (owner, 2026-11-19): what a run earned, for the award ceremony at its end.
## Read from the Career itself (each award records the run it came from), so it is
## right even when the run was resumed after a restart:
## - trophies: the Clubhouse shelf's slots (ClubhouseModel.trophies) that this run
##   earned: a League title (first or again), a rival's plaque, a club decoration.
##   A mastery ribbon comes with its goal, below;
## - goals: every open goal this run moved forward, from where it stood before the
##   run to where it stands now, and every goal it completed.
const Model = preload("res://src/clubhouse/clubhouse_model.gd")
const Career = preload("res://src/persistence/career_profile.gd")
const GOAL_LIMIT := 6 # rows the ceremony shows; completed goals first

static func for_run(career: Dictionary, graph: Dictionary, uid: int) -> Dictionary:
	return {"trophies": trophies(career, graph, uid), "goals": goals(career, graph, uid)}

static func is_empty(awards: Dictionary) -> bool:
	return awards.get("trophies", []).is_empty() and awards.get("goals", []).is_empty()

## The shelf's slots this run earned, titles first, then plaques, then decorations.
static func trophies(career: Dictionary, graph: Dictionary, uid: int) -> Array:
	var out: Array = []
	var before := _counts_before(career, uid)
	for slot in Model.trophies(career, graph):
		if not slot.earned:
			continue
		match String(slot.kind):
			"trophy":
				var entry: Dictionary = career.championships.get(slot.id, {})
				if int(entry.get("last_attempt", -1)) == uid:
					var wins := int(entry.get("wins", 0))
					out.append(slot.merged({"again": wins > 1, "headline": "League Champion!" if wins == 1 else "Champion Again!",
						"detail": "First title" if wins == 1 else "Title number %d" % wins}, true))
			"plaque":
				if int(career.first_clears.get(slot.id, {}).get("career_attempt", -1)) == uid:
					out.append(slot.merged({"again": false, "headline": "Rival Plaque!", "detail": "First cleared this run"}, true))
			"decoration":
				var cosmetic: Dictionary = _cosmetic(graph, slot.id)
				var kind: String = cosmetic.get("requires", {}).keys()[0] if not cosmetic.get("requires", {}).is_empty() else ""
				if not kind.is_empty() and int(before.get(kind, 0)) < int(cosmetic.requires[kind]):
					out.append(slot.merged({"again": false, "headline": "Clubhouse Upgrade!"}, true))
	var order := {"trophy": 0, "plaque": 1, "decoration": 2}
	out.sort_custom(func(a, b): return int(order.get(a.kind, 9)) < int(order.get(b.kind, 9)))
	return out

## Goals this run moved: {id, name, text, reward, asset (its ribbon), before, after,
## threshold, completed, scope ("career" or this run only), tracked}.
static func goals(career: Dictionary, graph: Dictionary, uid: int) -> Array:
	var out: Array = []
	var tally: Dictionary = career.get("tally", {})
	var this_run: Dictionary = tally.get("counts", {}) if int(tally.get("uid", -1)) == uid else {}
	for objective in graph.get("objectives", []):
		if not objective.prerequisites.all(func(g): return g in career.unlocked):
			continue
		var threshold := int(objective.threshold)
		var completed := int(career.mastery.get(objective.id, {}).get("career_attempt", -1)) == uid
		if career.mastery.has(objective.id) and not completed:
			continue # finished in an earlier run
		var after := mini(Career.progress(career, objective, uid), threshold)
		var before := 0
		if objective.scope == "career":
			before = mini(maxi(0, int(career.totals.get(objective.metric, 0)) - int(this_run.get(objective.metric, 0))), threshold)
		if completed:
			after = threshold
		if after <= before and not completed:
			continue
		out.append({"id": objective.id, "name": objective.name, "text": objective.text, "reward": objective.get("reward", ""),
			"asset": Model.asset_id("ribbon", objective.id), "before": before, "after": after, "threshold": threshold,
			"completed": completed, "scope": objective.scope, "tracked": objective.id in career.get("tracked", [])})
	out.sort_custom(func(a, b):
		if a.completed != b.completed: return a.completed
		if a.tracked != b.tracked: return a.tracked
		return float(a.after) / a.threshold > float(b.after) / b.threshold)
	return out.slice(0, GOAL_LIMIT)

## The Clubhouse milestones as they stood before this run: {first_clears, mastery, championships}.
static func _counts_before(career: Dictionary, uid: int) -> Dictionary:
	var clears := 0
	for entry in career.first_clears.values():
		if int(entry.get("career_attempt", -1)) != uid: clears += 1
	var mastered := 0
	for entry in career.mastery.values():
		if int(entry.get("career_attempt", -1)) != uid: mastered += 1
	var titles := 0
	for entry in career.championships.values():
		titles += int(entry.wins) - (1 if int(entry.get("last_attempt", -1)) == uid else 0)
	return {"first_clears": clears, "mastery": mastered, "championships": titles}

static func _cosmetic(graph: Dictionary, id: String) -> Dictionary:
	for c in graph.get("cosmetics", []):
		if c.id == id: return c
	return {}
