extends "res://tests/slice_journey.gd"
## The original complete slice journey retains all target, spin-lock, clean-sweep,
## first-clear and restart checks. Added assertions inspect only live artwork.
const Assets = preload("res://src/presentation/item_assets.gd")
var seen_rule_art := {}

func _capture(label: String) -> void:
	for i in range(12): await process_frame
	var rival: Dictionary = lab.division.rival_for(lab.division.boss())
	var id: String = rival.get("rule", "")
	if lab.hud.reaction.visible:
		_check(not lab.motion.equipment_art.visible, "rival reaction never overlaps equipment art")
	if not id.is_empty():
		_check(Assets.slot(id, "in_play") != null and lab.hud.badge.icon == Assets.slot(id,"in_play"), "native stable rule badge: " + id)
		seen_rule_art[id] = true
	if label == "slice_won":
		_check(seen_rule_art.size() == 2, "both actual slice rule identities observed")
	await super._capture(label)
