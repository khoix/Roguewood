extends RefCounted
const C15 = preload("res://tests/mechanics_c15_test.gd")
const C17 = preload("res://tests/mechanics_c17_test.gd")
const Slice = preload("res://tests/slice_test.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const Mods = preload("res://src/presentation/modification_events.gd")
const N3 = preload("res://src/presentation/neon_n3_events.gd")
static func run() -> Array[String]:
 var failures: Array[String] = []
 var catalogue: Dictionary = preload("res://src/rules/content_set.gd").load_set("slice").catalogue
 var items := {}
 for item in catalogue.items: items[item.id] = item
 var ids := ["charm.dry_side","charm.lane_reader","charm.bounce_back","charm.straight_money","consumable.line_call"]
 var loadout: Dictionary = Slice._loadout({},ids.slice(0,4))
 var scenarios := [
  {"lane":"lane_condition.house_oil","reports":[C15._rep(1,C15.ALL,C15.ALL)],"expected":{"charm.straight_money":[2.0],"consumable.line_call":[4.0]}},
  {"lane":"lane_condition.long_oil","reports":[C17._left(C15._rep(1,C15.ALL,C15.ALL,"ball.house",0.5))],"expected":{"charm.dry_side":[4.0],"charm.lane_reader":[1.5]}},
  {"lane":"lane_condition.long_oil","reports":[C15._rep(1,[1,2,3],C15.ALL,"ball.house",0.0,"clean",true),C15._rep(2,[4,5,6],[4,5,6,7,8,9,10])],"expected":{"charm.bounce_back":[3.0],"consumable.line_call":[4.0]}}
 ]
 for scenario in scenarios:
  var tactics := {1:["consumable.line_call"]}
  var built: Dictionary = Builder.build(loadout,catalogue,scenario.reports,tactics,{"lane_condition":scenario.lane})
  var result: Dictionary = Rules.resolve(built.frame)
  var original := JSON.stringify([built.frame,result])
  var owners: Dictionary = Mods.owners(built.frame,items,{"tactics":tactics})
  var cues: Array = []
  for event in result.events:
   cues.append_array(Mods.combine(built.frame,event,owners,result.facts))
   cues.append_array(N3.project(event,owners))
   if not N3.project(event,{}).is_empty(): failures.append("Line Call without confirmed ownership")
  for id in ids:
   var amounts: Array = cues.filter(func(c): return c.id == id).map(func(c): return c.amount)
   if amounts != scenario.expected.get(id,[]): failures.append("AV-N3 exact paid cues %s: %s" % [id,str(amounts)])
  if JSON.stringify([built.frame,result]) != original: failures.append("AV-N3 mutated authoritative result")
 return failures
