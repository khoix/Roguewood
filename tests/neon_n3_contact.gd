extends "res://tests/neon_n1_contact.gd"
func _initialize() -> void:
 ids = ["charm.dry_side","charm.lane_reader","consumable.hook_shot"]
 super._initialize()
func _context(id: String, _count: int) -> Dictionary:
 return {"amount":1.5 if id == "charm.lane_reader" else 4}
