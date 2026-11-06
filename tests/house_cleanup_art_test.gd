extends RefCounted
const Slice=preload("res://tests/slice_test.gd")
const Builder=preload("res://src/rules/frame_builder.gd")
const Rules=preload("res://src/rules/frame_rules.gd")
const Events=preload("res://src/presentation/ability_events.gd")
static func run() -> Array[String]:
 var failures:Array[String]=[]
 var catalogue:Dictionary=preload("res://src/rules/content_set.gd").load_set("slice").catalogue
 for leave in [1,2,3,10]:
  var reports:=Slice._spare(range(1,11-leave))
  var built:=Builder.build(Slice._loadout({},["charm.cleanup_crew"]),catalogue,reports)
  var result:=Rules.resolve(built.frame)
  var before:=JSON.stringify([built,result])
  var cues:=[]
  for event in result.events:
   cues.append_array(Events.project(built.frame,event,result.facts).filter(func(c):return c.id=="charm.cleanup_crew"))
  if cues.size()!=(0 if leave==1 else 1):failures.append("Crew threshold at leave %d"%leave)
  if cues.size()==1 and (cues[0].leave!=leave or cues[0].required!=2 or cues[0].amount!=5 or cues[0].positions!=range(11-leave,11)):failures.append("Crew exact first-roll leave at %d"%leave)
  if before!=JSON.stringify([built,result]):failures.append("Crew projection changes authoritative data")
 for down in [0,6,7,8,9]:
  var built:=Builder.build(Slice._loadout({},["charm.lucky_seven","charm.cleanup_crew"]),catalogue,Slice._open(range(1,down+1),[]))
  var result:=Rules.resolve(built.frame)
  var cues:=[]
  for event in result.events:cues.append_array(Events.project(built.frame,event,result.facts).filter(func(c):return c.id in ["charm.lucky_seven","charm.cleanup_crew"]))
  if cues.size()!=(1 if down==7 else 0):failures.append("Lucky Seven exact open-frame gate: %d down"%down)
  if cues.size()==1 and (cues[0].id!="charm.lucky_seven" or cues[0].face!=7 or cues[0].standing!=3 or cues[0].down!=7 or cues[0].amount!=7):failures.append("Lucky Seven counted die details")
 for reports in [Slice._strike(),Slice._spare([1,2,3,4,5,6,7])]:
  var built:=Builder.build(Slice._loadout({},["charm.lucky_seven"]),catalogue,reports)
  for event in Rules.resolve(built.frame).events:
   if Events.project(built.frame,event).any(func(c):return c.id=="charm.lucky_seven"):failures.append("Lucky Seven cannot light on strike or spare")
 return failures
