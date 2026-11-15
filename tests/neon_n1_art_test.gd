extends RefCounted
const C15=preload("res://tests/mechanics_c15_test.gd")
const Slice=preload("res://tests/slice_test.gd")
const Builder=preload("res://src/rules/frame_builder.gd")
const Rules=preload("res://src/rules/frame_rules.gd")
const Events=preload("res://src/presentation/ability_events.gd")
static func run() -> Array[String]:
 var failures:Array[String]=[]
 var catalogue:Dictionary=preload("res://src/rules/content_set.gd").load_set("slice").catalogue
 for grades in [["clean","miss"],["sweet","clean"],["perfect","sweet"]]:
  var count:int=grades.filter(func(g):return g in ["sweet","perfect"]).size()
  var loadout:Dictionary=Slice._loadout({1:"pin.tempo"},["charm.neon_sign"])
  var reports:=[C15._rep(1,[1,2,3,4,5,6],C15.ALL,"ball.laser",.5,grades[0]),C15._rep(2,[7,8,9,10],[7,8,9,10],"ball.house",.5,grades[1])]
  var built:Dictionary=Builder.build(loadout,catalogue,reports,{}, {})
  var frame:Dictionary=built.frame
  var result:Dictionary=Rules.resolve(frame)
  var before:=JSON.stringify([frame,result])
  var cues:Array=[]
  for event in result.events:cues.append_array(Events.project(frame,event,result.facts))
  for spec in [["pin.tempo",20],["ball.laser",3],["charm.neon_sign",4]]:
   var paid:Array=cues.filter(func(c):return c.id==spec[0])
   if count==0:
    if not paid.is_empty():failures.append("No accuracy cue on clean/miss "+spec[0])
   elif paid.size()!=1 or paid[0].count!=count or paid[0].amount!=count*spec[1] or paid[0].accurate!=count or paid[0].grades!=grades:
    failures.append("Exact accurate count/amount/grades "+spec[0])
  if before!=JSON.stringify([frame,result]):failures.append("Art projection mutated authoritative data")
 # Attachment ownership: a modification must not activate the host's reward.
 var items:Dictionary={}
 for item in catalogue.items:items[item.id]=item
 var mods=preload("res://src/presentation/modification_events.gd")
 for spec in [["ball_mod.blacklight",.5,false,1.5],["ball_mod.blacklight",0.0,false,0.0],["ball_mod.bumper_guard",0.0,true,2.0],["ball_mod.bumper_guard",0.0,false,0.0]]:
  var reports:=[C15._rep(1,C15.ALL,C15.ALL,"ball.house",spec[1],"clean",spec[2])]
  var built:Dictionary=Builder.build(Slice._loadout(),catalogue,reports,{1:[spec[0]]},{})
  var result:Dictionary=Rules.resolve(built.frame)
  var before:=JSON.stringify([built.frame,result])
  var owners:Dictionary=mods.owners(built.frame,items,{"roll_mods":{1:spec[0]}})
  var cues:Array=[]
  for event in result.events:cues.append_array(mods.combine(built.frame,event,owners,result.facts))
  var paid:Array=cues.filter(func(c):return c.id==spec[0])
  if spec[3]==0.0:
   if not paid.is_empty():failures.append("Ineligible attachment cue "+spec[0])
  elif paid.size()!=1 or absf(paid[0].amount)!=spec[3]:failures.append("Exact attachment reward "+spec[0])
  if before!=JSON.stringify([built.frame,result]):failures.append("Attachment projection mutated data")
 return failures
