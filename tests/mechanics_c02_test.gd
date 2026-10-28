extends RefCounted
## E18-C02: the transform primitive (Glass Pin breaking) and its landing.
## - FrameRules reports a transform only for fallen pins that carry it, after the
##   bank, never in the score and never repeated by a retrigger.
## - Validation refuses malformed transforms (owner, trigger, amount, into, per).
## - RunInventory rolls each transform once on the attempt's effects stream:
##   seeded, deterministic, saved (a reload continues the same sequence), slot and
##   modification kept, growth and paid price reset; about 20% over many falls.
## - Glass Cutter counts Glass pins; the log names the chance.
const Rules = preload("res://src/rules/frame_rules.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const ContentSet = preload("res://src/rules/content_set.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
const SliceTest = preload("res://tests/slice_test.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = ContentSet.load_set("slice").catalogue
	_resolution(catalogue, failures)
	_refusals(catalogue, failures)
	_rolls(catalogue, failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _glass_rack(positions: Array) -> Dictionary:
	var pins := {}
	for p in positions:
		pins[p] = "pin.glass"
	return pins

static func _resolution(catalogue: Dictionary, failures: Array[String]) -> void:
	var glass := _glass_rack([1, 2, 3])
	var open := SliceTest._open([1, 2, 4, 5], []) # Glass at 1 and 2 fall; Glass at 3 stands
	var r: Dictionary = SliceTest._score(catalogue, SliceTest._loadout(glass), open)
	var transforms: Array = r.future_effects.filter(func(e): return e.op == "transform")
	_expect(transforms.map(func(e): return e.source) == ["pin:1", "pin:2"] and transforms.all(func(e): return int(e.amount) == 20 and e.into == "pin.wood" and e.phase == "after_bank"),
		"transforms are reported for fallen Glass pins only, after the bank: %s" % str(transforms.map(func(e): return e.source)), failures)
	var plain: Dictionary = SliceTest._score(catalogue, SliceTest._loadout(), open)
	_expect(r.score > plain.score and not r.events.any(func(e): return e.get("op") == "transform" and e.phase != "after_bank"), "a transform never changes the bank (only Glass's +30 does)", failures)
	# An Echo Ball strike retriggers the first pin it hits; the transform is still reported once.
	var echo := [SliceTest._rep(1, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], SliceTest.ALL, "ball.echo")] # pin 1 is the first direct knockdown
	var retriggered: Dictionary = SliceTest._score(catalogue, SliceTest._loadout({1: "pin.glass"}), echo)
	_expect(retriggered.retriggers >= 1 and retriggered.future_effects.filter(func(e): return e.op == "transform").size() == 1, "a retriggered Glass pin breaks at most once", failures)
	var cutter: Dictionary = SliceTest._score(catalogue, SliceTest._loadout(glass, ["charm.glass_cutter"]), open)
	_expect(cutter.score == int(r.pin_value * (r.mult + 8)), "Glass Cutter: two Glass pins down add +8 Mult", failures)
	var names := {}
	for item in catalogue.items:
		names[item.id] = item.name
	var built := Builder.build(SliceTest._loadout(glass), catalogue, open)
	var lines: Array = ScoreLog.steps(Rules.resolve(built.frame), built.frame, names, built.owners).map(func(s): return s.text)
	_expect(lines.any(func(l): return l.contains("20% chance to become Wood Pin")), "the log names the chance and the result pin", failures)

static func _refusals(catalogue: Dictionary, failures: Array[String]) -> void:
	var glass: Dictionary = catalogue.items.filter(func(i): return i.id == "pin.glass")[0]
	var mutate := func(change: Callable) -> Array:
		var copy := catalogue.duplicate(true)
		var item: Dictionary = copy.items.filter(func(i): return i.id == "pin.glass")[0]
		change.call(item)
		return Contracts.validate("catalogue", copy)
	_expect(Contracts.validate("catalogue", catalogue).is_empty() and glass.effects.any(func(e): return e.op == "transform"), "the catalogue with Glass validates", failures)
	_expect(not mutate.call(func(i): i.effects[1].amount = 0).is_empty() and not mutate.call(func(i): i.effects[1].amount = 101).is_empty()
		and not mutate.call(func(i): i.effects[1].amount = 12.5).is_empty(), "a transform chance is a whole percent from 1 to 100", failures)
	_expect(not mutate.call(func(i): i.effects[1].into = "pin.nope").is_empty() and not mutate.call(func(i): i.effects[1].into = "pin.glass").is_empty()
		and not mutate.call(func(i): i.effects[1].into = "charm.encore").is_empty(), "a transform names another existing pin", failures)
	_expect(not mutate.call(func(i): i.effects[1].trigger = "standing").is_empty() and not mutate.call(func(i): i.effects[1]["per"] = "fallen").is_empty(),
		"a transform triggers on a fall and is never scaled", failures)
	_expect(not mutate.call(func(i): i.effects[0]["into"] = "pin.wood").is_empty(), "only a transform names an into pin", failures)
	var frame_effect := {"op": "transform", "amount": 20, "trigger": "charm", "scope": "frame", "into": "pin.wood"}
	var charm_frame := Builder.build(SliceTest._loadout({}, ["charm.flat_bonus"]), catalogue, SliceTest._strike())
	charm_frame.frame.charms[0].effects = [frame_effect]
	_expect(not Rules.validate(charm_frame.frame).is_empty(), "FrameRules refuses a transform outside a pin's fall", failures)

## n Glass falls in one frame each, from a seeded run; returns the positions that broke.
static func _break_run(catalogue: Dictionary, seed_value: int, frames: int, inventory = null) -> Array:
	var run = inventory if inventory != null else Inventory.create(catalogue, SliceTest.ALL.map(func(_p): return "pin.glass"), [])
	if inventory == null:
		run.seed_effects(seed_value)
	var broke: Array = []
	for i in frames:
		for position in SliceTest.ALL:
			run.rack[position] = Inventory._entry("pin.glass", 6)
		var built := Builder.build(run.loadout(), catalogue, SliceTest._strike())
		run.apply_frame(Rules.resolve(built.frame), built.frame)
		broke.append(run.transformed.map(func(t): return t.position))
	return broke

static func _rolls(catalogue: Dictionary, failures: Array[String]) -> void:
	var a := _break_run(catalogue, 7, 40)
	var b := _break_run(catalogue, 7, 40)
	var c := _break_run(catalogue, 8, 40)
	_expect(a == b and a != c, "the same attempt seed breaks the same pins; another seed differs", failures)
	var total := 0
	for frame in a + _break_run(catalogue, 9, 60):
		total += frame.size()
	_expect(total >= 150 and total <= 250, "about 20%% of 1000 Glass falls break (%d)" % total, failures)
	# Save mid-sequence: a restored run continues exactly where the saved one would.
	var run = Inventory.create(catalogue, SliceTest.ALL.map(func(_p): return "pin.glass"), [])
	run.seed_effects(11)
	_break_run(catalogue, 0, 5, run)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(run.to_dict()))
	var restored = Inventory.from_dict(saved, catalogue)
	_expect(saved.has("effects_state") and _break_run(catalogue, 0, 10, run) == _break_run(catalogue, 0, 10, restored), "a reload continues the same breaks (no reroll)", failures)
	# A break keeps the slot and modification and resets growth.
	var one = Inventory.create(catalogue, SliceTest.ALL.map(func(_p): return "pin.wood"), [])
	one.seed_effects(3)
	for attempt_frame in 200:
		one.rack[4] = {"item_id": "pin.glass", "paid": 6, "mod": "pin_mod.test", "mod_paid": 2, "growth": 5}
		var built := Builder.build({"pins": {1: "pin.wood", 2: "pin.wood", 3: "pin.wood", 4: "pin.glass", 5: "pin.wood", 6: "pin.wood", 7: "pin.wood", 8: "pin.wood", 9: "pin.wood", 10: "pin.wood"}, "charms": []}, catalogue, SliceTest._strike())
		one.apply_frame(Rules.resolve(built.frame), built.frame)
		if not one.transformed.is_empty():
			break
	_expect(one.rack[4].item_id == "pin.wood" and one.rack[4].mod == "pin_mod.test" and one.rack[4].growth == 0 and one.rack[4].paid == 0
		and one.transformed[0].from == "pin.glass", "a broken Glass pin becomes Wood in place, keeping its modification", failures)
	var legacy = Inventory.from_dict({"money": 6, "match_number": 1, "rack": {}, "reserves": [], "charms": [], "cards": {}, "next_card": 1, "ledger": []}, catalogue)
	_expect(legacy.effects_state == 0 and not legacy.to_dict().has("effects_state"), "older saves without a stream load unchanged", failures)
