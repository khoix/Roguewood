extends "res://tests/neon_n1_contact.gd"
func _initialize() -> void:
 ids = ["charm.metronome","consumable.steady_hand"]
 super._initialize()
func _context(id: String, _count: int) -> Dictionary:
 return {"amount":1.5 if id == "charm.metronome" else 2.0}
func capture(label: String) -> void:
 if not root.has_node("RibbonSpecimen"):
  var ribbon := preload("res://src/clubhouse/clubhouse_art.gd").slot("ribbon.mastery.controlled_curve",220,true)
  ribbon.name = "RibbonSpecimen"; root.add_child(ribbon); ribbon.position = Vector2(690,80); ribbon.size = Vector2(220,300)
  var text := Label.new(); text.text = "Controlled Curve\nEarned art specimen"; text.position = Vector2(690,390); root.add_child(text)
  await process_frame
 await super.capture(label)
