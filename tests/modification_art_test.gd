extends RefCounted
const Slice=preload("res://tests/slice_test.gd")
const Builder=preload("res://src/rules/frame_builder.gd")
const Rules=preload("res://src/rules/frame_rules.gd")
const Events=preload("res://src/presentation/modification_events.gd")
static func run() -> Array[String]:
 var failures:Array[String]=[]
 var catalogue:Dictionary=preload("res://src/rules/content_set.gd").load_set("slice").catalogue
 var items:={}
 for item in catalogue.items:items[item.id]=item
 for host in ["pin.wood","pin.crown","pin.glass","pin.grower"]:
  var loadout:=Slice._loadout({1:host})
  loadout.pin_mods={1:"pin_mod.brass_cap",3:"pin_mod.gilt_leaf",5:"pin_mod.keystone"}
  var built:=Builder.build(loadout,catalogue,Slice._strike("ball.echo"))
  var result:=Rules.resolve(built.frame)
  var snapshot:={"pin_mods":loadout.pin_mods}
  var before:=JSON.stringify([built,result,snapshot])
  var owners:=Events.owners(built.frame,items,snapshot)
  for source in owners:
   if owners[source]!=built.owners.get(source,[]):failures.append("exact joined ownership "+source)
  var cues:=[];var keys:={}
  for event in result.events:
   var projected:=Events.combine(built.frame,event,owners,result.facts)
   if event.get("source","")=="pin:1" and int(event.get("effect_index",-1))==items[host].effects.size():
    if projected.any(func(c):return c.id==host):failures.append("mod row impersonated base host "+host)
   for cue in projected:
    if not keys.has(cue.key):keys[cue.key]=true;cues.append(cue)
  var ids:=cues.map(func(c):return c.id)
  if ids.count("pin_mod.brass_cap")!=2 or ids.count("ball.echo")!=1:failures.append("exact repeat ownership "+host)
  if ids.count("pin_mod.gilt_leaf")!=1:failures.append("Gilt Leaf one after-bank cue")
  var key:Array=cues.filter(func(c):return c.id=="pin_mod.keystone")
  if key.size()!=1 or key[0].count!=10 or key[0].amount!=40:failures.append("Keystone resolver count/amount")
  if key.size()==1 and key[0].positions!=range(1,11):failures.append("Keystone actual counted rack positions")
  if JSON.stringify([built,result,snapshot])!=before:failures.append("projection mutated authoritative data")
  var missing:=Events.owners(built.frame,items,{})
  if not missing["pin:1"].is_empty():failures.append("mismatched snapshot must refuse guessed ownership")
 for id in ["pin_mod.gilt_leaf","pin_mod.keystone"]:
  var loadout:=Slice._loadout();loadout.pin_mods={1:id}
  var built:=Builder.build(loadout,catalogue,Slice._strike("ball.echo"))
  var owners:=Events.owners(built.frame,items,{"pin_mods":loadout.pin_mods})
  var cues:=[];var keys:={}
  for event in Rules.resolve(built.frame).events:
   for cue in Events.combine(built.frame,event,owners):
    if cue.id==id and not keys.has(cue.key):keys[cue.key]=true;cues.append(cue)
  if cues.size()!=(1 if id=="pin_mod.gilt_leaf" else 2):failures.append("direct-pin repeat/deferred dedup "+id)
 var open_loadout:=Slice._loadout();open_loadout.pin_mods={1:"pin_mod.brass_cap",3:"pin_mod.gilt_leaf",5:"pin_mod.keystone"}
 var partial:=Builder.build(open_loadout,catalogue,Slice._open([1,5,10],[]))
 var partial_owners:=Events.owners(partial.frame,items,{"pin_mods":open_loadout.pin_mods})
 var partial_count:=0
 for event in Rules.resolve(partial.frame).events:
  for cue in Events.project(partial.frame,event,partial_owners):
   if cue.id=="pin_mod.keystone":
    partial_count+=1
    if cue.positions!=[1,5,10] or cue.count!=3 or cue.amount!=12:failures.append("partial Keystone count reflects actual fallen slots")
 if partial_count!=1:failures.append("one partial Keystone activation")
 var quiet:=Builder.build(open_loadout,catalogue,Slice._open([],[]))
 for event in Rules.resolve(quiet.frame).events:
  if not Events.project(quiet.frame,event,Events.owners(quiet.frame,items,{"pin_mods":open_loadout.pin_mods})).is_empty():failures.append("standing mods remain silent")
 _ball_cases(catalogue,items,failures)
 return failures

static func _ball_cases(catalogue:Dictionary,items:Dictionary,failures:Array[String]) -> void:
 var cases:=[
  {"id":"ball_mod.chalk_grip","reports":Slice._spare([1,2,3]),"mods":{1:"ball_mod.chalk_grip",2:"ball_mod.chalk_grip"},"count":2},
  {"id":"ball_mod.chalk_grip","reports":Slice._strike(),"mods":{1:"ball_mod.chalk_grip"},"count":0},
  {"id":"ball_mod.spin_wax","reports":[Slice._rep(1,[1,2,3],Slice.ALL,"ball.hook",.3),Slice._rep(2,[4,5,6,7,8,9,10],[4,5,6,7,8,9,10])],"mods":{2:"ball_mod.spin_wax"},"count":1},
  {"id":"ball_mod.spin_wax","reports":Slice._spare([1,2,3]),"mods":{1:"ball_mod.spin_wax",2:"ball_mod.spin_wax"},"count":0},
  {"id":"ball_mod.coin_slot","reports":Slice._strike("ball.echo"),"mods":{1:"ball_mod.coin_slot"},"count":1},
  {"id":"ball_mod.coin_slot","reports":Slice._spare([1,2,3]),"mods":{1:"ball_mod.coin_slot",2:"ball_mod.coin_slot"},"count":0}]
 for case in cases:
  var extras:={}
  for roll in case.mods:extras[roll]=[case.mods[roll]]
  var built:=Builder.build(Slice._loadout(),catalogue,case.reports,extras)
  var owners:=Events.owners(built.frame,items,{"roll_mods":case.mods})
  for roll in case.mods:
   var source:="roll:%d"%roll
   if owners[source]!=built.owners[source]:failures.append("exact ball modification ownership")
  var cues:=[];var seen:={}
  for event in Rules.resolve(built.frame).events:
   for cue in Events.combine(built.frame,event,owners):
    if cue.id==case.id and not seen.has(cue.key):seen[cue.key]=true;cues.append(cue)
  if cues.size()!=case.count:failures.append("ball modification active/quiet count "+case.id)
  if case.id=="ball_mod.spin_wax" and case.count==1 and (cues.is_empty() or cues[0].source!="roll:2"):failures.append("Wax uses actual equipped roll even when another roll curved")
  if case.id=="ball_mod.coin_slot" and case.count==1 and (cues.is_empty() or cues[0].phase!="after_bank" or cues[0].amount!=2):failures.append("Coin Slot pays once after bank despite host retrigger")
