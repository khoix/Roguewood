extends RefCounted
## Turns a FrameRules result into ordered, human-readable calculation steps. It only
## reads the authoritative event list: each step copies the running Pin Value and
## Mult that the resolver recorded, so presentation can never change a score.
const ADD := "+"
const TIMES := "×"
const Tactics = preload("res://src/rules/tactics.gd")
const Upgrades = preload("res://src/rules/upgrades.gd")

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
	var facts: Dictionary = result.get("facts", {})
	for event in result.events:
		var step := {"phase": event.phase, "symbol": "", "pin": 0}
		if event.phase == "accuracy":
			# A fallen pin that pays only if it fell last shows its 0 when it did not.
			for pin in frame.pins:
				if _fell(frame, int(pin.position)) and int(pin.position) != int(facts.get("last_fallen", 0)) and pin.effects.any(func(e): return e.get("condition", {}).get("last_fallen") == "self"):
					out.append({"phase": "fallen", "symbol": ADD, "pin": int(pin.position), "pin_value": value, "mult": mult,
						"text": "Pin %d %s +0 Value (did not fall last)" % [int(pin.position), names.get(pin.item_id, pin.item_id)]})
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
				if event.op == "transform":
					change = "%s%% chance to become %s" % [_n(event.amount), names.get(event.get("into", ""), event.get("into", ""))]
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
					step.text += " (%s)" % condition_text(event.condition, facts, names)
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

## An item's exact rules for cards and shop offers (design §8: "show exact effects
## on tap"): each effect with its trigger, condition and scaling, then any physics.
static func item_text(item: Dictionary, names: Dictionary = {}) -> String:
	var parts: Array = []
	# Instant tactics (E18-C06) and shop upgrades (E18-C07) have no frame effects:
	# their rules are their play and their shop effect.
	var rules: String = Tactics.describe(str(item.get("id", ""))) + Upgrades.describe(str(item.get("id", "")))
	if not rules.is_empty():
		parts.append(rules)
	var when := {"fallen": " when down", "standing": " if standing"}
	for effect in item.get("effects", []):
		var amount := _n(effect.amount)
		var text := ""
		match effect.op:
			"add_value": text = "+%s Value" % amount
			"add_mult": text = "+%s Mult" % amount
			"multiply_mult": text = "×%s Mult" % amount
			"payout": text = "+$%s" % amount
			"retrigger": text = "Retriggers the first pin it hits directly"
			"grow_value": text = "grows +%s" % amount
		if effect.has("per"):
			text += _per_text(String(effect.per), names)
		if effect.trigger == "match_end":
			text += " after each match"
		else:
			text += when.get(effect.trigger, "")
		if effect.has("condition"):
			text += " (%s)" % condition_text(effect.condition)
		parts.append(text)
	var physics: Dictionary = item.get("physics", {})
	if physics.has("spin_response"):
		parts.append("hook ×%s" % String.num(physics.spin_response, 2))
	if physics.has("mass_scale"):
		parts.append("mass ×%s" % String.num(physics.mass_scale, 2))
	if physics.has("bounce"):
		parts.append("bouncier")
	if item.get("category", "") == "consumable":
		parts.append("once")
	return " · ".join(parts) if not parts.is_empty() else "—"

static func _fell(frame: Dictionary, position: int) -> bool:
	return frame.rolls.any(func(r): return position in r.fallen_positions.map(func(p): return int(p)))

## Short reason a conditional effect applied, e.g. "strike", "frame 2", "1 standing".
## facts: the resolver's frame facts, to show the checked numbers when they are known.
static func condition_text(condition: Dictionary, facts: Dictionary = {}, names: Dictionary = {}) -> String:
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
			"leave_min":
				parts.append("first roll left %d, needs %d+" % [int(facts.leave), int(v)] if facts.has("leave") else "first roll leaves %d+" % int(v))
			"behind":
				if facts.has("match_target") and int(facts.match_target) > 0:
					parts.append("%s: %d vs half of %d" % ["behind" if v else "not behind", int(facts.match_score), int(facts.match_target)])
				else:
					parts.append("match score under half the target" if v else "not behind")
			"last_fallen":
				parts.append("fell last" if v == "self" else "%s fell last" % names.get(v, v))
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
		"accurate": return " per sweet or perfect roll"
		"fallen_at":
			var at := per.trim_prefix("fallen_at:")
			return " per back-row pin down" if at == "7,8,9,10" else " per pin down at " + at.replace(",", ", ")
	return ""

## Integral values print without decimals; others keep two places.
static func _n(number: Variant) -> String:
	var x := float(number)
	return str(int(x)) if x == floorf(x) and absf(x) < 1e15 else "%.2f" % x
