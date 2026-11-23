extends "res://tests/neon_c18_journey.gd"
const Assets = preload("res://src/presentation/item_assets.gd")
const CardView = preload("res://src/presentation/card_view.gd")
const ART_IDS = ["shop_upgrade.trade_in","shop_upgrade.specialist_shelf","ball.comet","charm.metronome","consumable.steady_hand"]
var evidence := {}
var observing := false
func _process(_delta: float) -> bool:
 if DisplayServer.get_name() == "headless": OS.delay_msec(16)
 if is_instance_valid(lab) and is_instance_valid(lab.motion) and is_instance_valid(lab.motion.abilities) and not observing: _observe()
 return false
func _observe() -> void:
 observing = true
 var art: Node = lab.motion.abilities.neon_n4
 if lab.state == "rolling" and art.trail_count > 3 and not evidence.has("comet_trail"):
  evidence.comet_trail = true
  _check(art.qualified and art.grade in ["sweet","perfect"] and lab.lane.launch.ball_id == "ball.comet","Comet tail follows measured accurate curved roll")
  _check(lab.lane.ball.get_meta("art_item_id","") == "ball.comet","live Comet material on actual ball")
  await super._capture("n4_comet_trail")
 if lab.state in ["scoring","frame_done"]:
  var glyph: Control = lab.motion.abilities.glyph
  if glyph.style != null and glyph.age < glyph.style.duration and glyph.style.item_id in ART_IDS and glyph.details.has("amount"):
   var id: String = glyph.style.item_id
   var key: String = id.get_slice(".",1)+"_paid"
   if not evidence.has(key):
    evidence[key] = true
    var amount: float = {"ball.comet":6.0,"charm.metronome":1.5,"consumable.steady_hand":2.0}.get(id,0)
    _check(is_equal_approx(glyph.details.amount,amount),"exact paid cue "+id)
    _check(glyph.still == bool(lab.settings.reduced_motion or lab.settings.reduced_flash),"cue respects reduced settings")
    _check(lab.motion.abilities.history.any(func(e): return e.id == id and e.details.has("amount") and e.audio_played),"native paid sound "+id)
    await super._capture("n4_"+key)
 observing = false
func _scored() -> Dictionary:
 await _wait_for(func(): return lab.state == "frame_done","unskipped score reveal",ROLL_FRAMES*3)
 for i in 4: await process_frame
 return lab.scored_frames[-1]
func _trade_in() -> void:
 await super._trade_in()
 for i in 4: await process_frame
 var sales: Array = lab.motion.abilities.history.filter(func(e): return e.id == "shop_upgrade.trade_in" and e.event == "confirmed_sale")
 _check(sales.any(func(e): return e.details.amount > 0),"Trade-In confirmed sale cue: "+str(sales))
 _check(sales.any(func(e): return e.audio_played),"Trade-In confirmed sale sound: "+str(sales))
 await super._capture("n4_trade_sale")
func _specialist_shelf() -> void:
 await super._specialist_shelf()
 for i in 4: await process_frame
 var index := -1
 for i in lab.shop.offers.size():
  if lab.shop.offers[i].slot == Shop.SPECIALIST: index = i
 _check(index >= 0 and Shop.SPECIALIST == 7,"actual Specialist slot 7 exists")
 var card: Control = lab.shop_panel.button_for_offer(index)
 _check(card.get_node("SpecialistArt").visible and card.text.contains("Specialist"),"Specialist offer has its cyan frame and label")
 _check(lab.motion.abilities.history.any(func(e): return e.id == "shop_upgrade.specialist_shelf" and e.event == "confirmed_purchase" and e.audio_played),"Shelf native purchase sound")
 await _reach(card)
 for i in 35: await process_frame
 await super._capture("n4_specialist")
 card.grab_focus()
 await process_frame
 await _action("ui_accept")
 await _wait_for(func(): return lab.shop_panel.offer_sheet.visible,"open Specialist offer")
 _check(lab.shop_panel.offer_kind.text.contains("Specialist"),"opened offer visibly names Specialist")
 for i in 4: await process_frame
 await super._capture("n4_specialist_offer")
 await _focus_accept(lab.shop_panel.offer_back)
func _tap(control: Control) -> void:
 # QaRender can buy the upgrade and sell an item inside the audio debounce's
 # wall-clock window. Model a separate player action without changing game audio.
 if String(control.name).begins_with("Sell_"):
  await process_frame
  OS.delay_msec(100)
 if control is CardView and control.item_id in ART_IDS:
  _check(not control.art_pending and control.art.texture == Assets.slot(control.item_id,"card"),"native final illustration "+control.item_id)
  var key: String = "shop_"+control.item_id.replace(".","_")
  if lab.state == "shop" and not evidence.has(key):
   evidence[key] = true
   await _reach(control)
   for i in 35: await process_frame
   await super._capture("n4_"+key)
 await super._tap(control)
 # Capture armed art before the timing-sensitive throw helper begins.
 if is_instance_valid(lab) and lab.state == "aim" and lab.armed_ball_id() == "ball.comet" and not lab.armed_tactical.is_empty() and not evidence.has("armed"):
  for i in 3: await process_frame
  evidence.armed = true
  _check(lab.motion.abilities.neon_n4.armed,"Steady Hand armed marker")
  await super._capture("n4_armed")
func _sound_sliders() -> void:
 await super._sound_sliders()
 for key in ["comet_trail","comet_paid","metronome_paid","steady_hand_paid","armed"]:
  _check(evidence.has(key),"native AV-N4 evidence "+key)
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
  await _menu_capture("n4_binder_"+id.replace(".","_"))
  await _focus_accept(scene.clubhouse.preview_close)
 for tab in ["trophies","goals"]:
  await _focus_accept(scene.clubhouse.tab_buttons[tab])
  var prefix := "Trophy_" if tab == "trophies" else "Goal_"
  var row: Control = scene.clubhouse.find_child(prefix+"mastery_controlled_curve",true,false)
  _check(row != null,"native mastery row in "+tab)
  if tab == "trophies": _check(row.find_child("Art",true,false) is TextureRect,"native ribbon replaces placeholder")
  var scroll: ScrollContainer = scene.clubhouse.pages[tab].get_parent()
  scroll.ensure_control_visible(row)
  for i in 4: await process_frame
  await _menu_capture("n4_ribbon_trophies" if tab == "trophies" else "n4_mastery_progress")
 await _focus_accept(scene.clubhouse.tab_buttons.board)
 await _focus_accept(scene.continue_button)
 await _wait_for(func(): return scene.lab != null,"return to saved game")
 lab = scene.lab
func _menu_capture(label: String) -> void:
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  _check(root.get_texture().get_image().save_png(artifact_dir.path_join(label+".png")) == OK,"capture "+label)
