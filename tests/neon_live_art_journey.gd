extends "res://tests/neon_league_journey.gd"
## Full live Neon journey plus art identity, reduction and native captures.
const RivalArt=preload("res://src/presentation/rival_art.gd")
var deck_captures:Dictionary={}
func _process(_delta:float) -> bool:
 if is_instance_valid(lab) and lab.state=="rolling" and lab.lane!=null and lab.lane.tracker!=null and not lab.lane.tracker.sequence.is_empty():
  var key:="live_pin_deck_reduced" if lab.settings.reduced_motion else "live_pin_deck_normal"
  if not deck_captures.has(key):
   deck_captures[key]=true
   _capture_deck(key)
 return false
func _capture_deck(key:String) -> void:
 # Keep the SceneTree _process return synchronous; only this observer awaits draw.
 await _capture(key)
func _play_match(division:int,m:Dictionary) -> void:
 var room:Node3D=lab.league_theme.environment
 _check(room.signage.league_title=="NEON","live native Neon sign")
 _check(room.signage.division==division,"live sign Division")
 _check(room.signage.championship==(division==8 and m.kind=="boss"),"live Championship sign")
 _check(room.find_children("*","CollisionObject3D",true,false).is_empty(),"live room is cosmetic")
 var finished:=0
 for wall in lab.lane.get_children():
  for mesh in wall.get_children():
   if mesh is MeshInstance3D and mesh.get_meta("neon_pin_deck",false):
    finished+=1
    _check(mesh.material_override.resource_path=="res://assets/leagues/neon/pin_deck.tres","live authored pin-deck finish")
 _check(finished==3,"two kickbacks and cushion are finished")
 if m.kind=="boss":
  _check(RivalArt.portrait(m.rival,"entrance")!=null,"live rival authored identity")
  for rule in RULES[m.rival]:_check(RivalArt.rule_badge(rule)!=null,"live rule seal "+rule)
 if m.kind=="opener" or (m.kind=="feature" and division in [2,3]) or division==8 and m.kind=="boss":
  var label:="live_d%02d_%s"%[division,m.kind]
  await _focus_accept(scene.options)
  await _focus_accept(lab.settings_panel.assist)
  await _focus_accept(lab.settings_panel.close)
  await _capture(label)
  if division==8 and m.kind=="boss":
   _check(lab.hud.extra_rule_badges.get_child_count()==2,"live champion paired seals")
   await _focus_accept(scene.options)
   await _focus_accept(lab.settings_panel.reduced_motion)
   await _focus_accept(lab.settings_panel.close)
   _check(not lab.backdrop.reduced,"live normal flank")
   await _capture("live_champion_normal")
   root.size=Vector2i(1280,720)
   for i in 12:await process_frame
   await _capture("live_champion_landscape")
   root.size=PORTRAIT
   for i in 12:await process_frame
   await _focus_accept(scene.options)
   await _focus_accept(lab.settings_panel.reduced_motion)
   await _focus_accept(lab.settings_panel.close)
   _check(lab.backdrop.reduced,"live reduced flank restored")
  await _focus_accept(scene.options)
  await _focus_accept(lab.settings_panel.assist)
  await _focus_accept(lab.settings_panel.close)
 # A normal physical roll complements the existing reduced physical rolls.
 var normal_trial:bool=division==2 and m.kind=="opener"
 if normal_trial:
  await _focus_accept(scene.options)
  await _focus_accept(lab.settings_panel.reduced_motion)
  await _focus_accept(lab.settings_panel.close)
 await super._play_match(division,m)
 if normal_trial:
  _check(deck_captures.has("live_pin_deck_normal") and deck_captures.has("live_pin_deck_reduced"),"both native pin-deck views captured")
  await _focus_accept(scene.options)
  await _focus_accept(lab.settings_panel.reduced_motion)
  await _focus_accept(lab.settings_panel.close)
