extends RefCounted
## ScoreLog inserts explanatory zero rows before accuracy. Map display rows back
## to resolver events without parsing display text, inventing events or rescoring.
static func at(scored: Dictionary, index: int) -> Dictionary:
 var frame: Dictionary = scored.get("frame", {})
 var result: Dictionary = scored.get("result", {})
 var events: Array = result.get("events", [])
 var facts: Dictionary = result.get("facts", {})
 var zeros: Array = []
 for pin in frame.get("pins", []):
  var position := int(pin.position)
  var fell: bool = frame.get("rolls", []).any(func(r): return position in r.fallen_positions)
  if fell and position != int(facts.get("last_fallen", 0)) and pin.effects.any(func(e): return e.get("condition", {}).get("last_fallen") == "self"):
   zeros.append(pin)
 var insertion := -1
 for i in events.size():
  if events[i].phase == "accuracy":
   insertion = i
   break
 if insertion >= 0 and index >= insertion and index < insertion + zeros.size():
  var pin: Dictionary = zeros[index-insertion]
  return {"zero": pin.item_id, "position": int(pin.position)}
 var event_index := index - zeros.size() if insertion >= 0 and index >= insertion else index
 if event_index < 0 or event_index >= events.size(): return {}
 return {"event": events[event_index], "event_index": event_index}
