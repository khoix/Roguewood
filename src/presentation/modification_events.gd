extends RefCounted
## Exact effect-index ownership from a pre-bank attachment snapshot. Never infer
## an item from its name, art, effect value or current animation. Reject mismatches.
static func owners(frame: Dictionary, items: Dictionary, snapshot: Dictionary) -> Dictionary:
 var out:={}
 for pin in frame.get("pins",[]):
  var mod: String=snapshot.get("pin_mods",{}).get(int(pin.position),"")
  out["pin:%d"%pin.position]=_joined(pin.effects,items.get(pin.item_id,{}),[mod],items)
 for roll in frame.get("rolls",[]):
  var extras:Array=[]
  var mod: String=snapshot.get("roll_mods",{}).get(int(roll.roll_index),"")
  if not mod.is_empty():extras.append(mod)
  extras.append_array(snapshot.get("tactics",{}).get(int(roll.roll_index),[]))
  out["roll:%d"%roll.roll_index]=_joined(roll.effects,items.get(roll.ball_id,{}),extras,items)
 return out
static func _joined(effects:Array,base:Dictionary,extras:Array,items:Dictionary) -> Array:
 var expected:Array=base.get("effects",[]).duplicate(true)
 var ids:Array=expected.map(func(_e):return base.get("id",""))
 for id in extras:
  if String(id).is_empty():continue
  var item:Dictionary=items.get(id,{})
  if item.is_empty():return []
  expected.append_array(item.effects)
  for _e in item.effects:ids.append(id)
 return ids if expected==effects else []
static func project(frame:Dictionary,event:Dictionary,owners_by_source:Dictionary) -> Array:
 var source:String=event.get("source","")
 var ids:Array=owners_by_source.get(source,[])
 var index:=int(event.get("effect_index",-1))
 var out:=[]
 if index>=0 and index<ids.size():
  var id:String=ids[index]
  if id.begins_with("pin_mod.") or id.begins_with("ball_mod."):
   out.append({"id":id,"key":"%s:%s:%s:%d"%[id,source,event.phase,int(event.get("repeat",0))],"phase":event.phase,
    "count":int(event.get("count",1)),"amount":float(event.get("amount",0)),"position":int(source.get_slice(":",1)),"source":source})
   if id=="pin_mod.keystone":
    var positions:Array=[]
    for roll in frame.get("rolls",[]):
     for position in roll.fallen_positions:
      if position not in positions:positions.append(position)
    positions.sort();out[-1]["positions"]=positions
 if int(event.get("repeat",0))>0:
  var cause:String=event.get("cause","")
  for roll in frame.get("rolls",[]):
   if cause!="roll:%d"%roll.roll_index:continue
   var cause_ids:Array=owners_by_source.get(cause,[])
   for i in mini(cause_ids.size(),roll.effects.size()):
    if cause_ids[i]=="ball_mod.echo_charge" and roll.effects[i].op=="retrigger":
     out.append({"id":"ball_mod.echo_charge","key":"charge:%s:%s:%d"%[cause,source,int(event.repeat)],"phase":"retrigger","position":int(source.get_slice(":",1)),"count":int(event.repeat),"amount":1})
 return out
static func combine(frame:Dictionary,event:Dictionary,owners_by_source:Dictionary,facts:Dictionary={}) -> Array:
 var out:=project(frame,event,owners_by_source)
 var source_ids:Array=owners_by_source.get(event.get("source",""),[])
 var index:=int(event.get("effect_index",-1))
 var attached:=index>=0 and index<source_ids.size() and (String(source_ids[index]).begins_with("pin_mod.") or String(source_ids[index]).begins_with("ball_mod."))
 for cue in preload("res://src/presentation/ability_events.gd").project(frame,event,facts):
  # A modification's effect is not its host's effect. A retrigger's cause is
  # independent: Echo must still read when a Crown's only paid row is its mod.
  if not attached or cue.phase=="retrigger":out.append(cue)
 return out
