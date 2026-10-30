extends "res://tests/av_c03_a_journey.gd"
## Purchases and card attachments are real. Seeded hands use owned UIDs only;
## every arm/consume/throw/report/award is the native game, never fabricated.
const Deck=preload("res://src/rules/card_deck.gd")
const HOST_BALLS={"ball_mod.chalk_grip":"ball.hook","ball_mod.spin_wax":"ball.hook","ball_mod.coin_slot":"ball.hammer"}
var host_refs:Dictionary={}
func _batch() -> String:return "AV-C04-B"
func _purchase() -> void:
 lab.run.credit(100000,"fixture: bounded C04-B art offers")
 lab.shop.division=2
 for id in wanted:
  for gate in lab.run.item(id).unlock.prerequisites:
   if gate not in lab.shop.unlocked:lab.shop.unlocked.append(gate)
 lab._refresh_shop()
 print(batch," fixture: wallet and eligible shop pool; real offers and attachments follow")
 for attempt in 160:
  for index in lab.shop.offers.size():
   var offer:Dictionary=lab.shop.offers[index];var id:String=offer.item_id
   if id not in wanted or host_refs.has(id) or offer.sold:continue
   var hosts:Array=lab.run.mod_hosts(id);var target:=""
   for ref in hosts:
    if lab.run.entry_at(ref).item_id==HOST_BALLS[id] and ref not in host_refs.values():target=ref;break
   if target.is_empty():continue
   var button:Button=lab.shop_panel.button_for_offer(index)
   _check(button.icon==Assets.slot(id,"icon"),"shop exact icon "+id)
   await _capture(id.replace(".","_")+"_shop")
   var money:int=lab.run.money
   await _focus_accept(button)
   await _focus_accept(lab.shop_panel.choice_button(hosts.find(target)))
   _check(lab.run.entry_at(target).mod==id and lab.run.money==money-int(offer.price),"real paid card attachment "+id)
   host_refs[id]=target
  if host_refs.size()==wanted.size():break
  await _focus_accept(lab.shop_panel.reroll_button)
 _check(host_refs.size()==wanted.size(),"all three purchased onto distinct cards")
 for i in 8:await process_frame
 for id in wanted:
  var badge=lab.shop_panel.sell_button(host_refs[id]).get_node_or_null("ModificationBadge")
  _check(badge!=null and badge.texture==Assets.slot(id,"icon"),"owned card badge "+id)
 await _capture("owned_shop")
 await _leave_shop();await _aim()
 _hand_for(wanted)
 for i in 12:await process_frame
 await _capture("inventory")
 for id in wanted:
  var uid:=String(host_refs[id]).trim_prefix("card:")
  var button:Button=lab.card_hand.button_for(uid)
  _check(button.icon==Assets.slot(HOST_BALLS[id],"icon") and button.get_node("ModificationBadge").texture==Assets.slot(id,"icon"),"hand preserves host plus exact modification")
  await _focus_accept(lab.card_hand.inspect_button);await _focus_accept(button)
  for i in 8:await process_frame
  _check(lab.inspector.visible and lab.inspector.art.texture==Assets.slot(HOST_BALLS[id],"card"),"inspector host remains")
  _check(lab.inspector.art.get_node("ModificationBadge").texture==Assets.slot(id,"icon"),"inspector exact modification")
  await _capture(id.replace(".","_")+"_inspector")
  await _focus_accept(lab.inspector.close_button)
func _binder() -> void:
 await _focus_accept(scene.back);await _wait_for(func():return scene.screen=="menu","binder menu")
 await _focus_accept(scene.clubhouse.tab_buttons.binder)
 await _focus_accept(scene.clubhouse.filter_button("ball_mod"))
 for id in wanted:
  await _focus_accept(scene.clubhouse.entry_button(id))
  for i in 8:await process_frame
  _check(scene.clubhouse.binder_art.get_child(0).texture==Assets.slot(id,"card"),"binder exact card "+id)
  await _capture(id.replace(".","_")+"_binder")
 await _focus_accept(scene.clubhouse.tab_buttons.board);await _focus_accept(scene.continue_button)
 await _wait_for(func():return scene.lab!=null and scene.lab.state=="aim","continue attached cards")
 lab=scene.lab;lab.trial_log_path=""
 for id in wanted:_check(lab.run.entry_at(host_refs[id]).mod==id,"actual attachment reload "+id)
 lab.score_panel.step_revealed.connect(_observe_row)
 process_frame.connect(_watch_roll)
func _hand_for(ids:Array) -> void:
 var uids:Array=ids.map(func(id):return String(host_refs[id]).trim_prefix("card:"))
 for seed_value in 256:
  var deck=Deck.create_with(lab.run.deck_cards(),seed_value);deck.start_frame()
  if uids.all(func(uid):return uid in deck.hand):
   lab.equipment=deck;lab.armed_ball="";lab._refresh_hand()
   print(batch," fixture: seeded owned-UID hand ",seed_value," for ",ids)
   return
 _check(false,"bounded owned-UID seed fixture")
func _arm_mod(id:String) -> void:
 _hand_for([id])
 var uid:=String(host_refs[id]).trim_prefix("card:")
 await _focus_accept(lab.card_hand.button_for(uid))
 for i in 8:await process_frame
 _check(lab.armed_ball==uid and lab.run.card_mod(uid)==id,"actual modified card armed "+id)
 var body:Node3D=lab.lane.aim_ball
 var overlay=body.get_node_or_null("ModificationOverlay")
 _check(overlay!=null and overlay.item_id==id and body.get_meta("art_item_id")==HOST_BALLS[id],"aim host plus overlay "+id)
 if not captures.has(id+":detail"):
  captures[id+":detail"]=true
  if DisplayServer.get_name()!="headless":
   var camera:Transform3D=lab._camera.transform;var layers:int=lab._marker.layers;lab._marker.layers=0
   lab._camera.position=body.global_position+Vector3(.24,.20,.45);lab._camera.look_at(body.global_position)
   for i in 8:await process_frame
   await RenderingServer.frame_post_draw
   _check(lab._viewport.get_texture().get_image().save_png(artifact_dir.path_join(id.replace(".","_")+"_host_detail.png"))==OK,"actual ball detail")
   lab._camera.transform=camera;lab._marker.layers=layers
func _watch_roll() -> void:
 if lab==null or lab.state!="rolling" or lab.motion._trail.size()<5:return
 var id:String=lab.frame_mods.get(lab.roll_index,"")
 if id not in wanted:return
 var key:=id+":rolling"
 if not captures.has(key):
  captures[key]=true
  var body:RigidBody3D=lab.lane.ball
  var physical:=_physical(body)
  preload("res://src/presentation/modification_art.gd").dress(body,id,HOST_BALLS[id])
  _check(_physical(body)==physical and body.get_node("ModificationOverlay").item_id==id,"real rolling body keeps physics and modification")
  await _capture(id.replace(".","_")+"_rolling")
 if id=="ball_mod.spin_wax" and lab.motion.wax_trail_active() and not captures.has("wax_trail"):
  captures["wax_trail"]=true;await _capture("wax_trail")
 if id=="ball_mod.spin_wax" and not preload("res://src/simulation/lane_spec.gd").is_curved(float(lab.lane.launch.spin)) and not captures.has("wax_straight_checked"):
  captures["wax_straight_checked"]=true
  _check(not lab.motion.wax_trail_active(),"straight waxed roll has no curve accent")
func _observe_row(step:Dictionary,index:int,skipped:bool) -> void:
 var history:Array=lab.motion.abilities.history
 for cue in history.slice(observed_count):
  if cue.id not in wanted:continue
  observed_rows.append({"index":index,"phase":step.phase,"text":step.text,"cue":cue.duplicate(true),"skipped":skipped})
  _check(step.text.contains(lab.run.item(cue.id).name),"mod row owns its cue "+cue.id)
  _check(cue.event==("after_bank" if cue.id=="ball_mod.coin_slot" else "ball"),"actual mod phase "+cue.id)
 observed_count=history.size()
func _play_batch() -> void:
 await _arm_mod("ball_mod.coin_slot")
 var quiet:=await _mod_frame([GUTTER,GUTTER],[0,0],"Coin Slot open")
 _check(quiet.income==0 and _ids().is_empty(),"open Coin Slot stays quiet")
 await _next_frame();await _arm_mod("ball_mod.spin_wax")
 var wax:=await _mod_frame([[-.25,0,.7],GUTTER],[.25,0],"Spin Wax curved frame")
 _check(wax.frame.rolls[0].curved and _ids().count("ball_mod.spin_wax")==1,"one used waxed card in actual curved frame")
 _check(captures.has("wax_trail"),"narrow actual curved trail accent captured")
 await _controls(wax)
 await _focus_accept(scene.options)
 await _focus_accept(lab.settings_panel.reduced_motion);await _focus_accept(lab.settings_panel.reduced_flash);await _focus_accept(lab.settings_panel.close)
 await _next_frame();await _arm_mod("ball_mod.chalk_grip")
 var chalk:=await _mod_frame([LEAVE,[0,0,.6]],[0,0],"Chalk Grip spare")
 _check(chalk.result.category=="spare" and _ids().count("ball_mod.chalk_grip")==1,"spare-only +2 for the actual used card")
 await _next_frame();await _arm_mod("ball_mod.coin_slot")
 var coin:=await _mod_frame([STRIKE],[0],"Coin Slot strike")
 _check(coin.result.category=="strike" and coin.income==2 and _ids().count("ball_mod.coin_slot")==1,"one native after-bank two-dollar payout")
 await _next_frame();await _arm_mod("ball_mod.spin_wax")
 await _mod_frame([GUTTER,GUTTER],[0,0],"Spin Wax straight frame")
 _check(_ids().is_empty(),"straight Wax stays quiet")
 _check(captures.has("wax_straight_checked"),"straight trail condition checked during real rolling")
 await _next_frame();await _arm_mod("ball_mod.chalk_grip")
 var strike:=await _mod_frame([STRIKE],[0],"Chalk Grip strike")
 _check(strike.result.category=="strike" and _ids().is_empty(),"strike Chalk stays quiet")
 for id in wanted:_check(captures.has(id+":rolling"),"actual rolling host inspected "+id)
func _mod_frame(shots:Array,spins:Array,label:String) -> Dictionary:
 var loadout:Dictionary=lab.run.loadout();var context:Dictionary=lab.frame_context()
 var before:int=lab.history.size();var start:int=lab.motion.abilities.history.size()
 var played_uid:String=lab.armed_ball;var played_mod:String=lab.run.card_mod(played_uid)
 for i in shots.size():
  if i>0 and Builder.is_complete(lab.frame_reports):break
  await _throw(shots[i],spins[i])
  if i==0:_check(lab.frame_mods.get(1,"")==played_mod and played_uid not in lab.equipment.hand and played_uid in lab.equipment.discard,"actual card consumed and exact modification committed")
 var scored:=await _scored();var extras:={}
 for roll in lab.frame_mods:extras[roll]=[lab.frame_mods[roll]]
 var built:=Builder.build(loadout,lab.content.catalogue,lab.history.slice(before),extras,context)
 var expected:=Rules.resolve(built.frame)
 _check(built.ok and expected.score==scored.banked and expected.facts==scored.result.facts,"independent bank/facts "+label)
 frame_cues=lab.motion.abilities.history.slice(start).filter(func(e):return e.id in wanted)
 for cue in frame_cues:
  _check(cue.details.amount=={"ball_mod.chalk_grip":2,"ball_mod.spin_wax":4,"ball_mod.coin_slot":2}[cue.id],"actual per-roll award "+cue.id)
 checks.append({"label":label,"bank":scored.banked,"income":scored.income,"facts":scored.result.facts,"cues":frame_cues.duplicate(true)});metrics.append(lab.motion.metrics())
 print(batch," ",label," bank=",scored.banked," category=",scored.result.category," income=",scored.income," cues=",_ids())
 return scored
