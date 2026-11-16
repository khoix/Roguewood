extends Node2D
## Read-only side/lane/tactical observations. No physics or rule writes.
const Lane = preload("res://src/simulation/lane_spec.gd")
const Assets = preload("res://src/presentation/item_assets.gd")
const FONT = preload("res://assets/ui/fonts/PixelifySans.ttf")
var lab: Control
var director: Node
var lane_id := 0
var side_seen := false
var side_left := false
var side_age := 10.0
var rescue_seen := false
var hook_seen := false
var reduced := false
var armed := ""
var lane_name := ""
func owns(id: String) -> bool:
 return lab.run != null and lab.run.charms.any(func(e): return e.item_id == id)
func _process(delta: float) -> void:
 if lab.lane == null: return
 reduced = lab.settings.reduced_motion or lab.settings.reduced_flash
 side_age += delta
 if lane_id != lab.lane.get_instance_id():
  lane_id = lab.lane.get_instance_id(); side_seen = false; rescue_seen = false; hook_seen = false; side_age = 10.0
 armed = lab._item_of(lab.armed_tactical) if not lab.armed_tactical.is_empty() else ""
 var lane_key: String = preload("res://src/rules/frame_rules.gd").lane_id(lab.frame_context().get("lane_condition", "lane.house"))
 Assets._ensure()
 lane_name = Assets._items.get(lane_key, {}).get("name", lane_key.trim_prefix("lane_condition."))
 if lab.state == "rolling" and lab.lane.tracker != null:
  var tracker = lab.lane.tracker
  if owns("charm.dry_side") and tracker.get("_side_read") and not side_seen:
   side_seen = true; side_left = tracker.left_side; side_age = 0.0
  if owns("charm.bounce_back") and tracker.rebounded and not rescue_seen:
   rescue_seen = true
   # Keep the Charm readable beside the Bumper Guard's own gutter marker.
   var rebound: Vector3 = lab.lane.ball_position()
   director._world_cue("charm.bounce_back","observed_rescue",lab.screen_point(rebound)+Vector2(-signf(rebound.x)*80,0))
  if not hook_seen and "consumable.hook_shot" in lab.motion.modifications.snapshots.get(lab.frame_number,{}).get("tactics",{}).get(lab.roll_index,[]):
   hook_seen = true
   director._world_cue("consumable.hook_shot","committed_hook",lab.screen_point(lab.lane.ball_position()))
 queue_redraw()
func _draw() -> void:
 if lab.lane == null or lab.state not in ["aim","holding","rolling"] or lab.settings_panel.visible or not lab.motion.sound.enabled: return
 if owns("charm.lane_reader"):
  var at: Vector2 = lab.screen_point(Lane.world(-0.42,8.5,0.02))
  draw_style_box(_plate,Rect2(at-Vector2(4,19),Vector2(170,26)))
  if _chart: draw_texture_rect(_chart,Rect2(at-Vector2(1,17),Vector2(20,20)),false)
  draw_string(FONT,at+Vector2(23,0),lane_name,HORIZONTAL_ALIGNMENT_LEFT,140,14,Color("a3c6d9"))
 if owns("charm.dry_side") and (lab.state in ["aim","holding"] or side_age < 1.2):
  var a: Vector2 = lab.screen_point(Lane.world(-Lane.LANE_HALF_WIDTH,Lane.TWO_TONE_LEFT_END_F,0.02))
  var b: Vector2 = lab.screen_point(Lane.world(0,Lane.TWO_TONE_LEFT_END_F,0.02))
  var c: Vector2 = lab.screen_point(Lane.world(Lane.LANE_HALF_WIDTH,Lane.TWO_TONE_LEFT_END_F,0.02))
  var ink := Color("64dacb") if side_seen and side_left else Color("728799")
  draw_line(a,b,ink,4,true);draw_line(b,c,Color("51496c"),3,true)
  draw_string(FONT,a-Vector2(0,7),("LEFT" if side_left else "RIGHT")+" · 34ft" if side_seen else "34ft",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
 if armed in ["consumable.hook_shot","consumable.line_call"] and lab.state in ["aim","holding"]:
  var points := PackedVector2Array()
  var spin: float = lab.charged_spin()*lab.hook_scale() if armed == "consumable.hook_shot" else 0.0
  for i in 19:
   var t := float(i)/18
   points.append(lab.screen_point(Lane.world(lab.lane.ball_position().x+spin*0.06*t*t,Lane.BALL_START_F+Lane.BALL_RADIUS*2+4.5*t,0.003)))
  var ink := Color("64dacb") if armed == "consumable.hook_shot" else Color("f4e6cd")
  draw_polyline(points,ink,3,true)
  var tip := points[-1];var direction := (tip-points[-2]).normalized();var wing := direction.orthogonal()*6
  draw_polyline(PackedVector2Array([tip-direction*10+wing,tip,tip-direction*10-wing]),ink,2,true)
var _plate: StyleBoxFlat
var _chart: Texture2D
func _ready() -> void:
 _plate = StyleBoxFlat.new();_plate.bg_color = Color("101b2d")
 _chart = Assets.slot("charm.lane_reader","icon")
