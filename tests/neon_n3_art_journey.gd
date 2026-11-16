extends "res://tests/neon_c17_journey.gd"
const CardView = preload("res://src/presentation/card_view.gd")
const Assets = preload("res://src/presentation/item_assets.gd")
const ART_IDS = ["charm.dry_side","charm.lane_reader","consumable.hook_shot","consumable.line_call","charm.bounce_back","charm.straight_money"]
var art_captures := {}
var observing := false
func _process(_delta: float) -> bool:
 if DisplayServer.get_name() == "headless": OS.delay_msec(16)
 if is_instance_valid(lab) and is_instance_valid(lab.motion) and is_instance_valid(lab.motion.abilities) and not observing: _observe()
 return false
func _observe() -> void:
 observing = true
 var art: Node = lab.motion.abilities.neon_n3
 if lab.state == "rolling":
  for key in ["side", "rescue", "hook"]:
   var seen: bool = art.side_seen and art.side_left if key == "side" else (art.rescue_seen if key == "rescue" else art.hook_seen)
   if seen and not art_captures.has(key):
    art_captures[key] = true
    if key == "side": _check(lab.lane.tracker.left_side and lab.lane.tracker.get("_side_read"),"Dry Side reads actual 34ft crossing")
    if key == "rescue":
     _check(lab.lane.tracker.rebounded,"Bounce Back follows actual Bumper Guard rescue")
     var markers: Array = lab.motion.abilities.world_glyphs.filter(func(g): return g.style != null and g.age < g.style.duration and g.style.item_id in ["ball_mod.bumper_guard","charm.bounce_back"])
     _check(markers.size() == 2 and not markers[0].get_rect().intersects(markers[1].get_rect()),"rescue identities stay individually readable")
    if key == "hook":
     _check(is_equal_approx(float(lab.lane.rules.get("spin_scale",0)),1.5),"Hook Shot uses actual committed scale")
     _check(lab.motion.abilities.history.any(func(e): return e.id == "consumable.hook_shot" and e.event == "committed_hook" and e.audio_played),"Hook Shot native sound")
    await super._capture("n3_"+key)
 if lab.state in ["scoring","frame_done"]:
  var glyph: Control = lab.motion.abilities.glyph
  if glyph.style != null and glyph.age < glyph.style.duration and glyph.style.item_id in ART_IDS and glyph.details.has("amount"):
   var id: String = glyph.style.item_id
   var key := id.get_slice(".",1)+"_paid"
   if not art_captures.has(key):
    art_captures[key] = true
    _check(glyph.still == bool(lab.settings.reduced_motion or lab.settings.reduced_flash),"paid cue respects reduction")
    _check(lab.motion.abilities.history.any(func(e): return e.id == id and e.details.has("amount") and e.audio_played),"paid native sound "+id)
    var expected: float = {"charm.dry_side":4,"charm.lane_reader":1.5,"consumable.line_call":4,"charm.bounce_back":3,"charm.straight_money":2}.get(id,0)
    _check(is_equal_approx(float(glyph.details.amount),expected),"exact paid amount "+id)
    await super._capture("n3_"+key)
 observing = false
func _scored() -> Dictionary:
 await _wait_for(func(): return lab.state == "frame_done","natural unskipped reveal",ROLL_FRAMES*3)
 # The state changes before the deferred keep-card layout has settled.
 for i in 4: await process_frame
 return lab.scored_frames[-1]
func _focus_accept(control: Control) -> void:
 if is_instance_valid(lab) and control == lab.assist_panel.throw_button:
  var art: Node = lab.motion.abilities.neon_n3
  for i in 3: await process_frame
  _check(art.lane_name in ["House Oil","Long Oil"],"Lane Reader shows a catalogue name, not an internal lane ID")
  if art.armed in ["consumable.hook_shot","consumable.line_call"]:
   var key: String = art.armed.get_slice(".",1)+"_armed"
   if not art_captures.has(key):
    art_captures[key] = true
    await super._capture("n3_"+key)
  if art.lane_name == "Long Oil" and not art_captures.has("lane"):
   art_captures.lane = true
   await super._capture("n3_lane")
 await super._focus_accept(control)
func _tap(control: Control) -> void:
 if control is CardView and control.item_id in ART_IDS:
  _check(not control.art_pending and control.art.texture == Assets.slot(control.item_id,"card"),"native illustrated card "+control.item_id)
  var key := "shop_"+String(control.item_id).replace(".","_")
  if lab.state == "shop" and not art_captures.has(key):
   art_captures[key] = true
   await super._capture("n3_"+key)
 await super._tap(control)
func _capture(label: String) -> void:
 await super._capture(label)
 if label == "c17_bounce_back":
  for key in ["side","rescue","hook","lane","hook_shot_armed","line_call_armed","dry_side_paid","lane_reader_paid","line_call_paid","bounce_back_paid","straight_money_paid"]:
   _check(art_captures.has(key),"native AV-N3 evidence "+key)
  await _focus_accept(scene.back)
  await _wait_for(func(): return scene.screen == "menu","Binder return")
  await _focus_accept(scene.clubhouse.tab_buttons.binder)
  for id in ART_IDS:
   await _focus_accept(scene.clubhouse.filter_button(id.get_slice(".",0)))
   var card = scene.clubhouse.entry_button(id)
   _check(card != null,"Binder includes "+id)
   if card == null: continue
   await _focus_accept(card)
   for i in 6: await process_frame
   _check(scene.clubhouse.selected_item == id and scene.clubhouse.binder_preview.visible,"Binder preview selects "+id)
   if DisplayServer.get_name() != "headless":
    await RenderingServer.frame_post_draw
    _check(root.get_texture().get_image().save_png(artifact_dir.path_join("n3_binder_"+id.replace(".","_")+".png")) == OK,"Binder capture")
   await _focus_accept(scene.clubhouse.preview_close)
