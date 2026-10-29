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
 _batch_b(catalogue,failures)
 return failures

static func _batch_b(catalogue:Dictionary,failures:Array[String]) -> void:
 var ids:=["charm.sweet_spot","charm.back_row","charm.underdog"]
 for grades in [["clean","miss"],["sweet","clean"],["sweet","perfect"]]:
  for context in [{"match_score":149,"match_target":300},{"match_score":150,"match_target":300},{"match_score":151,"match_target":300},{"match_score":0,"match_target":0}]:
   var reports:=Slice._open([7,9],[])
   for i in reports.size():reports[i].roll_result.accuracy=grades[i]
   var result:=Slice._score(catalogue,Slice._loadout({},ids),reports,context)
   var before:=JSON.stringify(result)
   var cues:=[]
   for event in result.events:cues.append_array(Events.project(result.frame,event,result.facts))
   var sweet:Array=cues.filter(func(e):return e.id==ids[0])
   var count:int=grades.filter(func(g):return g in ["sweet","perfect"]).size()
   if sweet.size()!=(1 if count>0 else 0):failures.append("Sweet Spot eligibility")
   elif count>0 and (sweet[0].count!=count or sweet[0].accurate!=count or sweet[0].grades!=grades or sweet[0].amount!=3*count):failures.append("Sweet Spot actual grades and count")
   var back:Array=cues.filter(func(e):return e.id==ids[1])
   if back.size()!=1 or back[0].count!=2 or back[0].positions!=[7,9]:failures.append("Back Row highlights only fallen slots 7 and 9")
   var under:Array=cues.filter(func(e):return e.id==ids[2])
   var behind:bool=context.match_target>0 and context.match_score*2<context.match_target
   if under.size()!=(1 if behind else 0):failures.append("Underdog half-target/Practice boundary")
   elif behind and (under[0].match_score!=context.match_score or under[0].match_target!=context.match_target or not under[0].behind):failures.append("Underdog authoritative comparison")
   if JSON.stringify(result)!=before:failures.append("C03-B projection mutated resolver")
