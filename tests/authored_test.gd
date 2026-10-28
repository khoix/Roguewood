extends RefCounted
## E17 authored batches: the shipped batches validate against the catalogue and the
## prospective unlock graph; each rule refuses a mutated copy (price band, resale,
## catalogue clash, recolor, asset IDs, completeness, trigger, batch size, an
## unreachable or circular unlock). Counts and the E18 primitive list are reported.
## Definitions built only from existing frame-rule pieces (D02's seven Charms) are
## also scored through the real FrameBuilder and FrameRules against their trigger text.
const Authored = preload("res://src/content/authored_batches.gd")
const ContentSet = preload("res://src/rules/content_set.gd")
const SliceTest = preload("res://tests/slice_test.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = ContentSet.load_set("slice").catalogue
	var batches: Array = Authored.load_all()
	_expect(batches.size() >= 1 and batches[0].data.batch == "E17-D01", "batch E17-D01 is present", failures)
	_expect(_errors(batches, catalogue).is_empty(), "the shipped batches validate: %s" % str(_errors(batches, catalogue)), failures)
	var d01: Array = batches[0].data.definitions
	_expect(d01.size() == 10 and batches[0].data.landed.size() == 1 and d01.all(func(d): return d.item.completeness.mechanics == false), "D01: ten authored, Glass Pin landed by E18-C02", failures)
	var counts := Authored.counts(catalogue, batches)
	_expect(counts.ball == {"implemented": 4, "authored": 4, "target": 24} and counts.consumable.authored == 3, "counts per category against the targets", failures)
	_expect(Authored.primitives(batches).has("physics.split_ball") and Authored.primitives(batches)["condition.last_fallen"] == ["pin.crown", "charm.crown_jewel"],
		"the E18 primitive list groups items needing the same primitive", failures)
	var d02: Array = batches[1].data.definitions if batches.size() > 1 else []
	_expect(d02.size() == 5 and batches[1].data.landed.size() == 7 and d02.all(func(d): return d.item.category == "charm"), "D02: five Charms authored, seven landed (C01 six, C02 Glass Cutter)", failures)
	_expect(Authored.designs(batches).has("charm.pin_counter") and Authored.designs(batches)["charm.pin_counter"].asset_ids.card == "card.charm.pin_counter",
		"a landed item keeps its design block and asset IDs in the batch", failures)
	_refuses(func(b): b[1].data.landed[0].id = "charm.nowhere", catalogue, "a landed entry names a catalogue item", "a landed entry for an item not in the catalogue", failures)
	_expressible(catalogue, batches, failures)
	_expect(not ContentSet.load_set("slice").catalogue.items.any(func(i): return i.id == "ball.spark"), "authored items stay out of the playable catalogue", failures)
	# Each rule refuses a mutation.
	_refuses(func(b): b[0].data.definitions[0].item.purchase_price = 9; b[0].data.definitions[0].item.resale_price = 4, catalogue, "price $9 outside", "a price outside its rarity band", failures)
	_refuses(func(b): b[0].data.definitions[0].item.resale_price = 1, catalogue, "resale is half the price", "resale not half the price", failures)
	_refuses(func(b): b[0].data.definitions[0].item.id = "ball.echo", catalogue, "already in the catalogue", "an ID already in the catalogue", failures)
	_refuses(func(b): b[0].data.definitions[1].design.primitives = ["physics.impact_burst"]; b[0].data.definitions[1].item.effects = []; b[0].data.definitions[1].item.category = "ball",
		catalogue, "a recolor is not a new type", "two balls with the same behaviour", failures)
	_refuses(func(b): b[0].data.definitions[2].design.asset_ids.erase("in_play"), catalogue, "asset IDs for", "a missing asset slot", failures)
	_refuses(func(b): b[0].data.definitions[2].item.completeness.mechanics = true, catalogue, "no mechanics or integration yet", "claiming mechanics before E18", failures)
	_refuses(func(b): b[0].data.definitions[3].design.trigger = "Pays money.", catalogue, "needs an exact trigger", "a vague trigger", failures)
	_refuses(func(b): b[0].data.definitions[4].item.downside = "", catalogue, "needs a real tradeoff", "a missing tradeoff", failures)
	_refuses(func(b):
		var extra: Array = []
		for i in 2:
			var copy: Dictionary = b[0].data.definitions[0].duplicate(true)
			copy.item.id = "ball.extra_%d" % i
			copy.design.primitives = ["physics.extra_%d" % i]
			extra.append(copy)
		b[0].data.definitions.append_array(extra), catalogue, "1 to 12 definitions", "more than twelve definitions", failures)
	_refuses(func(b): b[0].data.definitions[1].item.unlock.prerequisites = ["gate.nowhere"], catalogue, "requires undeclared gate gate.nowhere", "an unlock on an undeclared gate", failures)
	_refuses(func(b): b[0].data.definitions[0].item.unlock = {"kind": "mastery", "prerequisites": ["gate.mastery_spare_hand"]}; b[0].data.definitions[0].item.incompatibilities = ["ball.nope"],
		catalogue, "invalid incompatibility ball.nope", "an incompatibility naming no item", failures)
	_refuses(func(b): b[0].data.batch = "E17-1", catalogue, "batch id must be E17-Dxx", "a malformed batch id", failures)
	return failures

## The expressible D02 Charms, scored on a Wood rack against their written triggers.
static func _expressible(catalogue: Dictionary, batches: Array, failures: Array[String]) -> void:
	var cat := catalogue.duplicate(true)
	cat.items.append_array(Authored.items(batches))
	var base := func(reports: Array, context: Dictionary = {}, pins: Dictionary = {}) -> Dictionary:
		return SliceTest._score(cat, SliceTest._loadout(pins), reports, context)
	var with := func(charm: String, reports: Array, context: Dictionary = {}, pins: Dictionary = {}) -> Dictionary:
		return SliceTest._score(cat, SliceTest._loadout(pins, [charm]), reports, context)
	var strike: Dictionary = base.call(SliceTest._strike())
	var plus := func(r: Dictionary, k: float) -> int: return int(r.pin_value * (r.mult + k))
	_expect(with.call("charm.pin_counter", SliceTest._strike()).score == plus.call(strike, 10), "Pin Counter: a strike adds +10 Mult", failures)
	var open := SliceTest._open([1, 2, 3], [])
	_expect(with.call("charm.pin_counter", open).score == plus.call(base.call(open), 3), "Pin Counter: three pins add +3 Mult", failures)
	_expect(with.call("charm.hot_streak", SliceTest._strike(), {"strike_streak": 1}).score == plus.call(base.call(SliceTest._strike(), {"strike_streak": 1}), 6)
		and with.call("charm.hot_streak", SliceTest._strike()).score == strike.score, "Hot Streak: +6 Mult from the second strike in a row only", failures)
	var leave := SliceTest._open([1, 2, 3, 4, 5, 6, 7], [])
	_expect(with.call("charm.last_stand", leave).score == plus.call(base.call(leave), 6) and with.call("charm.last_stand", SliceTest._strike()).score == strike.score,
		"Last Stand: three standing add +6 Mult; a strike adds nothing", failures)
	var spare := SliceTest._spare([1, 2, 3, 4, 5, 6, 7])
	var tip: Dictionary = with.call("charm.tip_jar", spare)
	_expect(tip.score == base.call(spare).score and tip.future_effects.any(func(e): return e.op == "payout" and e.amount == 1)
		and not with.call("charm.tip_jar", SliceTest._strike()).future_effects.any(func(e): return e.op == "payout"), "Tip Jar: $1 after a spare, nothing on a strike", failures)
	var curved: Array = SliceTest._strike("ball.house", 0.6)
	_expect(with.call("charm.banana_ball", curved).score == int(base.call(curved).score * 1.5) and with.call("charm.banana_ball", SliceTest._strike()).score == strike.score,
		"Banana Ball: ×1.5 on a curved strike only", failures)
	_expect(with.call("charm.plumb_line", SliceTest._strike()).score == plus.call(strike, 5) and with.call("charm.plumb_line", curved).score == base.call(curved).score,
		"Plumb Line: +5 Mult when no roll curved; nothing after a curve", failures)
	var glass := {1: "pin.glass", 2: "pin.glass"}
	_expect(with.call("charm.glass_cutter", SliceTest._strike(), {}, glass).score == plus.call(base.call(SliceTest._strike(), {}, glass), 8),
		"Glass Cutter: two Glass pins down add +8 Mult", failures)

static func _errors(batches: Array, catalogue: Dictionary) -> Array[String]:
	var graph := ContentSet.career_graph(ContentSet.UNLOCKS, Authored.items(batches))
	return Authored.validate(batches, catalogue, graph.errors)

static func _refuses(change: Callable, catalogue: Dictionary, text: String, label: String, failures: Array[String]) -> void:
	var batches: Array = Authored.load_all().duplicate(true)
	change.call(batches)
	var errors := _errors(batches, catalogue)
	_expect(errors.any(func(e): return e.contains(text)), "%s is refused (%s): %s" % [label, text, str(errors)], failures)

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)
