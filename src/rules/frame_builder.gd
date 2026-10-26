extends RefCounted
## Assembles a completed frame for FrameRules from simulation roll reports and the
## rack loadout, hydrating every effect from a catalogue by stable ID (UI never
## supplies effects). Pure: no scene, physics or presentation access.
const Contracts = preload("res://src/contracts/contracts.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
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

## Returns {ok, frame} or {ok=false, errors}. Reports are LaneWorld reports
## ({launch, roll_result, knockdown_log}) in roll order.
static func build(loadout: Dictionary, catalogue: Dictionary, reports: Array) -> Dictionary:
	var errors: Array[String] = []
	if not is_complete(reports):
		errors.append("frame is not complete")
	var pins: Array = []
	for position in range(1, 11):
		var pin_id: String = loadout.pins.get(position, loadout.pins.get(str(position), ""))
		var pin := item(catalogue, pin_id)
		if pin.is_empty() or pin.category != "pin":
			errors.append("unknown pin item at %d: %s" % [position, pin_id])
			continue
		pins.append({"position": position, "item_id": pin.id, "effects": pin.effects.duplicate(true)})
	var rolls: Array = []
	for report in reports:
		var result: Dictionary = report.roll_result
		errors.append_array(Contracts.validate_result_for_launch(report.launch, result))
		errors.append_array(Contracts.validate_log_for_result(result, report.knockdown_log))
		var ball := item(catalogue, str(result.get("ball_id", "")))
		if ball.is_empty() or ball.category != "ball":
			errors.append("unknown ball item: %s" % str(result.get("ball_id")))
			continue
		rolls.append({"roll_index": int(result.roll_index), "ball_id": ball.id, "fallen_positions": result.fallen_positions.duplicate(),
			"accuracy": result.accuracy, "effects": ball.effects.duplicate(true)})
	var charms: Array = []
	for charm_id in loadout.charms:
		var charm := item(catalogue, charm_id)
		if charm.is_empty() or charm.category != "charm":
			errors.append("unknown Charm item: %s" % charm_id)
			continue
		charms.append({"item_id": charm.id, "effects": charm.effects.duplicate(true)})
	var frame := {"schema_version": 1, "pins": pins, "rolls": rolls, "charms": charms}
	if errors.is_empty():
		errors.append_array(Rules.validate(frame))
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	return {"ok": true, "frame": frame}
