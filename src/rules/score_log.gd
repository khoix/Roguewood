extends RefCounted
## Turns a FrameRules result into ordered, human-readable calculation steps. It only
## reads the authoritative event list: each step copies the running Pin Value and
## Mult that the resolver recorded, so presentation can never change a score.
const ADD := "+"
const TIMES := "×"

static func grade_name(frame: Dictionary) -> String:
	var best := "miss"
	var rank := {"miss": 0, "clean": 1, "sweet": 2, "perfect": 3}
	for roll in frame.rolls:
		if rank[roll.accuracy] > rank[best]:
			best = roll.accuracy
	return best

## names: optional {item_id: display name}.
static func steps(result: Dictionary, frame: Dictionary, names: Dictionary = {}) -> Array:
	var out: Array = []
	var pins := {}
	for pin in frame.pins:
		pins[int(pin.position)] = pin.item_id
	var balls := {}
	for roll in frame.rolls:
		balls[int(roll.roll_index)] = roll.ball_id
	var value := 0.0
	var mult := 1.0
	for event in result.events:
		var step := {"phase": event.phase, "symbol": "", "pin": 0}
		match event.phase:
			"category":
				value = event.pin_value
				mult = event.mult
				step.text = "%s — base %s Value × %s Mult" % [String(event.category).capitalize(), _n(value), _n(mult)]
				step.symbol = "="
			"accuracy":
				mult = event.mult
				step.text = "Accuracy %s %s%s Mult" % [grade_name(frame), ADD, _n(event.amount)]
				step.symbol = ADD
			"bank":
				step.text = "Bank ⌊%s × %s⌋ = %s" % [_n(event.pin_value), _n(event.mult), _n(event.score)]
				step.symbol = "="
				step.score = event.score
			"after_bank":
				step.text = "After bank: %s %s %s (%s)" % [_owner(event.source, pins, balls, names), event.op.replace("_", " "), _n(event.amount), event.scope]
				step.symbol = "→"
			_:
				value = event.pin_value
				mult = event.mult
				var owner := _owner(event.source, pins, balls, names)
				var amount := _n(event.amount)
				match event.op:
					"add_value":
						step.text = "%s %s%s Value" % [owner, ADD, amount]
						step.symbol = ADD
					"add_mult":
						step.text = "%s %s%s Mult" % [owner, ADD, amount]
						step.symbol = ADD
					"multiply_mult":
						step.text = "%s %s%s Mult" % [owner, TIMES, amount]
						step.symbol = TIMES
				if event.phase == "standing":
					step.text += " (standing)"
				if int(event.get("repeat", 0)) > 0:
					step.text += " (retrigger %d)" % int(event.repeat)
				if String(event.source).begins_with("pin:"):
					step.pin = int(String(event.source).trim_prefix("pin:"))
		step.pin_value = value
		step.mult = mult
		out.append(step)
	return out

static func _owner(source: String, pins: Dictionary, balls: Dictionary, names: Dictionary) -> String:
	var parts := source.split(":")
	var index := int(parts[1])
	match parts[0]:
		"pin":
			return "Pin %d %s" % [index, names.get(pins.get(index, ""), pins.get(index, ""))]
		"roll":
			return "Roll %d %s" % [index, names.get(balls.get(index, ""), balls.get(index, ""))]
		"charm":
			return "Charm %d" % index
	return source

## Integral values print without decimals; others keep two places.
static func _n(number: Variant) -> String:
	var x := float(number)
	return str(int(x)) if x == floorf(x) and absf(x) < 1e15 else "%.2f" % x
