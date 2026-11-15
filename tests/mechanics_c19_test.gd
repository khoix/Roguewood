extends RefCounted
## E18-C19 (DC-N5, E17-D16): Neon's last five items, all mastery rewards.
## - Both Halves (strike from each half of a Two-Tone lane in one attempt) unlocks
##   Compass Pin (+25 Value off House Oil), Split Pattern (×2 Mult on a Two-Tone
##   strike), Dry Run (+1 Mult per pin down with a roll left of centre at 34 ft) and
##   Long Game (×1.5 Mult on a curved strike on Long Oil);
## - Rebound Rescue (three rebounds turned into a spare or strike, Career-wide)
##   unlocks Second Chance (×1.5 Mult on a spare or strike with a rebound).
const ContentSet = preload("res://src/rules/content_set.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
const Career = preload("res://src/persistence/career_profile.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const SliceTest = preload("res://tests/slice_test.gd")
const C15 = preload("res://tests/mechanics_c15_test.gd")
const HALVES := "gate.mastery_both_halves"
const RESCUE := "gate.mastery_rebound_rescue"
const HALVES_ITEMS := ["pin.compass", "charm.split_pattern", "charm.dry_run", "charm.long_game"]
const ALL := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const REST := [7, 8, 9, 10]
const CURVE := 0.6
const LONG := "lane_condition.long_oil"
const TWO_TONE := "lane_condition.two_tone"

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = ContentSet.load_set("neon").catalogue
	var items := {}
	for item in catalogue.items:
		items[item.id] = item
	var graph: Dictionary = ContentSet.career_graph(ContentSet.UNLOCKS)
	_expect(graph.errors.is_empty() and graph.items_by_gate.get(HALVES, []) == HALVES_ITEMS and graph.items_by_gate.get(RESCUE, []) == ["charm.second_chance"]
		and (HALVES_ITEMS + ["charm.second_chance"]).all(func(id): return items[id].unlock.kind == "mastery" and items[id].completeness.mechanics),
		"Both Halves unlocks four items and Rebound Rescue one", failures)
	_compass(catalogue, failures)
	_charms(catalogue, failures)
	_career(graph, failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("mechanics_c19: " + label)

## A frame on `lane`, with its explanation lines.
static func _on(catalogue: Dictionary, reports: Array, loadout: Dictionary, lane: String) -> Dictionary:
	var built := Builder.build(loadout, catalogue, reports, {}, {"lane_condition": lane})
	if not built.ok:
		return {"ok": false, "mult": -1.0, "pin_value": -1.0, "lines": []}
	var result := Rules.resolve(built.frame)
	var names := {}
	for entry in catalogue.items:
		names[entry.id] = entry.name
	result["lines"] = ScoreLog.steps(result, built.frame, names, built.owners).map(func(s): return s.text)
	return result

static func _left(report: Dictionary) -> Dictionary:
	report.knockdown_log["left_side"] = true
	return report

static func _compass(catalogue: Dictionary, failures: Array[String]) -> void:
	var rack: Dictionary = SliceTest._loadout({1: "pin.compass", 5: "pin.compass"})
	var wood: Dictionary = SliceTest._loadout()
	var strike := [C15._rep(1, ALL, ALL)]
	var off := _on(catalogue, strike, rack, LONG)
	_expect(off.ok and off.pin_value == _on(catalogue, strike, wood, LONG).pin_value - 2 * 10.0 + 2 * 25.0 and off.lines.any(func(l): return l.contains("Compass Pin") and l.contains("Long Oil")),
		"Compass Pin: +25 Value each when it falls on Long Oil", failures)
	_expect(_on(catalogue, strike, rack, "lane.house").pin_value == _on(catalogue, strike, wood, "lane.house").pin_value - 2 * 10.0, "on House Oil it is worth nothing", failures)

static func _charms(catalogue: Dictionary, failures: Array[String]) -> void:
	var none: Dictionary = SliceTest._loadout()
	var strike := [C15._rep(1, ALL, ALL)]
	var split: Dictionary = SliceTest._loadout({}, ["charm.split_pattern"])
	_expect(_on(catalogue, strike, split, TWO_TONE).mult == _on(catalogue, strike, none, TWO_TONE).mult * 2.0, "Split Pattern: ×2 Mult on a Two-Tone strike", failures)
	_expect(_on(catalogue, strike, split, LONG).mult == _on(catalogue, strike, none, LONG).mult, "nothing on another lane", failures)
	var dry: Dictionary = SliceTest._loadout({}, ["charm.dry_run"])
	var left := [_left(C15._rep(1, ALL, ALL))]
	_expect(_on(catalogue, left, dry, "lane.house").mult == _on(catalogue, left, none, "lane.house").mult + 10.0, "Dry Run: +1 Mult per pin down from the left at 34 ft", failures)
	var leave := [_left(C15._rep(1, [1, 2, 3], ALL)), C15._rep(2, [4, 5], [4, 5, 6, 7, 8, 9, 10])]
	_expect(_on(catalogue, leave, dry, "lane.house").mult == _on(catalogue, leave, none, "lane.house").mult + 5.0, "five pins down: +5", failures)
	_expect(_on(catalogue, strike, dry, "lane.house").mult == _on(catalogue, strike, none, "lane.house").mult, "nothing when every roll stayed right", failures)
	var long_game: Dictionary = SliceTest._loadout({}, ["charm.long_game"])
	var curved := [C15._rep(1, ALL, ALL, "ball.house", CURVE)]
	_expect(_on(catalogue, curved, long_game, LONG).mult == _on(catalogue, curved, none, LONG).mult * 1.5, "Long Game: ×1.5 Mult on a curved strike on Long Oil", failures)
	_expect(_on(catalogue, strike, long_game, LONG).mult == _on(catalogue, strike, none, LONG).mult and _on(catalogue, curved, long_game, TWO_TONE).mult == _on(catalogue, curved, none, TWO_TONE).mult,
		"nothing for a straight strike, or on another lane", failures)
	var second: Dictionary = SliceTest._loadout({}, ["charm.second_chance"])
	var rescued := [C15._rep(1, [1, 2, 3, 4, 5, 6], ALL, "ball.house", 0.0, "clean", true), C15._rep(2, REST, REST)]
	_expect(_on(catalogue, rescued, second, "lane.house").mult == _on(catalogue, rescued, none, "lane.house").mult * 1.5, "Second Chance: ×1.5 Mult on a spare with a rebound", failures)
	var plain := [C15._rep(1, [1, 2, 3, 4, 5, 6], ALL), C15._rep(2, REST, REST)]
	_expect(_on(catalogue, plain, second, "lane.house").mult == _on(catalogue, plain, none, "lane.house").mult, "nothing without a rebound", failures)

static func _stats(category: String, lane: String, left: bool = false, rebounded: bool = false) -> Dictionary:
	var log := {}
	if left: log["left_side"] = true
	if rebounded: log["rebounded"] = true
	var reports := [{"launch": {"spin": 0.0}, "roll_result": {"fallen_positions": [1, 2, 3], "accuracy": "clean"}, "knockdown_log": log}]
	return Career.frame_stats(category, reports, {}, func(s): return Lane.is_curved(s), lane)

static func _career(graph: Dictionary, failures: Array[String]) -> void:
	_expect(_stats("strike", TWO_TONE, true).halves == ["left"] and _stats("strike", TWO_TONE).halves == ["right"] and _stats("strike", LONG, true).halves.is_empty()
		and _stats("spare", TWO_TONE, true).halves.is_empty(), "a Two-Tone strike names its half; other lanes and spares name none", failures)
	_expect(_stats("spare", "lane.house", false, true).rescues == 1 and _stats("open", "lane.house", false, true).rescues == 0 and _stats("strike", "lane.house").rescues == 0,
		"a rebound that ends in a spare or strike is a rescue", failures)
	var halves: Dictionary = graph.objectives.filter(func(o): return o.id == "mastery.both_halves")[0]
	var rescue: Dictionary = graph.objectives.filter(func(o): return o.id == "mastery.rebound_rescue")[0]
	var career := Career.fresh()
	var uid := Career.begin_attempt(career)
	var ctx := {"league": "league.neon", "division": 2, "frame_score": 100, "total": 100}
	Career.bank_frame(career, uid, 1, _stats("strike", TWO_TONE, true), ctx, graph.objectives)
	Career.bank_frame(career, uid, 2, _stats("strike", TWO_TONE, true), ctx, graph.objectives)
	_expect(Career.progress(career, halves, uid) == 1 and not career.mastery.has(halves.id), "two strikes from the left are one half", failures)
	var out: Dictionary = Career.bank_frame(career, uid, 3, _stats("strike", TWO_TONE), ctx, graph.objectives)
	_expect(career.mastery.has(halves.id) and HALVES in out.gates, "a strike from the right completes Both Halves", failures)
	for frame in range(4, 6):
		Career.bank_frame(career, uid, frame, _stats("spare", "lane.house", false, true), ctx, graph.objectives)
	var next := Career.begin_attempt(career)
	_expect(Career.progress(career, rescue, next) == 2, "rescues count across attempts (Career scope)", failures)
	Career.bank_frame(career, next, 1, _stats("strike", "lane.house", false, true), ctx, graph.objectives)
	_expect(career.mastery.has(rescue.id) and RESCUE in career.unlocked, "the third rescue completes Rebound Rescue", failures)
	var older := {"uid": next, "frame": 0, "practice": false, "counts": {}, "materials": []}
	var legacy := Career.fresh()
	legacy.tally = older
	_expect(Career.progress(legacy, halves, next) == 0, "an older tally without halves reads 0", failures)
