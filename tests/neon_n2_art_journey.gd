extends "res://tests/neon_c16_journey.gd"
## Retains all original J03C16 input, independent banks and negative assertions.
const CardView=preload("res://src/presentation/card_view.gd")
const Assets=preload("res://src/presentation/item_assets.gd")
const ART_IDS=["ball.glow","pin.prism","ball_mod.grip_tape","pin_mod.spotlight","charm.afterimage","charm.laser_level"]
var art_captures:Dictionary={}
var observing:=false
func _process(_delta:float) -> bool:
 # Fixed-fps headless simulation otherwise outruns Dummy's wall-clock mixer.
 # Preserve the real four-voice limit and assert each audible reward at play speed.
 if DisplayServer.get_name()=="headless":OS.delay_msec(16)
 if is_instance_valid(lab) and is_instance_valid(lab.motion) and is_instance_valid(lab.motion.abilities) and not observing:_observe()
 return false
func _observe() -> void:
 observing=true
 var art:Node=lab.motion.abilities.neon_n2
 if lab.state=="rolling":
  if art.trail.size()>3 and not art_captures.has("glow_trail"):
   art_captures.glow_trail=true
   _check(art.curved and lab.lane.launch.ball_id=="ball.glow","Glow trail belongs to the actual curved Glow roll")
   await super._capture("n2_glow_trail")
  if art.spotlight_position>0 and not art_captures.has("spotlight_hit"):
   art_captures.spotlight_hit=true
   _check(Builder.first_direct({"knockdowns":lab.lane.tracker.knockdowns()})==art.spotlight_position and art.curved,"Spotlight follows the first direct curved hit")
   var overlay=lab.lane.pins[art.spotlight_position].get_node_or_null("ModificationOverlay")
   _check(overlay!=null and overlay.lit,"actual host lamp lights")
   await super._capture("n2_spotlight_hit")
  if art.grip_seen and not art_captures.has("grip_hook"):
   art_captures.grip_hook=true
   _check(is_equal_approx(float(lab.lane.rules.get("spin_scale",0)),1.4) and art.curved,"Grip Tape reads the committed hook scale")
   _check(art.reduced,"extra Grip Tape throw uses reduced motion")
   _check(lab.motion.abilities.history.any(func(e):return e.id=="ball_mod.grip_tape" and e.event=="committed_hook" and e.audio_played),"Grip Tape native sound")
   await super._capture("n2_grip_hook_reduced")
 if lab.state in ["scoring","frame_done"]:
  var glyph:Control=lab.motion.abilities.glyph
  if glyph.style!=null and glyph.age<glyph.style.duration and glyph.style.item_id in ART_IDS:
   var id:String=glyph.style.item_id
   var key:=id.get_slice(".",1)+"_paid"
   if not art_captures.has(key):
    art_captures[key]=true
    _check(glyph.still==bool(lab.settings.reduced_motion or lab.settings.reduced_flash),"cue respects reduced effects")
    _check(lab.motion.abilities.history.any(func(e):return e.id==id and e.event==glyph.details.phase and e.audio_played),"paid native audio "+id)
    if id=="charm.laser_level":
     _check(glyph.details.count==10 and glyph.details.amount==50 and glyph.details.positions.size()==10,"Laser Level marks exactly ten paid pins")
    await super._capture("n2_"+key)
 observing=false
func _scored() -> Dictionary:
 await _wait_for(func():return lab.state=="frame_done","natural unskipped score reveal",ROLL_FRAMES*3)
 return lab.scored_frames[-1]
func _tap(control:Control) -> void:
 if control is CardView and control.item_id in ART_IDS:
  _check(not control.art_pending and control.art.texture==Assets.slot(control.item_id,"card"),"native card uses final illustration "+control.item_id)
  var key:="shop_"+String(control.item_id).replace(".","_")
  if lab.state=="shop" and not art_captures.has(key):
   art_captures[key]=true
   await super._capture("n2_"+key)
 await super._tap(control)
 if is_instance_valid(lab) and lab.state=="aim" and lab.run.card_mod(lab.armed_ball)=="ball_mod.grip_tape":
  for i in 2:await process_frame
  var overlay=lab.lane.aim_ball.get_node_or_null("ModificationOverlay")
  _check(overlay!=null and overlay.item_id=="ball_mod.grip_tape" and overlay.host_id==lab.armed_ball_id(),"Grip Tape keeps its actual host identity")
  if not art_captures.has("host_grip"):
   art_captures.host_grip=true
   await super._capture("n2_host_grip")
func _capture(label:String) -> void:
 await super._capture(label)
 if label=="c16_straight":
  for key in ["glow_paid","prism_paid","spotlight_paid","afterimage_paid","laser_level_paid","glow_trail","spotlight_hit"]:
   _check(art_captures.has(key),"native art observed "+key)
  await _focus_accept(lab.next_rack)
  await _aim()
  await _focus_accept(scene.options)
  await _focus_accept(lab.settings_panel.reduced_motion)
  await _focus_accept(lab.settings_panel.close);await _focus_accept(scene.resume)
  var uid:=""
  for card in lab.run.cards:
   if lab.run.cards[card].mod=="ball_mod.grip_tape":uid=card
  await _card_frame(uid,[[-0.3,0.0,0.6]],0.25,"Grip Tape reduced native demonstration")
  _check(art_captures.has("grip_hook"),"actual modified curved throw observed")
  await _focus_accept(scene.back)
  await _wait_for(func():return scene.screen=="menu","Binder return")
  await _focus_accept(scene.clubhouse.tab_buttons.binder)
  for id in ART_IDS:
   await _focus_accept(scene.clubhouse.filter_button(id.get_slice(".",0)))
   var card=scene.clubhouse.entry_button(id)
   _check(card!=null,"Binder includes "+id)
   if card==null:continue
   await _focus_accept(card)
   for i in 6:await process_frame
   card=scene.clubhouse.entry_button(id)
   var scroll:ScrollContainer=scene.clubhouse.pages.binder.get_parent()
   scroll.ensure_control_visible(card)
   for i in 3:await process_frame
   _check(not card.art_pending and card.art.texture==Assets.slot(id,"card"),"Binder illustration "+id)
   if DisplayServer.get_name()!="headless":
    await RenderingServer.frame_post_draw
    _check(root.get_texture().get_image().save_png(artifact_dir.path_join("n2_binder_"+id.replace(".","_")+".png"))==OK,"Binder capture")
