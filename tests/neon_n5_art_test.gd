extends RefCounted
const C15 = preload("res://tests/mechanics_c15_test.gd")
const C19 = preload("res://tests/mechanics_c19_test.gd")
const Slice = preload("res://tests/slice_test.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const Mods = preload("res://src/presentation/modification_events.gd")
const N5 = preload("res://src/presentation/neon_n5_events.gd")
static func run() -> Array[String]:
 var failures: Array[String] = []
 var catalogue: Dictionary = preload("res://src/rules/content_set.gd").load_set("neon").catalogue
 var items := {}
 for item in catalogue.items: items[item.id] = item
 var ids := ["pin.compass","charm.split_pattern","charm.dry_run","charm.long_game","charm.second_chance"]
 var loadout: Dictionary = Slice._loadout({1:"pin.compass"},ids.slice(1))
 var cases := [
  {"lane":C19.TWO_TONE,"rolls":[C19._left(C15._rep(1,C15.ALL,C15.ALL))],"amounts":{"pin.compass":[25.0],"charm.split_pattern":[2.0],"charm.dry_run":[10.0]}},
  {"lane":C19.LONG,"rolls":[C15._rep(1,C15.ALL,C15.ALL,"ball.house",0.75)],"amounts":{"pin.compass":[25.0],"charm.long_game":[1.5]}},
  {"lane":"lane.house","rolls":[C15._rep(1,[1,2,3,4,5,6],C15.ALL,"ball.house",0.0,"clean",true),C15._rep(2,[7,8,9,10],[7,8,9,10])],"amounts":{"charm.second_chance":[1.5]}},
  {"lane":"lane.house","rolls":[C15._rep(1,[1,2,3,4,5,6],C15.ALL),C15._rep(2,[7,8,9,10],[7,8,9,10])],"amounts":{}},
  {"lane":C19.LONG,"rolls":[C19._left(C15._rep(1,[1,2,3],C15.ALL)),C15._rep(2,[4,5],[4,5,6,7,8,9,10])],"amounts":{"pin.compass":[25.0],"charm.dry_run":[5.0]}}
 ]
 for scenario in cases:
  var built: Dictionary = Builder.build(loadout,catalogue,scenario.rolls,{}, {"lane_condition":scenario.lane})
  var result: Dictionary = Rules.resolve(built.frame)
  var original := JSON.stringify([built.frame,result])
  var owners: Dictionary = Mods.owners(built.frame,items,{})
  var cues: Array = []
  for event in result.events:
   cues.append_array(Mods.combine(built.frame,event,owners,result.facts))
   cues.append_array(N5.project(event,owners))
   if not N5.project(event,{}).is_empty(): failures.append("AV-N5 Compass without exact ownership")
  for id in ids:
   var amounts: Array = cues.filter(func(c): return c.id == id).map(func(c): return c.amount)
   if amounts != scenario.amounts.get(id,[]): failures.append("AV-N5 exact rewards %s / %s: %s" % [scenario.lane,id,str(amounts)])
  for cue in cues:
   if cue.id == "charm.dry_run" and cue.count != int(cue.amount): failures.append("AV-N5 tally count differs from actual fallen count")
  if JSON.stringify([built.frame,result]) != original: failures.append("AV-N5 mutated authoritative input")
 return failures
