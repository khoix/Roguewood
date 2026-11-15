extends "res://tests/neon_n1_contact.gd"
func _initialize() -> void:
 ids=["ball.glow","pin.prism","ball_mod.grip_tape"]
 super._initialize()
func _context(id:String,count:int) -> Dictionary:
 return {"count":count,"amount":25 if id=="pin.prism" else 5}
