extends "res://tests/neon_n3_contact.gd"
func _initialize() -> void:
 ids = ["consumable.line_call","charm.bounce_back","charm.straight_money"]
 call_deferred("run")
func _context(id: String, _count: int) -> Dictionary:
 return {"amount":4 if id == "consumable.line_call" else (3 if id == "charm.bounce_back" else 2)}
