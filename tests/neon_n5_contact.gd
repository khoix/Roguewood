extends "res://tests/neon_n1_contact.gd"
func _initialize() -> void:
 ids = ["pin.compass","charm.split_pattern","charm.dry_run"]
 super._initialize()
func _context(id: String, count: int) -> Dictionary:
 if id == "charm.dry_run": return {"count":count*5,"amount":count*5}
 return {"amount":25 if id == "pin.compass" else 2}
