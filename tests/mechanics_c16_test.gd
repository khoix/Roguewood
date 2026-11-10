extends RefCounted
## E18-C16 (DC-N2, E17-D13): Neon's opening pool.
## - Glow Ball: +5 Mult on a strike with a curved roll, thrown with it.
## - Prism Pin: +25 Value when a curved roll knocks it down (nothing otherwise).
## - Grip Tape: its card's rolls hook 1.4 times as far.
## - Spotlight: +3 Mult when its pin is the first a curved roll's ball meets.
## - Afterimage: ×1.5 Mult on a curved spare.
## - Laser Level: +5 Value per pin down in a straight frame.
const ContentSet = preload("res://src/rules/content_set.gd")
const ItemPhysics = preload("res://src/simulation/item_physics.gd")
const SliceTest = preload("res://tests/slice_test.gd")
const C15 = preload("res://tests/mechanics_c15_test.gd")
const IDS := ["ball.glow", "pin.prism", "ball_mod.grip_tape", "pin_mod.spotlight", "charm.afterimage", "charm.laser_level"]
const ALL := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const REST := [7, 8, 9, 10]
const CURVE := 0.6

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = ContentSet.load_set("slice").catalogue
	var items := {}
	for item in catalogue.items:
		items[item.id] = item
	_expect(IDS.all(func(id): return items.has(id) and items[id].completeness.mechanics and items[id].unlock.kind == "initial" and int(items[id].earliest_division) == 1),
		"the six items are in the catalogue with mechanics, in the initial pool from Division 1", failures)
	_expect(ItemPhysics.roll_rules(items["ball.hook"], items["ball_mod.grip_tape"]) == {"spin_scale": 1.4} and ItemPhysics.roll_rules(items["ball.glow"]).is_empty(),
		"Grip Tape scales its card's hook by 1.4; Glow Ball changes nothing in the roll", failures)
	_glow(catalogue, failures)
	_prism_and_spotlight(catalogue, failures)
	_charms(catalogue, failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("mechanics_c16: " + label)

static func _glow(catalogue: Dictionary, failures: Array[String]) -> void:
	var curved: Dictionary = C15._resolve(catalogue, [C15._rep(1, ALL, ALL, "ball.glow", CURVE)])
	var house: Dictionary = C15._resolve(catalogue, [C15._rep(1, ALL, ALL, "ball.house", CURVE)])
	_expect(curved.ok and curved.mult == house.mult + 5.0 and curved.lines.any(func(l): return l.contains("Glow Ball")), "Glow Ball: +5 Mult on a curved strike", failures)
	var straight: Dictionary = C15._resolve(catalogue, [C15._rep(1, ALL, ALL, "ball.glow")])
	_expect(straight.ok and straight.mult == C15._resolve(catalogue, [C15._rep(1, ALL, ALL)]).mult, "nothing on a straight strike", failures)
	var spare := [C15._rep(1, [1, 2, 3, 4, 5, 6], ALL, "ball.glow", CURVE), C15._rep(2, REST, REST)]
	var plain := [C15._rep(1, [1, 2, 3, 4, 5, 6], ALL, "ball.house", CURVE), C15._rep(2, REST, REST)]
	_expect(C15._resolve(catalogue, spare).mult == C15._resolve(catalogue, plain).mult, "nothing on a curved spare", failures)

static func _prism_and_spotlight(catalogue: Dictionary, failures: Array[String]) -> void:
	var rack: Dictionary = SliceTest._loadout({1: "pin.prism", 7: "pin.prism"})
	var wood := 10.0
	var base: Dictionary = C15._resolve(catalogue, [C15._rep(1, ALL, ALL, "ball.house", CURVE)])
	var curved: Dictionary = C15._resolve(catalogue, [C15._rep(1, ALL, ALL, "ball.house", CURVE)], rack)
	_expect(curved.ok and curved.pin_value == base.pin_value - 2 * wood + 2 * 25.0, "Prism Pin: +25 Value each when a curved roll takes them", failures)
	var straight: Dictionary = C15._resolve(catalogue, [C15._rep(1, ALL, ALL)], rack)
	_expect(straight.ok and straight.pin_value == C15._resolve(catalogue, [C15._rep(1, ALL, ALL)]).pin_value - 2 * wood, "a straight roll: nothing, less than Wood", failures)
	# Roll 1 straight takes the Prism at 1; roll 2 curved takes the Prism at 7: only that one pays.
	var split: Dictionary = C15._resolve(catalogue, [C15._rep(1, [1, 2, 3, 4, 5, 6], ALL), C15._rep(2, REST, REST, "ball.house", CURVE)], rack)
	_expect(split.ok and split.lines.filter(func(l): return l.contains("Prism Pin")).size() == 1, "it reads the roll that knocked it down, not the frame", failures)
	# Spotlight on the head pin: C15._rep makes the first listed pin the first hit.
	var lit: Dictionary = SliceTest._loadout()
	lit["pin_mods"] = {1: "pin_mod.spotlight"}
	var first: Dictionary = C15._resolve(catalogue, [C15._rep(1, ALL, ALL, "ball.house", CURVE)], lit)
	_expect(first.ok and first.mult == base.mult + 3.0 and first.lines.any(func(l): return l.contains("Spotlight")), "Spotlight: +3 Mult when a curved ball meets its pin first", failures)
	var straight_first: Dictionary = C15._resolve(catalogue, [C15._rep(1, ALL, ALL)], lit)
	_expect(straight_first.ok and not straight_first.lines.any(func(l): return l.contains("Spotlight")), "a straight roll does not light it", failures)
	var elsewhere: Dictionary = SliceTest._loadout()
	elsewhere["pin_mods"] = {5: "pin_mod.spotlight"}
	var not_first: Dictionary = C15._resolve(catalogue, [C15._rep(1, ALL, ALL, "ball.house", CURVE)], elsewhere)
	_expect(not_first.ok and not not_first.lines.any(func(l): return l.contains("Spotlight")), "nor a pin the ball did not meet first", failures)

static func _charms(catalogue: Dictionary, failures: Array[String]) -> void:
	var none: Dictionary = SliceTest._loadout()
	var after: Dictionary = SliceTest._loadout({}, ["charm.afterimage"])
	var curved_spare := [C15._rep(1, [1, 2, 3, 4, 5, 6], ALL, "ball.house", CURVE), C15._rep(2, REST, REST)]
	_expect(C15._resolve(catalogue, curved_spare, after).mult == C15._resolve(catalogue, curved_spare, none).mult * 1.5, "Afterimage: ×1.5 Mult on a curved spare", failures)
	var straight_spare := [C15._rep(1, [1, 2, 3, 4, 5, 6], ALL), C15._rep(2, REST, REST)]
	_expect(C15._resolve(catalogue, straight_spare, after).mult == C15._resolve(catalogue, straight_spare, none).mult, "nothing on a straight spare", failures)
	var curved_strike := [C15._rep(1, ALL, ALL, "ball.house", CURVE)]
	_expect(C15._resolve(catalogue, curved_strike, after).mult == C15._resolve(catalogue, curved_strike, none).mult, "nothing on a curved strike", failures)
	var level: Dictionary = SliceTest._loadout({}, ["charm.laser_level"])
	var strike := [C15._rep(1, ALL, ALL)]
	_expect(C15._resolve(catalogue, strike, level).pin_value == C15._resolve(catalogue, strike, none).pin_value + 50.0, "Laser Level: +5 Value per pin on a straight strike (+50)", failures)
	var open := [C15._rep(1, [1, 2, 3], ALL), C15._rep(2, [], [4, 5, 6, 7, 8, 9, 10])]
	_expect(C15._resolve(catalogue, open, level).pin_value == C15._resolve(catalogue, open, none).pin_value + 15.0, "three down in a straight open frame: +15", failures)
	_expect(C15._resolve(catalogue, curved_strike, level).pin_value == C15._resolve(catalogue, curved_strike, none).pin_value, "a curved roll switches it off", failures)
