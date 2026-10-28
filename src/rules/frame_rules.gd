extends RefCounted
## Pure, versioned frame resolver. Physical results are inputs, never simulated here.
## Scope labels describe lifetime; match/run growth and streaks belong to the run
## (RunInventory), which supplies them as frame context and applies the result.
##
## Frame v2 (E13, ADR 008) adds, all optional and all closed vocabularies:
## - effect `condition` (every key must hold): category, match_frame, standing_count,
##   curved (any roll's committed spin passed the curve threshold), all_house (every
##   roll used the House ball) and streak_min (consecutive strikes including this one);
## - effect `per`: the amount is multiplied by a count (growth: the owner's growth;
##   retriggers: repeats performed this frame; fallen/standing, optionally ":item_id"),
##   and a zero count applies nothing;
## - op `retrigger` on a ball: repeats the scoring effects of the first pin the ball
##   knocked down directly that roll (roll.first_direct), in that pin's rack slot;
## - pin/charm `growth`, roll `first_direct` and `curved`, frame `context`
##   {match_frame, strike_streak (consecutive strikes before this frame)}.
## - op `transform` (E18-C02) on a pin's `fallen` trigger, with `into` (a pin item
##   id) and an integer percent `amount` (1..100): deferred like a payout, so it
##   never touches the score, is never retriggered, and only reports the chance;
##   the run inventory rolls it on the attempt's effects stream after banking.
##
## E18-C03 adds, all optional:
## - roll `last_fallen`: the pin that roll knocked down last (highest knockdown
##   sequence; 0 if none). The frame's last fallen pin is the last roll's that felled any;
## - context `match_score` and `match_target`: the match before this frame (target 0 in
##   Practice, which has none);
## - conditions `leave_min` (the first roll left at least n standing), `behind` (the match
##   score is below half its target; never in Practice) and `last_fallen` ("self": the
##   owner pin fell last; a pin item id: the pin that fell last is that item);
## - per `accurate` (rolls graded sweet or perfect) and `fallen_at:7,8,9,10` (fallen pins
##   at the listed positions).
const SCOPES = ["roll", "frame", "match", "run"]
const OPS = ["add_value", "add_mult", "multiply_mult", "payout", "grow_value"]
const V2_OPS = ["retrigger", "transform"]
const GRADES = {"miss": 0, "clean": 0, "sweet": 1, "perfect": 2}
const MAX_SAFE_SCORE = 9007199254740991.0
const MAX_RETRIGGERS := 8
const HOUSE := "ball.house"
const CONDITIONS := ["category", "match_frame", "standing_count", "curved", "all_house", "streak_min", "leave_min", "behind", "last_fallen"]
const PER_KINDS := ["growth", "retriggers", "fallen", "standing", "accurate", "fallen_at"]
const DEFERRED := ["payout", "grow_value", "transform"]

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
	var context: Dictionary = frame.get("context", {})
	var last_fallen := 0
	for roll in rolls:
		if int(roll.get("last_fallen", 0)) > 0:
			last_fallen = int(roll.last_fallen)
	var match_target := int(context.get("match_target", 0))
	var facts := {"category": category, "match_frame": int(context.get("match_frame", 1)), "standing_count": 10 - fallen.size(),
		"curved": rolls.any(func(r): return bool(r.get("curved", false))), "all_house": rolls.all(func(r): return r.ball_id == HOUSE),
		"streak": int(context.get("strike_streak", 0)) + 1 if category == "strike" else 0, "retriggers": 0, "fallen": {}, "standing": {},
		"leave": 10 - rolls[0].fallen_positions.size(), "behind": match_target > 0 and int(context.get("match_score", 0)) * 2 < match_target,
		"last_fallen": last_fallen, "last_item": "", "accurate": rolls.filter(func(r): return GRADES[r.accuracy] > 0).size(), "fallen_at": fallen}
	for pin in pins:
		var bucket: Dictionary = facts.fallen if fallen.has(int(pin.position)) else facts.standing
		bucket[pin.item_id] = int(bucket.get(pin.item_id, 0)) + 1
		if int(pin.position) == last_fallen:
			facts.last_item = pin.item_id
	var bases: Dictionary = {"open": [0.0, 1.0], "spare": [20.0, 2.0], "strike": [40.0, 4.0]}
	var state: Dictionary = {"value": bases[category][0], "mult": bases[category][1], "events": [], "future": [], "facts": facts}
	state.events.append({"phase": "category", "category": category, "pin_value": state.value, "mult": state.mult})
	# Ball retriggers land on the first pin each roll knocked down directly.
	var granted: Dictionary = {} # position -> [roll sources], one entry per repeat
	for roll in rolls:
		var target := int(roll.get("first_direct", 0))
		for effect in roll.effects:
			if effect.op == "retrigger" and target > 0 and fallen.get(target, 0) == int(roll.roll_index) and _holds(effect, facts, roll):
				for i in int(effect.amount):
					granted[target] = granted.get(target, []) + ["roll:%d" % roll.roll_index]
	for pin in pins:
		if fallen.has(int(pin.position)):
			var source := "pin:%d" % pin.position
			_apply_effects(state, pin, "fallen", source)
			var causes: Array = []
			for i in int(pin.get("retriggers", 0)):
				causes.append("")
			causes.append_array(granted.get(int(pin.position), []))
			for repeat in range(mini(causes.size(), MAX_RETRIGGERS)):
				facts.retriggers += 1
				_apply_effects(state, pin, "fallen", source, repeat + 1, causes[repeat])
	for pin in pins:
		if not fallen.has(int(pin.position)):
			_apply_effects(state, pin, "standing", "pin:%d" % pin.position)
	for roll in rolls:
		_apply_effects(state, roll, "ball", "roll:%d" % roll.roll_index)
	state.mult += accuracy
	state.events.append({"phase": "accuracy", "amount": accuracy, "mult": state.mult})
	for i in range(frame.charms.size()):
		_apply_effects(state, frame.charms[i], "charm", "charm:%d" % (i + 1))
	var total: float = state.value * state.mult
	if not is_finite(total) or total > MAX_SAFE_SCORE or total < 0:
		return {"ok": false, "errors": ["score exceeds exact supported numeric range"]}
	var score: int = floori(total)
	state.events.append({"phase": "bank", "score": score, "pin_value": state.value, "mult": state.mult})
	# Explicit after-bank effects are gathered in the same stable owner order.
	for pin in pins:
		_apply_effects(state, pin, "after_bank", "pin:%d" % pin.position)
	for roll in rolls:
		_apply_effects(state, roll, "after_bank", "roll:%d" % roll.roll_index)
	for i in range(frame.charms.size()):
		_apply_effects(state, frame.charms[i], "after_bank", "charm:%d" % (i + 1))
	for effect in state.future:
		state.events.append(effect.duplicate(true))
	return {"ok": true, "schema_version": int(frame.schema_version), "category": category, "pin_value": state.value,
		"mult": state.mult, "score": score, "events": state.events, "future_effects": state.future,
		"strike_streak": facts.streak, "retriggers": facts.retriggers,
		"facts": {"leave": facts.leave, "last_fallen": facts.last_fallen, "accurate": facts.accurate, "behind": facts.behind,
			"match_score": int(context.get("match_score", 0)), "match_target": match_target}}

## Every condition key must hold for this frame.
static func _holds(effect: Dictionary, facts: Dictionary, owner: Dictionary = {}) -> bool:
	var condition: Dictionary = effect.get("condition", {})
	for key in condition:
		var wanted: Variant = condition[key]
		match key:
			"category":
				if facts.category not in wanted: return false
			"match_frame":
				if facts.match_frame != int(wanted): return false
			"standing_count":
				if facts.standing_count != int(wanted): return false
			"curved", "all_house":
				if bool(facts[key]) != bool(wanted): return false
			"streak_min":
				if facts.streak < int(wanted): return false
			"leave_min":
				if facts.leave < int(wanted): return false
			"behind":
				if facts.behind != bool(wanted): return false
			"last_fallen":
				var last: int = facts.last_fallen
				if last == 0 or (int(owner.get("position", 0)) != last if wanted == "self" else facts.last_item != wanted): return false
	return true

## The count a `per` effect scales by, from this frame's facts or its owner.
static func _count(per: String, owner: Dictionary, facts: Dictionary) -> int:
	var kind := per.get_slice(":", 0)
	var item_id := per.get_slice(":", 1) if per.contains(":") else ""
	match kind:
		"growth": return int(owner.get("growth", 0))
		"retriggers": return int(facts.retriggers)
		"accurate": return int(facts.accurate)
		"fallen_at":
			return Array(per.get_slice(":", 1).split(",")).filter(func(p): return facts.fallen_at.has(int(p))).size()
		"fallen", "standing":
			var bucket: Dictionary = facts[kind]
			if not item_id.is_empty():
				return int(bucket.get(item_id, 0))
			var n := 0
			for id in bucket:
				n += int(bucket[id])
			return n
	return 0

static func _apply_effects(state: Dictionary, owner: Dictionary, trigger: String, source: String, repeat: int = 0, cause: String = "") -> void:
	var effects: Array = owner.effects
	for index in effects.size():
		var effect: Dictionary = effects[index]
		if effect.trigger != trigger or effect.op == "retrigger":
			continue
		var op: String = effect.op
		if repeat > 0 and op in DEFERRED:
			continue
		if not _holds(effect, state.facts, owner):
			continue
		var amount: float = effect.amount
		var event: Dictionary = {"phase": trigger, "source": source, "op": op,
			"amount": amount, "scope": effect.scope, "repeat": repeat, "effect_index": index}
		if effect.has("per"):
			var count := _count(effect.per, owner, state.facts)
			if count <= 0:
				continue
			event.amount = amount * count
			event["per"] = effect.per
			event["count"] = count
			event["base"] = amount
		if effect.has("condition"):
			event["condition"] = effect.condition.duplicate(true)
		if effect.has("into"):
			event["into"] = effect.into
		if not cause.is_empty():
			event["cause"] = cause
		if op in DEFERRED:
			event.phase = "after_bank"
			event["trigger"] = trigger
			state.future.append(event)
			continue
		match op:
			"add_value": state.value += event.amount
			"add_mult": state.mult += event.amount
			"multiply_mult": state.mult *= event.amount
		event["pin_value"] = state.value
		event["mult"] = state.mult
		state.events.append(event)

static func validate(frame: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var v2: bool = frame.get("schema_version") is int or frame.get("schema_version") is float
	v2 = v2 and int(frame.schema_version) == 2
	_unknown_keys(frame, ["schema_version", "pins", "rolls", "charms"] + (["context"] if v2 else []), errors)
	if not _integer_between(frame.get("schema_version"), 1, 2):
		errors.append("frame.schema_version must be 1 or 2")
	for key in ["pins", "rolls", "charms"]:
		if not frame.get(key) is Array:
			errors.append("frame.%s must be an array" % key)
	if frame.has("context"):
		var context: Variant = frame.context
		if not context is Dictionary:
			errors.append("frame.context must be an object")
		else:
			_unknown_keys(context, ["match_frame", "strike_streak", "match_score", "match_target"], errors)
			for key in ["match_score", "match_target"]:
				if not _integer_between(context.get(key, 0), 0, 1000000000000):
					errors.append("context.%s must be a whole score" % key)
			if not _integer_between(context.get("match_frame", 1), 1, 8):
				errors.append("context.match_frame must be 1..8")
			if not _integer_between(context.get("strike_streak", 0), 0, 100000):
				errors.append("context.strike_streak must be a count")
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
		_unknown_keys(pin, ["position", "item_id", "effects", "retriggers"] + (["growth"] if v2 else []), errors)
		if not _integer_between(pin.get("growth", 0), 0, 1000000):
			errors.append("pin growth must be a whole count")
		if not _integer_between(pin.get("position"), 1, 10):
			errors.append("pin position must be 1..10")
		elif positions.has(int(pin.position)):
			errors.append("duplicate pin position")
		else:
			positions[int(pin.position)] = true
		if not _integer_between(pin.get("retriggers", 0), 0, 8):
			errors.append("pin retriggers must be 0..8")
		_validate_owner(pin, "item_id", "pin.", ["fallen", "standing", "after_bank"], errors, v2)
	var roll_indices: Dictionary = {}
	var fallen: Dictionary = {}
	var first_count: int = -1
	for roll in frame.rolls:
		if not roll is Dictionary:
			errors.append("roll must be an object")
			continue
		_unknown_keys(roll, ["roll_index", "ball_id", "fallen_positions", "accuracy", "effects"] + (["first_direct", "curved", "last_fallen"] if v2 else []), errors)
		for key in ["first_direct", "last_fallen"]:
			if not _integer_between(roll.get(key, 0), 0, 10):
				errors.append("%s must be 0..10" % key)
			elif int(roll.get(key, 0)) > 0 and roll.get("fallen_positions") is Array and int(roll[key]) not in roll.fallen_positions.map(func(p): return int(p)):
				errors.append("%s must be a pin that fell that roll" % key)
		if roll.has("curved") and typeof(roll.curved) != TYPE_BOOL:
			errors.append("curved must be a boolean")
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
		_validate_owner(roll, "ball_id", "ball.", ["ball", "after_bank"], errors, v2)
	if first_count == 10 and frame.rolls.size() != 1:
		errors.append("a strike ends the frame immediately")
	if first_count != 10 and (frame.rolls.size() != 2 or not roll_indices.has(1) or not roll_indices.has(2)):
		errors.append("a non-strike completed frame requires rolls 1 and 2")
	for charm in frame.charms:
		if not charm is Dictionary:
			errors.append("Charm must be an object")
		else:
			_unknown_keys(charm, ["item_id", "effects"] + (["growth"] if v2 else []), errors)
			if not _integer_between(charm.get("growth", 0), 0, 1000000):
				errors.append("Charm growth must be a whole count")
			_validate_owner(charm, "item_id", "charm.", ["charm", "after_bank", "match_end"], errors, v2)
	return errors

static func _validate_owner(owner: Dictionary, id_key: String, prefix: String, triggers: Array, errors: Array[String], v2: bool = false) -> void:
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
		_unknown_keys(effect, ["op", "amount", "trigger", "scope"] + (["condition", "per"] if v2 else []) + (["into"] if v2 and effect.get("op") == "transform" else []), errors)
		if effect.get("op") == "transform" and (effect.get("trigger") != "fallen" or not _integer_between(effect.get("amount"), 1, 100) or not _valid_id(effect.get("into"), "pin.") or effect.has("per")):
			errors.append("transform is a fallen pin's 1..100 percent chance to become another pin (into), unscaled")
		if not effect.get("op") in OPS + (V2_OPS if v2 else []):
			errors.append("unsupported effect op")
		if effect.get("trigger") == "match_end" and not v2:
			errors.append("unsupported effect trigger for owner")
		if effect.get("trigger") == "match_end" and effect.get("op") != "grow_value":
			errors.append("match_end only permits growth")
		if effect.get("op") == "retrigger" and (effect.get("trigger") != "ball" or not _integer_between(effect.get("amount"), 1, MAX_RETRIGGERS) or effect.has("per")):
			errors.append("retrigger is 1..8 unscaled repeats from a ball")
		if effect.has("condition"):
			if not effect.condition is Dictionary:
				errors.append("condition must be an object")
			else:
				_unknown_keys(effect.condition, CONDITIONS, errors)
				var c: Dictionary = effect.condition
				if c.has("category") and (not c.category is Array or c.category.is_empty() or not c.category.all(func(k): return k in ["open", "spare", "strike"])):
					errors.append("condition.category lists frame categories")
				for key in ["match_frame", "standing_count", "streak_min", "leave_min"]:
					if c.has(key) and not _integer_between(c[key], 0 if key == "standing_count" else 1, 10 if key in ["standing_count", "leave_min"] else 100):
						errors.append("condition.%s out of range" % key)
				if c.has("last_fallen") and not (c.last_fallen is String and c.last_fallen == "self" and prefix == "pin.") and not _valid_id(c.last_fallen, "pin."):
					errors.append("condition.last_fallen is \"self\" on a pin (it fell last) or a pin item id")
				for key in ["curved", "all_house", "behind"]:
					if c.has(key) and typeof(c[key]) != TYPE_BOOL:
						errors.append("condition.%s must be a boolean" % key)
		if effect.has("per"):
			var per: Variant = effect.per
			var kind: String = String(per).get_slice(":", 0) if per is String else ""
			if kind not in PER_KINDS or not _valid_per(String(per)):
				errors.append("unsupported per count")
			elif effect.get("op") in ["multiply_mult", "payout"]:
				errors.append("only additions and growth scale per count")
		if not effect.get("scope") in SCOPES:
			errors.append("unsupported effect scope")
		if not effect.get("trigger") in triggers:
			errors.append("unsupported effect trigger for owner")
		if not _number(effect.get("amount")) or effect.get("amount", -1) < 0 or effect.get("amount", 0) > 1000000:
			errors.append("effect amount must be finite and within 0..1e6")
		if effect.get("op") == "multiply_mult" and _number(effect.get("amount")) and effect.amount <= 0:
			errors.append("multiply_mult amount must be positive")
		if effect.get("trigger") == "after_bank" and not effect.get("op") in DEFERRED:
			errors.append("after_bank only permits deferred mutations")

## A per count's suffix: an item id for fallen/standing, positions for fallen_at, none otherwise.
static func _valid_per(per: String) -> bool:
	var kind := per.get_slice(":", 0)
	var suffix := per.trim_prefix(kind + ":") if per.contains(":") else ""
	match kind:
		"fallen", "standing": return suffix.is_empty() or _valid_id(suffix, "")
		"fallen_at":
			var positions := Array(suffix.split(",")).map(func(p): return int(p) if String(p).is_valid_int() else 0)
			var unique := {}
			for p in positions: unique[p] = true
			return not suffix.is_empty() and positions.all(func(p): return p >= 1 and p <= 10) and unique.size() == positions.size()
	return suffix.is_empty()

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
