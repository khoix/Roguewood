extends RefCounted
## Resolver attribution only. No reconstructed rewards or eligibility guesses.
static func project(event: Dictionary, owners: Dictionary) -> Array:
 var source: String = event.get("source", "")
 var ids: Array = owners.get(source, [])
 var index := int(event.get("effect_index", -1))
 if index < 0 or index >= ids.size(): return []
 var id: String = ids[index]
 var op: String = {"ball.comet":"add_mult", "consumable.steady_hand":"multiply_mult"}.get(id, "")
 if op.is_empty() or event.get("op", "") != op or float(event.get("amount", 0)) <= 0: return []
 return [{"id":id,"key":"n4:%s:%s:%s:%d" % [id,source,event.phase,int(event.get("repeat",0))],"phase":event.phase,"amount":float(event.amount),"source":source}]
