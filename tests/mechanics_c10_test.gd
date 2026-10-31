extends RefCounted
## E18-C10 (DC-H3, E17-D09): House's two balls, two pins and two Charms on existing
## rule pieces and physics profiles.
## - Spare Ball: spin response 0.5; +4 Mult per roll thrown with it in a spare.
## - Workhorse: mass ×1.15; +2 Value per pin down in the frame, per roll thrown with it.
## - Oak Pin: mass ×1.3; +20 Value when it falls.
## - Tin Pin: +5 Value when it falls; +$1 when it stands at the end of the frame.
## - Spare Jar: +8 Value per spare since bought (run growth after the bank).
## - Consolation Prize: +$1 after an open frame.
const ContentSet = preload("res://src/rules/content_set.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
const ItemPhysics = preload("res://src/simulation/item_physics.gd")
const SliceTest = preload("res://tests/slice_test.gd")
const IDS := ["ball.spare_ball", "ball.workhorse", "pin.oak", "pin.tin", "charm.spare_jar", "charm.consolation_prize"]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var content: Dictionary = ContentSet.load_set("slice")
	var catalogue: Dictionary = content.catalogue
	var items := {}
	for item in catalogue.items:
		items[item.id] = item
	_expect(IDS.all(func(id): return items.has(id) and items[id].completeness.mechanics and items[id].unlock.kind == "initial"),
		"the six D09 items are in the catalogue with mechanics, in the initial pool", failures)
	_expect(ItemPhysics.ball(items["ball.spare_ball"]) == {"mass_scale": 1.0, "spin_response": 0.5} and ItemPhysics.ball(items["ball.workhorse"]).mass_scale == 1.15
		and ItemPhysics.pin(items["pin.oak"]).mass_scale == 1.3 and ItemPhysics.pin(items["pin.tin"]) == ItemPhysics.pin({}),
		"physics profiles: a straighter Spare Ball, a heavier Workhorse and Oak Pin, a standard Tin Pin", failures)
	_balls(catalogue, failures)
	_pins(catalogue, failures)
	_charms(content, failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _base(catalogue: Dictionary, reports: Array, pins: Dictionary = {}) -> Dictionary:
	return SliceTest._score(catalogue, SliceTest._loadout(pins), reports, {})

static func _house(reports: Array) -> Array:
	for r in reports:
		r.launch.ball_id = "ball.house"
		r.roll_result.ball_id = "ball.house"
		r.knockdown_log.ball_id = "ball.house"
	return reports

static func _ball(reports: Array, index: int, ball: String) -> Array:
	reports[index].launch.ball_id = ball
	reports[index].roll_result.ball_id = ball
	reports[index].knockdown_log.ball_id = ball
	return reports

static func _payouts(result: Dictionary) -> int:
	return result.future_effects.filter(func(e): return e.op == "payout").reduce(func(n, e): return n + int(e.amount), 0)

static func _balls(catalogue: Dictionary, failures: Array[String]) -> void:
	var plain := _house(SliceTest._spare([1, 2, 3]))
	var b := _base(catalogue, plain)
	var one := _base(catalogue, _ball(SliceTest._spare([1, 2, 3]), 1, "ball.spare_ball"))
	var both := _base(catalogue, _ball(_ball(SliceTest._spare([1, 2, 3]), 0, "ball.spare_ball"), 1, "ball.spare_ball"))
	_expect(one.score == int(b.pin_value * (b.mult + 4)) and both.score == int(b.pin_value * (b.mult + 8)), "Spare Ball: +4 Mult per roll thrown with it in a spare", failures)
	var open := _base(catalogue, _ball(SliceTest._open([1, 2, 3], [4]), 0, "ball.spare_ball"))
	_expect(open.score == _base(catalogue, _house(SliceTest._open([1, 2, 3], [4]))).score and _base(catalogue, SliceTest._strike("ball.spare_ball")).score == _base(catalogue, SliceTest._strike()).score,
		"nothing on an open frame or a strike", failures)
	var strike := _base(catalogue, SliceTest._strike("ball.workhorse"))
	var s := _base(catalogue, SliceTest._strike())
	_expect(strike.score == int((s.pin_value + 20) * s.mult), "Workhorse: a strike adds +20 Value (2 per pin)", failures)
	var mixed := _base(catalogue, _ball(SliceTest._open([1, 2, 3], [4, 5]), 1, "ball.workhorse"))
	var m := _base(catalogue, _house(SliceTest._open([1, 2, 3], [4, 5])))
	_expect(mixed.score == int((m.pin_value + 10) * m.mult), "five pins down with one Workhorse roll add +10", failures)

static func _pins(catalogue: Dictionary, failures: Array[String]) -> void:
	var oak := {1: "pin.oak"}
	var down := _base(catalogue, SliceTest._open([1, 2], [3]), oak)
	var wood := _base(catalogue, SliceTest._open([1, 2], [3]))
	_expect(down.score == int((wood.pin_value + 10) * wood.mult), "Oak Pin: +20 Value when it falls (Wood is +10)", failures)
	var tin := {5: "pin.tin"}
	var standing := _base(catalogue, SliceTest._open([1, 2], [3]), tin)
	_expect(standing.score == wood.score and _payouts(standing) == 1, "Tin Pin: standing, it pays $1 and scores nothing", failures)
	var fell := _base(catalogue, SliceTest._open([1, 5], [3]), tin)
	var fell_wood := _base(catalogue, SliceTest._open([1, 5], [3]))
	_expect(fell.score == int((fell_wood.pin_value - 5) * fell_wood.mult) and _payouts(fell) == 0, "down, it adds +5 Value and pays nothing", failures)

static func _charms(content: Dictionary, failures: Array[String]) -> void:
	var catalogue: Dictionary = content.catalogue
	var run = Inventory.create(catalogue, content.kit.pins, content.kit.deck, 10)
	run.place("charm.spare_jar", 4, "charm:new")
	var score := func(reports: Array) -> Dictionary:
		return SliceTest._score(catalogue, run.loadout(), reports, {})
	var first: Dictionary = score.call(SliceTest._spare([1, 2, 3]))
	_expect(first.score == _base(catalogue, SliceTest._spare([1, 2, 3])).score and first.future_effects.any(func(e): return e.op == "grow_value"),
		"Spare Jar: the first spare scores +0 and drops a pin in the jar", failures)
	run.apply_frame(first, first.frame)
	var strike: Dictionary = score.call(SliceTest._strike())
	var s := _base(catalogue, SliceTest._strike())
	_expect(int(run.charms[0].growth) == 1 and strike.score == int((s.pin_value + 8) * s.mult) and not strike.future_effects.any(func(e): return e.op == "grow_value"),
		"one spare in the jar adds +8 Value to a strike, which adds none", failures)
	var prize := SliceTest._score(catalogue, SliceTest._loadout({}, ["charm.consolation_prize"]), SliceTest._open([1, 2], [3]), {})
	var spare := SliceTest._score(catalogue, SliceTest._loadout({}, ["charm.consolation_prize"]), SliceTest._spare([1, 2]), {})
	_expect(_payouts(prize) == 1 and prize.score == _base(catalogue, SliceTest._open([1, 2], [3])).score and _payouts(spare) == 0,
		"Consolation Prize: an open frame pays $1; a spare pays nothing", failures)
