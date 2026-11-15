extends RefCounted
const C15=preload("res://tests/mechanics_c15_test.gd")
const Slice=preload("res://tests/slice_test.gd")
const Builder=preload("res://src/rules/frame_builder.gd")
const Rules=preload("res://src/rules/frame_rules.gd")
const Mods=preload("res://src/presentation/modification_events.gd")
static func run() -> Array[String]:
 var failures:Array[String]=[]
 var catalogue:Dictionary=preload("res://src/rules/content_set.gd").load_set("slice").catalogue
 var items:Dictionary={}
 for item in catalogue.items:items[item.id]=item
 var loadout:Dictionary=Slice._loadout({1:"pin.prism",2:"pin.prism"},["charm.afterimage","charm.laser_level"])
 loadout["pin_mods"]={1:"pin_mod.spotlight"}
 var scenarios:=[
  {"reports":[C15._rep(1,C15.ALL,C15.ALL,"ball.glow",.5)],"expected":{"pin.prism":[25.0,25.0],"pin_mod.spotlight":[3.0],"ball.glow":[5.0]}},
  {"reports":[C15._rep(1,C15.ALL,C15.ALL,"ball.glow",0.0)],"expected":{"charm.laser_level":[50.0]}},
  {"reports":[C15._rep(1,[2,3,4,5,6,7,8,9,10],C15.ALL),C15._rep(2,[1],[1],"ball.house",.5)],"expected":{"pin.prism":[25.0],"pin_mod.spotlight":[3.0],"charm.afterimage":[1.5]}},
  {"reports":[C15._rep(1,[2,1,3,4,5,6,7,8,9,10],C15.ALL,"ball.glow",.5)],"expected":{"pin.prism":[25.0,25.0],"ball.glow":[5.0]}}
 ]
 var ids:=["ball.glow","pin.prism","pin_mod.spotlight","charm.afterimage","charm.laser_level"]
 for scenario in scenarios:
  var built:Dictionary=Builder.build(loadout,catalogue,scenario.reports,{}, {})
  var result:Dictionary=Rules.resolve(built.frame)
  var before:=JSON.stringify([built.frame,result])
  var owners:Dictionary=Mods.owners(built.frame,items,{"pin_mods":loadout.pin_mods})
  var cues:Array=[]
  for event in result.events:cues.append_array(Mods.combine(built.frame,event,owners,result.facts))
  for id in ids:
   var actual:Array=cues.filter(func(c):return c.id==id).map(func(c):return c.amount)
   if actual!=scenario.expected.get(id,[]):failures.append("Exact qualifying cues %s: %s"%[id,str(actual)])
  for cue in cues:
   if cue.id=="charm.laser_level" and (cue.count!=10 or cue.positions.size()!=10):failures.append("Laser Level exact fallen count")
  if before!=JSON.stringify([built.frame,result]):failures.append("N2 projection mutated authoritative data")
 return failures
