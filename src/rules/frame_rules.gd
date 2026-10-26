extends RefCounted
## Pure, versioned frame resolver. Physical results are inputs, never simulated here.
## Scope labels describe lifetime; match/run deduplication belongs to their future owners.
const SCOPES = ["roll", "frame", "match", "run"]
const OPS = ["add_value", "add_mult", "multiply_mult", "payout", "grow_value"]
const GRADES = {"miss": 0, "clean": 0, "sweet": 1, "perfect": 2}
const MAX_SAFE_SCORE = 9007199254740991.0

static func resolve(frame: Dictionary) -> Dictionary:
	var errors: Array[String] = validate(frame)
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	var pins: Array = frame.pins.duplicate(true)
	pins.sort_custom(func(a, b): return a.position < b.position)
	var rolls: Array = frame.rolls.duplicate(true)
	rolls.sort_custom(func(a, b): return a.roll_index < b.roll_index)
	var fallen: Dictionary = {}
	var accuracy: int = 0
	for roll in rolls:
		accuracy = maxi(accuracy, GRADES[roll.accuracy])
		for position in roll.fallen_positions:
			fallen[int(position)] = int(roll.roll_index)
	var category: String = "open"
	if rolls[0].fallen_positions.size() == 10:
		category = "strike"
	elif fallen.size() == 10:
		category = "spare"
	var bases: Dictionary = {"open": [0.0, 1.0], "spare": [20.0, 2.0], "strike": [40.0, 4.0]}
	var state: Dictionary = {"value": bases[category][0], "mult": bases[category][1], "events": [], "future": []}
	state.events.append({"phase": "category", "category": category, "pin_value": state.value, "mult": state.mult})
	for pin in pins:
		if fallen.has(int(pin.position)):
			_apply_effects(state, pin.effects, "fallen", "pin:%d" % pin.position)
			for repeat in range(int(pin.get("retriggers", 0))):
				_apply_effects(state, pin.effects, "fallen", "pin:%d" % pin.position, repeat + 1)
	for pin in pins:
		if not fallen.has(int(pin.position)):
			_apply_effects(state, pin.effects, "standing", "pin:%d" % pin.position)
	for roll in rolls:
		_apply_effects(state, roll.effects, "ball", "roll:%d" % roll.roll_index)
	state.mult += accuracy
	state.events.append({"phase": "accuracy", "amount": accuracy, "mult": state.mult})
	for i in range(frame.charms.size()):
		_apply_effects(state, frame.charms[i].effects, "charm", "charm:%d" % (i + 1))
	var total: float = state.value * state.mult
	if not is_finite(total) or total > MAX_SAFE_SCORE or total < 0:
		return {"ok": false, "errors": ["score exceeds exact supported numeric range"]}
	var score: int = floori(total)
	state.events.append({"phase": "bank", "score": score, "pin_value": state.value, "mult": state.mult})
	# Explicit after-bank effects are gathered in the same stable owner order.
	for pin in pins:
		_apply_effects(state, pin.effects, "after_bank", "pin:%d" % pin.position)
	for roll in rolls:
		_apply_effects(state, roll.effects, "after_bank", "roll:%d" % roll.roll_index)
	for i in range(frame.charms.size()):
		_apply_effects(state, frame.charms[i].effects, "after_bank", "charm:%d" % (i + 1))
	for effect in state.future:
		state.events.append(effect.duplicate(true))
	return {"ok": true, "schema_version": 1, "category": category, "pin_value": state.value,
		"mult": state.mult, "score": score, "events": state.events, "future_effects": state.future}

static func _apply_effects(state: Dictionary, effects: Array, trigger: String, source: String, repeat: int = 0) -> void:
	for effect in effects:
		if effect.trigger != trigger:
			continue
		var op: String = effect.op
		if repeat > 0 and op in ["payout", "grow_value"]:
			continue
		var event: Dictionary = {"phase": trigger, "source": source, "op": op,
			"amount": effect.amount, "scope": effect.scope, "repeat": repeat}
		if op in ["payout", "grow_value"]:
			event.phase = "after_bank"
			event["trigger"] = trigger
			state.future.append(event)
			continue
		match op:
			"add_value": state.value += effect.amount
			"add_mult": state.mult += effect.amount
			"multiply_mult": state.mult *= effect.amount
		event["pin_value"] = state.value
		event["mult"] = state.mult
		state.events.append(event)

static func validate(frame: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	_unknown_keys(frame, ["schema_version", "pins", "rolls", "charms"], errors)
	if not _integer_between(frame.get("schema_version"), 1, 1):
		errors.append("frame.schema_version must be 1")
	for key in ["pins", "rolls", "charms"]:
		if not frame.get(key) is Array:
			errors.append("frame.%s must be an array" % key)
	if not errors.is_empty():
		return errors
	if frame.pins.size() != 10:
		errors.append("frame requires exactly ten pins")
	if frame.rolls.size() < 1 or frame.rolls.size() > 2:
		errors.append("frame requires one or two rolls")
	if frame.charms.size() > 5:
		errors.append("frame permits at most five Charms")
	var positions: Dictionary = {}
	for pin in frame.pins:
		if not pin is Dictionary:
			errors.append("pin must be an object")
			continue
		_unknown_keys(pin, ["position", "item_id", "effects", "retriggers"], errors)
		if not _integer_between(pin.get("position"), 1, 10):
			errors.append("pin position must be 1..10")
		elif positions.has(int(pin.position)):
			errors.append("duplicate pin position")
		else:
			positions[int(pin.position)] = true
		if not _integer_between(pin.get("retriggers", 0), 0, 8):
			errors.append("pin retriggers must be 0..8")
		_validate_owner(pin, "item_id", "pin.", ["fallen", "standing", "after_bank"], errors)
	var roll_indices: Dictionary = {}
	var fallen: Dictionary = {}
	var first_count: int = -1
	for roll in frame.rolls:
		if not roll is Dictionary:
			errors.append("roll must be an object")
			continue
		_unknown_keys(roll, ["roll_index", "ball_id", "fallen_positions", "accuracy", "effects"], errors)
		if not _integer_between(roll.get("roll_index"), 1, 2):
			errors.append("roll_index must be 1 or 2")
		elif roll_indices.has(int(roll.roll_index)):
			errors.append("duplicate roll_index")
		else:
			roll_indices[int(roll.roll_index)] = true
		if not roll.get("accuracy") is String or not GRADES.has(roll.get("accuracy")):
			errors.append("unknown accuracy grade")
		if not roll.get("fallen_positions") is Array:
			errors.append("fallen_positions must be an array")
		else:
			if roll.get("roll_index") == 1:
				first_count = roll.fallen_positions.size()
			for position in roll.fallen_positions:
				if not _integer_between(position, 1, 10):
					errors.append("fallen position must be 1..10")
				elif fallen.has(int(position)):
					errors.append("pin cannot fall twice in a frame")
				else:
					fallen[int(position)] = true
		_validate_owner(roll, "ball_id", "ball.", ["ball", "after_bank"], errors)
	if first_count == 10 and frame.rolls.size() != 1:
		errors.append("a strike ends the frame immediately")
	if first_count != 10 and (frame.rolls.size() != 2 or not roll_indices.has(1) or not roll_indices.has(2)):
		errors.append("a non-strike completed frame requires rolls 1 and 2")
	for charm in frame.charms:
		if not charm is Dictionary:
			errors.append("Charm must be an object")
		else:
			_unknown_keys(charm, ["item_id", "effects"], errors)
			_validate_owner(charm, "item_id", "charm.", ["charm", "after_bank"], errors)
	return errors

static func _validate_owner(owner: Dictionary, id_key: String, prefix: String, triggers: Array, errors: Array[String]) -> void:
	var item_id: Variant = owner.get(id_key)
	if not _valid_id(item_id, prefix):
		errors.append("invalid %s" % id_key)
	if not owner.get("effects") is Array:
		errors.append("effects must be an array")
		return
	if owner.effects.size() > 64:
		errors.append("at most 64 effects per owner")
	for effect in owner.effects:
		if not effect is Dictionary:
			errors.append("effect must be an object")
			continue
		_unknown_keys(effect, ["op", "amount", "trigger", "scope"], errors)
		if not effect.get("op") in OPS:
			errors.append("unsupported effect op")
		if not effect.get("scope") in SCOPES:
			errors.append("unsupported effect scope")
		if not effect.get("trigger") in triggers:
			errors.append("unsupported effect trigger for owner")
		if not _number(effect.get("amount")) or effect.get("amount", -1) < 0 or effect.get("amount", 0) > 1000000:
			errors.append("effect amount must be finite and within 0..1e6")
		if effect.get("op") == "multiply_mult" and _number(effect.get("amount")) and effect.amount <= 0:
			errors.append("multiply_mult amount must be positive")
		if effect.get("trigger") == "after_bank" and not effect.get("op") in ["payout", "grow_value"]:
			errors.append("after_bank only permits deferred mutations")

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _integer_between(value: Variant, low: int, high: int) -> bool:
	return _number(value) and value == floor(value) and value >= low and value <= high

static func _valid_id(value: Variant, prefix: String) -> bool:
	if not value is String or not value.begins_with(prefix):
		return false
	var pattern: RegEx = RegEx.new()
	pattern.compile("^[a-z][a-z0-9_]*\\.[a-z][a-z0-9_]*$")
	return pattern.search(value) != null

static func _unknown_keys(record: Dictionary, allowed: Array, errors: Array[String]) -> void:
	for key in record:
		if key not in allowed:
			errors.append("unknown field: %s" % str(key))
