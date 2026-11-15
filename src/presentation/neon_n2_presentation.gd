extends Node2D
## Cosmetic observations of committed curve, attachment and tracker facts.
const Assets=preload("res://src/presentation/item_assets.gd")
const Lane=preload("res://src/simulation/lane_spec.gd")
const Builder=preload("res://src/rules/frame_builder.gd")
var lab:Control
var director:Node
var lane_id:=0
var grip_seen:=false
var first_seen:=false
var spotlight_position:=0
var prism_seen:Dictionary={}
var trail:Array[Vector3]=[]
var curved:=false
var reduced:=false
func _process(_delta:float) -> void:
 if lab.lane==null:return
 reduced=lab.settings.reduced_motion or lab.settings.reduced_flash
 if lane_id!=lab.lane.get_instance_id():
  lane_id=lab.lane.get_instance_id();grip_seen=false;first_seen=false;spotlight_position=0;prism_seen.clear();trail.clear()
 curved=Lane.is_curved(float(lab.lane.launch.get("spin",0)))
 if lab.state=="rolling":
  var id:String=lab.lane.launch.get("ball_id","")
  if id=="ball.glow" and curved:
   trail.append(lab.lane.ball_position())
   if trail.size()>12:trail.pop_front()
  else:trail.clear()
  if not grip_seen and curved and lab.frame_mods.get(lab.roll_index,"")=="ball_mod.grip_tape":
   grip_seen=true
   director._world_cue("ball_mod.grip_tape","committed_hook",lab.screen_point(lab.lane.ball_position()))
  var tracker=lab.lane.tracker
  if tracker!=null and curved:
   var first:int=Builder.first_direct({"knockdowns":tracker.knockdowns()})
   if first>0 and not first_seen:
    first_seen=true
    if lab.run.rack[first].get("mod","")=="pin_mod.spotlight":
     spotlight_position=first
     director._world_cue("pin_mod.spotlight","first_curved_hit",lab.screen_point(lab.lane.pins[first].global_position))
   for position in tracker.sequence:
    if lab.run.rack[position].item_id=="pin.prism" and not prism_seen.has(position):
     prism_seen[position]=true
     director._world_cue("pin.prism","curved_knockdown",lab.screen_point(lab.lane.pins[position].global_position))
 for position in lab.lane.pins:
  var overlay=lab.lane.pins[position].get_node_or_null("ModificationOverlay")
  if overlay!=null and overlay.item_id=="pin_mod.spotlight":
   overlay.set_lit(lab.motion.sound.enabled and position==spotlight_position)
 queue_redraw()
func _draw() -> void:
 if lab.lane==null or lab.state!="rolling" or lab.settings_panel.visible or not lab.motion.sound.enabled or trail.is_empty():return
 if reduced:
  var at:Vector2=lab.screen_point(trail[-1])
  draw_arc(at,13,PI*.1,PI*.9,16,Color("9de5bc"),2,true)
 else:
  for i in range(1,trail.size()):
   var strength:float=float(i)/trail.size()
   draw_line(lab.screen_point(trail[i-1]),lab.screen_point(trail[i]),Color(.55,.91,.76,strength*.7),2.0+strength*3,true)
