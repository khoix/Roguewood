extends "res://tests/ability_v08_journey.gd"
## AV-C03-A: real shop purchases/binder, then explicitly logged C03 Crown rack.
## Physics reports, resolver facts, events and banks are never fabricated.
const C03_SPLIT := [-0.5,0.0,0.6]
const C03_CONVERT := [0.3,0.0,0.6]
var observed_rows: Array = []
var observed_count := 0

func _batch() -> String: return "AV-C03-A"
func _run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--artifact-dir="): artifact_dir=arg.trim_prefix("--artifact-dir=")
 batch=_batch()
 wanted=JSON.parse_string(FileAccess.get_file_as_string("res://assets/effects/batches.json"))[batch].map(func(row):return row[0])
 root.size=Vector2i(720,1280)
 scene=load("res://src/bootstrap/bootstrap.tscn").instantiate()
 scene.throw_settings={"score_speed":1}
 root.add_child(scene)
 await process_frame
 await _focus_accept(scene.enter)
 await _wait_for(func():return scene.lab!=null and scene.lab.state=="aim","C03 ready")
 lab=scene.lab
 lab.trial_log_path=""
 await _toggle_assist()
 await _arm("ball.echo")
 await _throw(STRIKE)
 await _scored()
 await _to_shop("C03 identity")
 await _purchase()
 await _binder()
 await _play_batch()
 for id in wanted:
  _check(lab.motion.abilities.history.any(func(e):return e.id==id and not e.skipped and e.audio_played),"native cue and actual audio start: "+id)
  _check(captures.has(id),"native activation capture: "+id)
 _check(lab.motion.sound.max_active<=4,"four-voice bound")
 var report={"batch":batch,"checks":checks,"motion":metrics,"audio":{"played":lab.motion.sound.played,"max_active":lab.motion.sound.max_active},"events":lab.motion.abilities.history,"rows":observed_rows}
 var file:=FileAccess.open(artifact_dir.path_join("metrics.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"\t"));file.close()
 if "--inject-failure" in OS.get_cmdline_user_args():_check(false,"Injected AV-C03 diagnostic failure")
 if failures.is_empty():print("ROGUEWOOD_AV_C03_OK "+batch)
 for i in 8:await process_frame
 quit(0 if failures.is_empty() else 1)

func _purchase() -> void:
 lab.run.credit(100000,"fixture: bounded C03 art offer sampling")
 lab.shop.division=3
 for id in wanted:
  for gate in lab.run.item(id).unlock.prerequisites:
   if gate not in lab.shop.unlocked:lab.shop.unlocked.append(gate)
 print(batch," fixture: wallet, Division 3 offer eligibility and unlock gates; actual purchase follows")
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
   var money:int=lab.run.money
   await _focus_accept(button)
   if id=="pin.crown":
    _check(lab.shop_panel.choice_sheet.visible,"Crown placement sheet")
    await _focus_accept(lab.shop_panel.choice_button(5))
    _check(lab.run.rack[6].item_id==id,"Crown bought into slot six")
    _check(lab.shop_panel.rack_label.text.contains("6 Crown Pin"),"owned rack names Crown")
   else:
    _check(lab.run.charms.any(func(e):return e.item_id==id),"owned Charm "+id)
   _check(lab.shop.offers[index].sold and lab.run.money==money-int(offer.price),"real payment "+id)
   bought[id]=true
  if bought.size()==wanted.size():break
  await _focus_accept(lab.shop_panel.reroll_button)
 _check(bought.size()==wanted.size(),"seeded shop offered all three")
 await _capture("owned_shop")
 await _leave_shop()
 await _aim()
 for i in 12:await process_frame
 for id in wanted:
  if id.begins_with("charm."):
   var panel:Node=lab.motion.equipment_art.get_node_or_null(id.replace(".","_"))
   _check(panel!=null and panel.get_node("Body/Identity").texture==Assets.slot(id,"icon"),"owned inventory icon "+id)
  else:_crown_body(6)
 await _capture("inventory")

func _binder() -> void:
 await _focus_accept(scene.back)
 await _wait_for(func():return scene.screen=="menu","binder menu")
 await _focus_accept(scene.clubhouse.tab_buttons.binder)
 for id in wanted:
  await _focus_accept(scene.clubhouse.filter_button("pin" if id.begins_with("pin.") else "charm"))
  await _focus_accept(scene.clubhouse.entry_button(id))
  for i in 8:await process_frame
  var holder:Control=scene.clubhouse.binder_art
  _check(holder.get_child_count()==1 and holder.get_child(0).texture==Assets.slot(id,"card"),"binder exact card "+id)
  await _capture(id.replace(".","_")+"_binder")
 await _focus_accept(scene.clubhouse.tab_buttons.board)
 await _focus_accept(scene.continue_button)
 await _wait_for(func():return scene.lab!=null and scene.lab.state=="aim","continue owned rack")
 lab=scene.lab
 lab.trial_log_path=""
 lab.score_panel.step_revealed.connect(_observe_row)

func _observe_row(step:Dictionary,index:int,skipped:bool) -> void:
 var history:Array=lab.motion.abilities.history
 for cue in history.slice(observed_count):
  if cue.id not in wanted:continue
  observed_rows.append({"index":index,"phase":step.phase,"pin":step.get("pin",0),"text":step.text,"cue":cue.duplicate(true),"skipped":skipped})
  if cue.id=="pin.crown":
   _check(step.phase=="fallen" and step.pin==cue.details.position,"Crown cue aligned to exact pin row")
  else:
   _check(step.phase=="charm" and step.text.contains(lab.run.item(cue.id).name),"Charm cue aligned to its own explanation row: "+cue.id)
 observed_count=history.size()

func _controls(scored:Dictionary) -> void:
 var expected:Array=frame_cues.map(func(e):return [e.id,e.event,e.details])
 var start:int=lab.motion.abilities.history.size()
 await super._controls(scored)
 var replay:Array=lab.motion.abilities.history.slice(start).filter(func(e):return e.id in wanted)
 _check(replay.size()>=expected.size(),"4x retains every batch cue")
 if replay.size()>=expected.size():
  _check(replay.slice(0,expected.size()).map(func(e):return [e.id,e.event,e.details])==expected,"4x preserves exact Crown/count order")

func _play_batch() -> void:
 _check(lab.run.place("pin.crown",0,"rack:8").is_empty(),"logged fixture: second Crown at eight")
 print("AV-C03-A fixture: second Crown at 8, matching J03C03; Crown 6 and both Charms were purchased")
 lab._new_roll(false)
 await _aim()
 var physical:={}
 for position in [6,8]:
  var body:RigidBody3D=lab.lane.pins[position]
  physical[position]=_physical(body)
  _crown_body(position)
  preload("res://src/presentation/pin_identity.gd").dress(body,"pin.crown")
  _check(_physical(body)==physical[position],"idempotent Crown dressing preserves physical body")
 var camera:Transform3D=lab._camera.transform
 lab._camera.position=Vector3(0.15,0.85,-16.1)
 lab._camera.look_at(Vector3(0,0.12,-18.5))
 for i in 12:await process_frame
 await _capture("crown_rack_detail")
 lab._camera.transform=camera
 var first:=await _frame([C03_SPLIT,C03_CONVERT],"converted split")
 _check(first.result.category=="spare" and first.result.facts.leave==4,"real four-pin leave converted")
 _crown_results(first,8,6)
 _check(_ids().count("charm.split_specialist")==1,"Split Specialist at its own row")
 await _controls(first)
 await _next_frame()
 var second:=await _frame([STRIKE],"Crown six last")
 _crown_results(second,6,8)
 _check(not _ids().has("charm.split_specialist"),"strike has no Split cue")
 await _next_frame()
 await _frame([GUTTER,GUTTER],"no fallen Crown, no converted split")
 _check(_ids().is_empty(),"all three stay quiet when conditions fail")

func _frame(shots:Array,label:String,spin:float=0.0) -> Dictionary:
 var loadout:Dictionary=lab.run.loadout()
 var context:Dictionary=lab.frame_context()
 var before:int=lab.history.size()
 var start:int=lab.motion.abilities.history.size()
 for shot in shots:await _throw(shot,spin)
 var bodies:={}
 for position in lab.lane.pins:bodies[position]=_physical(lab.lane.pins[position])
 var scored:=await _scored()
 for position in bodies:_check(_physical(lab.lane.pins[position])==bodies[position],"scoring effects preserve actual body, mass and collision")
 var built:=Builder.build(loadout,lab.content.catalogue,lab.history.slice(before),{},context)
 var expected:=Rules.resolve(built.frame)
 _check(built.ok and expected.score==scored.banked,"independent bank "+label)
 _check(expected.facts==scored.result.facts,"same authoritative facts "+label)
 frame_cues=lab.motion.abilities.history.slice(start).filter(func(e):return e.id in wanted)
 checks.append({"label":label,"bank":scored.banked,"facts":scored.result.facts,"cues":frame_cues.duplicate(true)})
 metrics.append(lab.motion.metrics())
 print(batch," ",label," bank=",scored.banked," facts=",scored.result.facts," cues=",_ids())
 return scored

func _crown_results(scored:Dictionary,paid:int,zero:int) -> void:
 var crowns:Array=frame_cues.filter(func(e):return e.id=="pin.crown")
 _check(crowns.size()==2,"one paid Crown, one explicit zero")
 _check(crowns.any(func(e):return e.details.position==paid and e.details.amount==40 and e.audio_played),"last Crown paid cue and audio")
 _check(crowns.any(func(e):return e.details.position==zero and e.details.get("zero",false) and not e.audio_played),"non-last Crown explicit quiet zero")
 _check(scored.result.facts.last_fallen==paid,"actual last pin")
 var jewels:Array=frame_cues.filter(func(e):return e.id=="charm.crown_jewel")
 _check(jewels.size()==1 and jewels[0].details.last_fallen==paid and jewels[0].details.amount==2,"Jewel shares last Crown outcome")

func _scored() -> Dictionary:
 for tick in ROLL_FRAMES*3:
  if lab.state in ["scoring","frame_done"]:
   var glyph:Control=lab.motion.abilities.glyph
   if glyph.style!=null and glyph.age<glyph.style.duration:
    var id:String=glyph.style.item_id
    var key:=id+"_zero" if glyph.details.get("zero",false) else id
    if id in wanted and not captures.has(key):
     captures[key]=true
     await _capture(key.replace(".","_")+"_activation")
  if lab.state=="frame_done":return lab.scored_frames[-1]
  await process_frame
 _check(false,"C03 scoring timeout")
 return lab.scored_frames[-1]

func _physical(body:RigidBody3D) -> Dictionary:
 var shapes:=[]
 for child in body.get_children():
  if child is CollisionShape3D:shapes.append([child.get_instance_id(),child.shape.get_rid(),child.transform,child.disabled])
 return {"id":body.get_instance_id(),"mass":body.mass,"layer":body.collision_layer,"mask":body.collision_mask,"shapes":shapes}

func _crown_body(position:int) -> void:
 var body:RigidBody3D=lab.lane.pins[position]
 var identity:=body.get_node_or_null("CatalogueIdentity")
 _check(body.get_meta("art_item_id","")=="pin.crown" and identity!=null,"Crown attached to actual body")
 if identity!=null:
  _check(identity.scene_file_path==Assets.slot("pin.crown","in_play").resource_path,"exact Crown identity scene")
  _check(identity.find_children("*","CollisionObject3D",true,false).is_empty() and identity.find_children("*","CollisionShape3D",true,false).is_empty(),"cosmetic Crown has no physics nodes")

func _capture(label:String) -> void:
 if scene.screen=="menu":
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw
   _check(root.get_texture().get_image().save_png(artifact_dir.path_join(label+".png"))==OK,"binder capture")
  return
 await super._capture(label)
