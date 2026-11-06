extends RefCounted
const Slice=preload("res://tests/slice_test.gd")
const Builder=preload("res://src/rules/frame_builder.gd")
const Rules=preload("res://src/rules/frame_rules.gd")
const Events=preload("res://src/presentation/modification_events.gd")
const Tactical=preload("res://src/presentation/house_tactical_events.gd")
static func run() -> Array[String]:
 var failures:Array[String]=[]
 var catalogue:Dictionary=preload("res://src/rules/content_set.gd").load_set("slice").catalogue
 var items:={}
 for item in catalogue.items:items[item.id]=item
 for ball in ["ball.house","ball.echo","ball.workhorse"]:
  for mods in [[],["ball_mod.echo_charge"]]:
   var extras:Array=mods+["consumable.double_take"]
   var built:=Builder.build(Slice._loadout(),catalogue,Slice._strike(ball),{1:extras})
   var result:=Rules.resolve(built.frame)
   var snapshot:={"tactics":{1:["consumable.double_take"]},"roll_mods":{1:mods[0]} if not mods.is_empty() else {}}
   var owners:=Events.owners(built.frame,items,snapshot)
   var before:=JSON.stringify([built,result,snapshot])
   var seen:={};var cues:=[]
   for event in result.events:
    for cue in Events.combine(built.frame,event,owners,result.facts):
     if not seen.has(cue.key):seen[cue.key]=true;cues.append(cue)
   for id in ["ball.echo","ball_mod.echo_charge","consumable.double_take"]:
    var count:int=cues.filter(func(c):return c.id==id).size()
    var expected:=1 if id=="consumable.double_take" or id==ball or id in mods else 0
    if count!=expected:failures.append("exact tactical repeat cause %s with %s/%s: %d"%[id,ball,str(mods),count])
   var double:Array=cues.filter(func(c):return c.id=="consumable.double_take")
   if double.size()==1 and double[0].positions!=[built.frame.rolls[0].first_direct]:failures.append("Double Take outlines the first direct pin")
   if before!=JSON.stringify([built,result,snapshot]):failures.append("tactical projection mutated score state")
 for down in [0,1,5,10]:
  var reports:=Slice._open(range(1,down+1),[]) if down<10 else Slice._strike()
  var built:=Builder.build(Slice._loadout(),catalogue,reports,{1:["consumable.pin_count"]})
  var result:=Rules.resolve(built.frame)
  var owners:=Events.owners(built.frame,items,{"tactics":{1:["consumable.pin_count"]}})
  var cues:=[]
  for event in result.events:cues.append_array(Tactical.project(built.frame,event,owners,result.facts))
  if cues.size()!=(0 if down==0 else 1):failures.append("Pin Count silence/activation at %d"%down)
  elif down>0 and (cues[0].count!=down or cues[0].amount!=5*down or cues[0].positions.size()!=down):failures.append("Pin Count exact count at %d: %s facts=%s"%[down,str(cues),str(result.facts)])
 for reports in [Slice._strike(),Slice._spare([1,2,3]),Slice._open([1],[])]:
  var built:=Builder.build(Slice._loadout(),catalogue,reports,{1:["consumable.called_shot"]})
  var result:=Rules.resolve(built.frame)
  var owners:=Events.owners(built.frame,items,{"tactics":{1:["consumable.called_shot"]}})
  var cues:=[]
  for event in result.events:cues.append_array(Tactical.project(built.frame,event,owners,result.facts))
  var miss:=Tactical.missed(built.frame,owners,result)
  if result.category=="strike":
   if cues.size()!=1 or not miss.is_empty() or cues[0].amount!=2:failures.append("Called Shot lit only on paid strike: %s / %s"%[str(cues),str(miss)])
  elif not cues.is_empty() or miss.size()!=1 or miss[0].lit or not miss[0].zero:failures.append("Called Shot grey, silent miss")
  var missing:=Events.owners(built.frame,items,{})
  if not Tactical.missed(built.frame,missing,result).is_empty():failures.append("missing snapshot must not invent tactical ownership")
 return failures
