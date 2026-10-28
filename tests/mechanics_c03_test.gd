extends RefCounted
## E18-C03: five new frame-rule primitives and the six items they land.
## - leave_min (Split Specialist): ×3 on a spare after a first-roll leave of 4+;
## - per accurate (Sweet Spot): +3 Mult per sweet or perfect roll, so at most +6;
## - per fallen_at (Back Row): +6 Value per back-row pin down, whatever its material;
## - behind (Underdog): ×2 when the match score is under half its target; never in
##   Practice (target 0) and never at exactly half;
## - last_fallen (Crown Pin "self", Crown Jewel "pin.crown"): the pin with the highest
##   knockdown sequence in the last roll that felled any; a Crown that falls earlier
##   adds 0 and the explanation says so.
## Each primitive's validation refuses malformed uses; the log shows the checked numbers.
const Rules = preload("res://src/rules/frame_rules.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const ContentSet = preload("res://src/rules/content_set.gd")
const SliceTest = preload("res://tests/slice_test.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = ContentSet.load_set("slice").catalogue
	_split_specialist(catalogue, failures)
	_sweet_spot(catalogue, failures)
	_back_row(catalogue, failures)
	_underdog(catalogue, failures)
	_crown(catalogue, failures)
	_refusals(catalogue, failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _with(catalogue: Dictionary, charm: String, reports: Array, context: Dictionary = {}, pins: Dictionary = {}) -> Dictionary:
	return SliceTest._score(catalogue, SliceTest._loadout(pins, [charm]), reports, context)

static func _base(catalogue: Dictionary, reports: Array, context: Dictionary = {}, pins: Dictionary = {}) -> Dictionary:
	return SliceTest._score(catalogue, SliceTest._loadout(pins), reports, context)

## A report list with the given accuracy grades per roll.
static func _graded(reports: Array, grades: Array) -> Array:
	for i in reports.size():
		reports[i].roll_result.accuracy = grades[i]
	return reports

static func _split_specialist(catalogue: Dictionary, failures: Array[String]) -> void:
	var hard := SliceTest._spare([1, 2, 3, 4, 5, 6]) # four standing after roll 1
	var r := _with(catalogue, "charm.split_specialist", hard)
	_expect(r.score == int(_base(catalogue, hard).pin_value * _base(catalogue, hard).mult * 3), "Split Specialist: ×3 on a spare after a four-pin leave", failures)
	_expect(r.lines.any(func(l): return l.contains("first roll left 4, needs 4+")), "the log shows the first-roll leave: %s" % str(r.lines), failures)
	var light := SliceTest._spare([1, 2, 3, 4, 5, 6, 7])
	_expect(_with(catalogue, "charm.split_specialist", light).score == _base(catalogue, light).score, "a three-pin leave gets nothing", failures)
	_expect(_with(catalogue, "charm.split_specialist", SliceTest._strike()).score == _base(catalogue, SliceTest._strike()).score
		and _with(catalogue, "charm.split_specialist", SliceTest._open([1, 2], [3])).score == _base(catalogue, SliceTest._open([1, 2], [3])).score,
		"a strike or an open frame gets nothing", failures)

static func _sweet_spot(catalogue: Dictionary, failures: Array[String]) -> void:
	var plus := func(reports: Array, k: float) -> int:
		var b := _base(catalogue, reports)
		return int(b.pin_value * (b.mult + k))
	var two := _graded(SliceTest._open([1, 2, 3], [4]), ["sweet", "perfect"])
	_expect(_with(catalogue, "charm.sweet_spot", two).score == plus.call(two, 6), "Sweet Spot: two graded rolls add +6 Mult (the cap)", failures)
	var one := _graded(SliceTest._open([1, 2, 3], [4]), ["clean", "sweet"])
	_expect(_with(catalogue, "charm.sweet_spot", one).score == plus.call(one, 3), "one sweet roll adds +3 Mult", failures)
	var none := _graded(SliceTest._open([1, 2, 3], [4]), ["clean", "miss"])
	_expect(_with(catalogue, "charm.sweet_spot", none).score == _base(catalogue, none).score, "clean and miss count zero", failures)
	var strike := _graded(SliceTest._strike(), ["perfect"])
	_expect(_with(catalogue, "charm.sweet_spot", strike).lines.any(func(l): return l.contains("per sweet or perfect roll")), "the log names the count", failures)

static func _back_row(catalogue: Dictionary, failures: Array[String]) -> void:
	var value_plus := func(reports: Array, k: float, pins: Dictionary = {}) -> int:
		var b := _base(catalogue, reports, {}, pins)
		return int((b.pin_value + k) * b.mult)
	_expect(_with(catalogue, "charm.back_row", SliceTest._strike()).score == value_plus.call(SliceTest._strike(), 24), "Back Row: a full back row adds +24 Value", failures)
	var front := SliceTest._open([1, 2, 3, 5], [7])
	_expect(_with(catalogue, "charm.back_row", front).score == value_plus.call(front, 6), "one back-row pin down adds +6 Value", failures)
	var glass := {8: "pin.glass", 10: "pin.glass"}
	var mixed := SliceTest._open([8, 10], [])
	_expect(_with(catalogue, "charm.back_row", mixed, {}, glass).score == value_plus.call(mixed, 12, glass), "whatever its material", failures)
	_expect(_with(catalogue, "charm.back_row", SliceTest._open([1, 2, 3], [])).score == _base(catalogue, SliceTest._open([1, 2, 3], [])).score, "no back-row pin, nothing", failures)
	_expect(_with(catalogue, "charm.back_row", front).lines.any(func(l): return l.contains("per back-row pin down")), "the log names the back row", failures)

static func _underdog(catalogue: Dictionary, failures: Array[String]) -> void:
	var strike := SliceTest._strike()
	var base: Dictionary = _base(catalogue, strike)
	var behind := _with(catalogue, "charm.underdog", strike, {"match_score": 100, "match_target": 300})
	_expect(behind.score == int(base.pin_value * base.mult * 2), "Underdog: ×2 below half the target", failures)
	_expect(behind.lines.any(func(l): return l.contains("behind: 100 vs half of 300")), "the log shows the check: %s" % str(behind.lines), failures)
	_expect(_with(catalogue, "charm.underdog", strike, {"match_score": 150, "match_target": 300}).score == base.score, "exactly half is not behind", failures)
	_expect(_with(catalogue, "charm.underdog", strike, {"match_score": 0, "match_target": 0}).score == base.score
		and _with(catalogue, "charm.underdog", strike).score == base.score, "Practice (no target) never triggers it", failures)

static func _crown(catalogue: Dictionary, failures: Array[String]) -> void:
	var crown := {7: "pin.crown"}
	# Spare: roll 2 knocks down 8, 9 then 7: Crown at 7 fell last.
	var last := [SliceTest._rep(1, [1, 2, 3, 4, 5, 6, 10], SliceTest.ALL), SliceTest._rep(2, [8, 9, 7], [7, 8, 9])]
	var wood: Dictionary = _base(catalogue, last)
	var r: Dictionary = _base(catalogue, last, {}, crown)
	_expect(r.pin_value == wood.pin_value - 10 + 40, "Crown Pin: +40 Value when it fell last, and no base Value of its own", failures)
	_expect(r.lines.any(func(l): return l.contains("Crown Pin +40 Value (fell last)")), "the log shows the +40", failures)
	var early := [SliceTest._rep(1, [1, 2, 3, 4, 5, 6, 10], SliceTest.ALL), SliceTest._rep(2, [7, 8, 9], [7, 8, 9])]
	var e: Dictionary = _base(catalogue, early, {}, crown)
	_expect(e.pin_value == _base(catalogue, early).pin_value - 10, "a Crown that does not fall last adds nothing", failures)
	_expect(e.lines.any(func(l): return l.contains("Pin 7 Crown Pin +0 Value (did not fall last)")), "the log shows a clear 0: %s" % str(e.lines), failures)
	# A strike: the last pin in the knockdown order; a second roll that fells nothing keeps roll 1's last pin.
	var strike := [SliceTest._rep(1, [1, 2, 3, 4, 5, 6, 8, 9, 10, 7], SliceTest.ALL)]
	_expect(_base(catalogue, strike, {}, crown).pin_value == _base(catalogue, strike).pin_value - 10 + 40, "a strike's last knockdown counts", failures)
	var gutter := [SliceTest._rep(1, [1, 2, 3, 7], SliceTest.ALL), SliceTest._rep(2, [], [4, 5, 6, 8, 9, 10])]
	_expect(_base(catalogue, gutter, {}, crown).frame.rolls[1].last_fallen == 0 and _base(catalogue, gutter, {}, crown).pin_value == _base(catalogue, gutter).pin_value - 10 + 40,
		"an empty second roll leaves roll 1's last pin as the frame's", failures)
	var two := {7: "pin.crown", 9: "pin.crown"}
	_expect(_base(catalogue, last, {}, two).pin_value == wood.pin_value - 20 + 40, "with two Crowns only the last one pays", failures)
	var jewel := _with(catalogue, "charm.crown_jewel", last, {}, crown)
	_expect(jewel.score == int(r.pin_value * r.mult * 2) and _with(catalogue, "charm.crown_jewel", early, {}, crown).score == e.score
		and _with(catalogue, "charm.crown_jewel", last).score == wood.score, "Crown Jewel: ×2 only when a Crown pin fell last", failures)

static func _refusals(catalogue: Dictionary, failures: Array[String]) -> void:
	_expect(Contracts.validate("catalogue", catalogue).is_empty(), "the catalogue with the C03 items validates", failures)
	var mutate := func(id: String, change: Callable) -> Array:
		var copy := catalogue.duplicate(true)
		change.call(copy.items.filter(func(i): return i.id == id)[0].effects[0])
		return Contracts.validate("catalogue", copy)
	_expect(not mutate.call("charm.split_specialist", func(e): e.condition.leave_min = 11).is_empty()
		and not mutate.call("charm.split_specialist", func(e): e.condition.leave_min = 0).is_empty(), "leave_min is 1..10", failures)
	_expect(not mutate.call("charm.back_row", func(e): e.per = "fallen_at:7,7").is_empty() and not mutate.call("charm.back_row", func(e): e.per = "fallen_at:11").is_empty()
		and not mutate.call("charm.back_row", func(e): e.per = "fallen_at:").is_empty(), "fallen_at lists distinct positions 1..10", failures)
	_expect(not mutate.call("charm.sweet_spot", func(e): e.per = "accurate:pin.wood").is_empty(), "accurate takes no item", failures)
	_expect(not mutate.call("charm.crown_jewel", func(e): e.condition.last_fallen = "self").is_empty()
		and not mutate.call("charm.crown_jewel", func(e): e.condition.last_fallen = "pin.nope").is_empty()
		and not mutate.call("pin.crown", func(e): e.condition.last_fallen = true).is_empty(), "last_fallen is self on a pin or a catalogue pin", failures)
	_expect(not mutate.call("charm.underdog", func(e): e.condition.behind = "yes").is_empty(), "behind is a boolean", failures)
	# FrameRules refuses the same shapes and a last_fallen that did not fall.
	var built := Builder.build(SliceTest._loadout({}, ["charm.back_row"]), catalogue, SliceTest._strike(), {}, {"match_score": 10, "match_target": 300})
	_expect(built.ok and Rules.validate(built.frame).is_empty(), "a full v2 frame with match context validates", failures)
	var bad: Dictionary = built.frame.duplicate(true)
	bad.charms[0].effects[0].per = "fallen_at:0,7"
	_expect(not Rules.validate(bad).is_empty(), "FrameRules refuses a position outside 1..10", failures)
	bad = built.frame.duplicate(true)
	bad.charms[0].effects[0]["condition"] = {"last_fallen": "self"}
	_expect(not Rules.validate(bad).is_empty(), "FrameRules refuses self on a Charm", failures)
	bad = built.frame.duplicate(true)
	bad.context.match_target = -1
	_expect(not Rules.validate(bad).is_empty(), "FrameRules refuses a negative target", failures)
	var open := Builder.build(SliceTest._loadout(), catalogue, SliceTest._open([1, 2], [3]))
	bad = open.frame.duplicate(true)
	bad.rolls[1].last_fallen = 9
	_expect(not Rules.validate(bad).is_empty(), "a roll's last_fallen is a pin that fell that roll", failures)
