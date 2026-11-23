extends Node2D
## Read-only lane, side and rebound observations; never infer a scoring reward.
const Lane = preload("res://src/simulation/lane_spec.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const Assets = preload("res://src/presentation/item_assets.gd")
const FONT = preload("res://assets/ui/fonts/PixelifySans.ttf")
const PANEL_IDS = ["pin.compass","charm.split_pattern","charm.long_game"]
const PANEL_NAMES = ["Compass", "Split", "Long"]
var lab: Control
var director: Node
var lane_id := 0
var lane_key := ""
var lane_name := ""
var side_seen := false
var side_left := false
var side_age := 10.0
var rescue_seen := false
var reduced := false
var compass_owned := false
var compass_active := false
var needle_angle := 0.0
var pin_materials: Array[ShaderMaterial] = []
var icons: Array[Texture2D] = []
var plate: StyleBoxFlat
func _ready() -> void:
 Assets._ensure()
 for id in PANEL_IDS: icons.append(Assets.slot(id,"icon"))
 plate = StyleBoxFlat.new(); plate.bg_color = Color("101b2d")
 plate.border_color = Color("486369"); plate.set_border_width_all(1); plate.set_corner_radius_all(4)
func owns(id: String) -> bool:
 if lab.run == null: return false
 return compass_owned if id == "pin.compass" else lab.run.charms.any(func(e): return e.item_id == id)
func _process(delta: float) -> void:
 if lab.lane == null or lab.run == null: return
 reduced = lab.settings.reduced_motion or lab.settings.reduced_flash
 side_age += delta
 if lane_id != lab.lane.get_instance_id():
  lane_id = lab.lane.get_instance_id(); side_seen = false; rescue_seen = false; side_age = 10.0
  pin_materials.clear()
 lane_key = Rules.lane_id(lab.frame_context().get("lane_condition","lane.house"))
 lane_name = Assets._items.get(lane_key,{}).get("name",lane_key.trim_prefix("lane_condition."))
 compass_owned = lab.run.rack.values().any(func(e): return e.item_id == "pin.compass")
 compass_active = lane_key in Assets._items.get("pin.compass",{}).get("effects",[{}])[0].get("condition",{}).get("lane",[])
 var angle: float = {"lane_condition.house_oil":0.0,"lane_condition.two_tone":PI*.5,"lane_condition.long_oil":PI*.25,"lane_condition.dry_backend":-PI*.25}.get(lane_key,0.0)
 needle_angle = angle if reduced else move_toward(needle_angle,angle,delta*3)
 # Materials are private to presentation meshes. A pin's rigid body is untouched.
 for position in lab.lane.pins:
  var pin: Node3D = lab.lane.pins[position]
  if pin.get_meta("art_item_id","") != "pin.compass" or pin.has_meta("n5_material"): continue
  for child in pin.get_children():
   if child is MeshInstance3D and child.material_override is ShaderMaterial:
    var material: ShaderMaterial = child.material_override.duplicate()
    child.material_override = material; pin.set_meta("n5_material",true); pin_materials.append(material)
    break
 for material in pin_materials:
  material.set_shader_parameter("needle_angle",needle_angle)
  material.set_shader_parameter("lane_light",1.0 if compass_active and lab.motion.sound.enabled else 0.0)
 if lab.state == "rolling" and lab.lane.tracker != null:
  var tracker = lab.lane.tracker
  if owns("charm.dry_run") and tracker.get("_side_read") and not side_seen:
   side_seen = true; side_left = tracker.left_side; side_age = 0.0
  if owns("charm.second_chance") and tracker.rebounded and not rescue_seen:
   rescue_seen = true
   var rebound: Vector3 = lab.lane.ball_position()
   # Leave room for Bumper Guard and Bounce Back if both Charms are owned.
   director._world_cue("charm.second_chance","observed_rescue",lab.screen_point(rebound)+Vector2(-signf(rebound.x)*160,35))
 queue_redraw()
func _draw() -> void:
 if lab.lane == null or lab.state not in ["aim","holding","rolling"] or lab.settings_panel.visible or not lab.motion.sound.enabled: return
 var anchor := Vector2(14,100 if lab.state == "rolling" else 184)
 var row := 0
 for i in PANEL_IDS.size():
  if not owns(PANEL_IDS[i]): continue
  var at := anchor+Vector2(0,row*30); row += 1
  var active: bool = compass_active if i == 0 else lane_key == ("lane_condition.two_tone" if i == 1 else "lane_condition.long_oil")
  var ink := Color("a5ded5") if active else Color("9a9cab")
  draw_style_box(plate,Rect2(at,Vector2(220,28)))
  if icons[i]: draw_texture_rect(icons[i],Rect2(at+Vector2(3,4),Vector2(20,20)),false,ink)
  draw_string(FONT,at+Vector2(26,20),PANEL_NAMES[i]+": "+lane_name,HORIZONTAL_ALIGNMENT_LEFT,194,16,ink)
 if owns("charm.dry_run") and (lab.state in ["aim","holding"] or side_age < 1.5):
  var a: Vector2 = lab.screen_point(Lane.world(-Lane.LANE_HALF_WIDTH,Lane.TWO_TONE_LEFT_END_F,.02))
  var b: Vector2 = lab.screen_point(Lane.world(0,Lane.TWO_TONE_LEFT_END_F,.02))
  var ink := Color("f4e6cd") if side_seen and side_left else Color("8b8293")
  draw_line(a+Vector2(0,5),b+Vector2(0,5),ink,3,true)
  draw_string(FONT,a+Vector2(0,25),"Dry Run · "+(("LEFT" if side_left else "RIGHT")+" 34ft" if side_seen else "34ft"),HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink)
 if owns("charm.long_game") and lane_key == "lane_condition.long_oil":
  var at: Vector2 = lab.screen_point(Lane.world(-Lane.LANE_HALF_WIDTH,47,.02))
  var end: Vector2 = lab.screen_point(Lane.world(Lane.LANE_HALF_WIDTH,47,.02))
  draw_line(at,end,Color("637f90"),2,true)
  draw_string(FONT,at+Vector2(0,-6),"47ft",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("a5ded5"))
  draw_arc(end-Vector2(12,0),9,PI*.15,PI*1.5,12,Color("b99359"),2,true)
