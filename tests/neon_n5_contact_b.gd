extends "res://tests/neon_n1_contact.gd"
func _initialize() -> void:
 ids = ["charm.long_game","charm.second_chance"]
 super._initialize()
func _context(_id: String, _count: int) -> Dictionary:
 return {"amount":1.5}
func capture(label: String) -> void:
 if not root.has_node("RibbonSpecimens"):
  var specimens := Control.new(); specimens.name = "RibbonSpecimens"; root.add_child(specimens)
  for i in 2:
   var id: String = ["both_halves","rebound_rescue"][i]
   var ribbon := preload("res://src/clubhouse/clubhouse_art.gd").slot("ribbon.mastery."+id,180,true)
   specimens.add_child(ribbon); ribbon.position = Vector2(695,20+i*300); ribbon.size = Vector2(190,215)
   var text := Label.new(); text.text = ["Both Halves","Rebound Rescue"][i]+"\nEarned art specimen"; text.position = Vector2(680,240+i*300); specimens.add_child(text)
  await process_frame
 await super.capture(label)
