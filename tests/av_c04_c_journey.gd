extends "res://tests/av_c03_a_journey.gd"
const Deck=preload("res://src/rules/card_deck.gd")
var host_refs:Dictionary={}
var hook_ref:=""
var charge_host:="ball.hammer"
## Real C04 purchases and throws. Seeded hands use purchased UIDs only.
const CHARGE="ball_mod.echo_charge"
const LANTERN="pin_mod.lantern"
func _batch() -> String:return "AV-C04-C"
func _purchase() -> void:
 lab.run.credit(100000,"fixture: bounded C04-C offers")
 lab.shop.division=2
 for id in wanted:
  for gate in lab.run.item(id).unlock.prerequisites:
   if gate not in lab.shop.unlocked:lab.shop.unlocked.append(gate)
 lab._refresh_shop()
 print(batch," fixture: wallet, Division 2 and unlock gates; actual purchases and attachments follow")
 for attempt in 160:
  for index in lab.shop.offers.size():
   var offer:Dictionary=lab.shop.offers[index];var id:String=offer.item_id
   if id not in wanted or host_refs.has(id) or offer.sold:continue
   var hosts:Array=lab.run.mod_hosts(id);var target:="rack:6" if id==LANTERN else ""
   if id==CHARGE:
    _check(hosts.all(func(ref):return lab.run.entry_at(ref).item_id!="ball.echo"),"native host choices exclude Echo Ball")
    for ref in hosts:
     if lab.run.entry_at(ref).item_id=="ball.hammer":target=ref;break
   _check(target in hosts,"actual legal host")
   var button:Button=lab.shop_panel.button_for_offer(index)
   _check(button.icon==Assets.slot(id,"icon"),"exact offer icon "+id)
   await _capture(id.replace(".","_")+"_shop")
   var money:int=lab.run.money
   await _focus_accept(button)
   _check(lab.shop_panel.choice_sheet.visible,"real modification host sheet")
   await _focus_accept(lab.shop_panel.choice_button(hosts.find(target)))
   _check(lab.run.entry_at(target).mod==id and lab.run.money==money-int(offer.price),"paid actual attachment "+id)
   host_refs[id]=target
  if host_refs.size()==wanted.size():break
  await _focus_accept(lab.shop_panel.reroll_button)
 _check(host_refs.size()==2,"both modifications purchased")
 for i in 8:await process_frame
 _check(lab.shop_panel.sell_button(host_refs[CHARGE]).get_node("ModificationBadge").texture==Assets.slot(CHARGE,"icon"),"owned Charge badge")
 _check(lab.motion.modifications.rack_badges.get_node("Slot6/Host/ModificationBadge").texture==Assets.slot(LANTERN,"icon"),"owned Lantern rack badge")
 await _capture("owned_shop");await _leave_shop();await _aim()
 _hand_for([CHARGE])
 for i in 12:await process_frame
 var uid:=String(host_refs[CHARGE]).trim_prefix("card:")
 var card:Button=lab.card_hand.button_for(uid)
 _check(card.icon==Assets.slot("ball.hammer","icon") and card.get_node("ModificationBadge").texture==Assets.slot(CHARGE,"icon"),"Hammer hand identity plus Charge clasp")
 await _capture("inventory")
 await _focus_accept(lab.card_hand.inspect_button);await _focus_accept(card)
 for i in 8:await process_frame
 _check(lab.inspector.art.texture==Assets.slot("ball.hammer","card") and lab.inspector.art.get_node("ModificationBadge").texture==Assets.slot(CHARGE,"icon"),"exact inspector host and modification")
 await _capture("ball_mod_echo_charge_inspector");await _focus_accept(lab.inspector.close_button)
func _binder() -> void:
 await _focus_accept(scene.back);await _wait_for(func():return scene.screen=="menu","binder menu")
 await _focus_accept(scene.clubhouse.tab_buttons.binder)
 for id in wanted:
  await _focus_accept(scene.clubhouse.filter_button(id.get_slice(".",0)))
  await _focus_accept(scene.clubhouse.entry_button(id))
  for i in 8:await process_frame
  _check(scene.clubhouse.binder_art.get_child(0).texture==Assets.slot(id,"card"),"exact binder "+id)
  await _capture(id.replace(".","_")+"_binder")
 await _focus_accept(scene.clubhouse.tab_buttons.board);await _focus_accept(scene.continue_button)
 await _wait_for(func():return scene.lab!=null and scene.lab.state=="aim","continue attachments")
 lab=scene.lab;lab.trial_log_path=""
 for id in wanted:_check(lab.run.entry_at(host_refs[id]).mod==id,"native menu reload attachment "+id)
 lab.score_panel.step_revealed.connect(_observe_row)
 process_frame.connect(_watch_roll)
func _arm_mod(id:String) -> void:
 _hand_for([id])
 var uid:=String(host_refs[id]).trim_prefix("card:")
 await _focus_accept(lab.card_hand.button_for(uid))
 for i in 8:await process_frame
 _check(lab.armed_ball==uid and lab.run.card_mod(uid)==id,"actual charged card armed")
 var body:Node3D=lab.lane.aim_ball
 _check(body.get_node("ModificationOverlay").item_id==CHARGE and body.get_meta("art_item_id")==charge_host,"actual Hammer retains identity beside ring")
 if not captures.has("charge_detail:"+charge_host):
  captures["charge_detail:"+charge_host]=true
  await _detail(body,Vector3(.24,.20,.45),Vector3.ZERO,"ball_mod_echo_charge_host_detail" if charge_host=="ball.hammer" else "charge_hook_host_detail")
func _detail(body:Node3D,offset:Vector3,look:Vector3,label:String) -> void:
 if DisplayServer.get_name()=="headless":return
 var camera:Transform3D=lab._camera.transform;var layers:int=lab._marker.layers;lab._marker.layers=0
 var visibility:={}
 for position in lab.lane.pins:
  visibility[position]=lab.lane.pins[position].visible
  if body in lab.lane.pins.values():lab.lane.pins[position].visible=lab.lane.pins[position]==body
 lab._camera.position=body.global_position+offset;lab._camera.look_at(body.global_position+look)
 for i in 8:await process_frame
 await RenderingServer.frame_post_draw
 _check(lab._viewport.get_texture().get_image().save_png(artifact_dir.path_join(label+".png"))==OK,"native host detail "+label)
 lab._camera.transform=camera;lab._marker.layers=layers
 for position in visibility:lab.lane.pins[position].visible=visibility[position]
func _watch_roll() -> void:
 if lab==null or lab.state!="rolling":return
 var capture_key:="charge_rolling" if charge_host=="ball.hammer" else "charge_hook_rolling"
 if lab.frame_mods.get(lab.roll_index,"")==CHARGE and lab.lane.tracker!=null and lab.lane.tracker.tick>5 and not captures.has(capture_key):
  captures[capture_key]=true
  var body:RigidBody3D=lab.lane.ball;var physical:=_physical(body)
  preload("res://src/presentation/modification_art.gd").dress(body,CHARGE,charge_host)
  _check(_physical(body)==physical and body.get_node("ModificationOverlay").item_id==CHARGE,"cosmetic charge preserves rolling physics")
  await _capture(capture_key)
func _observe_row(step:Dictionary,index:int,skipped:bool) -> void:
 var history:Array=lab.motion.abilities.history
 for cue in history.slice(observed_count):
  if cue.id not in wanted:continue
  observed_rows.append({"index":index,"phase":step.phase,"text":step.text,"cue":cue.duplicate(true),"skipped":skipped})
  if cue.id==LANTERN:
   _check(step.phase=="standing" and step.pin==6 and step.text.contains("Lantern"),"exact native standing row")
  else:
   var row:=preload("res://src/presentation/ability_score_rows.gd").at(lab.scored_frames[-1],index)
   _check(row.has("event") and row.event.get("cause","")=="roll:%d"%cue.details.roll and row.event.repeat==cue.details.repeat and step.pin==cue.details.position,"Charge tied to actual repeated row/cause/slot")
  if not skipped:_check(lab.motion.abilities.counted_rack_positions()==cue.details.positions,"actual counted or repeated slot outlines")
 observed_count=history.size()
func _play_batch() -> void:
 for i in 12:await process_frame
 var pin:RigidBody3D=lab.lane.pins[6];var physical:=_physical(pin)
 var lantern=pin.get_node("ModificationOverlay")
 _check(lantern.item_id==LANTERN and lantern.lit and lantern.flame.visible,"actual standing lantern lit")
 _check(pin.get_meta("art_item_id")=="pin.wood" and _physical(pin)==physical,"Lantern keeps Wood body/physics")
 _check(lantern.find_children("*","CollisionObject3D",true,false).is_empty() and lantern.find_children("*","CollisionShape3D",true,false).is_empty(),"lantern is cosmetic")
 await _detail(pin,Vector3(.15,.34,.72),Vector3(0,.19,0),"pin_mod_lantern_host_detail")
 pin=null;lantern=null
 await _arm_mod(CHARGE)
 var full:=await _mod_frame([GUTTER,GUTTER],[0,0],"charged gutter, ten standing")
 _check(_ids()==[LANTERN] and frame_cues[0].details.count==10,"missed charge quiet, exact ten standing")
 await _next_frame();await _arm_mod(CHARGE)
 var charged:=await _mod_frame([STRIKE],[0],"charged Hammer strike")
 _charge_result(charged)
 await _controls(charged)
 var dark=lab.lane.pins[6].get_node("ModificationOverlay")
 _check(not dark.lit and not dark.flame.visible,"actual fallen lantern extinguishes, no flash")
 await _capture("lantern_unlit")
 dark=null
 await _next_frame()
 var partial:=await _mod_frame([LEAVE,GUTTER],[0,0],"partial standing rack")
 _check(lab.motion.abilities.glyph.still,"native Lantern reduced state stays static")
 _check(partial.result.category=="open" and _ids()==[LANTERN] and frame_cues[0].details.count>0 and frame_cues[0].details.count<10,"partial actual standing count")
 await _focus_accept(scene.options);await _focus_accept(lab.settings_panel.reduced_motion);await _focus_accept(lab.settings_panel.reduced_flash);await _focus_accept(lab.settings_panel.close)
 await _next_frame();await _arm_mod(CHARGE)
 _charge_result(await _mod_frame([STRIKE],[0],"second charged strike"))
 await _purchase_hook_charge()
 host_refs[CHARGE]=hook_ref;charge_host="ball.hook"
 await _arm_mod(CHARGE)
 _charge_result(await _mod_frame([STRIKE],[0],"charged Hook strike"))
 _check(captures.has("charge_rolling") and captures.has("charge_hook_rolling"),"both compatible rolling hosts captured")
 _check(captures.has("lantern_reduced"),"actual static standing count captured")
func _charge_result(scored:Dictionary) -> void:
 _check(scored.result.category=="strike" and _ids()==[CHARGE],"one Charge cue; fallen Lantern quiet")
 if not frame_cues.is_empty():
  var cue:Dictionary=frame_cues[0]
  _check(cue.details.position==scored.frame.rolls[0].first_direct and cue.details.count==1 and scored.result.retriggers==1,"actual first-direct slot and one repeat")
func _mod_frame(shots:Array,spins:Array,label:String) -> Dictionary:
 var loadout:Dictionary=lab.run.loadout();var context:Dictionary=lab.frame_context()
 var before:int=lab.history.size();var start:int=lab.motion.abilities.history.size()
 var uid:String=lab.armed_ball;var mod:String=lab.run.card_mod(uid)
 for i in shots.size():
  if i>0 and Builder.is_complete(lab.frame_reports):break
  await _throw(shots[i],spins[i])
  if i==0 and mod==CHARGE:_check(lab.frame_mods.get(1,"")==CHARGE and uid in lab.equipment.discard and uid not in lab.equipment.hand,"actual charged UID consumed")
 var scored:=await _scored();var extras:={}
 for roll in lab.frame_mods:extras[roll]=[lab.frame_mods[roll]]
 var built:=Builder.build(loadout,lab.content.catalogue,lab.history.slice(before),extras,context)
 var expected:=Rules.resolve(built.frame)
 _check(built.ok and expected.score==scored.banked and expected.facts==scored.result.facts,"independent native bank/facts "+label)
 frame_cues=lab.motion.abilities.history.slice(start).filter(func(e):return e.id in wanted)
 var standing:=range(1,11).filter(func(p):return not scored.frame.rolls.any(func(r):return p in r.fallen_positions))
 for cue in frame_cues:
  if cue.id==LANTERN:_check(cue.details.positions==standing and cue.details.count==standing.size() and cue.details.amount==standing.size(),"actual standing rack and Mult agree")
 checks.append({"label":label,"bank":scored.banked,"facts":scored.result.facts,"standing":standing,"cues":frame_cues.duplicate(true)});metrics.append(lab.motion.metrics())
 print(batch," ",label," bank=",scored.banked," standing=",standing," cues=",_ids())
 return scored

func _hand_for(ids:Array) -> void:
 var uids:Array=ids.map(func(id):return String(host_refs[id]).trim_prefix("card:"))
 for seed_value in 256:
  var deck=Deck.create_with(lab.run.deck_cards(),seed_value);deck.start_frame()
  if uids.all(func(uid):return uid in deck.hand):
   lab.equipment=deck;lab.armed_ball="";lab._refresh_hand()
   print(batch," fixture: seeded owned-UID hand ",seed_value," for ",ids)
   return
 _check(false,"bounded owned-UID seed fixture")

func _scored() -> Dictionary:
 for tick in ROLL_FRAMES*3:
  if lab.state in ["scoring","frame_done"]:
   var glyph:Control=lab.motion.abilities.glyph
   if glyph.style!=null and glyph.age<glyph.style.duration and glyph.style.item_id in wanted:
    var id:String=glyph.style.item_id
    if not captures.has(id):
     captures[id]=true;await _capture(id.replace(".","_")+"_activation")
    if id==LANTERN and glyph.still and not captures.has("lantern_reduced"):
     captures.lantern_reduced=true;await _capture("lantern_reduced")
  if lab.state=="frame_done":return lab.scored_frames[-1]
  await process_frame
 _check(false,"C04-C scoring timeout")
 return lab.scored_frames[-1]

func _purchase_hook_charge() -> void:
 # Echo Charge is max_owned=1. Sell its real Hammer host before buying it for
 # another compatible host; do not fabricate duplicates or bypass its limit.
 await _focus_accept(lab.next_rack)
 _check(lab.state=="shop","Division 2 shop for legal host replacement")
 var old:String=host_refs[CHARGE];var money:int=lab.run.money;var sale:int=lab.run.sale_value(old)
 await _focus_accept(lab.shop_panel.sell_button(old))
 _check(lab.run.entry_at(old)==null and lab.run.money==money+sale and lab.run.owned_count(CHARGE)==0,"actual sale clears the max-one attachment")
 for gate in lab.run.item(CHARGE).unlock.prerequisites:
  if gate not in lab.shop.unlocked:lab.shop.unlocked.append(gate)
 print(batch," fixture: same Charge unlock gate for second shop; real sale and repurchase")
 lab._refresh_shop()
 for attempt in 160:
  for index in lab.shop.offers.size():
   var offer:Dictionary=lab.shop.offers[index]
   if offer.item_id!=CHARGE or offer.sold:continue
   var hosts:Array=lab.run.mod_hosts(CHARGE)
   for ref in hosts:
    if lab.run.entry_at(ref).item_id=="ball.hook":hook_ref=ref;break
   _check(not hook_ref.is_empty(),"Hook is a real compatible host")
   money=lab.run.money
   await _focus_accept(lab.shop_panel.button_for_offer(index))
   await _focus_accept(lab.shop_panel.choice_button(hosts.find(hook_ref)))
   _check(lab.run.entry_at(hook_ref).mod==CHARGE and lab.run.owned_count(CHARGE)==1 and lab.run.money==money-int(offer.price),"actual Hook attachment respects one-copy limit")
   break
  if not hook_ref.is_empty():break
  await _focus_accept(lab.shop_panel.reroll_button)
 _check(not hook_ref.is_empty(),"second compatible host purchased")
 await _capture("charge_hook_shop")
 await _leave_shop();await _aim()
