extends RefCounted
## E15 Career (ADR 010): the unlock graph's validation (IDs, kinds, sources,
## circular prerequisites, reachability, self-unlocks, starting counters), the
## production and lab graphs, Career v2 awards and their idempotence, mastery,
## championships, practice policy, records, collection states, attempt pool
## snapshots and the v1 -> v2 migration.
const Graph = preload("res://src/career/unlock_graph.gd")
const Career = preload("res://src/persistence/career_profile.gd")
const ContentSet = preload("res://src/rules/content_set.gd")
const Store = preload("res://src/persistence/save_store.gd")
const Snapshot = preload("res://src/persistence/attempt_snapshot.gd")
const Shop = preload("res://src/rules/shop.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const GOLDEN := "res://tests/fixtures/saves/v1"
const GOLDEN_V2 := "res://tests/fixtures/saves/v2"

static func run() -> Array[String]:
	var failures: Array[String] = []
	_shipped_graphs(failures)
	_graph_refusals(failures)
	_awards(failures)
	_mastery(failures)
	_championships(failures)
	_practice(failures)
	_pool_snapshot(failures)
	_migration(failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _item(id: String, category: String, kind: String = "initial", gates: Array = [], tags: Array = ["basic"]) -> Dictionary:
	return {"id": id, "category": category, "rarity": "common", "pool_weight": 1, "earliest_division": 1,
		"unlock": {"kind": kind, "prerequisites": gates}, "synergy_tags": tags}

## A small valid world: one League with one rival, a boss-locked Charm, a
## championship-locked pin and a mastery-locked ball.
static func _world() -> Dictionary:
	var registry := {"schema_version": 1,
		"leagues": [{"id": "league.a", "name": "A", "content_set": "a", "access": [], "championship": {"gates": ["gate.a_champion"], "text": "won"}}],
		"gates": [{"id": "gate.a_rival", "kind": "boss", "name": "Rival beaten"}, {"id": "gate.a_champion", "kind": "championship", "name": "A champion"},
			{"id": "gate.spares", "kind": "mastery", "name": "Spares"}],
		"objectives": [{"id": "mastery.spares", "name": "Spares", "text": "Convert 3 spares.", "metric": "spares", "threshold": 3, "scope": "career",
			"prerequisites": [], "gates": ["gate.spares"], "reward": "a ribbon"}],
		"counters": {"boss_rule.x": ["counter"]}}
	var catalogue := {"items": [_item("pin.one", "pin"), _item("pin.two", "pin"), _item("charm.counter", "charm", "initial", [], ["counter"]),
		_item("charm.locked", "charm", "boss", ["gate.a_rival"]), _item("pin.champ", "pin", "championship", ["gate.a_champion"]),
		_item("ball.master", "ball", "mastery", ["gate.spares"])]}
	var sources := {"league.a": {"rivals": [{"id": "rival.a", "rule": "boss_rule.x", "first_clear": {"unlocks": ["gate.a_rival"], "text": "x"}}],
		"bosses": [{"rule": "boss_rule.x", "division": 1}], "kit": {"deck": [], "pins": []}}}
	return {"registry": registry, "catalogue": catalogue, "sources": sources}

static func _errors_for(change: Callable) -> Array:
	var world := _world()
	change.call(world)
	return Graph.build(world.registry, world.catalogue, world.sources).errors

static func _has(errors: Array, text: String) -> bool:
	return errors.any(func(e): return String(e).contains(text))

static func _shipped_graphs(failures: Array[String]) -> void:
	var production := ContentSet.career_graph(ContentSet.UNLOCKS)
	_expect(production.errors.is_empty(), "the production unlock graph validates: %s" % str(production.errors), failures)
	_expect(production.league_of_set.get("slice") == "league.house" and production.league_of_set.get("campaign") == "league.house_campaign",
		"the production graph spans the slice and the campaign", failures)
	_expect(production.items_by_gate.get("gate.surveyor_cleared") == ["charm.encore"] and production.items_by_gate.get("gate.custodian_cleared") == ["charm.standing_order"],
		"the slice's boss gates unlock Encore and Standing Order", failures)
	_expect(production.objectives.size() == 3 and production.gates.size() == 7, "three mastery objectives and seven gates", failures)
	_expect(production.availability.charm == {"initial": 31, "locked": 5} and production.availability.pin == {"initial": 7, "locked": 1}, "availability report: 31 Charms initially (twelve House Charms, E18-C08…C09), 5 locked; 7 pins and Crown (E18-C01…C03)", failures)
	var lab := ContentSet.career_graph(ContentSet.LAB_UNLOCKS)
	_expect(lab.errors.is_empty() and lab.items_by_gate.get("gate.lab_rival") == ["pin.lab_lead"], "the lab fixture graph validates", failures)
	_expect(Graph.build(_world().registry, _world().catalogue, _world().sources).errors.is_empty(), "the synthetic world validates", failures)
	for set_id in ["slice", "lab", "campaign"]:
		_expect(not String(ContentSet.load_set(set_id).unlocks).is_empty(), set_id + " names its unlock registry", failures)

static func _graph_refusals(failures: Array[String]) -> void:
	_expect(_has(_errors_for(func(w): w.catalogue.items.append(_item("charm.ghost", "charm", "boss", ["gate.ghost"]))), "requires undeclared gate gate.ghost"),
		"an item waiting for an undeclared gate is refused", failures)
	_expect(_has(_errors_for(func(w): w.registry.gates.append({"id": "gate.orphan", "kind": "boss", "name": "Orphan"})), "gate gate.orphan is never awarded"),
		"a gate nothing awards is refused", failures)
	_expect(_has(_errors_for(func(w): w.catalogue.items[3].unlock.kind = "mastery"), "is a mastery unlock but waits for boss gate"),
		"an item's unlock kind must match its gate", failures)
	_expect(_has(_errors_for(func(w): w.registry.gates.append({"id": "gate.a_rival", "kind": "boss", "name": "Again"})), "duplicate id: gate.a_rival"),
		"duplicate IDs are refused", failures)
	_expect(_has(_errors_for(func(w): w.registry.gates[0].id = "a_rival"), "gate id must start with gate."), "malformed IDs are refused", failures)
	_expect(_has(_errors_for(func(w): w.sources["league.a"].rivals[0].first_clear.unlocks = ["gate.a_champion"]), "is a championship gate but league.a:rival.a awards it"),
		"a boss cannot award a championship gate", failures)
	# Circular prerequisites.
	_expect(_has(_errors_for(func(w): w.registry.leagues[0].access = ["gate.a_champion"]), "circular prerequisite"),
		"a League needing its own championship is circular", failures)
	_expect(_has(_errors_for(func(w): w.registry.objectives[0].prerequisites = ["gate.spares"]), "circular prerequisite: gate.spares -> mastery.spares -> gate.spares"),
		"an objective needing its own gate is circular", failures)
	_expect(_has(_errors_for(func(w):
		w.registry.gates.append({"id": "gate.b", "kind": "mastery", "name": "B"})
		w.registry.objectives.append({"id": "mastery.b", "name": "B", "text": "b", "metric": "strikes", "threshold": 1, "scope": "career", "prerequisites": ["gate.spares"], "gates": ["gate.b"], "reward": "b"})
		w.registry.objectives[0].prerequisites = ["gate.b"]), "circular prerequisite"), "a longer loop between objectives is circular", failures)
	# Unreachable without a loop: a second League whose access gate no source can award.
	var unreachable := _errors_for(func(w):
		w.registry.gates.append({"id": "gate.never", "kind": "championship", "name": "Never"})
		w.registry.leagues.append({"id": "league.b", "name": "B", "content_set": "b", "access": ["gate.never"], "championship": {"gates": ["gate.never"], "text": "b"}})
		w.sources["league.b"] = {"rivals": [], "bosses": [], "kit": {}})
	_expect(_has(unreachable, "circular prerequisite") or _has(unreachable, "League league.b can never be entered"), "a League behind its own title is caught", failures)
	# Self-unlock: three materials in one attempt with only two pins outside the reward.
	var self_unlock := _errors_for(func(w):
		w.registry.gates.append({"id": "gate.mix", "kind": "mastery", "name": "Mix"})
		w.registry.objectives.append({"id": "mastery.mix", "name": "Mix", "text": "m", "metric": "pin_materials", "threshold": 3, "scope": "attempt", "prerequisites": [], "gates": ["gate.mix"], "reward": "m"})
		w.catalogue.items[4].unlock = {"kind": "mastery", "prerequisites": ["gate.mix"]})
	_expect(_has(self_unlock, "objective mastery.mix can never be completed") and _has(self_unlock, "pin.champ is unreachable"),
		"an objective that needs the pin it unlocks is refused", failures)
	_expect(_has(_errors_for(func(w): w.registry.objectives[0].merge({"metric": "pin_materials", "scope": "career"}, true)), "cannot be counted with scope career"),
		"pin materials are counted per attempt only", failures)
	_expect(_has(_errors_for(func(w): w.registry.objectives[0].threshold = 0), "threshold must be a positive integer"), "thresholds are positive integers", failures)
	_expect(_has(_errors_for(func(w): w.registry.objectives[0].metric = "luck"), "unknown metric luck"), "unknown metrics are refused", failures)
	# Starting counters (§16): never only behind the rival they are needed for.
	_expect(_has(_errors_for(func(w): w.registry.counters = {}), "declares no counter tags"), "every boss rule declares its counters", failures)
	_expect(_has(_errors_for(func(w): w.catalogue.items[2].unlock = {"kind": "boss", "prerequisites": ["gate.a_rival"]}), "no initially available counter to boss_rule.x"),
		"a counter locked behind its own rival is refused", failures)
	_expect(_errors_for(func(w):
		w.catalogue.items[2].unlock = {"kind": "boss", "prerequisites": ["gate.a_rival"]}
		w.sources["league.a"].kit = {"deck": ["charm.counter"], "pins": []}).is_empty(), "a counter in the kit satisfies the check", failures)
	_expect(not Graph.build({"schema_version": 2}, {}, {}).errors.is_empty(), "an unknown registry version is refused", failures)

static func _awards(failures: Array[String]) -> void:
	var career := Career.fresh()
	var first := Career.begin_attempt(career)
	var second := Career.begin_attempt(career)
	_expect(first == 1 and second == 2 and career.attempts == 2 and career.tally.uid == 2, "attempt uids never repeat", failures)
	var rival := {"id": "rival.a", "first_clear": {"unlocks": ["gate.a_rival"], "text": "x"}}
	_expect(Career.record_first_clear(career, rival, 1, second) and career.unlocked == ["gate.a_rival"]
		and career.awards["gate.a_rival"] == {"source": "boss:rival.a", "career_attempt": 2}, "a first clear banks its gate with provenance", failures)
	_expect(not Career.record_first_clear(career, rival, 3, 3) and career.unlocked.size() == 1 and career.first_clears["rival.a"].career_attempt == 2,
		"a repeat clear (later attempt or reload) changes nothing", failures)
	_expect(Career.gates_from(career, 2) == ["gate.a_rival"] and Career.gates_from(career, 3).is_empty(), "gates are attributed to the attempt that earned them", failures)
	var catalogue: Dictionary = _world().catalogue
	var locked: Dictionary = catalogue.items[4]
	_expect(Career.collection_state(Career.fresh(), catalogue.items[3]) == "locked" and Career.collection_state(career, catalogue.items[3]) == "available"
		and Career.collection_state(career, locked) == "locked", "Locked and Available follow the held gates", failures)
	_expect(Career.record_items(career, ["pin.one", "pin.one", "charm.locked"], 2) and not Career.record_items(career, ["pin.one"], 2)
		and career.items["pin.one"].attempts == 1, "an owned item counts once per attempt", failures)
	_expect(Career.collection_state(career, catalogue.items[0]) == "discovered", "owned items are Discovered", failures)
	_expect(Career.summary(career, []).begins_with("Career: 1 rival cleared · 0 championships"), "the menu summary", failures)
	_expect(Career.unknown_ids(career, {"gates": {}}) == ["gate.a_rival"], "gates the graph no longer declares are reported, not dropped", failures)

static func _stats(category: String, spin: float = 0.0, fallen: Array = [1, 2, 3]) -> Dictionary:
	var pins := {1: "pin.wood", 2: "pin.ruby", 3: "pin.gold", 4: "pin.wood"}
	return Career.frame_stats(category, [{"launch": {"spin": spin}, "roll_result": {"fallen_positions": fallen}}], pins, func(s): return Lane.is_curved(s))

static func _mastery(failures: Array[String]) -> void:
	var stats := _stats("strike", 0.6, [1, 2, 4])
	_expect(stats.strikes == 1 and stats.curved_strikes == 1 and stats.materials == ["pin.wood", "pin.ruby"], "a curved strike's stats and distinct materials", failures)
	_expect(_stats("strike", 0.0).curved_strikes == 0 and _stats("spare").spares == 1 and _stats("open").spares == 0, "straight strikes, spares and opens", failures)
	var objectives: Array = ContentSet.career_graph(ContentSet.UNLOCKS).objectives
	var career := Career.fresh()
	var uid := Career.begin_attempt(career)
	var ctx := {"league": "league.house", "practice": false, "division": 1, "total": 100, "frame_score": 100}
	var spare := _stats("spare")
	for frame in range(1, 10):
		Career.bank_frame(career, uid, frame, spare, ctx, objectives)
	_expect(career.totals.spares == 9 and not career.mastery.has("mastery.spare_hand"), "nine spares: progress 9/10", failures)
	var again := Career.bank_frame(career, uid, 9, spare, ctx, objectives)
	_expect(not again.counted and career.totals.spares == 9, "a frame banked again (reload) is not counted twice", failures)
	var done := Career.bank_frame(career, uid, 10, spare, ctx, objectives)
	_expect(done.completed.size() == 1 and done.completed[0].id == "mastery.spare_hand" and done.gates == ["gate.mastery_spare_hand"]
		and career.awards["gate.mastery_spare_hand"].source == "mastery:mastery.spare_hand", "the tenth spare completes Spare Hand and banks its gate", failures)
	_expect(Career.bank_frame(career, uid, 11, spare, ctx, objectives).completed.is_empty() and career.unlocked.count("gate.mastery_spare_hand") == 1,
		"a completed objective is never awarded again", failures)
	_expect(career.records["league.house"].attempts == 1 and career.records["league.house"].best_frame == 100, "records count the attempt once and keep bests", failures)
	# Attempt-scoped feats restart with each attempt; cumulative progress carries.
	var mixed: Dictionary = objectives.filter(func(o): return o.id == "mastery.mixed_rack")[0]
	var curve: Dictionary = objectives.filter(func(o): return o.id == "mastery.true_curve")[0]
	Career.bank_frame(career, uid, 12, _stats("strike", 0.6, [1, 2]), ctx, objectives)
	_expect(Career.progress(career, mixed, uid) == 3 and career.mastery.has("mastery.mixed_rack"), "three materials in one attempt complete Mixed Rack", failures)
	_expect(Career.progress(career, curve, uid) == 1, "one curved strike so far", failures)
	var next := Career.begin_attempt(career)
	_expect(Career.progress(career, curve, next) == 0 and Career.progress(career, curve, uid) == 0, "attempt progress starts over", failures)
	Career.bank_frame(career, next, 1, _stats("strike", 0.6), ctx, objectives)
	Career.bank_frame(career, next, 2, _stats("strike", 0.6), ctx, objectives)
	_expect(not career.mastery.has("mastery.true_curve") and Career.progress(career, curve, next) == 2, "two curved strikes in the new attempt", failures)
	var goals := Career.goals(career, objectives, next)
	_expect(goals.size() == 1 and goals[0].id == "mastery.true_curve" and goals[0].progress == 2, "goals list what is left, with progress", failures)
	Career.bank_frame(career, next, 3, _stats("strike", 0.6), ctx, objectives)
	_expect(career.mastery.get("mastery.true_curve", {}).get("career_attempt") == next and Career.goals(career, objectives, next).is_empty(), "the third completes True Curve", failures)
	# An older attempt resumed after a newer one began counts from where it resumes.
	Career.bank_frame(career, uid, 13, spare, ctx, objectives)
	_expect(career.tally.uid == uid and career.totals.spares == 12, "a resumed older attempt keeps counting once per frame", failures)
	# Prerequisites hold an objective back until its gate is met.
	var gated := {"id": "mastery.gated", "name": "G", "text": "g", "metric": "strikes", "threshold": 1, "scope": "career", "prerequisites": ["gate.later"], "gates": ["gate.g"], "reward": "g"}
	Career.bank_frame(career, next, 4, _stats("strike"), ctx, [gated])
	_expect(not career.mastery.has("mastery.gated"), "an objective waits for its prerequisites", failures)

static func _championships(failures: Array[String]) -> void:
	var career := Career.fresh()
	var league := {"id": "league.a", "name": "A", "championship": {"gates": ["gate.a_champion"], "text": "won"}}
	var uid := Career.begin_attempt(career)
	Career.record_items(career, ["pin.one", "ball.x"], uid)
	var first := Career.record_championship(career, league, uid, ["pin.one"])
	_expect(first.counted and first.first and first.gates == ["gate.a_champion"] and career.championships["league.a"].wins == 1, "the first title awards its gate", failures)
	var reload := Career.record_championship(career, league, uid, ["pin.one"])
	_expect(not reload.counted and career.championships["league.a"].wins == 1 and career.items["pin.one"].league_wins == 1, "the same attempt's title counts once", failures)
	var catalogue: Dictionary = _world().catalogue
	_expect(Career.collection_state(career, catalogue.items[0]) == "mastered" and Career.collection_state(career, catalogue.items[4]) == "available",
		"an item owned in a League win is Mastered; the title's pin is Available", failures)
	var later := Career.begin_attempt(career)
	var second := Career.record_championship(career, league, later, [])
	_expect(second.counted and not second.first and second.gates.is_empty() and career.championships["league.a"].wins == 2
		and career.unlocked.count("gate.a_champion") == 1 and career.records["league.a"].wins == 2, "a later title is a record, not a repeat unlock", failures)

static func _practice(failures: Array[String]) -> void:
	var objectives: Array = ContentSet.career_graph(ContentSet.UNLOCKS).objectives
	var career := Career.fresh()
	var uid := Career.begin_attempt(career)
	var ctx := {"league": "league.house", "practice": true, "division": 1, "total": 900, "frame_score": 900}
	for frame in range(1, 15):
		Career.bank_frame(career, uid, frame, _stats("spare", 0.6, [1, 2, 3]), ctx, objectives)
	_expect(career.totals.is_empty() and career.mastery.is_empty() and career.unlocked.is_empty(), "practice never advances mastery or unlocks", failures)
	var record: Dictionary = career.records["league.house"]
	_expect(record.practice_best_frame == 900 and record.best_frame == 0 and record.practice_attempts == 1 and record.attempts == 0, "practice keeps practice records apart", failures)
	_expect(not Career.record_first_clear(career, {"id": "rival.a", "first_clear": {"unlocks": ["gate.a_rival"]}}, 1, uid, true)
		and not Career.record_championship(career, {"id": "league.house", "championship": {"gates": ["gate.x"]}}, uid, [], true).counted,
		"practice banks no first clear or title", failures)
	_expect(Career.record_items(career, ["pin.one"], uid), "practice still records discoveries", failures)

## §16: unlocking means eligible from the next attempt; an attempt's pool is a snapshot.
static func _pool_snapshot(failures: Array[String]) -> void:
	var content := ContentSet.load_set("slice")
	var catalogue: Dictionary = content.catalogue
	var encore: Dictionary = catalogue.items.filter(func(i): return i.id == "charm.encore")[0]
	var career := Career.fresh()
	var run = Inventory.create(catalogue, content.kit.pins, content.kit.deck, 6)
	var shop = Shop.create(catalogue, 7)
	shop.unlocked = career.unlocked.duplicate()
	Career.record_first_clear(career, content.divisions[0].rivals[0], 1, 1)
	_expect("gate.surveyor_cleared" in career.unlocked and shop.ineligibility(encore, run) == "locked", "an unlock mid-attempt leaves this attempt's pool unchanged", failures)
	var back = Shop.from_dict(JSON.parse_string(JSON.stringify(shop.to_dict())), catalogue)
	_expect(back.ineligibility(encore, run) == "locked", "the saved attempt keeps its pool after a reload", failures)
	var next = Shop.create(catalogue, 8)
	next.unlocked = career.unlocked.duplicate()
	_expect(next.ineligibility(encore, run).is_empty(), "the next attempt's pool includes the unlock", failures)
	# The attempt snapshot carries the Career uid only when there is one.
	var parts := {"attempt": 1, "seed": 1, "phase": "aim", "lab": {}, "run": run, "shop": shop, "division": preload("res://src/rules/league_run.gd").create(content.divisions),
		"equipment": preload("res://src/rules/card_deck.gd").create_with(run.deck_cards(), 1)}
	_expect(not Snapshot.build(parts, {}, "slice").has("career_attempt") and Snapshot.build(parts.merged({"career_attempt": 4}), {}, "slice").career_attempt == 4,
		"attempt snapshots record their Career uid additively", failures)

static func _migration(failures: Array[String]) -> void:
	var dir := ProjectSettings.globalize_path("user://career_test")
	DirAccess.make_dir_recursive_absolute(dir)
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file))
	DirAccess.copy_absolute(ProjectSettings.globalize_path(GOLDEN).path_join("career.json"), dir.path_join("career.json"))
	var store = Store.create(dir)
	var read: Dictionary = store.read("career")
	_expect(read.ok and read.schema_version == 1 and Career.validate(read.payload).is_empty(), "the golden v1 Career migrates to v2: %s" % read.get("error", ""), failures)
	if not read.ok:
		return
	var career: Dictionary = read.payload
	_expect(career.first_clears.has("rival.lab_custodian") and career.unlocked == ["gate.lab_rival"] and career.awards["gate.lab_rival"].source.begins_with("boss")
		and career.attempts == 0 and career.mastery.is_empty(), "migration keeps the first clear and its gate and starts the new records empty", failures)
	_expect(store.write("career", career).is_empty() and store.read("career").schema_version == 2, "the migrated Career saves as v2", failures)
	var uid := Career.begin_attempt(career)
	_expect(uid == 1 and not Career.record_first_clear(career, {"id": "rival.lab_custodian", "first_clear": {"unlocks": ["gate.lab_rival"]}}, 1, uid),
		"a migrated first clear is still not repeatable", failures)
	# The frozen v2 Career (written by tools/make_save_fixture.gd) keeps loading.
	DirAccess.copy_absolute(ProjectSettings.globalize_path(GOLDEN_V2).path_join("career.json"), dir.path_join("career.json"))
	DirAccess.remove_absolute(dir.path_join("career.json.bak"))
	var golden: Dictionary = Store.create(dir).read("career")
	_expect(golden.ok and golden.schema_version == 2 and Career.validate(golden.payload).is_empty(), "the golden v2 Career loads", failures)
	if golden.ok:
		var g: Dictionary = Career.normalized(golden.payload)
		_expect(g.attempts == 2 and g.totals.get("spares") == 1.0 and g.championships.has("league.lab") and g.items["pin.wood"].league_wins == 1
			and Career.record_championship(g, {"id": "league.lab", "championship": {"gates": []}}, 2, []).counted == false,
			"golden v2: attempts, totals, a title and an item history; its title stays counted once", failures)
