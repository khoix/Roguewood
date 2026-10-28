extends RefCounted
## Pure causal projection. Resolver events are read, never changed or re-scored.
static func owner(frame: Dictionary, source: String) -> String:
	var parts := source.split(":")
	if parts.size() != 2: return ""
	var index := int(parts[1])
	match parts[0]:
		"pin":
			for pin in frame.get("pins",[]):
				if int(pin.position) == index: return pin.item_id
		"roll":
			for roll in frame.get("rolls",[]):
				if int(roll.roll_index) == index: return roll.ball_id
		"charm":
			var charms: Array = frame.get("charms",[])
			if index > 0 and index <= charms.size(): return charms[index-1].item_id
	return ""
static func project(frame: Dictionary, event: Dictionary) -> Array:
	var out: Array = []
	var source: String = event.get("source", "")
	var id := owner(frame,source)
	var phase: String = event.get("phase", "")
	var op: String = event.get("op", "")
	var repeat := int(event.get("repeat",0))
	var key := "%s:%s:%s:%d" % [id,source,phase,repeat]
	var eligible := id.begins_with("charm.") and float(event.get("amount",0)) != 0
	if id == "pin.grower": eligible = phase == "after_bank" and op == "grow_value"
	elif id == "pin.gold": eligible = phase == "after_bank" and op == "payout"
	elif id == "pin.anchor": eligible = phase == "standing"
	elif id in ["pin.wood","pin.ruby","pin.rubber"]: eligible = phase == "fallen"
	if eligible:
		out.append({"id":id,"key":key,"phase":phase,"count":int(event.get("count",0)),
			"amount":float(event.get("amount",0)),
			"streak":int(frame.get("context",{}).get("strike_streak",0))+1 if id == "charm.hot_streak" else 0})
	if repeat > 0:
		var cause: String = event.get("cause", "")
		var origin := owner(frame,cause)
		if origin == "ball.echo":
			out.append({"id":origin,"key":"%s:%s:%s:%d" % [origin,cause,source,repeat],"phase":"retrigger"})
	return out
