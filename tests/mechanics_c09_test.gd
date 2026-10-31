extends RefCounted
## E18-C09 (DC-H2, E17-D08): six more House Charms on existing rule pieces.
## - Trophy Case: +1 Mult per trophy; each strike adds one after the bank (run growth).
## - Corner Pockets: +25 Value per corner pin (7, 10) down.
## - Late Rally: +10 Mult in a match's second frame when behind; never in Practice.
## - Clean Pickup: ×1.5 on a spare with no curved roll.
## - House Special: ×1.5 on a strike thrown only with the House Ball.
## - Front Line: +2 Mult per front-three pin (1, 2, 3) down.
const ContentSet = preload("res://src/rules/content_set.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
const SliceTest = preload("res://tests/slice_test.gd")
const IDS := ["charm.trophy_case", "charm.corner_pockets", "charm.late_rally", "charm.clean_pickup", "charm.house_special", "charm.front_line"]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var content: Dictionary = ContentSet.load_set("slice")
	var catalogue: Dictionary = content.catalogue
	var items := {}
	for item in catalogue.items:
		items[item.id] = item
	_expect(IDS.all(func(id): return items.has(id) and items[id].category == "charm" and items[id].completeness.mechanics and items[id].unlock.kind == "initial"),
		"the six D08 Charms are in the catalogue with mechanics, in the initial pool", failures)
	_trophy_case(content, failures)
	_corner_pockets(catalogue, failures)
	_late_rally(catalogue, failures)
	_clean_pickup(catalogue, failures)
	_house_special(catalogue, failures)
	_front_line(catalogue, failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _with(catalogue: Dictionary, charm: String, reports: Array, context: Dictionary = {}, pins: Dictionary = {}) -> Dictionary:
	return SliceTest._score(catalogue, SliceTest._loadout(pins, [charm]), reports, context)

static func _base(catalogue: Dictionary, reports: Array, context: Dictionary = {}) -> Dictionary:
	return SliceTest._score(catalogue, SliceTest._loadout(), reports, context)

static func _plus(catalogue: Dictionary, reports: Array, value: float, mult: float = 0.0, times: float = 1.0, context: Dictionary = {}) -> int:
	var b := _base(catalogue, reports, context)
	return int((b.pin_value + value) * (b.mult + mult) * times)

static func _trophy_case(content: Dictionary, failures: Array[String]) -> void:
	var catalogue: Dictionary = content.catalogue
	var run = Inventory.create(catalogue, content.kit.pins, content.kit.deck, 10)
	run.place("charm.trophy_case", 6, "charm:new")
	var score := func(reports: Array) -> Dictionary:
		return SliceTest._score(catalogue, run.loadout(), reports, {})
	var first: Dictionary = score.call(SliceTest._strike())
	_expect(first.score == _base(catalogue, SliceTest._strike()).score and first.future_effects.any(func(e): return e.op == "grow_value"),
		"Trophy Case: the first strike scores +0 and earns a trophy after the bank", failures)
	run.apply_frame(first, first.frame)
	_expect(int(run.charms[0].growth) == 1, "the trophy is kept on the Charm", failures)
	var second: Dictionary = score.call(SliceTest._strike())
	_expect(second.score == _plus(catalogue, SliceTest._strike(), 0, 1), "the next strike scores +1 Mult", failures)
	run.apply_frame(second, second.frame)
	var spare: Dictionary = score.call(SliceTest._spare([1, 2, 3]))
	_expect(spare.score == _plus(catalogue, SliceTest._spare([1, 2, 3]), 0, 2) and not spare.future_effects.any(func(e): return e.op == "grow_value"),
		"two trophies add +2 Mult to a spare, which earns none", failures)

static func _corner_pockets(catalogue: Dictionary, failures: Array[String]) -> void:
	_expect(_with(catalogue, "charm.corner_pockets", SliceTest._strike()).score == _plus(catalogue, SliceTest._strike(), 50), "Corner Pockets: both corners add +50 Value", failures)
	var one := SliceTest._open([1, 2, 3, 7], [])
	_expect(_with(catalogue, "charm.corner_pockets", one).score == _plus(catalogue, one, 25), "one corner adds +25", failures)
	var none := SliceTest._open([1, 2, 3], [5])
	_expect(_with(catalogue, "charm.corner_pockets", none).score == _base(catalogue, none).score, "no corner, nothing", failures)

static func _late_rally(catalogue: Dictionary, failures: Array[String]) -> void:
	var open := SliceTest._open([1, 2, 3], [4])
	var behind := {"match_frame": 2, "match_score": 100, "match_target": 500}
	_expect(_with(catalogue, "charm.late_rally", open, behind).score == _plus(catalogue, open, 0, 10, 1, behind), "Late Rally: +10 Mult behind in frame 2", failures)
	var ahead := {"match_frame": 2, "match_score": 300, "match_target": 500}
	var early := {"match_frame": 1, "match_score": 0, "match_target": 500}
	var practice := {"match_frame": 2, "match_score": 0, "match_target": 0}
	_expect([ahead, early, practice].all(func(c): return _with(catalogue, "charm.late_rally", open, c).score == _base(catalogue, open, c).score),
		"nothing when at half the target or more, in frame 1, or in Practice", failures)

static func _clean_pickup(catalogue: Dictionary, failures: Array[String]) -> void:
	var spare := SliceTest._spare([1, 2, 3])
	_expect(_with(catalogue, "charm.clean_pickup", spare).score == _plus(catalogue, spare, 0, 0, 1.5), "Clean Pickup: ×1.5 on a straight spare", failures)
	var curved := SliceTest._spare([1, 2, 3])
	curved[1].launch.spin = 0.8
	_expect(_with(catalogue, "charm.clean_pickup", curved).score == _base(catalogue, curved).score, "a curved roll cancels it", failures)
	_expect(_with(catalogue, "charm.clean_pickup", SliceTest._strike()).score == _base(catalogue, SliceTest._strike()).score, "a strike gets nothing", failures)

static func _house_special(catalogue: Dictionary, failures: Array[String]) -> void:
	_expect(_with(catalogue, "charm.house_special", SliceTest._strike()).score == _plus(catalogue, SliceTest._strike(), 0, 0, 1.5), "House Special: ×1.5 on a House Ball strike", failures)
	var hook := SliceTest._strike("ball.hook")
	_expect(_with(catalogue, "charm.house_special", hook).score == _base(catalogue, hook).score, "a special ball cancels it", failures)
	var spare := SliceTest._spare([1, 2])
	_expect(_with(catalogue, "charm.house_special", spare).score == _base(catalogue, spare).score, "a spare gets nothing", failures)

static func _front_line(catalogue: Dictionary, failures: Array[String]) -> void:
	_expect(_with(catalogue, "charm.front_line", SliceTest._strike()).score == _plus(catalogue, SliceTest._strike(), 0, 6), "Front Line: the full front three add +6 Mult", failures)
	var two := SliceTest._open([1, 3, 5], [])
	_expect(_with(catalogue, "charm.front_line", two).score == _plus(catalogue, two, 0, 4), "two of the front three add +4", failures)
	var back := SliceTest._open([7, 8, 9], [])
	_expect(_with(catalogue, "charm.front_line", back).score == _base(catalogue, back).score, "the back of the rack adds nothing", failures)
