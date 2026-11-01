extends RefCounted
## E16 Clubhouse model: League board rows and records, binder states and their
## requirements and history, trophy shelf (titles, ribbons, plaques, decorations),
## goals with tracking, latest unlocks, cosmetic validation and art placeholders.
const Model = preload("res://src/clubhouse/clubhouse_model.gd")
const Art = preload("res://src/clubhouse/clubhouse_art.gd")
const Career = preload("res://src/persistence/career_profile.gd")
const ContentSet = preload("res://src/rules/content_set.gd")
const Graph = preload("res://src/career/unlock_graph.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	var graph := ContentSet.career_graph(ContentSet.UNLOCKS)
	_expect(graph.errors.is_empty(), "the production graph (with cosmetics) validates: %s" % str(graph.errors), failures)
	_fresh(graph, failures)
	_after_play(graph, failures)
	_goals(graph, failures)
	_cosmetic_rules(failures)
	_art(failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _entry(entries: Array, id: String) -> Dictionary:
	for e in entries:
		if e.id == id:
			return e
	return {}

static func _fresh(graph: Dictionary, failures: Array[String]) -> void:
	var career := Career.fresh()
	var rows := Model.board(career, graph)
	_expect(rows.size() == 2 and rows[0].id == "league.house" and rows[0].access.is_empty() and Model.record_line(rows[0]) == "House League · not played yet",
		"a fresh board: both Leagues open, nothing played", failures)
	var binder := Model.binder(career, graph, graph.catalogue)
	var counts := Model.binder_counts(binder)
	_expect(binder.size() == 72 and counts.locked == 9 and counts.available == 63 and counts.discovered == 0, "a fresh binder: 9 Locked, 63 Available (boss rules excluded)", failures)
	var encore := _entry(binder, "charm.encore")
	_expect(encore.state == "locked" and encore.requirement == "Beat The Surveyor (House League)" and encore.asset == _entry(graph.catalogue.items, "charm.encore").assets.card and Art.has_art(encore.asset),
		"Encore names its unlocking rival and resolves its catalogue card artwork", failures)
	_expect(Model.inspect(encore, graph.catalogue).contains("Unlock: Beat The Surveyor (House League). It then joins the pool from your next attempt."),
		"inspecting a locked card explains the unlock and the next-attempt rule", failures)
	var shelf := Model.trophies(career, graph)
	_expect(shelf.all(func(t): return not t.earned) and shelf.filter(func(t): return t.kind == "plaque").map(func(t): return t.id) == ["rival.custodian", "rival.surveyor"],
		"a fresh shelf: nothing earned; plaques only for the slice's rivals, not provisional encounters", failures)
	_expect(shelf.filter(func(t): return t.kind == "trophy").map(func(t): return t.asset) == ["trophy.house", "trophy.house_campaign"]
		and shelf.filter(func(t): return t.kind == "decoration").size() == 3, "trophy and decoration slots carry stable asset IDs", failures)
	_expect(Model.latest(career, graph).is_empty(), "no unlocks yet", failures)

static func _after_play(graph: Dictionary, failures: Array[String]) -> void:
	var career := Career.fresh()
	var slice := ContentSet.load_set("slice")
	var uid := Career.begin_attempt(career)
	Career.record_items(career, ["pin.wood", "ball.echo", "charm.flat_bonus"], uid)
	Career.record_first_clear(career, slice.divisions[0].rivals[0], 1, uid)
	Career.bank_frame(career, uid, 1, {"spares": 1, "strikes": 0, "curved_strikes": 0, "materials": ["pin.wood"]},
		{"league": "league.house", "practice": false, "division": 2, "total": 4000, "frame_score": 600}, graph.objectives)
	var later := Career.begin_attempt(career)
	Career.record_items(career, ["pin.wood", "charm.finisher"], later)
	Career.record_first_clear(career, slice.divisions[1].rivals[0], 1, later)
	Career.record_championship(career, graph.leagues["league.house"], later, ["pin.wood", "charm.finisher"])
	var binder := Model.binder(career, graph, graph.catalogue)
	_expect(_entry(binder, "pin.wood").state == "mastered" and _entry(binder, "charm.flat_bonus").state == "discovered"
		and _entry(binder, "charm.encore").state == "available" and _entry(binder, "charm.gold_rush").state == "available",
		"all four states: Mastered (owned in a win), Discovered, Available (unlocked or never owned)", failures)
	_expect(Model.inspect(_entry(binder, "pin.wood"), graph.catalogue).contains("Owned in 2 attempts; in 1 League win.")
		and Model.inspect(_entry(binder, "charm.flat_bonus"), graph.catalogue).contains("Win a League with it in your build to master it."), "inspect shows history", failures)
	_expect(Model.binder(career, graph, graph.catalogue, "pin").all(func(e): return e.category == "pin") and Model.binder(career, graph, graph.catalogue, "pin").size() == 10,
		"the binder filters by category", failures)
	var row: Dictionary = Model.board(career, graph)[0]
	_expect(row.titles == 1 and row.attempts == 1 and row.best_total == 4000 and Model.record_line(row).contains("best Division 2 · best total 4000 · best frame 600 · 1 title"),
		"the board shows records and titles", failures)
	var shelf := Model.trophies(career, graph)
	var earned: Array = shelf.filter(func(t): return t.earned).map(func(t): return t.id)
	_expect(earned == ["league.house", "rival.custodian", "rival.surveyor", "deco.club_sign", "deco.trophy_case"],
		"titles, plaques and the milestone decorations are earned: %s" % str(earned), failures)
	var latest := Model.latest(career, graph)
	_expect(latest.size() == 3 and latest[0].gate == "gate.house_champion" and latest[0].text == "Win the House League: Crown Pin, Split Specialist, Crown Jewel, Echo Charge join the shop pool from your next attempt."
		and latest[2].text == "Beat The Surveyor (House League): Encore joins the shop pool from your next attempt.", "latest unlocks, newest first: %s" % str(latest.map(func(l): return l.text)), failures)

static func _goals(graph: Dictionary, failures: Array[String]) -> void:
	var career := Career.fresh()
	var objectives: Array = graph.objectives
	_expect(Career.goals(career, objectives, 0).map(func(g): return g.id) == ["mastery.spare_hand", "mastery.true_curve", "mastery.mixed_rack"], "untracked: the first three open goals", failures)
	_expect(Career.toggle_tracked(career, "mastery.mixed_rack", objectives).is_empty() and Career.goals(career, objectives, 0).map(func(g): return g.id) == ["mastery.mixed_rack"],
		"following one goal shows it alone", failures)
	Career.toggle_tracked(career, "mastery.spare_hand", objectives)
	Career.toggle_tracked(career, "mastery.true_curve", objectives)
	var extra := {"id": "mastery.extra", "name": "E", "text": "e", "metric": "strikes", "threshold": 1, "scope": "career", "prerequisites": [], "gates": ["gate.e"], "reward": "e"}
	_expect(Career.toggle_tracked(career, "mastery.extra", objectives + [extra]).contains("follow 3 goals at once") and career.tracked.size() == 3, "at most three goals are followed", failures)
	_expect(Career.toggle_tracked(career, "mastery.true_curve", objectives).is_empty() and career.tracked.size() == 2, "unfollowing frees a place", failures)
	_expect(not Career.toggle_tracked(career, "mastery.nope", objectives).is_empty(), "unknown goals are refused", failures)
	career.mastery["mastery.spare_hand"] = {"career_attempt": 1}
	_expect(Career.toggle_tracked(career, "mastery.spare_hand", objectives).is_empty() and "mastery.spare_hand" not in career.tracked, "a completed goal can be unfollowed", failures)
	_expect(Career.toggle_tracked(career, "mastery.spare_hand", objectives) == "already complete", "a completed goal cannot be followed", failures)
	var rows := Model.goals(career, graph)
	_expect(rows.filter(func(g): return g.done).map(func(g): return g.id) == ["mastery.spare_hand"] and rows.filter(func(g): return g.tracked).map(func(g): return g.id) == ["mastery.mixed_rack"],
		"the Goals page shows done and tracked states", failures)
	_expect(Career.validate(Career.normalized({"first_clears": {}, "unlocked": [], "awards": {}, "intros_seen": {}, "attempts": 0, "championships": {}, "mastery": {},
		"totals": {}, "tally": {}, "records": {}, "items": {}})).is_empty(), "a schema 2 Career saved before tracking still validates", failures)

static func _cosmetic_rules(failures: Array[String]) -> void:
	var registry := Graph.read(ContentSet.UNLOCKS)
	var graph := ContentSet.career_graph(ContentSet.UNLOCKS)
	var sources := {}
	for league_id in graph.leagues:
		sources[league_id] = ContentSet.graph_source(ContentSet.load_set(graph.leagues[league_id].content_set))
	registry.cosmetics.append({"id": "deco.club_sign", "name": "Again", "requires": {"first_clears": 1}})
	_expect(Graph.build(registry, graph.catalogue, sources).errors.any(func(e): return e.contains("duplicate id: deco.club_sign")), "cosmetic IDs are unique", failures)
	registry.cosmetics[-1] = {"id": "deco.bad", "name": "Bad", "requires": {"score": 100}}
	_expect(Graph.build(registry, graph.catalogue, sources).errors.any(func(e): return e.contains("deco.bad: requires one milestone count")), "cosmetics need a known milestone", failures)

static func _art(failures: Array[String]) -> void:
	var slot := Art.slot("test.missing_clubhouse_art", 96)
	_expect(slot.name == "Placeholder" and slot.get_child(0).text.contains("test.missing_clubhouse_art"), "missing art draws a placeholder naming its asset ID", failures)
	_expect(Art.path_for("trophy.house") == "res://assets/clubhouse/trophy.house.png" and Art.path_for("res://x.png") == "res://x.png", "asset paths resolve by ID", failures)
	slot.free()
