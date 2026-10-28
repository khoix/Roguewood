extends RefCounted
## The Career record kept apart from attempt saves (E10; E15 schema 2, design §16,
## ADR 010). It holds horizontal progress only: unlock gates, first clears,
## championships, mastery objectives, records and the collection. Nothing here
## raises a score, a payout or starting money.
##
## Schema 2 (schema 1 migrates by adding the new keys):
##   first_clears   rival id -> {attempt, career_attempt}
##   unlocked       gate ids in the order they were banked (an attempt copies them)
##   awards         gate id -> {source, career_attempt}: why each gate is held
##   intros_seen    rival id -> true
##   attempts       attempts begun in this Career; each attempt's career_attempt
##                  (its uid) is the count when it began, so uids never repeat
##   championships  league id -> {wins, first_attempt, last_attempt}
##   mastery        objective id -> {career_attempt}: completed objectives
##   totals         metric -> count over normal attempts (cumulative objectives)
##   tally          the attempt being counted: {uid, frame, practice, counts, materials}
##   records        league id -> {attempts, practice_attempts, best_division,
##                  best_total, best_frame, practice_best_frame, wins}
##   items          item id -> {first_attempt, attempts, league_wins, last_attempt,
##                  last_win}: discovered items and their history
##
## Every award is banked the moment it is earned, before the attempt snapshot
## records the step that earned it, and every update is idempotent: a gate is held
## once; a frame counts once (tally.frame marks the last frame counted for that
## uid); a championship or an item's attempt counts once per uid. A reload after a
## crash between the two writes therefore neither repeats nor loses a reward.
## Practice attempts record discoveries and practice records but never gameplay
## unlocks, mastery progress or championships.
const SCHEMA_VERSION := 2
const COUNTED := ["strikes", "spares", "curved_strikes"]

static func fresh() -> Dictionary:
	return {"first_clears": {}, "unlocked": [], "awards": {}, "intros_seen": {}, "attempts": 0, "championships": {},
		"mastery": {}, "totals": {}, "tally": {}, "records": {}, "items": {}}

## Fills missing keys (and drops unknown ones) so older in-memory records fit.
static func normalized(data: Dictionary) -> Dictionary:
	var out := fresh()
	for key in out:
		if data.has(key) and (typeof(data[key]) == typeof(out[key]) or (key == "attempts" and data[key] is float)):
			out[key] = data[key].duplicate(true) if data[key] is Dictionary or data[key] is Array else int(data[key])
	return out

## Career v1 -> v2: the new records start empty; each held gate is attributed to a
## first clear (v1 could only bank boss gates).
static func migrate_v1(payload: Dictionary) -> Dictionary:
	var out := normalized(payload)
	for gate in out.unlocked:
		out.awards[gate] = {"source": "boss (from a v1 Career)", "career_attempt": 0}
	return out

static func validate(data: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary:
		errors.append("not a record")
		return errors
	for key in fresh():
		if not data.has(key):
			errors.append("missing " + key)
	return errors

## Gates and items the Career names that the current graph no longer declares:
## kept (a later version may bring them back), but reported.
static func unknown_ids(career: Dictionary, graph: Dictionary) -> Array:
	var out: Array = []
	for gate in career.unlocked:
		if not graph.get("gates", {}).has(gate):
			out.append(gate)
	return out

## Begins an attempt: returns its uid. Counting starts with its first banked frame.
static func begin_attempt(career: Dictionary) -> int:
	career.attempts = int(career.attempts) + 1
	career.tally = {"uid": career.attempts, "frame": 0, "practice": false, "counts": {}, "materials": []}
	return int(career.attempts)

static func _award(career: Dictionary, gate: String, source: String, uid: int) -> bool:
	if gate in career.unlocked:
		return false
	career.unlocked.append(gate)
	career.awards[gate] = {"source": source, "career_attempt": uid}
	return true

## Banks a rival's first clear; returns true only the first time. Practice never banks.
static func record_first_clear(career: Dictionary, rival: Dictionary, attempt: int, uid: int = 0, practice: bool = false) -> bool:
	if practice or career.first_clears.has(rival.id):
		return false
	career.first_clears[rival.id] = {"attempt": attempt, "career_attempt": uid}
	for gate in rival.first_clear.unlocks:
		_award(career, gate, "boss:" + rival.id, uid)
	return true

## A League won. The first win awards its championship gates; later wins add to
## the record only. Items owned in the winning build count a League win. Idempotent
## per uid. Returns {counted, first, gates (newly held)}.
static func record_championship(career: Dictionary, league: Dictionary, uid: int, owned: Array, practice: bool = false) -> Dictionary:
	var out := {"counted": false, "first": false, "gates": []}
	if practice:
		return out
	var entry: Dictionary = career.championships.get(league.id, {"wins": 0, "first_attempt": uid, "last_attempt": 0})
	if int(entry.last_attempt) == uid:
		return out
	out.counted = true
	out.first = int(entry.wins) == 0
	entry.wins = int(entry.wins) + 1
	entry.last_attempt = uid
	career.championships[league.id] = entry
	if out.first:
		for gate in league.championship.gates:
			if _award(career, gate, "championship:" + league.id, uid):
				out.gates.append(gate)
	_record(career, league.id).wins = int(entry.wins)
	for id in owned:
		var item: Dictionary = career.items.get(id, {})
		if not item.is_empty() and int(item.get("last_win", 0)) != uid:
			item.league_wins = int(item.league_wins) + 1
			item.last_win = uid
	return out

## Discovered items: each owned item notes this attempt once. Practice discovers too.
static func record_items(career: Dictionary, ids: Array, uid: int) -> bool:
	var changed := false
	for id in ids:
		var item: Dictionary = career.items.get(id, {})
		if item.is_empty():
			item = {"first_attempt": uid, "attempts": 0, "league_wins": 0, "last_attempt": 0, "last_win": 0}
			career.items[id] = item
			changed = true
		if int(item.last_attempt) != uid:
			item.attempts = int(item.attempts) + 1
			item.last_attempt = uid
			changed = true
	return changed

static func _record(career: Dictionary, league_id: String) -> Dictionary:
	if not career.records.has(league_id):
		career.records[league_id] = {"attempts": 0, "practice_attempts": 0, "best_division": 0, "best_total": 0, "best_frame": 0,
			"practice_best_frame": 0, "wins": 0}
	return career.records[league_id]

## A frame banked in attempt uid. stats: frame_stats() of the frame. context:
## {league, practice, division, total, frame_score}. Counts once per frame number;
## completes objectives whose progress reaches the threshold (normal attempts only).
## Returns {counted, completed: [objectives], gates: [newly held]}.
static func bank_frame(career: Dictionary, uid: int, frame_number: int, stats: Dictionary, context: Dictionary, objectives: Array) -> Dictionary:
	var out := {"counted": false, "completed": [], "gates": []}
	var practice: bool = context.get("practice", false)
	if career.tally.is_empty() or int(career.tally.uid) != uid:
		# A resumed attempt that is not the latest begun: count it from here.
		career.tally = {"uid": uid, "frame": 0, "practice": practice, "counts": {}, "materials": []}
	var tally: Dictionary = career.tally
	if frame_number <= int(tally.frame):
		return out
	out.counted = true
	var record := _record(career, context.get("league", ""))
	if int(tally.frame) == 0 or bool(tally.practice) != practice:
		# The attempt's first counted frame (or practice switched before throwing).
		record["practice_attempts" if practice else "attempts"] = int(record["practice_attempts" if practice else "attempts"]) + 1
	tally.frame = frame_number
	tally.practice = practice
	if practice:
		record.practice_best_frame = maxi(int(record.practice_best_frame), int(context.get("frame_score", 0)))
		return out
	record.best_frame = maxi(int(record.best_frame), int(context.get("frame_score", 0)))
	record.best_total = maxi(int(record.best_total), int(context.get("total", 0)))
	record.best_division = maxi(int(record.best_division), int(context.get("division", 0)))
	for metric in COUNTED:
		var n := int(stats.get(metric, 0))
		tally.counts[metric] = int(tally.counts.get(metric, 0)) + n
		career.totals[metric] = int(career.totals.get(metric, 0)) + n
	for id in stats.get("materials", []):
		if id not in tally.materials:
			tally.materials.append(id)
	for objective in objectives:
		if career.mastery.has(objective.id) or not objective.prerequisites.all(func(g): return g in career.unlocked):
			continue
		if progress(career, objective, uid) >= int(objective.threshold):
			career.mastery[objective.id] = {"career_attempt": uid}
			out.completed.append(objective)
			for gate in objective.gates:
				if _award(career, gate, "mastery:" + objective.id, uid):
					out.gates.append(gate)
	return out

## An objective's progress: Career totals, or this attempt's tally (0 for another uid).
static func progress(career: Dictionary, objective: Dictionary, uid: int) -> int:
	if career.mastery.has(objective.id):
		return int(objective.threshold)
	if objective.scope == "career":
		return int(career.totals.get(objective.metric, 0))
	if career.tally.is_empty() or int(career.tally.uid) != uid:
		return 0
	if objective.metric == "pin_materials":
		return career.tally.materials.size()
	return int(career.tally.counts.get(objective.metric, 0))

## What one scored frame contributes: {strikes, spares, curved_strikes (a strike
## whose first roll was curved), materials (distinct pin items knocked down)}.
static func frame_stats(category: String, reports: Array, pins: Dictionary, curved: Callable) -> Dictionary:
	var materials: Array = []
	for report in reports:
		for position in report.roll_result.fallen_positions:
			var id: String = pins.get(int(position), pins.get(str(int(position)), ""))
			if not id.is_empty() and id not in materials:
				materials.append(id)
	var strike := category == "strike"
	return {"strikes": 1 if strike else 0, "spares": 1 if category == "spare" else 0,
		"curved_strikes": 1 if strike and not reports.is_empty() and curved.call(float(reports[0].launch.spin)) else 0, "materials": materials}

## Locked, Available, Discovered or Mastered (owned in a League win), per §16.
static func collection_state(career: Dictionary, item: Dictionary) -> String:
	if item.unlock.kind != "initial" and not item.unlock.prerequisites.all(func(g): return g in career.unlocked):
		return "locked"
	var history: Dictionary = career.items.get(item.id, {})
	if history.is_empty():
		return "available"
	return "mastered" if int(history.league_wins) > 0 else "discovered"

## Gates banked during attempt uid, in order.
static func gates_from(career: Dictionary, uid: int) -> Array:
	return career.unlocked.filter(func(g): return int(career.awards.get(g, {}).get("career_attempt", -1)) == uid)

## Up to three goals not yet complete, with progress, for results and the menu.
static func goals(career: Dictionary, objectives: Array, uid: int, limit: int = 3) -> Array:
	var out: Array = []
	for objective in objectives:
		if career.mastery.has(objective.id) or not objective.prerequisites.all(func(g): return g in career.unlocked):
			continue
		out.append({"id": objective.id, "name": objective.name, "text": objective.text, "progress": progress(career, objective, uid), "threshold": int(objective.threshold)})
		if out.size() == limit:
			break
	return out

## One line for the menu.
static func summary(career: Dictionary, objectives: Array) -> String:
	var titles := 0
	for entry in career.championships.values():
		titles += int(entry.wins)
	return "Career: %d rival%s cleared · %d championship%s · %d/%d mastery goals · %d attempt%s" % [career.first_clears.size(),
		"" if career.first_clears.size() == 1 else "s", titles, "" if titles == 1 else "s", career.mastery.size(), objectives.size(),
		int(career.attempts), "" if int(career.attempts) == 1 else "s"]
