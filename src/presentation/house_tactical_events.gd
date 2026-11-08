extends RefCounted
## Read-only attribution for the three House throw tacticals. Missing ownership
## is rejected. Counts/conditions come from committed resolver events and facts.
const IDS=["consumable.double_take","consumable.called_shot","consumable.pin_count"]
static func repeat_owner(frame:Dictionary,event:Dictionary,owners:Dictionary) -> String:
 var remaining:=int(event.get("repeat",0))
 var position:=int(String(event.get("source","")).get_slice(":",1))
 if remaining<=0 or String(event.get("cause","")).is_empty():return ""
 for pin in frame.get("pins",[]):
  if int(pin.position)==position:remaining-=int(pin.get("retriggers",0))
 if remaining<=0:return ""
 for roll in frame.get("rolls",[]):
  if int(roll.get("first_direct",0))!=position or position not in roll.fallen_positions:continue
  var source:="roll:%d"%roll.roll_index
  var ids:Array=owners.get(source,[])
  if ids.size()!=roll.effects.size():return ""
  for i in roll.effects.size():
   var effect:Dictionary=roll.effects[i]
   if effect.op!="retrigger":continue
   # All currently landed roll retriggers are unconditional. Do not guess at
   # a future conditional grant if its eligibility is absent from the event.
   if not effect.get("condition",{}).is_empty():return ""
   remaining-=int(effect.amount)
   if remaining<=0:return ids[i] if source==event.cause else ""
 return ""
static func project(frame:Dictionary,event:Dictionary,owners:Dictionary,_facts:Dictionary) -> Array:
 var source:String=event.get("source","")
 var ids:Array=owners.get(source,[])
 var index:=int(event.get("effect_index",-1))
 var out:Array=[]
 if index>=0 and index<ids.size() and ids[index] in IDS:
  var id:String=ids[index]
  out.append({"id":id,"key":"%s:%s:%s"%[id,source,event.phase],"phase":event.phase,"source":source,
   "count":int(event.get("count",1)),"amount":float(event.get("amount",0)),"positions":fallen_positions(frame),"lit":true})
 if repeat_owner(frame,event,owners)=="consumable.double_take":
  var position:=int(source.get_slice(":",1))
  out.append({"id":"consumable.double_take","key":"double:%s:%s:%d"%[event.cause,source,event.repeat],"phase":"retrigger",
   "position":position,"positions":[position],"count":1,"repeat":int(event.repeat),"amount":1})
 return out
static func missed(frame:Dictionary,owners:Dictionary,result:Dictionary) -> Array:
 if result.get("category","") in ["","strike"]:return []
 for roll in frame.get("rolls",[]):
  var source:="roll:%d"%roll.roll_index
  if "consumable.called_shot" in owners.get(source,[]):
   return [{"id":"consumable.called_shot","phase":"missed","lit":false,"zero":true,"source":source,"count":0,"amount":0}]
 return []

static func fallen_positions(frame:Dictionary) -> Array:
 var positions:Array=[]
 for roll in frame.get("rolls",[]):
  for position in roll.fallen_positions:
   if position not in positions:positions.append(position)
 positions.sort()
 return positions
