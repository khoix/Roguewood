extends Node
## Observes the saved, post-bank explanation. No RNG, inventory or physics writes.
const Identity = preload("res://src/presentation/pin_identity.gd")
var lab: Control

func _ready() -> void:
	lab.score_panel.step_revealed.connect(_step)

## C02 appends pin-indexed rule rows after resolver events and rival banking.
## Match their original Glass identity to the already-saved Wood outcome. This
## also works on restored explanations, where run.transformed is not persisted.
static func broken_position(scored: Dictionary, rack: Dictionary, step: Dictionary, index: int) -> int:
	var position := int(step.get("pin", 0))
	if step.get("phase", "") != "rule" or position < 1: return 0
	if index < scored.get("result", {}).get("events", []).size(): return 0
	if rack.get(position, {}).get("item_id", "") != "pin.wood": return 0
	for pin in scored.get("frame", {}).get("pins", []):
		if int(pin.position) == position and pin.item_id == "pin.glass": return position
	return 0

func _step(step: Dictionary, index: int, _skipped: bool) -> void:
	if lab.scored_frames.is_empty() or lab.lane == null: return
	var position := broken_position(lab.scored_frames[-1], lab.run.rack, step, index)
	if position > 0 and lab.lane.pins.has(position):
		Identity.dress(lab.lane.pins[position], "pin.wood")
