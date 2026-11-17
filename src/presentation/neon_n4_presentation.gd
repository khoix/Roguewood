extends Node2D
## Read-only observations. Shop cues use confirmed ownership/ledger entries;
## release cues wait for the authoritative target crossing and measured grade.
const Assets = preload("res://src/presentation/item_assets.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const Shop = preload("res://src/rules/shop.gd")
const UPGRADES = ["shop_upgrade.trade_in","shop_upgrade.specialist_shelf"]
const CAPACITY = 12
var lab: Control
var director: Node
var lane_id := 0
var run_id := 0
var ledger_cursor := 0
var owned: Array = []
var qualified := false
var grade := ""
var armed := false
var reduced := false
var trail := PackedVector3Array()
var trail_count := 0
var trail_cursor := 0
var row: HBoxContainer
var shop_glyph: Control
var trade_icon: TextureRect
var shelf_icon: TextureRect
var notice: Label
var hand: Texture2D
var metronome: Texture2D
var has_metronome := false
var beat_clock := 0.0
var border: StyleBoxFlat
func _ready() -> void:
 trail.resize(CAPACITY)
 hand = Assets.slot("consumable.steady_hand","icon")
 metronome = Assets.slot("charm.metronome","icon")
 border = StyleBoxFlat.new(); border.bg_color = Color.TRANSPARENT
 border.border_color = Color("64dacb"); border.set_border_width_all(3); border.set_corner_radius_all(8)
 row = HBoxContainer.new(); row.name = "NeonMasteryShopArt"
 row.mouse_filter = Control.MOUSE_FILTER_IGNORE
 lab.shop_panel._main.add_child(row); lab.shop_panel._main.move_child(row,2)
 shop_glyph = preload("res://src/presentation/ability_glyph.gd").new(); row.add_child(shop_glyph)
 trade_icon = _icon(UPGRADES[0]); shelf_icon = _icon(UPGRADES[1])
 notice = Label.new(); notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 notice.size_flags_horizontal = Control.SIZE_EXPAND_FILL; notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
 notice.add_theme_font_size_override("font_size",16); row.add_child(notice)
func _icon(id: String) -> TextureRect:
 var picture := TextureRect.new(); picture.texture = Assets.slot(id,"icon")
 picture.custom_minimum_size = Vector2(40,40); picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 picture.mouse_filter = Control.MOUSE_FILTER_IGNORE; row.add_child(picture); return picture
func _shop_cue(id: String, event: String, details: Dictionary = {}) -> void:
 director.cue(id,event,false,details)
 shop_glyph.show_cue(Assets.slot(id,"activation"),reduced,Assets.slot(id,"icon"),details)
func _process(delta: float) -> void:
 if lab.run == null: return
 reduced = lab.settings.reduced_motion or lab.settings.reduced_flash
 beat_clock += delta
 has_metronome = lab.run.charms.any(func(e): return e.item_id == "charm.metronome")
 var now: Array = lab.run.upgrades.map(func(e): return e.item_id)
 if run_id != lab.run.get_instance_id():
  run_id = lab.run.get_instance_id(); owned = now; ledger_cursor = lab.run.ledger.size()
 else:
  for id in UPGRADES:
   if id in now and id not in owned: _shop_cue(id,"confirmed_purchase")
  owned = now
  while ledger_cursor < lab.run.ledger.size():
   var entry: Dictionary = lab.run.ledger[ledger_cursor]; ledger_cursor += 1
   if entry.kind == "sale" and UPGRADES[0] in owned:
    _shop_cue(UPGRADES[0],"confirmed_sale",{"amount":int(entry.amount)})
 shop_glyph.enabled = lab.motion.sound.enabled
 trade_icon.visible = UPGRADES[0] in owned; shelf_icon.visible = UPGRADES[1] in owned
 row.visible = lab.state == "shop" and lab.motion.sound.enabled and (trade_icon.visible or shelf_icon.visible)
 notice.text = "Trade-In · sale values include the bonus" if trade_icon.visible else ""
 if shelf_icon.visible: notice.text += ("\n" if trade_icon.visible else "") + "Specialist · cyan-edged offer"
 if lab.state == "shop" and lab.shop != null:
  for i in lab.shop.offers.size():
   var button: Control = lab.shop_panel.button_for_offer(i)
   var previous: Panel = button.get_node_or_null("SpecialistArt")
   if previous != null: previous.visible = false
   if lab.shop.offers[i].slot == Shop.SPECIALIST:
    var frame: Panel = button.get_node_or_null("SpecialistArt")
    if frame == null:
     frame = Panel.new(); frame.name = "SpecialistArt"; frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
     button.add_child(frame); frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
     frame.add_theme_stylebox_override("panel",border)
    frame.visible = shelf_icon.visible and lab.motion.sound.enabled
 if lab.lane == null: return
 if lane_id != lab.lane.get_instance_id():
  lane_id = lab.lane.get_instance_id(); qualified = false; grade = ""; trail_count = 0; trail_cursor = 0
 armed = lab._item_of(lab.armed_tactical) == "consumable.steady_hand" if not lab.armed_tactical.is_empty() else false
 if lab.state == "rolling":
  var launch: Dictionary = lab.lane.launch
  var tracker = lab.lane.tracker
  if tracker != null and tracker.target_crossed and grade.is_empty():
   grade = Lane.grade_accuracy(true,tracker.target_offset()-float(launch.target_x),float(launch.ring_radius),float(lab.lane.rules.get("zone_scale",1.0)))
   qualified = grade in ["sweet","perfect"] and Lane.is_curved(float(launch.spin))
   if qualified:
    if launch.ball_id == "ball.comet": director._world_cue("ball.comet","measured_accurate_curve",lab.screen_point(lab.lane.ball_position())+Vector2(-60,0))
    if "consumable.steady_hand" in lab.motion.modifications.snapshots.get(lab.frame_number,{}).get("tactics",{}).get(lab.roll_index,[]):
     director._world_cue("consumable.steady_hand","measured_accurate_curve",lab.screen_point(lab.lane.ball_position())+Vector2(60,0))
   if has_metronome and grade in ["sweet","perfect"]:
    director._world_cue("charm.metronome","measured_accuracy",lab.screen_point(lab.lane.ball_position())+Vector2(0,-72))
  if qualified and launch.ball_id == "ball.comet":
   trail[trail_cursor] = lab.lane.ball_position(); trail_cursor = (trail_cursor+1)%CAPACITY; trail_count = mini(trail_count+1,CAPACITY)
 else: trail_count = 0
 queue_redraw()
func _draw() -> void:
 if lab.lane == null or lab.settings_panel.visible or not lab.motion.sound.enabled: return
 if lab.state in ["aim","holding"] and armed and hand:
  draw_texture_rect(hand,Rect2(lab.ball_screen_position()+Vector2(-20,-65),Vector2(40,40)),false)
 if lab.state in ["aim","holding"] and has_metronome and metronome:
  var beat: Vector2 = (lab.ball_screen_position()+Vector2(-65,-30)).clamp(Vector2(32,32),lab.size-Vector2(32,32))
  draw_texture_rect(metronome,Rect2(beat-Vector2(16,20),Vector2(32,32)),false)
  var swing := 0.0 if reduced else sin(beat_clock*3.2)*10.0
  draw_line(beat+Vector2(0,7),beat+Vector2(swing,-14),Color("64dacb"),2,true)
 if lab.state != "rolling" or trail_count == 0: return
 var at: Vector2 = lab.screen_point(trail[(trail_cursor-1+CAPACITY)%CAPACITY])
 if reduced:
  draw_arc(at,15,0,TAU,20,Color("64dacb"),2,true)
 else:
  for i in range(1,trail_count):
   var start := (trail_cursor-trail_count+CAPACITY)%CAPACITY
   var strength := float(i)/trail_count
   draw_line(lab.screen_point(trail[(start+i-1)%CAPACITY]),lab.screen_point(trail[(start+i)%CAPACITY]),Color(0.39,0.85,0.8,strength*0.7),2+strength*4,true)
