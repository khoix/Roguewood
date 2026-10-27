extends RefCounted
## Assembles a completed frame for FrameRules from simulation roll reports and the
## rack loadout, hydrating every effect from a catalogue by stable ID (UI never
## supplies effects). Pure: no scene, physics or presentation access.
const Contracts = preload("res://src/contracts/contracts.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const LAB_CATALOGUE := "res://content/fixtures/lab_catalogue.json"

## The throw lab's fixed loadout: ten Wood pins, no Charms. Not a catalogue claim.
static func lab_loadout() -> Dictionary:
	var pins := {}
	for position in range(1, 11):
		pins[position] = "pin.wood"
	return {"pins": pins, "charms": []}

## A frame ends on a first-roll strike or after the second roll.
static func is_complete(reports: Array) -> bool:
	if reports.size() == 1:
		return reports[0].roll_result.fallen_positions.size() == 10
	return reports.size() == 2

static func item(catalogue: Dictionary, item_id: String) -> Dictionary:
	for entry in catalogue.get("items", []):
		if entry.id == item_id:
			return entry
	return {}

## The first pin a roll's ball knocked down directly (0 if none): Echo's target.
static func first_direct(knockdown_log: Dictionary) -> int:
	var best := 0
	var sequence := 1 << 30
	for entry in knockdown_log.get("knockdowns", []):
		if entry.cause == "ball" and int(entry.sequence) < sequence:
			sequence = int(entry.sequence)
			best = int(entry.position)
	return best

## Returns {ok, frame, owners} or {ok=false, errors}: a v2 frame (ADR 008). Reports
## are LaneWorld reports ({launch, roll_result, knockdown_log}) in roll order. The
## loadout gives pins by position, ordered Charms, optional pin_mods (position ->
## pin_mod id), whose effects join that pin's, and optional run growth
## (pin_growth: position -> count, charm_growth: [count per Charm slot]). extras
## maps a roll index to the tactical cards and ball modification played with that
## roll; their effects join the roll's. context: {match_frame, strike_streak}.
static func build(loadout: Dictionary, catalogue: Dictionary, reports: Array, extras: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var errors: Array[String] = []
	if not is_complete(reports):
		errors.append("frame is not complete")
	var pins: Array = []
	var owners := {}
	var pin_mods: Dictionary = loadout.get("pin_mods", {})
	for position in range(1, 11):
		var pin_id: String = loadout.pins.get(position, loadout.pins.get(str(position), ""))
		var pin := item(catalogue, pin_id)
		if pin.is_empty() or pin.category != "pin":
			errors.append("unknown pin item at %d: %s" % [position, pin_id])
			continue
		var effects: Array = pin.effects.duplicate(true)
		var effect_owners: Array = pin.effects.map(func(_e): return pin.id)
		var mod_id: String = pin_mods.get(position, pin_mods.get(str(position), ""))
		if not mod_id.is_empty():
			var mod := item(catalogue, mod_id)
			if mod.is_empty() or mod.category != "pin_mod":
				errors.append("unknown pin modification at %d: %s" % [position, mod_id])
			else:
				effects.append_array(mod.effects.duplicate(true))
				for _e in mod.effects:
					effect_owners.append(mod.id)
		owners["pin:%d" % position] = effect_owners
		var pin_growth: Dictionary = loadout.get("pin_growth", {})
		pins.append({"position": position, "item_id": pin.id, "effects": effects,
			"growth": int(pin_growth.get(position, pin_growth.get(str(position), 0)))})
	var rolls: Array = []
	for report in reports:
		var result: Dictionary = report.roll_result
		errors.append_array(Contracts.validate_result_for_launch(report.launch, result))
		errors.append_array(Contracts.validate_log_for_result(result, report.knockdown_log))
		var ball := item(catalogue, str(result.get("ball_id", "")))
		if ball.is_empty() or ball.category != "ball":
			errors.append("unknown ball item: %s" % str(result.get("ball_id")))
			continue
		var effects: Array = ball.effects.duplicate(true)
		var effect_owners: Array = ball.effects.map(func(_e): return ball.id)
		for extra_id in extras.get(int(result.roll_index), []):
			var extra := item(catalogue, extra_id)
			if extra.is_empty() or extra.category not in ["consumable", "ball_mod"]:
				errors.append("unknown tactical item or ball modification: %s" % extra_id)
				continue
			effects.append_array(extra.effects.duplicate(true))
			for _e in extra.effects:
				effect_owners.append(extra.id)
		owners["roll:%d" % int(result.roll_index)] = effect_owners
		rolls.append({"roll_index": int(result.roll_index), "ball_id": ball.id, "fallen_positions": result.fallen_positions.duplicate(),
			"accuracy": result.accuracy, "effects": effects, "first_direct": first_direct(report.knockdown_log),
			"curved": Lane.is_curved(float(report.launch.spin))})
	var charms: Array = []
	var charm_growth: Array = loadout.get("charm_growth", [])
	for i in loadout.charms.size():
		var charm_id: String = loadout.charms[i]
		var charm := item(catalogue, charm_id)
		if charm.is_empty() or charm.category != "charm":
			errors.append("unknown Charm item: %s" % charm_id)
			continue
		charms.append({"item_id": charm.id, "effects": charm.effects.duplicate(true), "growth": int(charm_growth[i]) if i < charm_growth.size() else 0})
	var frame := {"schema_version": 2, "pins": pins, "rolls": rolls, "charms": charms,
		"context": {"match_frame": int(context.get("match_frame", 1)), "strike_streak": int(context.get("strike_streak", 0))}}
	if errors.is_empty():
		errors.append_array(Rules.validate(frame))
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	# owners: event source ("pin:3", "roll:1") -> item id behind each effect, for the log.
	return {"ok": true, "frame": frame, "owners": owners}
