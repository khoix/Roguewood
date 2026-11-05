extends RefCounted
## Read-only reveal state. Inventory may already be banked; use the frame snapshot.
const Events = preload("res://src/presentation/ability_events.gd")
var count := 0
var added := 0
var seen := {}
func begin(frame: Dictionary) -> void:
	count = 0
	added = 0
	seen.clear()
	for charm in frame.get("charms",[]):
		if charm.item_id == "charm.spare_jar": count = int(charm.get("growth",0))
func reveal(frame: Dictionary, event: Dictionary, index: int) -> bool:
	if seen.has(index): return false
	seen[index] = true
	if event.get("phase","") != "after_bank" or event.get("op","") != "grow_value": return false
	if Events.owner(frame,event.get("source","")) != "charm.spare_jar": return false
	var amount := int(event.get("amount",0))
	count += amount
	added += amount
	return amount > 0
