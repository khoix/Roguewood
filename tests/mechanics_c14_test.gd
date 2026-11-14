extends RefCounted
## E18-C14: the Neon primitives, built before the items that use them.
## - `physics.gutter_rebound`: the tracker rules one rebound at the gutter edge (the
##   lane turns the ball; physics_test `_cards` rolls it), the roll carries
##   `rebounded`, and op `lose_mult` takes Mult down, never below 1.
## - A ball's `oil_hold` and a ball modification's `spin_response` and
##   `gutter_rebound` reach the roll through ItemPhysics.roll_rules.
## - Conditions `rebounded`, `felled_curved` and `first_hit`.
const Rules = preload("res://src/rules/frame_rules.gd")
const Tracker = preload("res://src/simulation/knockdown_tracker.gd")
const ItemPhysics = preload("res://src/simulation/item_physics.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const LOSS := {"op": "lose_mult", "amount": 2, "trigger": "ball", "scope": "roll", "condition": {"rebounded": true}}

static func run() -> Array[String]:
	var failures: Array[String] = []
	_tracker(failures)
	_loss(failures)
	_conditions(failures)
	_validation(failures)
	_card_rules(failures)
	_catalogue(failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("mechanics_c14: " + label)

## A tick with the ball at (x, f) and no pins racked.
static func _at(x: float, f: float) -> Dictionary:
	return {"ball": {"x": x, "y": Lane.BALL_RADIUS, "f": f, "speed": 6.0}, "pins": {}}

static func _tracker(failures: Array[String]) -> void:
	var edge := Lane.LANE_HALF_WIDTH
	var plain := Tracker.new([])
	plain.step(_at(edge + 0.01, 5.0))
	_expect(plain.gutter and not plain.rebounded and plain.take_rebound() == 0.0, "without the modification a ball over the edge is a gutter ball", failures)
	var guarded := Tracker.new([], edge, 1)
	guarded.step(_at(0.3, 4.0))
	_expect(not guarded.rebounded and guarded.take_rebound() == 0.0, "nothing happens while the ball is on the lane", failures)
	guarded.step(_at(edge + 0.002, 5.0))
	_expect(guarded.rebounded and not guarded.gutter and guarded.take_rebound() == 1.0 and guarded.take_rebound() == 0.0,
		"the first crossing is a rebound, told to the lane once, with its side", failures)
	guarded.step(_at(edge + 0.001, 5.1)) # still over the edge on its way back
	_expect(not guarded.gutter, "the ball may still be over the edge while it turns back", failures)
	for i in Tracker.REBOUND_GRACE:
		guarded.step(_at(0.2, 5.2 + i * 0.05))
	guarded.step(_at(-edge - 0.01, 9.0))
	_expect(guarded.gutter and guarded.rebounded and guarded.take_rebound() == 0.0, "it rebounds once: leaving the lane again is a gutter ball", failures)
	var stuck := Tracker.new([], edge, 1)
	for i in Tracker.REBOUND_GRACE + 2:
		stuck.step(_at(-edge - 0.02, 5.0 + i * 0.05))
	_expect(stuck.rebounded and stuck.gutter, "a ball still out after the grace is a gutter ball", failures)
	var left := Tracker.new([], edge, 1)
	left.step(_at(-edge - 0.002, 5.0))
	_expect(left.take_rebound() == -1.0, "the left edge rebounds from the left", failures)
	var narrow := Tracker.new([], edge - 2 * Lane.BOARD_WIDTH, 1)
	narrow.step(_at(edge - Lane.BOARD_WIDTH, 5.0))
	_expect(narrow.rebounded and not narrow.gutter, "on Narrow Lane the rebound is at the ruled edge", failures)

static func _pins(effect: Dictionary = {}) -> Array:
	var pins: Array = []
	for position in range(1, 11):
		pins.append({"position": position, "item_id": "pin.wood", "effects": [] if effect.is_empty() else [effect.duplicate(true)]})
	return pins

static func _roll(index: int, fallen: Array, extra: Dictionary = {}, effects: Array = []) -> Dictionary:
	var roll := {"roll_index": index, "ball_id": "ball.house", "fallen_positions": fallen, "accuracy": "clean", "effects": effects.duplicate(true),
		"first_direct": fallen[0] if not fallen.is_empty() else 0, "last_fallen": fallen[-1] if not fallen.is_empty() else 0, "curved": false}
	roll.merge(extra, true)
	return roll

static func _frame(rolls: Array, pins: Array = _pins(), charms: Array = []) -> Dictionary:
	return {"schema_version": 2, "pins": pins, "rolls": rolls, "charms": charms, "context": {"match_frame": 1, "strike_streak": 0}}

static func _loss(failures: Array[String]) -> void:
	var all: Array = range(1, 11)
	var strike: Dictionary = Rules.resolve(_frame([_roll(1, all, {"rebounded": true}, [LOSS])]))
	_expect(strike.ok and strike.mult == 2.0 and strike.score == 80, "a rebounded strike loses 2 Mult: 40 × 2 = 80 (%s)" % str(strike.get("score", strike.get("errors"))), failures)
	var clean: Dictionary = Rules.resolve(_frame([_roll(1, all, {}, [LOSS])]))
	_expect(clean.ok and clean.mult == 4.0 and clean.score == 160, "the same strike without a rebound loses nothing", failures)
	var spare: Dictionary = Rules.resolve(_frame([_roll(1, [1, 2, 3, 4, 5, 6], {"rebounded": true}, [LOSS]), _roll(2, [7, 8, 9, 10])]))
	_expect(spare.ok and spare.mult == 1.0 and spare.score == 20, "a rebounded spare's Mult of 2 falls to 1, not 0: 20 × 1 (%s)" % str(spare.get("score", spare.get("errors"))), failures)
	var open: Dictionary = Rules.resolve(_frame([_roll(1, [1, 2, 3], {"rebounded": true}, [LOSS]), _roll(2, [])]))
	_expect(open.ok and open.mult == 1.0, "an open frame's Mult of 1 stays 1", failures)
	var event: Dictionary = strike.events.filter(func(e): return e.get("op", "") == "lose_mult")[0] if strike.ok else {}
	_expect(event.get("mult", 0.0) == 2.0 and event.get("source", "") == "roll:1", "the loss is an ordinary event in the chain", failures)
	# The mutation this guards against: treating the loss as a plain subtraction.
	_expect(spare.ok and spare.mult != 0.0, "Mult never reaches 0", failures)

static func _conditions(failures: Array[String]) -> void:
	# On a roll's own effects `rebounded` is that roll; elsewhere it is any roll.
	var second_only: Dictionary = Rules.resolve(_frame([_roll(1, [1, 2, 3, 4, 5, 6], {"rebounded": true}), _roll(2, [7, 8, 9, 10], {}, [LOSS])]))
	_expect(second_only.ok and second_only.mult == 2.0, "a roll's own condition reads that roll: roll 2 did not rebound", failures)
	var charm := {"item_id": "charm.test", "effects": [{"op": "add_mult", "amount": 3, "trigger": "charm", "scope": "frame", "condition": {"rebounded": true}}]}
	var with_charm: Dictionary = Rules.resolve(_frame([_roll(1, [1, 2, 3, 4, 5, 6], {"rebounded": true}), _roll(2, [7, 8, 9, 10])], _pins(), [charm]))
	var without: Dictionary = Rules.resolve(_frame([_roll(1, [1, 2, 3, 4, 5, 6]), _roll(2, [7, 8, 9, 10])], _pins(), [charm]))
	_expect(with_charm.ok and with_charm.mult == 5.0 and without.ok and without.mult == 2.0, "a Charm's condition holds when any roll rebounded", failures)
	var curved_pin := {"op": "add_value", "amount": 5, "trigger": "fallen", "scope": "frame", "condition": {"felled_curved": true}}
	var mixed: Dictionary = Rules.resolve(_frame([_roll(1, [1, 2, 3]), _roll(2, [4, 5], {"curved": true})], _pins(curved_pin)))
	_expect(mixed.ok and mixed.pin_value == 10.0, "felled_curved pays only the pins a curved roll knocked down (%s)" % str(mixed.get("pin_value", mixed.get("errors"))), failures)
	var straight_pin := curved_pin.duplicate(true)
	straight_pin.condition = {"felled_curved": false}
	var straight: Dictionary = Rules.resolve(_frame([_roll(1, [1, 2, 3]), _roll(2, [4, 5], {"curved": true})], _pins(straight_pin)))
	_expect(straight.ok and straight.pin_value == 15.0, "and false pays the pins a straight roll knocked down; standing pins pay nothing", failures)
	var first_pin := {"op": "add_value", "amount": 7, "trigger": "fallen", "scope": "frame", "condition": {"first_hit": true}}
	var firsts: Dictionary = Rules.resolve(_frame([_roll(1, [1, 2, 3], {"first_direct": 2}), _roll(2, [4, 5], {"first_direct": 4})], _pins(first_pin)))
	_expect(firsts.ok and firsts.pin_value == 14.0, "first_hit pays the first pin each roll's ball knocked down directly (%s)" % str(firsts.get("pin_value", firsts.get("errors"))), failures)
	var both := {"op": "add_value", "amount": 9, "trigger": "fallen", "scope": "frame", "condition": {"first_hit": true, "felled_curved": true}}
	var lit: Dictionary = Rules.resolve(_frame([_roll(1, [1, 2, 3], {"first_direct": 2}), _roll(2, [4, 5], {"first_direct": 4, "curved": true})], _pins(both)))
	_expect(lit.ok and lit.pin_value == 9.0, "both together: the pin a curved ball met first", failures)
	_expect(ScoreLog.condition_text({"rebounded": true}) == "rebounded off the gutter" and ScoreLog.condition_text({"felled_curved": true, "first_hit": true}).contains("curved roll")
		and ScoreLog.condition_text({"first_hit": true}) == "the first pin the ball hit", "the score log words the new conditions", failures)

static func _validation(failures: Array[String]) -> void:
	var all: Array = range(1, 11)
	var scaled := LOSS.duplicate(true)
	scaled["per"] = "fallen"
	_expect(not Rules.validate(_frame([_roll(1, all, {}, [scaled])])).is_empty(), "a Mult loss does not scale per count", failures)
	var on_ball := {"op": "add_value", "amount": 1, "trigger": "ball", "scope": "roll", "condition": {"first_hit": true}}
	_expect(not Rules.validate(_frame([_roll(1, all, {}, [on_ball])])).is_empty(), "first_hit belongs to a pin, not a ball", failures)
	var standing := {"op": "add_value", "amount": 1, "trigger": "standing", "scope": "frame", "condition": {"felled_curved": true}}
	_expect(not Rules.validate(_frame([_roll(1, [1]), _roll(2, [])], _pins(standing))).is_empty(), "felled_curved belongs to a fallen pin", failures)
	_expect(not Rules.validate(_frame([_roll(1, all, {"rebounded": "yes"})])).is_empty(), "a roll's rebounded is a boolean", failures)
	var loose := LOSS.duplicate(true)
	loose.condition = {"rebounded": 1}
	_expect(not Rules.validate(_frame([_roll(1, all, {}, [loose])])).is_empty(), "the rebounded condition is a boolean", failures)
	_expect(Rules.validate(_frame([_roll(1, all, {"rebounded": true}, [LOSS])])).is_empty(), "the rebound frame itself validates", failures)

static func _card_rules(failures: Array[String]) -> void:
	var guard := {"id": "ball_mod.test_guard", "physics": {"gutter_rebound": true}}
	var tame := {"id": "ball_mod.test_tame", "physics": {"spin_response": 0.7}}
	var holder := {"id": "ball.test_holder", "physics": {"oil_hold": true, "spin_response": 1.1}}
	_expect(ItemPhysics.roll_rules({}, {}).is_empty() and ItemPhysics.roll_rules({"id": "ball.house"}).is_empty(), "a plain card changes nothing in its roll", failures)
	_expect(ItemPhysics.roll_rules({}, guard) == {"gutter_rebound": true}, "the modification gives its roll a rebound", failures)
	_expect(ItemPhysics.roll_rules({}, guard, true).is_empty(), "but not once the frame has used it", failures)
	_expect(ItemPhysics.roll_rules({}, tame) == {"spin_scale": 0.7}, "a modification's spin response scales the hook", failures)
	_expect(ItemPhysics.roll_rules(holder) == {"oil_hold": true}, "a ball's oil hold reaches the roll (its own spin response is its profile's)", failures)
	_expect(ItemPhysics.roll_rules(holder, guard) == {"oil_hold": true, "gutter_rebound": true}, "the ball and its modification combine", failures)

static func _catalogue(failures: Array[String]) -> void:
	var shipped: Dictionary = Contracts.read_json("res://content/catalogue.json")
	var problems := func(change: Callable) -> Array:
		var copy: Dictionary = shipped.duplicate(true)
		change.call(copy.items)
		return Contracts.validate("catalogue", copy)
	var of := func(items: Array, category: String) -> Dictionary: return items.filter(func(i): return i.category == category)[0]
	_expect(problems.call(func(_items): pass).is_empty(), "the shipped catalogue validates", failures)
	_expect(problems.call(func(items):
		var mod: Dictionary = of.call(items, "ball_mod")
		mod["physics"] = {"gutter_rebound": true}
		mod.effects = [LOSS.duplicate(true)]).is_empty(), "a ball modification may carry the rebound and its Mult loss", failures)
	_expect(problems.call(func(items): of.call(items, "ball_mod")["physics"] = {"spin_response": 0.7}).is_empty(), "or a hook scale", failures)
	_expect(problems.call(func(items): of.call(items, "ball")["physics"] = {"oil_hold": true}).is_empty(), "a ball may hold its hook through oil", failures)
	_expect(not problems.call(func(items): of.call(items, "ball_mod")["physics"] = {"mass_scale": 1.2}).is_empty(), "a ball modification's mass waits for its own primitive", failures)
	_expect(not problems.call(func(items): of.call(items, "pin")["physics"] = {"oil_hold": true}).is_empty(), "a pin has no oil hold", failures)
	_expect(not problems.call(func(items): of.call(items, "ball")["physics"] = {"gutter_rebound": true}).is_empty(), "the rebound is a modification's, not a ball's", failures)
	_expect(not problems.call(func(items): of.call(items, "charm")["physics"] = {"oil_hold": true}).is_empty(), "a Charm has no physics", failures)
	_expect(not problems.call(func(items):
		of.call(items, "charm").effects = [{"op": "add_value", "amount": 1, "trigger": "charm", "scope": "frame", "condition": {"first_hit": true}}]).is_empty(),
		"first_hit is refused on a Charm", failures)
