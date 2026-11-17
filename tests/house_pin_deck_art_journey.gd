extends "res://tests/house_league_journey.gd"
var deck_key := ""
var deck_seen := {}
func _process(_delta: float) -> bool:
 if is_instance_valid(lab) and lab.state == "rolling" and not deck_key.is_empty() and not deck_seen.has(deck_key) and lab.lane.tracker != null and not lab.lane.tracker.sequence.is_empty():
  deck_seen[deck_key] = true
  _capture_roll(deck_key)
 return false
func _capture_roll(key: String) -> void:
 await _capture(key+"_roll")
func _play_match(division: int, m: Dictionary) -> void:
 var finished := 0
 for wall in lab.lane.get_children():
  for mesh in wall.get_children():
   if mesh is MeshInstance3D and mesh.has_meta("pin_deck"):
    finished += 1
    _check(mesh.material_override.resource_path == "res://assets/leagues/house/pin_deck.tres","House pin-deck material")
    _check(not mesh.has_meta("neon_pin_deck"),"House has no Neon marker")
 _check(finished == 3,"House two kickbacks and cushion dressed at every match")
 if m.kind == "opener" or division == 8 and m.kind == "boss":
  await _capture("deck_d%02d_%s" % [division,m.kind])
 deck_key = ""
 if division == 2 and m.kind == "feature" or division in [3,8] and m.kind == "boss":
  deck_key = "deck_d%02d_%s" % [division,m.kind]
  await _capture(deck_key+"_portrait")
  root.size = Vector2i(1280,720)
  for i in 12: await process_frame
  await _capture(deck_key+"_landscape")
  root.size = PORTRAIT
  for i in 12: await process_frame
  await _focus_accept(scene.options)
  await _focus_accept(lab.settings_panel.reduced_motion)
  await _focus_accept(lab.settings_panel.close)
 await super._play_match(division,m)
 if not deck_key.is_empty():
  _check(deck_seen.has(deck_key),"native pin-deck roll captured")
  await _focus_accept(scene.options)
  await _focus_accept(lab.settings_panel.reduced_motion)
  await _focus_accept(lab.settings_panel.close)
