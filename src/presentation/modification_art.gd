extends Node
## Read-only host badges/overlays and pre-bank attachment snapshots. RunInventory
## remains the sole owner of attachment state, card identity, physics and saves.
const Assets=preload("res://src/presentation/item_assets.gd")
const Overlay=preload("res://assets/items/d04/overlay.gd")
var lab:Control
var snapshots:Dictionary={}
var rack_badges:HFlowContainer
var rack_signature:=""
func _ready() -> void:name="ModificationArt"
func _process(_delta:float) -> void:
 if lab.run==null or lab.lane==null:return
 if lab.state in ["aim","holding","rolling"]:
  snapshots[lab.frame_number]={"pin_mods":lab.run.loadout().get("pin_mods",{}).duplicate(),"roll_mods":lab.frame_mods.duplicate(),"tactics":lab.frame_tactics.duplicate(true)}
  if snapshots.size()>8:snapshots.erase(snapshots.keys()[0])
 for uid in lab.card_hand.buttons:
  _badge(lab.card_hand.buttons[uid],lab.run.card_mod(uid),24)
 if lab.inspector.visible:
  _badge(lab.inspector.art,lab.run.card_mod(lab.inspector.selected_uid),48)
 if lab.state=="shop":
  _rack_badges()
  for owned in lab.run.entries():
   var button:Button=lab.shop_panel.sell_button(owned.ref)
   if button!=null and Assets.slot(owned.entry.mod,"icon")!=null:
    button.icon=Assets.slot(owned.entry.item_id,"icon")
    button.add_theme_constant_override("icon_max_width",28)
    _badge(button,owned.entry.mod,24)
 for position in lab.lane.pins:
  var entry:Dictionary=lab.run.rack.get(position,{})
  dress(lab.lane.pins[position],entry.get("mod",""),entry.get("item_id",""))
  var overlay=lab.lane.pins[position].get_node_or_null("ModificationOverlay")
  if overlay!=null and overlay.item_id=="pin_mod.lantern":
   overlay.set_lit(lab.lane.tracker==null or position not in lab.lane.tracker.sequence)
 var mod:String=lab.frame_mods.get(lab.roll_index,"") if lab.state in ["rolling","result","scoring","frame_done"] else lab.run.card_mod(lab.armed_ball)
 var host:String=lab.lane.launch.get("ball_id","ball.house") if lab.state in ["rolling","result","scoring","frame_done"] else lab.armed_ball_id()
 dress(lab.lane.ball,mod,host)
 dress(lab.lane.aim_ball,mod,host)
func _rack_badges() -> void:
 if rack_badges==null:
  rack_badges=HFlowContainer.new();rack_badges.name="ModifiedRackArt";rack_badges.mouse_filter=Control.MOUSE_FILTER_IGNORE
  lab.shop_panel._main.add_child(rack_badges)
  lab.shop_panel._main.move_child(rack_badges,lab.shop_panel.rack_label.get_index()+1)
 var signature:=str(lab.run.rack)
 if signature==rack_signature:return
 rack_signature=signature
 for child in rack_badges.get_children():rack_badges.remove_child(child);child.queue_free()
 for position in lab.run.rack:
  var entry:Dictionary=lab.run.rack[position]
  if Assets.slot(entry.mod,"icon")==null:continue
  var box:=HBoxContainer.new();box.name="Slot%d"%position;box.mouse_filter=Control.MOUSE_FILTER_IGNORE;rack_badges.add_child(box)
  var host:=TextureRect.new();host.name="Host";host.texture=Assets.slot(entry.item_id,"icon")
  host.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;host.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  host.custom_minimum_size=Vector2(56,48);host.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(host)
  _badge(host,entry.mod,24)
  var label:=Label.new();label.text="%d %s\n+ %s"%[position,lab.run.item(entry.item_id).name,lab.run.item(entry.mod).name]
  label.add_theme_font_size_override("font_size",16);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(label)
static func dress(body,mod:String,host:String) -> void:
 if not is_instance_valid(body):return
 var current=body.get_node_or_null("ModificationOverlay")
 if current!=null and current.item_id==mod and current.host_id==host:return
 if current!=null:body.remove_child(current);current.queue_free()
 if Assets.slot(mod,"icon")==null:return
 var overlay:=Overlay.new();overlay.item_id=mod;overlay.host_id=host;body.add_child(overlay)
static func _badge(parent:Control,id:String,extent:int) -> void:
 var node:=parent.get_node_or_null("ModificationBadge") as TextureRect
 var texture:=Assets.slot(id,"icon") as Texture2D
 if texture==null:
  if node!=null:node.hide()
  return
 if node==null:
  node=TextureRect.new();node.name="ModificationBadge";node.mouse_filter=Control.MOUSE_FILTER_IGNORE
  node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;parent.add_child(node)
 node.show();node.texture=texture;node.set_meta("item_id",id)
 node.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 node.offset_left=-extent-4;node.offset_right=-4;node.offset_top=4;node.offset_bottom=extent+4
