extends Node2D
## Read-only observation of committed launch, measured accuracy and rebound facts.
## Never calls tracker.take_rebound, writes physics, or manufactures score events.
const Assets=preload("res://src/presentation/item_assets.gd")
const Lane=preload("res://src/simulation/lane_spec.gd")
var lab:Control
var director:Node
var lane_id:=0
var oil_seen:=false
var beam_seen:=false
var rebound_seen:=false
var rebound_age:=10.0
var beam_age:=10.0
var rebound_at:=Vector3.ZERO
var beam_start:=Vector3.ZERO
var beam_end:=Vector3.ZERO
var beam_grade:=""
var reduced:=false
func _process(delta:float) -> void:
 rebound_age+=delta;beam_age+=delta
 reduced=lab.settings.reduced_motion or lab.settings.reduced_flash
 if lab.lane==null:return
 if lane_id!=lab.lane.get_instance_id():
  lane_id=lab.lane.get_instance_id();oil_seen=false;beam_seen=false;rebound_seen=false
  rebound_age=10;beam_age=10
 if lab.state=="rolling":
  var launch:Dictionary=lab.lane.launch
  var id:String=launch.get("ball_id","")
  if id=="ball.oilskin" and not oil_seen and Assets.slot(id,"activation")!=null:
   oil_seen=true
   director._world_cue(id,"oil_hold",lab.screen_point(lab.lane.ball_position()))
  var tracker=lab.lane.tracker
  if tracker!=null:
   if id=="ball.laser" and tracker.target_crossed and not beam_seen:
    beam_seen=true
    beam_grade=Lane.grade_accuracy(true,tracker.target_offset()-float(launch.target_x),float(launch.ring_radius),float(lab.lane.rules.get("zone_scale",1.0)))
    if beam_grade in ["sweet","perfect"]:
     beam_age=0;beam_end=lab.lane.ball_position();beam_start=beam_end+Vector3(0,0,1.4)
   if tracker.rebounded and not rebound_seen and lab.frame_mods.get(lab.roll_index,"")=="ball_mod.bumper_guard" and Assets.slot("ball_mod.bumper_guard","activation")!=null:
    rebound_seen=true;rebound_age=0
    rebound_at=lab.lane.ball_position()
    rebound_at.x=signf(rebound_at.x)*lab.lane.gutter_edge()
    director._world_cue("ball_mod.bumper_guard","physical_rebound",lab.screen_point(rebound_at))
 # Blacklight's own host accents brighten only on its paid curved-strike row.
 var overlay=lab.lane.ball.get_node_or_null("ModificationOverlay")
 if overlay!=null and overlay.item_id=="ball_mod.blacklight":
  var glyph:Control=director.glyph
  overlay.set_lit(lab.motion.sound.enabled and glyph.style!=null and glyph.style.item_id=="ball_mod.blacklight" and glyph.age<glyph.style.duration)
 queue_redraw()
func _draw() -> void:
 if lab.lane==null or not lab.motion.sound.enabled or lab.settings_panel.visible or lab.state!="rolling":return
 if beam_age<.85:
  var a:Vector2=lab.screen_point(beam_start)
  var b:Vector2=lab.screen_point(beam_end)
  draw_line(a,b,Color("162833"),6,true)
  draw_line(a,b,Color("90e4ed"),2,true)
 if rebound_age<.85:
  var a:Vector2=lab.screen_point(rebound_at+Vector3(0,.05,.8))
  var b:Vector2=lab.screen_point(rebound_at+Vector3(0,.05,-.8))
  draw_line(a,b,Color("14272e"),13,true)
  draw_line(a,b,Color("92ccc7"),7,true)
  draw_line(a,b,Color("e7bc70"),2,true)
  var mid:Vector2=(a+b)*.5
  var inward:float=-signf(rebound_at.x)
  draw_polyline(PackedVector2Array([mid+Vector2(inward*4,-8),mid+Vector2(inward*17,0),mid+Vector2(inward*4,8)]),Color("f4e6cd"),3,true)
