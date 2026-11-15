extends "res://tests/neon_c15_journey.gd"
## All J03C15 purchases, replay and independent banks are retained.
const CardView=preload("res://src/presentation/card_view.gd")
const Assets=preload("res://src/presentation/item_assets.gd")
const ART_IDS=["ball.oilskin","ball.laser","pin.tempo","charm.neon_sign","ball_mod.blacklight","ball_mod.bumper_guard"]
var art_captures:Dictionary={}
var observing:=false
func _process(_delta:float) -> bool:
 if is_instance_valid(lab) and is_instance_valid(lab.motion) and is_instance_valid(lab.motion.abilities) and not observing:
  _observe()
 return false
func _observe() -> void:
 observing=true
 var neon:Node=lab.motion.abilities.neon
 if lab.state=="rolling" and neon.rebound_age<.85 and not art_captures.has("rebound_live"):
  art_captures.rebound_live=true
  _check(lab.lane.tracker.rebounded and neon.reduced,"bumper rail appears for the real rebound, static under reduced effects")
  await super._capture("n1_rebound_live")
 if lab.state=="rolling" and neon.oil_seen and not art_captures.has("oil_hold"):
  art_captures.oil_hold=true
  _check(lab.lane.rules.get("oil_hold",false),"Oilskin cue follows committed oil hold")
  _check(lab.lane.ball.get_meta("art_item_id","")=="ball.oilskin","Oilskin actual body uses its material")
  _check(lab.motion.abilities.history.any(func(e):return e.id=="ball.oilskin" and e.event=="oil_hold" and e.audio_played),"Oilskin sound at launch")
  await super._capture("n1_oil_hold")
 if lab.state=="rolling" and neon.beam_age<.85 and not art_captures.has("laser_beam"):
  art_captures.laser_beam=true
  _check(neon.beam_grade in ["sweet","perfect"],"Laser beam follows measured accurate release")
  await super._capture("n1_laser_beam")
 if lab.state in ["scoring","frame_done"]:
  var glyph:Control=lab.motion.abilities.glyph
  if glyph.style!=null and glyph.age<glyph.style.duration and glyph.style.item_id in ART_IDS:
   var id:String=glyph.style.item_id
   var key:=id.get_slice(".",1)+"_paid"
   if not art_captures.has(key):
    art_captures[key]=true
    if id in ["ball.laser","pin.tempo","charm.neon_sign"]:
     _check(glyph.details.count==lab.scored_frames[-1].result.facts.accurate,"meter counts actual accurate rolls")
    _check(glyph.still==bool(lab.settings.reduced_motion or lab.settings.reduced_flash),"cue follows reduction")
    _check(lab.motion.abilities.history.any(func(e):return e.id==id and e.audio_played),"paid cue plays sound "+id)
    await super._capture("n1_"+key)
 observing=false
func _tap(control:Control) -> void:
 if control is CardView and control.item_id in ART_IDS:
  _check(not control.art_pending and control.art.texture==Assets.slot(control.item_id,"card"),"native card uses artwork "+control.item_id)
  var key:="shop_"+String(control.item_id).replace(".","_")
  if lab.state=="shop" and not art_captures.has(key):
   art_captures[key]=true
   await super._capture("n1_"+key)
 await super._tap(control)
 if is_instance_valid(lab) and lab.state=="aim" and lab.run!=null:
  var mod:String=lab.run.card_mod(lab.armed_ball)
  if mod in ["ball_mod.blacklight","ball_mod.bumper_guard"]:
   for i in 2:await process_frame
   var overlay=lab.lane.aim_ball.get_node_or_null("ModificationOverlay")
   _check(overlay!=null and overlay.item_id==mod and overlay.host_id==lab.armed_ball_id(),"real host keeps its identity and authored attachment")
   if overlay!=null:_check(overlay.find_children("*","CollisionObject3D",true,false).is_empty(),"attachment is cosmetic")
   var key:="host_"+mod.get_slice(".",1)
   if not art_captures.has(key):
    art_captures[key]=true
    await super._capture("n1_"+key)
func _scored() -> Dictionary:
 await _wait_for(func():return lab.state=="frame_done","natural unskipped score reveal",ROLL_FRAMES*3)
 return lab.scored_frames[-1]
func _capture(label:String) -> void:
 await super._capture(label)
 if label=="c15_laser":
  for key in ["laser_paid","tempo_paid","laser_beam","neon_sign_paid","blacklight_paid","bumper_guard_paid","rebound_live"]:
   _check(art_captures.has(key),"native art observed "+key)
  # Extra real frame after the unchanged parent banks: Oilskin is actually thrown.
  await _to_shop("boss")
  await _leave_shop()
  await _aim()
  var uid:=""
  for card in lab.run.cards:
   if lab.run.cards[card].item_id=="ball.oilskin":uid=card
  await _card_frame(uid,[STRIKE],0.0,"Oilskin native art demonstration")
  _check(art_captures.has("oil_hold"),"Oilskin actual launch was observed")
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
   _check(not card.art_pending and card.art.texture==Assets.slot(id,"card"),"Binder uses final card "+id)
   await _menu_capture("n1_binder_"+id.replace(".","_"))
func _menu_capture(label:String) -> void:
 if artifact_dir.is_empty() or DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 _check(root.get_texture().get_image().save_png(artifact_dir.path_join(label+".png"))==OK,"Binder capture")
