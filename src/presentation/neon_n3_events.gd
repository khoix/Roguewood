extends RefCounted
## Attribution only: the resolver decides whether a Line Call reward exists.
static func project(event: Dictionary, owners: Dictionary) -> Array:
 var source: String = event.get("source", "")
 var ids: Array = owners.get(source, [])
 var index := int(event.get("effect_index", -1))
 if index < 0 or index >= ids.size() or ids[index] != "consumable.line_call": return []
 if event.get("op", "") != "add_mult" or float(event.get("amount", 0)) <= 0: return []
 return [{"id":"consumable.line_call", "key":"line_call:%s:%s:%d" % [source,event.phase,int(event.get("repeat",0))],
  "phase":event.phase, "amount":float(event.amount), "count":int(event.get("count",1)), "source":source}]
