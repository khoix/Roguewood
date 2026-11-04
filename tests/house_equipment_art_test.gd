extends RefCounted
const Slice=preload("res://tests/slice_test.gd")
const Events=preload("res://src/presentation/ability_events.gd")
static func run() -> Array[String]:
 var failures:Array[String]=[]
 var catalogue:Dictionary=preload("res://src/rules/content_set.gd").load_set("slice").catalogue
 for count in [1,3,10]:
  var reports:=Slice._strike("ball.workhorse")
  # Pure projection supplements J03C10; the resolver is the count authority.
  var frame:Dictionary=Slice._score(catalogue,Slice._loadout(),reports).frame
  var event:={"phase":"ball","source":"roll:1","op":"add_value","amount":2*count,"count":count}
  var before:=JSON.stringify(frame)
  var cues:=Events.project(frame,event)
  if cues.size()!=1 or cues[0].count!=count or cues[0].roll!=1:failures.append("Workhorse count projection")
  if JSON.stringify(frame)!=before:failures.append("projection mutated frame")
 var scored:=Slice._score(catalogue,Slice._loadout({1:"pin.oak"}),Slice._strike("ball.spare_ball"))
 var cues:Array=[]
 for event in scored.events:cues.append_array(Events.project(scored.frame,event,scored.facts))
 if cues.any(func(c):return c.id=="ball.spare_ball"):failures.append("Spare Ball must stay silent on strike")
 if not cues.any(func(c):return c.id=="pin.oak" and c.amount==20):failures.append("Oak fallen cue")
 return failures
