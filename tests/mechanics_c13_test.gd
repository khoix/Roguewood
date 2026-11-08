extends RefCounted
## E18-C13 (the rules and lanes of E17-L02): the Neon League's three boss rules and
## two lane conditions.
## - Oil Slick halves the hook a charge produces; the committed spin is kept.
## - Narrow Lane moves each gutter edge two boards in and keeps the start inside.
## - Strobe halves the ring's perfect and sweet bands; clean and miss are unchanged.
## - Long Oil runs the oil to 47 ft; Two-Tone ends it at 34 ft on the left half.
## The physics suite rolls each one through a real lane (physics_test `_neon`).
const ContentSet = preload("res://src/rules/content_set.gd")
const RivalRules = preload("res://src/rules/rival_rules.gd")
const Division = preload("res://src/rules/division_run.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const Ring = preload("res://src/input/target_ring.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const OIL := "boss_rule.oil_slick"
const NARROW := "boss_rule.narrow_lane"
const STROBE := "boss_rule.strobe"
const IDS := [OIL, NARROW, STROBE, "lane_condition.long_oil", "lane_condition.two_tone"]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = ContentSet.load_set("slice").catalogue
	var items := {}
	for item in catalogue.items:
		items[item.id] = item
	_expect(IDS.all(func(id): return items.has(id) and items[id].completeness.mechanics and float(items[id].pool_weight) == 0.0),
		"the three Neon rules and two Neon lanes are in the catalogue, never sold", failures)
	_expect(RivalRules.unknown([OIL, NARROW, STROBE]).is_empty(), "the Neon rules are known rules", failures)
	_rules(failures)
	_grades(failures)
	_lanes(failures)
	# The Neon spec's Divisions now validate against the shipped catalogue (their kit lands with E22-L02).
	var neon: Dictionary = Contracts.read_json("res://content/leagues/neon.json")
	for d in neon.divisions:
		var errors := Division.validate_spec(d, catalogue)
		_expect(errors.is_empty(), "Neon Division %d validates against the shipped catalogue: %s" % [int(d.division), str(errors)], failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _rules(failures: Array[String]) -> void:
	var edge := Lane.LANE_HALF_WIDTH - 2.0 * Lane.BOARD_WIDTH
	_expect(RivalRules.lane_rules([]).is_empty() and RivalRules.lane_rules(["boss_rule.clean_sweep", "boss_rule.dead_straight"]).is_empty(),
		"no Neon rule, no change to the roll", failures)
	_expect(RivalRules.lane_rules([OIL]) == {"hook_scale": 0.5} and RivalRules.lane_rules([STROBE]) == {"zone_scale": 0.5},
		"Oil Slick halves the hook; Strobe halves the ring zones", failures)
	_expect(is_equal_approx(float(RivalRules.lane_rules([NARROW]).gutter_edge), edge) and absf(edge - 0.47300) < 0.0001,
		"Narrow Lane's edge is two of the 39 boards in (%.4f m)" % edge, failures)
	_expect(RivalRules.lane_rules([STROBE, OIL]) == {"zone_scale": 0.5, "hook_scale": 0.5}, "the Neon champion carries both of its rules", failures)
	var launch := {"start_x": 0.79, "spin": 0.8, "ball_id": "ball.hook"}
	_expect(RivalRules.constrain_launch([OIL], launch) == launch and RivalRules.constrain_launch([STROBE], launch) == launch,
		"Oil Slick and Strobe keep the committed launch (a curved throw still counts as curved)", failures)
	var narrowed := RivalRules.constrain_launch([NARROW], launch)
	_expect(is_equal_approx(float(narrowed.start_x), Lane.max_start_x(edge)) and is_equal_approx(float(RivalRules.constrain_launch([NARROW], {"start_x": -0.79}).start_x), -Lane.max_start_x(edge))
		and RivalRules.constrain_launch([NARROW], {"start_x": 0.2}).start_x == 0.2 and narrowed.spin == 0.8,
		"Narrow Lane keeps the start inside its edges (|start_x| <= %.3f)" % Lane.max_start_x(edge), failures)
	_expect(RivalRules.constrain_launch(["boss_rule.dead_straight", OIL], launch).spin == 0.0, "with Dead Straight too, spin is still disabled", failures)
	for rule in [OIL, NARROW, STROBE]:
		_expect(RivalRules.summary(rule).length() > 30 and RivalRules.summary(rule) != rule, "%s has a summary" % rule, failures)

## Strobe narrows each band from the ring's floor; scale 1 is exactly the old grading.
static func _grades(failures: Array[String]) -> void:
	_expect(Lane.ZONE_FLOOR == Ring.RING_MIN, "the zones are measured from the ring's smallest radius", failures)
	var same := true
	for i in 61:
		var r := 0.03 + i * 0.005
		for offset in [0.0, 0.05, 0.2]:
			var old := "miss" if offset > r else ("perfect" if r <= Lane.PERFECT_RING else ("sweet" if r <= Lane.SWEET_RING else "clean"))
			same = same and Lane.grade_accuracy(true, offset, r) == old and Lane.grade_accuracy(true, offset, r, 1.0) == old
	_expect(same, "without Strobe the grades are unchanged", failures)
	_expect(is_equal_approx(Lane.perfect_ring(0.5), 0.07) and is_equal_approx(Lane.sweet_ring(0.5), 0.11), "Strobe: perfect to 0.07, sweet to 0.11", failures)
	var expect := {0.065: ["perfect", "perfect"], 0.075: ["perfect", "sweet"], 0.1: ["sweet", "sweet"], 0.12: ["sweet", "clean"], 0.2: ["clean", "clean"]}
	for r in expect:
		_expect(Lane.grade_accuracy(true, 0.0, r) == expect[r][0] and Lane.grade_accuracy(true, 0.0, r, 0.5) == expect[r][1] and Ring.grade(r, 0.5) == expect[r][1],
			"ring %.3f grades %s, %s under Strobe" % [r, expect[r][0], expect[r][1]], failures)
	_expect(Lane.grade_accuracy(true, 0.09, 0.08, 0.5) == "miss" and Lane.grade_accuracy(false, 0.0, 0.07, 0.5) == "miss", "miss is unchanged under Strobe", failures)

static func _lanes(failures: Array[String]) -> void:
	var house := func(f: float) -> float: return Lane.ball_friction(f)
	var same := true
	for f in [0.5, 6.0, 10.0, 11.0, 12.0, 12.5, 13.0, 15.0, 17.5, 18.0]:
		same = same and Lane.ball_friction(f, "lane_condition.house_oil", -0.3) == house.call(f) and Lane.ball_friction(f, "lane.house", 0.3) == house.call(f)
		same = same and Lane.ball_friction(f, "lane_condition.two_tone", 0.2) == house.call(f)
	_expect(same, "House Oil, and Two-Tone's right half, are the standard pattern", failures)
	_expect(Lane.ball_friction(13.0, "lane_condition.long_oil") == Lane.OIL_FRICTION and house.call(13.0) == Lane.BACKEND_FRICTION
		and Lane.ball_friction(15.0, "lane_condition.long_oil") == Lane.BACKEND_FRICTION and Lane.ball_friction(17.5, "lane_condition.long_oil") == Lane.BALL_PIN_FRICTION,
		"Long Oil keeps the oil to 47 ft, then the usual backend and deck", failures)
	_expect(Lane.ball_friction(11.0, "lane_condition.two_tone", -0.2) == Lane.BACKEND_FRICTION and Lane.ball_friction(10.0, "lane_condition.two_tone", -0.2) == Lane.OIL_FRICTION
		and Lane.ball_friction(11.0, "lane_condition.two_tone", 0.2) == Lane.OIL_FRICTION,
		"Two-Tone's left half dries at 34 ft, its right half at 40 ft", failures)
	_expect(Lane.ball_friction(13.0, "lane_condition.dry_backend") == Lane.DRY_BACKEND_FRICTION, "Dry Backend is unchanged", failures)
