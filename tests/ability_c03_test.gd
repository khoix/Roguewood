extends RefCounted
const Slice=preload("res://tests/slice_test.gd")
const Rules=preload("res://src/rules/frame_rules.gd")
const Log=preload("res://src/rules/score_log.gd")
const Rows=preload("res://src/presentation/ability_score_rows.gd")
const Events=preload("res://src/presentation/ability_events.gd")
static func run() -> Array[String]:
 var failures:Array[String]=[]
 var catalogue:Dictionary=preload("res://src/rules/content_set.gd").load_set("slice").catalogue
 for last in [6,8,10]:
  var scored:=Slice._score(catalogue,Slice._loadout({6:"pin.crown",8:"pin.crown"},["charm.crown_jewel","charm.split_specialist"]),Slice._spare([1,2,3,4,5,7]))
  var frame:Dictionary=scored.frame
  frame.rolls[-1]["last_fallen"]=last
  var result:=Rules.resolve(frame)
  var steps:=Log.steps(result,frame)
  var before:=JSON.stringify([frame,result,steps])
  var event_index:=0
  var zeros:=[]
  var cues:=[]
  for i in steps.size():
   var row:=Rows.at({"frame":frame,"result":result},i)
   if row.has("zero"):
    zeros.append(row.position)
    if steps[i].pin!=row.position or steps[i].phase!="fallen":failures.append("zero row mismatches structured explanation")
   else:
    if row.get("event_index",-1)!=event_index or row.event!=result.events[event_index]:failures.append("zero rows shifted a later resolver event")
    cues.append_array(Events.project(frame,row.event,result.facts))
    event_index+=1
  if event_index!=result.events.size() or zeros.size()!=(1 if last in [6,8] else 2):failures.append("event/zero row count")
  var crown:Array=cues.filter(func(e):return e.id=="pin.crown")
  var jewel:Array=cues.filter(func(e):return e.id=="charm.crown_jewel")
  if crown.size()!=(1 if last in [6,8] else 0) or jewel.size()!=crown.size():failures.append("Crown/Jewel eligibility")
  if not crown.is_empty() and (crown[0].last_fallen!=last or crown[0].amount!=40 or jewel[0].last_fallen!=last):failures.append("Crown and Jewel must share authoritative last pin")
  var split:Array=cues.filter(func(e):return e.id=="charm.split_specialist")
  if split.size()!=1 or split[0].leave!=4:failures.append("Split leave from resolver facts")
  if not Rows.at({"frame":frame,"result":result},steps.size()).is_empty():failures.append("post-bank extra row must not fabricate an event")
  if JSON.stringify([frame,result,steps])!=before:failures.append("presentation mutated scoring data")
 return failures
