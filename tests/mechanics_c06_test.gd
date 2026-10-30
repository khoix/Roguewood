extends RefCounted
## E18-C06: the three tactical-card primitives (src/rules/tactics.gd).
## - Nudge (tactical.relocate_pin): before roll 2 only, a standing pin moves to an
##   adjacent fallen spot and keeps its identity (rack position).
## - Reserve Call (tactical.reserve_swap): before roll 1 only, a reserve pin swaps
##   into a rack position; the swap is undone exactly once after the frame.
## - Rule Waiver (tactical.waive_rule): boss matches only; the rules in force become
##   none for the frame, so Clean Sweep banks an open frame and Dead Straight keeps spin.
## - Saves: frame actions are optional in a snapshot and default to none.
const Tactics = preload("res://src/rules/tactics.gd")
const RivalRules = preload("res://src/rules/rival_rules.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
const ContentSet = preload("res://src/rules/content_set.gd")
const Snapshot = preload("res://src/persistence/attempt_snapshot.gd")
const IDS := ["consumable.nudge", "consumable.reserve_call", "consumable.rule_waiver"]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var content: Dictionary = ContentSet.load_set("slice")
	var items := {}
	for item in content.catalogue.items:
		items[item.id] = item
	_expect(IDS.all(func(id): return items.has(id) and items[id].category == "consumable" and items[id].completeness.mechanics and items[id].limits.exhaustion == "consume"),
		"the three tactical cards are in the catalogue with mechanics", failures)
	_expect(IDS.map(func(id): return Tactics.kind(id)) == ["relocate_pin", "reserve_swap", "waive_rule"] and Tactics.kind("consumable.lab_focus").is_empty(),
		"each card names its primitive; the lab's armed tacticals stay armed", failures)
	_nudge(failures)
	_reserve_call(content, failures)
	_rule_waiver(failures)
	_saves(failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _rack(positions: Array) -> Dictionary:
	return {"schema_version": 1, "standing": positions.map(func(p): return {"position": p, "x": Lane.spot(p).x, "f": Lane.spot(p).y})}

static func _at(roll: int, extra: Dictionary = {}) -> Dictionary:
	var at := {"roll_index": roll, "thrown": roll - 1, "boss": false, "rules": [], "rack": _rack([1, 2, 4, 7]), "run": null, "actions": []}
	at.merge(extra, true)
	return at

static func _nudge(failures: Array[String]) -> void:
	var rack := _rack([1, 2, 4, 7])
	var options := Tactics.nudge_options(rack)
	var by := {}
	for o in options: by[o.position] = o.to
	# Neighbours: 1-{2,3}; 2-{1,3,4,5}; 4-{2,5,7,8}; 7-{4,8}. Fallen: 3,5,6,8,9,10.
	_expect(by == {1: [3], 2: [3, 5], 4: [5, 8], 7: [8]}, "Nudge offers only adjacent fallen spots: %s" % str(by), failures)
	var moved := Tactics.apply_nudge(rack, 4, 8)
	var four: Dictionary = moved.standing.filter(func(e): return e.position == 4)[0]
	_expect(is_equal_approx(four.x, Lane.spot(8).x) and is_equal_approx(four.f, Lane.spot(8).y) and moved.standing.size() == 4 and rack.standing[2].x == Lane.spot(4).x,
		"the nudged pin keeps its identity on its new spot; the original rack is untouched", failures)
	_expect(Tactics.blocked("consumable.nudge", _at(2)).is_empty() and not Tactics.blocked("consumable.nudge", _at(1)).is_empty(),
		"Nudge is played before roll 2 only", failures)
	_expect(not Tactics.blocked("consumable.nudge", _at(2, {"rack": _rack(range(1, 11))})).is_empty() and Tactics.nudge_options(_rack([])).is_empty(),
		"Nudge needs a fallen neighbouring spot", failures)
	_expect(Tactics.text({"kind": "relocate_pin", "position": 4, "to": 8}, {}) == "Nudge: pin 4 moved to spot 8 before roll 2.", "Nudge explains the move", failures)

static func _reserve_call(content: Dictionary, failures: Array[String]) -> void:
	var run = Inventory.create(content.catalogue, content.kit.pins, content.kit.deck, int(content.kit.money))
	_expect(not Tactics.blocked("consumable.reserve_call", _at(1, {"run": run})).is_empty() and Tactics.reserve_options(run).is_empty(),
		"Reserve Call needs a pin in reserve", failures)
	run.reserves[1] = Inventory._entry("pin.ruby", 6)
	var before: Dictionary = run.rack[3]
	_expect(Tactics.reserve_options(run) == [2] and Tactics.blocked("consumable.reserve_call", _at(1, {"run": run})).is_empty(), "a reserve pin can be called before roll 1", failures)
	_expect(not Tactics.blocked("consumable.reserve_call", _at(2, {"run": run})).is_empty() and not Tactics.blocked("consumable.reserve_call", _at(1, {"run": run, "thrown": 1})).is_empty(),
		"Reserve Call is refused once the frame has a throw", failures)
	var action := {"kind": "reserve_swap", "reserve": 2, "position": 3, "called": "pin.ruby", "displaced": before.item_id, "restored": false}
	Tactics.swap_reserve(run, 2, 3)
	_expect(run.rack[3].item_id == "pin.ruby" and run.reserves[1] == before and run.loadout().pins[3] == "pin.ruby", "the called pin racks at its position for the frame", failures)
	_expect(not Tactics.blocked("consumable.reserve_call", _at(1, {"run": run, "actions": [action]})).is_empty(), "one Reserve Call per frame", failures)
	run.rack[3].growth = 2 # what the frame did to the called pin travels with it
	Tactics.restore_swaps(run, [action])
	Tactics.restore_swaps(run, [action])
	_expect(run.rack[3] == before and run.reserves[1].item_id == "pin.ruby" and int(run.reserves[1].growth) == 2 and action.restored,
		"after the frame both pins return exactly once, the called pin keeping its growth", failures)
	_expect(Tactics.text(action, {"pin.ruby": "Ruby Pin", "pin.wood": "Wood Pin"}).begins_with("Reserve Call: Ruby Pin played at position 3 this frame"), "Reserve Call explains the swap", failures)

static func _rule_waiver(failures: Array[String]) -> void:
	var sweep := ["boss_rule.clean_sweep"]
	_expect(not Tactics.blocked("consumable.rule_waiver", _at(1)).is_empty() and Tactics.blocked("consumable.rule_waiver", _at(2, {"boss": true, "rules": sweep})).is_empty(),
		"Rule Waiver is only played in a boss match", failures)
	var waiver := {"kind": "waive_rule", "rules": sweep}
	_expect(not Tactics.blocked("consumable.rule_waiver", _at(1, {"boss": true, "rules": sweep, "actions": [waiver]})).is_empty(), "one waiver per frame", failures)
	var open := {"score": 37, "category": "open"}
	_expect(RivalRules.bank(sweep, open).score == 0 and RivalRules.bank(Tactics.active_rules(sweep, [waiver]), open).score == 37,
		"waived, Clean Sweep banks an open frame as scored", failures)
	var straight := ["boss_rule.dead_straight"]
	_expect(RivalRules.constrain_launch(Tactics.active_rules(straight, [waiver]), {"spin": 0.6}).spin == 0.6 and RivalRules.constrain_launch(Tactics.active_rules(straight, []), {"spin": 0.6}).spin == 0.0,
		"waived, Dead Straight keeps the launch's spin", failures)
	var champion := ["boss_rule.clean_sweep", "boss_rule.house_rules"]
	_expect(Tactics.active_rules(champion, [waiver]).is_empty() and RivalRules.ball_allowed(Tactics.active_rules(champion, [waiver]), "ball.hook"),
		"a champion's rules are all waived together", failures)
	_expect(Tactics.text({"kind": "waive_rule", "rules": champion}, {"boss_rule.clean_sweep": "Clean Sweep", "boss_rule.house_rules": "House Rules"}) == "Rule Waiver: Clean Sweep + House Rules waived for this frame.",
		"Rule Waiver names what it waived", failures)

static func _saves(failures: Array[String]) -> void:
	var lab := {"frame_number": 1.0, "roll_index": 2.0, "match_number": 1.0, "match_frame": 1.0, "total_score": 0.0, "launch_serial": 1.0,
		"frame_tactics": {"2": ["consumable.nudge"]}, "frame_mods": {}, "frame_reports": [], "pending": null}
	_expect(Snapshot.normalized_lab(lab).frame_actions == [] and Snapshot.normalized_lab(lab).frame_tactics == {2: ["consumable.nudge"]}, "an older save restores with no frame actions", failures)
	_expect("frame_actions" not in Snapshot.LAB_KEYS, "frame actions are optional in a snapshot", failures)
