extends "res://tests/neon_n1_contact.gd"
func _initialize() -> void:
 ids=["pin_mod.spotlight","charm.afterimage","charm.laser_level"]
 super._initialize()
func _context(id:String,count:int) -> Dictionary:
 return {"count":count*5,"amount":3 if id=="pin_mod.spotlight" else 1.5 if id=="charm.afterimage" else count*25}
