extends "res://tests/neon_c19_journey.gd"
const Assets = preload("res://src/presentation/item_assets.gd")
const CardView = preload("res://src/presentation/card_view.gd")
const ART_IDS = ["pin.compass","charm.split_pattern","charm.dry_run","charm.long_game","charm.second_chance"]
var evidence := {}
var observing := false
func _process(_delta: float) -> bool:
 if DisplayServer.get_name() == "headless": OS.delay_msec(16)
 if is_instance_valid(lab) and is_instance_valid(lab.motion) and is_instance_valid(lab.motion.abilities) and not observing: _observe()
 return false
func _observe() -> void:
 observing = true
 var art: Node = lab.motion.abilities.neon_n5
 if lab.state == "rolling":
  if art.side_seen and art.side_left and not evidence.has("side"):
   evidence.side = true
   _check(lab.lane.tracker.get("_side_read") and lab.lane.tracker.left_side,"Dry Run reads the actual left crossing at 34 ft")
   await super._capture("n5_side")
  if art.rescue_seen and not evidence.has("rescue"):
   evidence.rescue = true
   _check(lab.lane.tracker.rebounded,"Second Chance observes the actual Bumper Guard rescue")
   var markers: Array = lab.motion.abilities.world_glyphs.filter(func(g): return g.style != null and g.age < g.style.duration and g.style.item_id in ["ball_mod.bumper_guard","charm.second_chance"])
   _check(markers.size() == 2 and not markers[0].get_rect().intersects(markers[1].get_rect()),"Bumper Guard and Second Chance markers stay separate")
   await super._capture("n5_rescue")
 if lab.state in ["scoring","frame_done"]:
  var glyph: Control = lab.motion.abilities.glyph
  if glyph.style != null and glyph.age < glyph.style.duration and glyph.style.item_id in ART_IDS and glyph.details.has("amount"):
   var id: String = glyph.style.item_id
   var key := id.get_slice(".",1)+"_paid"
   if not evidence.has(key):
    evidence[key] = true
    var amount: float = {"pin.compass":25,"charm.split_pattern":2,"charm.dry_run":10,"charm.long_game":1.5,"charm.second_chance":1.5}.get(id,0)
    _check(is_equal_approx(float(glyph.details.amount),amount),"exact paid amount "+id)
    if id == "charm.dry_run": _check(glyph.details.count == 10,"Dry Run marks ten actual fallen pins")
    _check(glyph.still == bool(lab.settings.reduced_motion or lab.settings.reduced_flash),"paid cue respects reduced settings")
    _check(lab.motion.abilities.history.any(func(e): return e.id == id and e.details.has("amount") and e.audio_played),"native paid sound "+id)
    await super._capture("n5_"+key)
 observing = false
func _scored() -> Dictionary:
 await _wait_for(func(): return lab.state == "frame_done","natural unskipped score reveal",ROLL_FRAMES*3)
 for i in 4: await process_frame
 return lab.scored_frames[-1]
func _focus_accept(control: Control) -> void:
 if is_instance_valid(lab) and control == lab.assist_panel.throw_button and lab.motion.abilities.neon_n5.compass_owned:
  var art: Node = lab.motion.abilities.neon_n5
  var key: String = "lane_"+art.lane_key.get_slice(".",1)
  if not evidence.has(key):
   for i in 35: await process_frame
   evidence[key] = true
   _check(art.lane_name in ["House Oil","Two-Tone","Long Oil"],"lane panels show the actual catalogue name")
   _check(art.compass_active == (art.lane_name != "House Oil"),"Compass light follows eligible lane")
   _check(lab.lane.pins[1].get_meta("art_item_id","") == "pin.compass" and art.pin_materials.size() == 1,"real rack pin has Compass material")
   _check(art.pin_materials[0].get_shader_parameter("lane_light") == (1.0 if art.compass_active else 0.0),"Compass enamel light follows lane")
   await super._capture("n5_"+key)
 await super._focus_accept(control)
func _tap(control: Control) -> void:
 if control is CardView and control.item_id in ART_IDS:
  _check(not control.art_pending and control.art.texture == Assets.slot(control.item_id,"card"),"native final identity "+control.item_id)
  var key: String = "shop_"+control.item_id.replace(".","_")
  if lab.state == "shop" and not evidence.has(key):
   evidence[key] = true
   await _reach(control)
   for i in 35: await process_frame
   await super._capture("n5_"+key)
 await super._tap(control)
func _capture(label: String) -> void:
 await super._capture(label)
 if label != "c19_rescue": return
 for key in ["side","rescue","lane_two_tone","lane_long_oil","lane_house_oil","compass_paid","split_pattern_paid","dry_run_paid","long_game_paid","second_chance_paid"]:
  _check(evidence.has(key),"native AV-N5 evidence "+key)
 await _focus_accept(scene.back)
 await _wait_for(func(): return scene.screen == "menu","return to Clubhouse")
 await _focus_accept(scene.clubhouse.tab_buttons.binder)
 for id in ART_IDS:
  await _focus_accept(scene.clubhouse.filter_button(id.get_slice(".",0)))
  var card = scene.clubhouse.entry_button(id)
  _check(card != null,"Binder entry "+id)
  if card == null: continue
  await _focus_accept(card)
  for i in 6: await process_frame
  _check(scene.clubhouse.selected_item == id and scene.clubhouse.binder_preview.visible,"Binder preview "+id)
  await _menu_capture("n5_binder_"+id.replace(".","_"))
  await _focus_accept(scene.clubhouse.preview_close)
 for tab in ["trophies","goals"]:
  await _focus_accept(scene.clubhouse.tab_buttons[tab])
  for id in ["both_halves","rebound_rescue"]:
   var prefix := "Trophy_" if tab == "trophies" else "Goal_"
   var row: Control = scene.clubhouse.find_child(prefix+"mastery_"+id,true,false)
   _check(row != null,"native mastery row "+id)
   if tab == "trophies": _check(row.find_child("Art",true,false) is TextureRect,"native ribbon replaces placeholder "+id)
   var scroll: ScrollContainer = scene.clubhouse.pages[tab].get_parent()
   scroll.ensure_control_visible(row)
   for i in 4: await process_frame
   await _menu_capture("n5_"+tab+"_"+id)
func _menu_capture(label: String) -> void:
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  _check(root.get_texture().get_image().save_png(artifact_dir.path_join(label+".png")) == OK,"capture "+label)
