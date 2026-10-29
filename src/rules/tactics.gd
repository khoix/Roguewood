extends RefCounted
## E18-C06 tactical-card primitives, played the moment the card is chosen (before
## the throw) rather than with the launch:
##   tactical.relocate_pin (Nudge): before roll 2, one standing pin moves to an
##     adjacent rack spot whose pin has fallen. The pin keeps its identity (its rack
##     position, material and modification), so reports and scoring credit it.
##   tactical.reserve_swap (Reserve Call): before roll 1, a reserve pin swaps into a
##     rack position for this frame; both return after the frame banks.
##   tactical.waive_rule (Rule Waiver): in a boss match, the rival's rules do not
##     apply for the rest of the frame (launch constraints, scoring loadout, bank).
## Every play is an action {kind, item_id, roll, ...} kept in the frame's actions and
## saved with the attempt, so a reload neither repeats nor loses one.
const Lane = preload("res://src/simulation/lane_spec.gd")
const KINDS := {"consumable.nudge": "relocate_pin", "consumable.reserve_call": "reserve_swap", "consumable.rule_waiver": "waive_rule"}
## Spots are adjacent when they are neighbours in the triangle (one pin spacing).
const ADJACENT := Lane.PIN_SPACING * 1.05

static func kind(item_id: String) -> String:
	return KINDS.get(item_id, "")

## Why a tactic cannot be played now ("" when it can). at: {roll_index, thrown (rolls
## thrown this frame), boss, rules, rack, run, actions}.
static func blocked(item_id: String, at: Dictionary) -> String:
	match kind(item_id):
		"relocate_pin":
			if int(at.roll_index) != 2:
				return "Nudge is played before roll 2."
			if nudge_options(at.rack).is_empty():
				return "Nudge: no standing pin has an empty neighbouring spot."
		"reserve_swap":
			if int(at.roll_index) != 1 or int(at.thrown) > 0:
				return "Reserve Call is played at the start of a frame, before roll 1."
			if reserve_options(at.run).is_empty():
				return "Reserve Call needs a pin in reserve."
			if at.actions.any(func(a): return a.kind == "reserve_swap"):
				return "Reserve Call: a reserve pin is already in this frame's rack."
		"waive_rule":
			if not at.boss or at.rules.is_empty():
				return "Rule Waiver is only played in a boss match."
			if waived(at.actions):
				return "Rule Waiver: the rules are already waived this frame."
		_:
			return "not an instant tactic"
	return ""

## Standing pins with an adjacent fallen spot: [{position, to: [spots]}].
static func nudge_options(rack: Dictionary) -> Array:
	var standing := {}
	for entry in rack.get("standing", []):
		standing[int(entry.position)] = true
	var out: Array = []
	for p in standing.keys():
		var free: Array = []
		for q in range(1, 11):
			if not standing.has(q) and Lane.spot(p).distance_to(Lane.spot(q)) < ADJACENT:
				free.append(q)
		if not free.is_empty():
			out.append({"position": p, "to": free})
	out.sort_custom(func(a, b): return a.position < b.position)
	return out

## The rack with standing pin `position` set upright on spot `to`.
static func apply_nudge(rack: Dictionary, position: int, to: int) -> Dictionary:
	var out := rack.duplicate(true)
	var spot := Lane.spot(to)
	for entry in out.standing:
		if int(entry.position) == position:
			entry.x = spot.x
			entry.f = spot.y
	return out

## Reserve slots (1-based) holding a pin.
static func reserve_options(run: RefCounted) -> Array:
	var out: Array = []
	for i in run.reserves.size():
		if run.reserves[i] != null:
			out.append(i + 1)
	return out

## Swaps reserve slot `reserve` (1-based) with rack `position`; the same call undoes it.
static func swap_reserve(run: RefCounted, reserve: int, position: int) -> void:
	var held = run.reserves[reserve - 1]
	run.reserves[reserve - 1] = run.rack[position]
	run.rack[position] = held

## Puts every swap of this frame back that has not been put back yet.
static func restore_swaps(run: RefCounted, actions: Array) -> void:
	for action in actions:
		if action.kind == "reserve_swap" and not action.get("restored", false):
			swap_reserve(run, int(action.reserve), int(action.position))
			action.restored = true

static func waived(actions: Array) -> bool:
	return actions.any(func(a): return a.kind == "waive_rule")

## The rules in force: a Rule Waiver this frame suspends all of them.
static func active_rules(rules: Array, actions: Array) -> Array:
	return [] if waived(actions) else rules

## One explanation line per action. names: item id -> name.
static func text(action: Dictionary, names: Dictionary) -> String:
	match action.kind:
		"relocate_pin":
			return "Nudge: pin %d moved to spot %d before roll 2." % [int(action.position), int(action.to)]
		"reserve_swap":
			return "Reserve Call: %s played at position %d this frame; %s waited in reserve %d." % [
				names.get(action.called, action.called), int(action.position), names.get(action.displaced, action.displaced), int(action.reserve)]
		"waive_rule":
			return "Rule Waiver: %s waived for this frame." % " + ".join(action.rules.map(func(r): return names.get(r, r)))
	return ""
