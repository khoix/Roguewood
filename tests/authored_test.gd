extends RefCounted
## E17 authored batches: the shipped batches validate against the catalogue and the
## prospective unlock graph; each rule refuses a mutated copy (price band, resale,
## catalogue clash, recolor, asset IDs, completeness, trigger, batch size, an
## unreachable or circular unlock). Counts and the E18 primitive list are reported.
const Authored = preload("res://src/content/authored_batches.gd")
const ContentSet = preload("res://src/rules/content_set.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = ContentSet.load_set("slice").catalogue
	var batches: Array = Authored.load_all()
	_expect(batches.size() >= 1 and batches[0].data.batch == "E17-D01", "batch E17-D01 is present", failures)
	_expect(_errors(batches, catalogue).is_empty(), "the shipped batches validate: %s" % str(_errors(batches, catalogue)), failures)
	var d01: Array = batches[0].data.definitions
	_expect(d01.size() == 11 and d01.all(func(d): return d.item.completeness.mechanics == false), "D01: eleven definitions, none claiming mechanics", failures)
	var counts := Authored.counts(catalogue, batches)
	_expect(counts.ball == {"implemented": 4, "authored": 4, "target": 24} and counts.consumable.authored == 3, "counts per category against the targets", failures)
	_expect(Authored.primitives(batches).size() == 11, "eleven new primitives listed for E18", failures)
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
