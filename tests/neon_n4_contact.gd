extends "res://tests/neon_n1_contact.gd"
func _initialize() -> void:
 ids = ["shop_upgrade.trade_in","shop_upgrade.specialist_shelf","ball.comet"]
 super._initialize()
func _context(id: String, _count: int) -> Dictionary:
 return {"amount":6} if id == "ball.comet" else ({"amount":3} if id == "shop_upgrade.trade_in" else {})
