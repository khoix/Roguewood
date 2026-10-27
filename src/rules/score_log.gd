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

## names: optional {item_id: display name}. owners: optional FrameBuilder map of
## event source ("pin:3", "roll:1") -> item id per effect, so tactical cards and
## modifications are named rather than the pin or ball that carries them.
static func steps(result: Dictionary, frame: Dictionary, names: Dictionary = {}, owners: Dictionary = {}) -> Array:
	var out: Array = []
	var pins := {}
	for pin in frame.pins:
		pins[int(pin.position)] = pin.item_id
	var balls := {}
	for roll in frame.rolls:
		balls[int(roll.roll_index)] = roll.ball_id
	var charms := {}
	for i in frame.charms.size():
		charms[i + 1] = frame.charms[i].item_id
	var value := 0.0
	var mult := 1.0
	var seen := {}
	var banked := -1
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
				banked = event.score
			"after_bank":
				var owner := _effect_owner(event, frame, owners, names, seen, _owner(event.source, pins, balls, charms, names), true)
				var change := ("+$%s" % _n(event.amount)) if event.op == "payout" else ("grows +%s" % _n(event.amount) if event.op == "grow_value" else "%s %s" % [event.op.replace("_", " "), _n(event.amount)])
				step.text = "After bank: %s %s (%s)" % [owner, change, event.scope]
				step.symbol = "→"
				step.score = banked # the bank stands; after-bank effects never rescore it
			_:
				value = event.pin_value
				mult = event.mult
				var owner := _effect_owner(event, frame, owners, names, seen, _owner(event.source, pins, balls, charms, names))
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
				if event.has("count"):
					step.text += " (%d × %s%s%s)" % [int(event.count), ADD if event.op != "multiply_mult" else TIMES, _n(event.base), _per_text(String(event.per), names)]
				if event.has("condition"):
					step.text += " (%s)" % condition_text(event.condition)
				if event.phase == "standing":
					step.text += " (standing)"
				if int(event.get("repeat", 0)) > 0:
					var by := ""
					if not String(event.get("cause", "")).is_empty():
						by = " · " + _owner(event.cause, pins, balls, charms, names)
					step.text += " (retrigger %d%s)" % [int(event.repeat), by]
				if String(event.source).begins_with("pin:"):
					step.pin = int(String(event.source).trim_prefix("pin:"))
		step.pin_value = value
		step.mult = mult
		out.append(step)
	return out

## The k-th event of an owner (pin or roll) for one trigger comes from its k-th
## effect with that trigger and of the same kind: deferred payouts/growth settle
## after the bank, the rest before it. Retriggers restart the count.
static func _effect_owner(event: Dictionary, frame: Dictionary, owners: Dictionary, names: Dictionary, seen: Dictionary, fallback: String, deferred: bool = false) -> String:
	var source: String = event.source
	var supplied: Array = owners.get(source, [])
	var parts := source.split(":")
	if supplied.is_empty() or parts[0] not in ["pin", "roll"]:
		return fallback
	var index := int(parts[1])
	# v2 events name the effect they came from; older event lists are matched by order.
	if event.has("effect_index"):
		var at := int(event.effect_index)
		return "%s %d %s" % [parts[0].capitalize(), index, names.get(supplied[at], supplied[at])] if at < supplied.size() else fallback
	var trigger: String = event.get("trigger", event.phase) if deferred else event.phase
	var effects: Array = []
	for owner in (frame.pins if parts[0] == "pin" else frame.rolls):
		if int(owner.get("position", owner.get("roll_index", 0))) == index:
			effects = owner.effects
	var key := "%s#%d#%s#%s" % [source, int(event.get("repeat", 0)), trigger, deferred]
	var k: int = seen.get(key, 0)
	seen[key] = k + 1
	var count := 0
	for i in effects.size():
		if effects[i].trigger != trigger or (effects[i].op in ["payout", "grow_value"]) != deferred:
			continue
		if count == k and i < supplied.size():
			return "%s %d %s" % [parts[0].capitalize(), index, names.get(supplied[i], supplied[i])]
		count += 1
	return fallback

static func _owner(source: String, pins: Dictionary, balls: Dictionary, charms: Dictionary, names: Dictionary) -> String:
	var parts := source.split(":")
	var index := int(parts[1])
	match parts[0]:
		"pin":
			return "Pin %d %s" % [index, names.get(pins.get(index, ""), pins.get(index, ""))]
		"roll":
			return "Roll %d %s" % [index, names.get(balls.get(index, ""), balls.get(index, ""))]
		"charm":
			return ("Charm %d %s" % [index, names.get(charms.get(index, ""), charms.get(index, ""))]).strip_edges()
	return source

## Short reason a conditional effect applied, e.g. "strike", "frame 2", "1 standing".
static func condition_text(condition: Dictionary) -> String:
	var parts: Array = []
	for key in condition:
		var v: Variant = condition[key]
		match key:
			"category": parts.append(" or ".join(v))
			"match_frame": parts.append("frame %d" % int(v))
			"standing_count": parts.append("%d standing" % int(v))
			"curved": parts.append("curved" if v else "straight")
			"all_house": parts.append("all House" if v else "not all House")
			"streak_min": parts.append("strike streak %d+" % int(v))
	return ", ".join(parts)

static func _per_text(per: String, names: Dictionary) -> String:
	var kind := per.get_slice(":", 0)
	var item_id := per.get_slice(":", 1) if per.contains(":") else ""
	var what: String = names.get(item_id, item_id) if not item_id.is_empty() else "pin"
	match kind:
		"growth": return " per growth"
		"retriggers": return " per retrigger"
		"fallen": return " per %s down" % what
		"standing": return " per %s standing" % what
	return ""

## Integral values print without decimals; others keep two places.
static func _n(number: Variant) -> String:
	var x := float(number)
	return str(int(x)) if x == floorf(x) and absf(x) < 1e15 else "%.2f" % x
