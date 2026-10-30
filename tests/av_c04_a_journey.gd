extends "res://tests/av_c03_a_journey.gd"
## Real purchases/attachments, reload, physical throws and presentation controls.
const HOSTS={"pin_mod.brass_cap":"rack:1","pin_mod.gilt_leaf":"rack:3","pin_mod.keystone":"rack:5"}
func _batch() -> String:return "AV-C04-A"
func _purchase() -> void:
 lab.run.credit(100000,"fixture: bounded C04 art offer sampling")
 lab.shop.division=2
 for id in wanted:
  for gate in lab.run.item(id).unlock.prerequisites:
   if gate not in lab.shop.unlocked:lab.shop.unlocked.append(gate)
 print(batch," fixture: wallet, Division 2 and unlock gates; offers/payment/host choices are native")
 lab._refresh_shop()
 var bought:={}
 for attempt in 160:
  for index in lab.shop.offers.size():
   var offer:Dictionary=lab.shop.offers[index]
   var id:String=offer.item_id
   if id not in wanted or bought.has(id) or offer.sold:continue
   var button:Button=lab.shop_panel.button_for_offer(index)
   _check(button.icon==Assets.slot(id,"icon"),"shop exact icon "+id)
   await _capture(id.replace(".","_")+"_shop")
   var hosts:Array=lab.run.mod_hosts(id)
   var money:int=lab.run.money
   await _focus_accept(button)
   _check(lab.shop_panel.choice_sheet.visible,"native host picker")
   await _focus_accept(lab.shop_panel.choice_button(hosts.find(HOSTS[id])))
   _check(lab.run.entry_at(HOSTS[id]).mod==id and lab.run.money==money-int(offer.price),"actual paid attachment "+id)
   bought[id]=true
  if bought.size()==wanted.size():break
  await _focus_accept(lab.shop_panel.reroll_button)
 _check(bought.size()==wanted.size(),"all three purchased")
 for i in 8:await process_frame
 for id in wanted:
  var badge=lab.motion.modifications.rack_badges.get_node_or_null("Slot%s/Host/ModificationBadge"%String(HOSTS[id]).get_slice(":",1))
  _check(badge!=null and badge.texture==Assets.slot(id,"icon"),"owned host exact badge "+id)
  if badge!=null:_check(Rect2(Vector2.ZERO,badge.get_parent().size).encloses(badge.get_rect()),"badge stays inside host icon after layout")
 await _capture("owned_shop")
 await _leave_shop()
 await _aim()
 for i in 12:await process_frame
 await _capture("inventory")
func _binder() -> void:
 await _focus_accept(scene.back)
 await _wait_for(func():return scene.screen=="menu","binder menu")
 await _focus_accept(scene.clubhouse.tab_buttons.binder)
 await _focus_accept(scene.clubhouse.filter_button("pin_mod"))
 for id in wanted:
  await _focus_accept(scene.clubhouse.entry_button(id))
  for i in 8:await process_frame
  var holder:Control=scene.clubhouse.binder_art
  _check(holder.get_child_count()==1 and holder.get_child(0).texture==Assets.slot(id,"card"),"binder exact card "+id)
  await _capture(id.replace(".","_")+"_binder")
 await _focus_accept(scene.clubhouse.tab_buttons.board)
 await _focus_accept(scene.continue_button)
 await _wait_for(func():return scene.lab!=null and scene.lab.state=="aim","continue attachments")
 lab=scene.lab;lab.trial_log_path=""
 for id in wanted:_check(lab.run.entry_at(HOSTS[id]).mod==id,"attachment survives real menu reload "+id)
 lab.score_panel.step_revealed.connect(_observe_row)
func _observe_row(step:Dictionary,index:int,skipped:bool) -> void:
 var history:Array=lab.motion.abilities.history
 for cue in history.slice(observed_count):
  if cue.id not in wanted:continue
  observed_rows.append({"index":index,"phase":step.phase,"text":step.text,"cue":cue.duplicate(true),"skipped":skipped})
  _check(step.text.contains(lab.run.item(cue.id).name),"mod cue aligned to its own explanation: "+cue.id)
  _check(cue.event==("after_bank" if cue.id=="pin_mod.gilt_leaf" else "fallen"),"exact activation phase "+cue.id)
  if cue.id=="pin_mod.keystone" and not skipped:
   _check(lab.motion.abilities.counted_rack_positions()==cue.details.positions and cue.details.positions.size()==cue.details.count,"Keystone highlights actual counted rack slots")
 observed_count=history.size()
func _play_batch() -> void:
 for i in 12:await process_frame
 for id in wanted:
  var body:RigidBody3D=lab.lane.pins[int(String(HOSTS[id]).get_slice(":",1))]
  var physical:=_physical(body)
  var overlay=body.get_node_or_null("ModificationOverlay")
  _check(overlay!=null and overlay.item_id==id,"actual host overlay "+id)
  if overlay!=null:
   _check(overlay.find_children("*","CollisionObject3D",true,false).is_empty() and overlay.find_children("*","CollisionShape3D",true,false).is_empty(),"cosmetic overlay has no collision")
  preload("res://src/presentation/modification_art.gd").dress(body,id,"pin.wood")
  _check(_physical(body)==physical and body.get_meta("art_item_id")=="pin.wood","body and host identity unchanged")
 var camera:Transform3D=lab._camera.transform
 lab._camera.position=Vector3(0.15,0.85,-16.1);lab._camera.look_at(Vector3(0,0.12,-18.5))
 for i in 12:await process_frame
 await _capture("host_overlays")
 lab._camera.transform=camera
 await _host_details()
 _check(await _arm("ball.echo"),"actual Echo card for modification repeat")
 var first:=await _frame([STRIKE],"Echo repeats attached Brass Cap")
 var accuracy:int=Rules.GRADES[first.frame.rolls[0].accuracy]
 _check(first.result.pin_value==190 and first.result.mult==6+accuracy and first.income==1,"190 Value, six Mult plus actual release grade, one after-bank coin")
 _check(_ids().count("pin_mod.brass_cap")==2 and _ids().count("pin_mod.gilt_leaf")==1 and _ids().count("pin_mod.keystone")==1,"one repeat, one deferred payout, one count")
 var key:Array=frame_cues.filter(func(e):return e.id=="pin_mod.keystone")
 _check(key.size()==1 and key[0].details.count==10 and key[0].details.amount==40,"Keystone actual ten and forty")
 await _capture("echo_repeat")
 await _controls(first)
 await _next_frame()
 var plain:=await _frame([STRIKE],"modified House strike")
 _check(plain.result.retriggers==0 and plain.banked==900 and plain.income==1,"House has no invented repeat; 180 Value x5 Mult and one coin")
 _check(_ids().count("pin_mod.brass_cap")==1,"one non-repeated Brass Cap")
 await _next_frame()
 await _frame([GUTTER,GUTTER],"no modified pin falls")
 _check(_ids().is_empty(),"all three quiet on gutter frame")

func _host_details() -> void:
 # Native 3D viewport inspection only: actual equipped body, original materials,
 # no model reconstruction. Move the inspection camera and restore it afterwards.
 if DisplayServer.get_name()=="headless":return
 var camera:Transform3D=lab._camera.transform
 var marker_layers:int=lab._marker.layers
 lab._marker.layers=0
 for id in wanted:
  var body:RigidBody3D=lab.lane.pins[int(String(HOSTS[id]).get_slice(":",1))]
  var visibility:={}
  for position in lab.lane.pins:
   var other:Node3D=lab.lane.pins[position]
   visibility[position]=other.visible
   other.visible=other==body
  lab._camera.position=body.global_position+Vector3(.15,.34,.72)
  lab._camera.look_at(body.global_position+Vector3(0,.19,0))
  for i in 8:await process_frame
  await RenderingServer.frame_post_draw
  _check(lab._viewport.get_texture().get_image().save_png(artifact_dir.path_join(id.replace(".","_")+"_host_detail.png"))==OK,"actual host viewport capture")
  for position in visibility:lab.lane.pins[position].visible=visibility[position]
 lab._camera.transform=camera;lab._marker.layers=marker_layers
