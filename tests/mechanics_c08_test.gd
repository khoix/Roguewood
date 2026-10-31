extends RefCounted
## E18-C08 (DC-H1, E17-D07): six House Charms on existing rule pieces.
## - Head Pin: +30 Value when rack position 1 falls, whatever its material.
## - Wood Grain: +3 Value per Wood Pin down; other pins count nothing.
## - Opening Act: ×2 Mult in a match's first frame only.
## - Open House: +4 Mult on an open frame only.
## - Strike Fund: +$1 after a strike, as frame income; no points.
## - Holdouts: +8 Value per pin standing at the end of the frame.
const ContentSet = preload("res://src/rules/content_set.gd")
const SliceTest = preload("res://tests/slice_test.gd")
const IDS := ["charm.head_pin", "charm.wood_grain", "charm.opening_act", "charm.open_house", "charm.strike_fund", "charm.holdouts"]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var content: Dictionary = ContentSet.load_set("slice")
	var catalogue: Dictionary = content.catalogue
	var items := {}
	for item in catalogue.items:
		items[item.id] = item
	_expect(IDS.all(func(id): return items.has(id) and items[id].category == "charm" and items[id].completeness.mechanics and items[id].unlock.kind == "initial"),
		"the six D07 Charms are in the catalogue with mechanics, in the initial pool", failures)
	_head_pin(catalogue, failures)
	_wood_grain(catalogue, failures)
	_opening_act(catalogue, failures)
	_open_house(catalogue, failures)
	_strike_fund(catalogue, failures)
	_holdouts(catalogue, failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _with(catalogue: Dictionary, charm: String, reports: Array, context: Dictionary = {}, pins: Dictionary = {}) -> Dictionary:
	return SliceTest._score(catalogue, SliceTest._loadout(pins, [charm]), reports, context)

static func _base(catalogue: Dictionary, reports: Array, context: Dictionary = {}, pins: Dictionary = {}) -> Dictionary:
	return SliceTest._score(catalogue, SliceTest._loadout(pins), reports, context)

## The base frame with `value` more Pin Value and `mult` more Mult, times `times`.
static func _plus(catalogue: Dictionary, reports: Array, value: float, mult: float = 0.0, times: float = 1.0, context: Dictionary = {}, pins: Dictionary = {}) -> int:
	var b := _base(catalogue, reports, context, pins)
	return int((b.pin_value + value) * (b.mult + mult) * times)

static func _head_pin(catalogue: Dictionary, failures: Array[String]) -> void:
	var down := SliceTest._open([1, 2, 3], [5])
	_expect(_with(catalogue, "charm.head_pin", down).score == _plus(catalogue, down, 30), "Head Pin: +30 Value when pin 1 falls", failures)
	var ruby := {1: "pin.ruby"}
	_expect(_with(catalogue, "charm.head_pin", down, {}, ruby).score == _plus(catalogue, down, 30, 0, 1, {}, ruby), "whatever its material", failures)
	var later := SliceTest._open([2, 3], [1])
	_expect(_with(catalogue, "charm.head_pin", later).score == _plus(catalogue, later, 30), "and whichever roll knocked it down", failures)
	var standing := SliceTest._open([2, 3, 5], [6])
	_expect(_with(catalogue, "charm.head_pin", standing).score == _base(catalogue, standing).score, "nothing while pin 1 stands", failures)

static func _wood_grain(catalogue: Dictionary, failures: Array[String]) -> void:
	_expect(_with(catalogue, "charm.wood_grain", SliceTest._strike()).score == _plus(catalogue, SliceTest._strike(), 30), "Wood Grain: a Wood strike adds +30 Value", failures)
	var mixed := {1: "pin.ruby", 2: "pin.gold", 3: "pin.glass"}
	_expect(_with(catalogue, "charm.wood_grain", SliceTest._strike(), {}, mixed).score == _plus(catalogue, SliceTest._strike(), 21, 0, 1, {}, mixed),
		"special pins count nothing (seven Wood down: +21)", failures)
	var open := SliceTest._open([1, 2], [3])
	_expect(_with(catalogue, "charm.wood_grain", open).score == _plus(catalogue, open, 9), "three Wood down: +9", failures)

static func _opening_act(catalogue: Dictionary, failures: Array[String]) -> void:
	var strike := SliceTest._strike()
	_expect(_with(catalogue, "charm.opening_act", strike, {"match_frame": 1}).score == _plus(catalogue, strike, 0, 0, 2, {"match_frame": 1}),
		"Opening Act: ×2 in a match's first frame", failures)
	_expect(_with(catalogue, "charm.opening_act", strike, {"match_frame": 2}).score == _base(catalogue, strike, {"match_frame": 2}).score, "nothing in the second", failures)

static func _open_house(catalogue: Dictionary, failures: Array[String]) -> void:
	var open := SliceTest._open([1, 2, 3, 4], [5, 6])
	_expect(_with(catalogue, "charm.open_house", open).score == _plus(catalogue, open, 0, 4), "Open House: +4 Mult on an open frame", failures)
	var spare := SliceTest._spare([1, 2, 3])
	_expect(_with(catalogue, "charm.open_house", spare).score == _base(catalogue, spare).score and _with(catalogue, "charm.open_house", SliceTest._strike()).score == _base(catalogue, SliceTest._strike()).score,
		"nothing on a spare or a strike", failures)

static func _strike_fund(catalogue: Dictionary, failures: Array[String]) -> void:
	var strike := _with(catalogue, "charm.strike_fund", SliceTest._strike())
	var payouts := func(r: Dictionary) -> int:
		return r.future_effects.filter(func(e): return e.op == "payout").reduce(func(n, e): return n + int(e.amount), 0)
	_expect(strike.score == _base(catalogue, SliceTest._strike()).score and payouts.call(strike) == 1, "Strike Fund: a strike pays $1 and scores the same", failures)
	var spare := _with(catalogue, "charm.strike_fund", SliceTest._spare([1, 2]))
	_expect(payouts.call(spare) == 0, "a spare pays nothing", failures)

static func _holdouts(catalogue: Dictionary, failures: Array[String]) -> void:
	var open := SliceTest._open([1, 2, 3, 4, 5], [6, 7])
	_expect(_with(catalogue, "charm.holdouts", open).score == _plus(catalogue, open, 24), "Holdouts: three standing add +24 Value", failures)
	_expect(_with(catalogue, "charm.holdouts", SliceTest._strike()).score == _base(catalogue, SliceTest._strike()).score, "a strike gets nothing", failures)
	_expect(_with(catalogue, "charm.holdouts", open).lines.any(func(l): return l.contains("Holdouts")), "the log names the Charm", failures)
