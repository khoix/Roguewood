extends RefCounted
const Rules = preload("res://src/rules/frame_rules.gd")

static func effect(op: String, amount: float, trigger: String = "fallen") -> Dictionary:
	return {"op": op, "amount": amount, "trigger": trigger, "scope": "frame"}

static func frame(first: Array, second: Array = []) -> Dictionary:
	var pins: Array = []
	for position in range(1, 11):
		pins.append({"position": position, "item_id": "pin.wood", "effects": [effect("add_value", 10)]})
	var rolls: Array = [{"roll_index": 1, "ball_id": "ball.house", "fallen_positions": first, "accuracy": "clean", "effects": []}]
	if first.size() != 10:
		rolls.append({"roll_index": 2, "ball_id": "ball.house", "fallen_positions": second, "accuracy": "miss", "effects": []})
	return {"schema_version": 1, "pins": pins, "rolls": rolls, "charms": []}

static func run() -> Array[String]:
	var failures: Array[String] = []
	var strike: Dictionary = frame(range(1, 11))
	_check(Rules.resolve(strike).get("score") == 560, "Wood strike = 560", failures)
	_check(Rules.resolve(frame(range(1, 8), [8, 9, 10])).get("score") == 240, "Wood spare = 240", failures)
	_check(Rules.resolve(frame(range(1, 9), [9])).get("score") == 90, "Wood open = 90", failures)
	_check(Rules.resolve(frame([], [])).get("score") == 0, "gutter frame = 0", failures)
	var ruby: Dictionary = strike.duplicate(true)
	for index in [8, 9]:
		ruby.pins[index].item_id = "pin.ruby"
		ruby.pins[index].effects.append(effect("add_mult", 2))
	ruby.charms = [{"item_id": "charm.flat_bonus", "effects": [effect("add_mult", 4, "charm")]}, {"item_id": "charm.finisher", "effects": [effect("multiply_mult", 2, "charm")]}]
	_check(Rules.resolve(ruby).get("score") == 3360, "ordered Charms = 3360", failures)
	ruby.charms.reverse()
	_check(Rules.resolve(ruby).get("score") == 2800, "reverse Charms = 2800", failures)
	var standing: Dictionary = frame(range(1, 10), [])
	standing.pins[9].effects.append(effect("add_mult", 3, "standing"))
	_check(Rules.resolve(standing).get("score") == 360, "standing effects", failures)
	var precise: Dictionary = frame([1, 2], [3])
	precise.rolls[0].accuracy = "sweet"
	precise.rolls[1].accuracy = "perfect"
	_check(Rules.resolve(precise).get("score") == 90, "best accuracy once", failures)
	var fractional: Dictionary = frame([1], [])
	fractional.pins[0].effects = [effect("add_value", 1.9)]
	fractional.charms = [{"item_id": "charm.fraction", "effects": [effect("multiply_mult", 1.9, "charm")]}]
	_check(Rules.resolve(fractional).get("score") == 3, "floor once at bank", failures)
	var repeated: Dictionary = strike.duplicate(true)
	repeated.pins[0].retriggers = 2
	repeated.pins[0].effects.append(effect("payout", 1))
	repeated.pins[0].effects.append(effect("grow_value", 5))
	var replay: Dictionary = Rules.resolve(repeated)
	_check(replay.get("score") == 640, "bounded pin retriggers", failures)
	_check(replay.future_effects.size() == 2, "retriggers do not repeat growth or payout", failures)
	_check(replay.events[-3].phase == "bank" and replay.events[-1].phase == "after_bank", "mutations after bank", failures)
	var snapshot: Dictionary = ruby.duplicate(true)
	var result: Dictionary = Rules.resolve(ruby)
	_check(ruby == snapshot, "input remains immutable", failures)
	_check(result == Rules.resolve(ruby), "deterministic replay", failures)
	var round_trip: Variant = JSON.parse_string(JSON.stringify(ruby))
	_check(Rules.resolve(round_trip) == result, "JSON fixture round trip", failures)
	var shuffled: Dictionary = ruby.duplicate(true)
	shuffled.pins.reverse()
	shuffled.rolls[0].fallen_positions.reverse()
	_check(Rules.resolve(shuffled) == result, "rack/input collision order cannot change score event order", failures)
	var ordered: Dictionary = frame([2, 1], [3])
	ordered.rolls[0].effects = [effect("add_mult", 2, "ball")]
	ordered.rolls[1].effects = [effect("multiply_mult", 2, "ball")]
	_check(Rules.resolve(ordered).get("score") == 180, "ball effects in roll order", failures)
	var event_result: Dictionary = Rules.resolve(ordered)
	var phase_sequence: Array = []
	for event in event_result.events:
		phase_sequence.append(event.phase)
	_check(phase_sequence == ["category", "fallen", "fallen", "fallen", "ball", "ball", "accuracy", "bank"], "exact event phase sequence", failures)
	var standing_reward: Dictionary = frame([1], [])
	standing_reward.pins[9].effects = [effect("payout", 2, "standing")]
	_check(Rules.resolve(standing_reward).future_effects.size() == 1, "standing payout activates once", failures)
	standing_reward.rolls[1].fallen_positions = [10]
	_check(Rules.resolve(standing_reward).future_effects.is_empty(), "standing payout cannot activate for fallen pin", failures)
	ordered.rolls.reverse()
	_check(Rules.resolve(ordered).get("score") == 180, "roll records canonicalized by index", failures)
	for bad in _invalid_frames():
		_check(not Rules.resolve(bad).ok, "reject malformed frame: %s" % JSON.stringify(bad), failures)
	return failures

static func _invalid_frames() -> Array:
	var cases: Array = [{}, {"schema_version": 1, "pins": null, "rolls": [], "charms": []}]
	var duplicate: Dictionary = frame([1], [1])
	cases.append(duplicate)
	var incomplete: Dictionary = frame([1], [])
	incomplete.rolls.pop_back()
	cases.append(incomplete)
	var extra_roll: Dictionary = frame(range(1, 11))
	extra_roll.rolls.append(frame([], []).rolls[1])
	cases.append(extra_roll)
	var missing: Dictionary = frame([], [])
	missing.pins.pop_back()
	cases.append(missing)
	var bad_effect: Dictionary = frame([1], [])
	bad_effect.pins[0].effects[0].amount = "ten"
	cases.append(bad_effect)
	var infinity: Dictionary = frame([1], [])
	infinity.pins[0].effects[0].amount = INF
	cases.append(infinity)
	var wrong_trigger: Dictionary = frame([1], [])
	wrong_trigger.pins[0].effects[0].trigger = "charm"
	cases.append(wrong_trigger)
	var bad_retrigger: Dictionary = frame([1], [])
	bad_retrigger.pins[0].retriggers = 1.5
	cases.append(bad_retrigger)
	var duplicate_position: Dictionary = frame([1], [])
	duplicate_position.pins[1].position = 1
	cases.append(duplicate_position)
	var overflow: Dictionary = frame([1], [])
	overflow.pins[0].effects = [effect("add_value", 1e6), effect("multiply_mult", 1e6), effect("multiply_mult", 1e6)]
	cases.append(overflow)
	for bad_id in ["pin.Wood", "pin.a.b", "pin.", "pin.wood-bad"]:
		var bad: Dictionary = frame([1], [])
		bad.pins[0].item_id = bad_id
		cases.append(bad)
	for bad_amount in [0, -1, true, 1000001]:
		var bad: Dictionary = frame([1], [])
		bad.pins[0].effects = [effect("multiply_mult", 1)]
		bad.pins[0].effects[0].amount = bad_amount
		cases.append(bad)
	var wrong_version: Dictionary = frame([1], [])
	wrong_version.schema_version = true
	cases.append(wrong_version)
	var unknown: Dictionary = frame([1], [])
	unknown.pins[0].effects[0].amout = 10
	cases.append(unknown)
	return cases

static func _check(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)
