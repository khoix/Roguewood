extends RefCounted
const C15 = preload("res://tests/mechanics_c15_test.gd")
const Slice = preload("res://tests/slice_test.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const Mods = preload("res://src/presentation/modification_events.gd")
const N4 = preload("res://src/presentation/neon_n4_events.gd")
static func run() -> Array[String]:
 var failures: Array[String] = []
 var catalogue: Dictionary = preload("res://src/rules/content_set.gd").load_set("neon").catalogue
 var items := {}
 for item in catalogue.items: items[item.id] = item
 var loadout: Dictionary = Slice._loadout({},["charm.metronome"])
 for test in [[0.5,"sweet",[6.0,2.0,1.5]],[0.5,"clean",[]],[0.0,"perfect",[1.5]]]:
  var tactics := {1:["consumable.steady_hand"]}
  var built: Dictionary = Builder.build(loadout,catalogue,[C15._rep(1,C15.ALL,C15.ALL,"ball.comet",test[0],test[1])],tactics,{})
  var result: Dictionary = Rules.resolve(built.frame)
  var original := JSON.stringify([built.frame,result])
  var owners: Dictionary = Mods.owners(built.frame,items,{"tactics":tactics})
  var cues: Array = []
  for event in result.events:
   cues.append_array(Mods.combine(built.frame,event,owners,result.facts))
   cues.append_array(N4.project(event,owners))
   if not N4.project(event,{}).is_empty(): failures.append("AV-N4 cue without confirmed owner")
  var amounts: Array = cues.filter(func(c): return c.id in ["ball.comet","consumable.steady_hand","charm.metronome"]).map(func(c): return c.amount)
  if amounts != test[2]: failures.append("AV-N4 exact positive/negative payouts %s: %s" % [str(test),str(amounts)])
  if JSON.stringify([built.frame,result]) != original: failures.append("AV-N4 changed authoritative input")
 return failures
