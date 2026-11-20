extends RefCounted
## UI-22: what a run earned (RunAwards), read from the Career on the real unlock graph.
const RunAwards = preload("res://src/clubhouse/run_awards.gd")
const Career = preload("res://src/persistence/career_profile.gd")
const ContentSet = preload("res://src/rules/content_set.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	var graph: Dictionary = ContentSet.career_graph(ContentSet.UNLOCKS)
	var career: Dictionary = Career.fresh()
	# Run 1: four spares and The Surveyor's plaque (which also lights the club sign).
	var first := Career.begin_attempt(career)
	career.first_clears["rival.surveyor"] = {"attempt": 1, "career_attempt": first}
	career.totals["spares"] = 4
	# Run 2: three more spares, True Curve completed, The Custodian and the House title.
	var uid := Career.begin_attempt(career)
	career.tally.counts = {"spares": 3, "curved_strikes": 3}
	career.totals["spares"] = 7
	career.totals["curved_strikes"] = 3
	career.mastery["mastery.true_curve"] = {"career_attempt": uid}
	career.first_clears["rival.custodian"] = {"attempt": 2, "career_attempt": uid}
	career.championships["league.house"] = {"wins": 1, "first_attempt": uid, "last_attempt": uid}
	var awards: Dictionary = RunAwards.for_run(career, graph, uid)
	var ids: Array = awards.trophies.map(func(t): return t.id)
	if ids != ["league.house", "rival.custodian", "deco.lane_trim", "deco.trophy_case"]:
		failures.append("run awards: this run's trophies, title first (%s)" % str(ids))
	if awards.trophies.size() > 0 and (awards.trophies[0].headline != "League Champion!" or awards.trophies[0].again):
		failures.append("run awards: a first title is announced as such")
	if "rival.surveyor" in ids or "deco.club_sign" in ids:
		failures.append("run awards: an earlier run's plaque or decoration is not this run's")
	var goals: Array = awards.goals
	var by_id := {}
	for g in goals: by_id[g.id] = g
	var curve: Dictionary = by_id.get("mastery.true_curve", {})
	var spares: Dictionary = by_id.get("mastery.spare_hand", {})
	if goals.is_empty() or goals[0].id != "mastery.true_curve" or not curve.get("completed", false) or curve.before != 0 or curve.after != 3:
		failures.append("run awards: a completed goal leads, from 0 to its threshold (%s)" % str(curve))
	if spares.is_empty() or spares.before != 4 or spares.after != 7 or spares.completed or spares.scope != "career":
		failures.append("run awards: a Career goal moves from where it stood (4 → 7 of 10) (%s)" % str(spares))
	if by_id.has("mastery.mixed_rack"):
		failures.append("run awards: a goal this run did not move is not shown")
	# UI-31 (owner, 2026-11-20): "Only for new awards": a title won again is no award,
	# and a run with nothing earned has no ceremony.
	var repeat := Career.begin_attempt(career)
	career.championships["league.house"] = {"wins": 2, "first_attempt": uid, "last_attempt": repeat}
	if not RunAwards.trophies(career, graph, repeat).filter(func(t): return t.id == "league.house").is_empty():
		failures.append("run awards: a repeat title is no new award")
	if not RunAwards.is_empty(RunAwards.for_run(career, graph, repeat)):
		failures.append("run awards: a run whose only win was a repeat title has no award page (%s)" % str(RunAwards.for_run(career, graph, repeat)))
	var quiet := Career.begin_attempt(career)
	if not RunAwards.is_empty(RunAwards.for_run(career, graph, quiet)):
		failures.append("run awards: a run that earned nothing has no awards")
	# UI-31 (owner, 2026-11-20): a within-run goal that falls short starts over next
	# run, so it is no progress, and a run with only that has no award page. Completed
	# in the run, it shows.
	var short := Career.begin_attempt(career)
	career.tally = {"uid": short, "counts": {}, "materials": ["pin.wood"], "halves": []}
	if not RunAwards.is_empty(RunAwards.for_run(career, graph, short)):
		failures.append("run awards: a within-run goal short of its count (Mixed Rack 1 of 3) is no award (%s)" % str(RunAwards.for_run(career, graph, short)))
	var full := Career.begin_attempt(career)
	career.tally = {"uid": full, "counts": {}, "materials": ["pin.wood", "pin.glass", "pin.lead"], "halves": []}
	career.mastery["mastery.mixed_rack"] = {"career_attempt": full}
	var mixed: Array = RunAwards.goals(career, graph, full).filter(func(g): return g.id == "mastery.mixed_rack")
	if mixed.is_empty() or not mixed[0].completed:
		failures.append("run awards: a within-run goal completed in the run is shown")
	return failures
