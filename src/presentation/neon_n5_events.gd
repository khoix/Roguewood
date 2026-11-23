extends RefCounted
## The resolver and exact effect-index ownership decide Compass Pin's payout.
static func project(event: Dictionary, owners: Dictionary) -> Array:
 var source: String = event.get("source", "")
 var ids: Array = owners.get(source, [])
 var index := int(event.get("effect_index", -1))
 if index < 0 or index >= ids.size() or ids[index] != "pin.compass": return []
 if event.get("phase", "") != "fallen" or event.get("op", "") != "add_value" or float(event.get("amount",0)) <= 0: return []
 return [{"id":"pin.compass","key":"n5:%s:%s:%d" % [source,event.phase,int(event.get("repeat",0))],"phase":event.phase,"amount":float(event.amount),"position":int(source.get_slice(":",1)),"source":source}]
