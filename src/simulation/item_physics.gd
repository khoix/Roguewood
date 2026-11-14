extends RefCounted
## Per-item physics profiles (E13, ADR 008): the catalogue's optional `physics`
## block turned into what one roll's LaneWorld needs. Balls scale mass and the side
## spin a charged throw produces; pins scale mass and set their restitution. An item
## without a block keeps the House/Wood values exactly, so lab and fixture rolls
## (and the physics digest) are unchanged. Pure data: no scene access.
const Lane = preload("res://src/simulation/lane_spec.gd")
const BALL_DEFAULT := {"mass_scale": 1.0, "spin_response": 1.0}
const PIN_DEFAULT := {"mass_scale": 1.0, "bounce": Lane.PIN_BOUNCE}

static func ball(item: Dictionary) -> Dictionary:
	var physics: Dictionary = item.get("physics", {})
	return {"mass_scale": float(physics.get("mass_scale", 1.0)), "spin_response": float(physics.get("spin_response", 1.0))}

static func pin(item: Dictionary) -> Dictionary:
	var physics: Dictionary = item.get("physics", {})
	return {"mass_scale": float(physics.get("mass_scale", 1.0)), "bounce": float(physics.get("bounce", Lane.PIN_BOUNCE))}

## E18-C14: what the thrown card brings to its own roll, for LaneWorld.rules.
## - a ball with `oil_hold` meets every lane as House Oil;
## - a ball modification with `gutter_rebound` gives the roll one rebound off the
##   gutter edge, unless the frame has used it (`rebound_used`);
## - a ball modification's `spin_response` scales the hook the charge produces.
## An empty result changes nothing.
static func roll_rules(ball_item: Dictionary, mod_item: Dictionary = {}, rebound_used: bool = false) -> Dictionary:
	var out := {}
	if bool(ball_item.get("physics", {}).get("oil_hold", false)):
		out["oil_hold"] = true
	var mod: Dictionary = mod_item.get("physics", {})
	if bool(mod.get("gutter_rebound", false)) and not rebound_used:
		out["gutter_rebound"] = true
	if mod.has("spin_response"):
		out["spin_scale"] = float(mod.spin_response)
	return out

## The profile table for one roll: every catalogue ball by id, and the racked pins
## by position (rack_pins: position -> pin item id).
static func profiles(catalogue: Dictionary, rack_pins: Dictionary) -> Dictionary:
	var items := {}
	for entry in catalogue.get("items", []):
		items[entry.id] = entry
	var balls := {}
	for id in items:
		if items[id].category == "ball":
			balls[id] = ball(items[id])
	var pins := {}
	for position in rack_pins:
		var id: String = rack_pins[position]
		pins[int(position)] = pin(items.get(id, {}))
		pins[int(position)]["item_id"] = id
	return {"balls": balls, "pins": pins}
