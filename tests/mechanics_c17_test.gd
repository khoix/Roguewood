extends RefCounted
## E18-C17 (DC-N3, E17-D14): the rest of Neon's opening pool.
## - Dry Side: +4 Mult when a roll was left of the centre board at 34 ft (roll.left_side).
## - Lane Reader: ×1.5 Mult on a strike on a lane that is not House Oil (condition.lane).
## - Hook Shot: the throw it is played with hooks 1.5 times as far (tactical.hook_scale).
## - Line Call: played with a throw, +4 Mult when no roll in the frame curved.
## - Bounce Back: +$3 after a frame with a rebound off the gutter edge.
## - Straight Money: +$2 after a strike with no curved roll.
const ContentSet = preload("res://src/rules/content_set.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const ItemPhysics = preload("res://src/simulation/item_physics.gd")
const Deck = preload("res://src/rules/card_deck.gd")
const Tactics = preload("res://src/rules/tactics.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const SliceTest = preload("res://tests/slice_test.gd")
const C15 = preload("res://tests/mechanics_c15_test.gd")
const IDS := ["charm.dry_side", "charm.lane_reader", "consumable.hook_shot", "consumable.line_call", "charm.bounce_back", "charm.straight_money"]
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
	_expect(["consumable.hook_shot", "consumable.line_call"].all(func(id): return Deck.kind(id) == "tactical" and Tactics.kind(id).is_empty() and items[id].limits.exhaustion == "consume"),
		"Hook Shot and Line Call are tactical cards played with a throw, spent on use", failures)
	_hook_shot(items, failures)
	_dry_side(catalogue, failures)
	_lane_reader(catalogue, failures)
	_line_call(catalogue, failures)
	_money(catalogue, failures)
	_validation(failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("mechanics_c17: " + label)

static func _hook_shot(items: Dictionary, failures: Array[String]) -> void:
	_expect(ItemPhysics.roll_rules(items["ball.hook"], {}, false, items["consumable.hook_shot"]) == {"spin_scale": 1.5}, "Hook Shot: the roll hooks 1.5 times as far", failures)
	var both: Dictionary = ItemPhysics.roll_rules(items["ball.hook"], items["ball_mod.grip_tape"], false, items["consumable.hook_shot"])
	_expect(is_equal_approx(float(both.get("spin_scale", 0.0)), 1.4 * 1.5), "with Grip Tape on the card the two multiply (1.4 × 1.5)", failures)
	_expect(ItemPhysics.roll_rules(items["ball.hook"], {}, false, items["consumable.line_call"]).is_empty(), "Line Call changes nothing in the roll itself", failures)

## A report whose roll was left of the centre board at 34 ft.
static func _left(report: Dictionary) -> Dictionary:
	report.knockdown_log["left_side"] = true
	return report

static func _dry_side(catalogue: Dictionary, failures: Array[String]) -> void:
	var none: Dictionary = SliceTest._loadout()
	var dry: Dictionary = SliceTest._loadout({}, ["charm.dry_side"])
	var left := [_left(C15._rep(1, ALL, ALL))]
	var got: Dictionary = C15._resolve(catalogue, left, dry)
	_expect(got.ok and got.mult == C15._resolve(catalogue, left, none).mult + 4.0 and got.lines.any(func(l): return l.contains("Dry Side")), "Dry Side: +4 Mult for a roll on the left at 34 ft", failures)
	var right := [C15._rep(1, ALL, ALL)]
	_expect(C15._resolve(catalogue, right, dry).mult == C15._resolve(catalogue, right, none).mult, "nothing for a ball on the right", failures)
	# Either roll counts: roll 1 right, roll 2 left.
	var second := [C15._rep(1, [1, 2, 3, 4, 5, 6], ALL), _left(C15._rep(2, REST, REST))]
	_expect(C15._resolve(catalogue, second, dry).mult == C15._resolve(catalogue, second, none).mult + 4.0, "a left second roll counts too", failures)
	var built := Builder.build(none, catalogue, left, {}, {})
	_expect(built.ok and built.frame.rolls[0].get("left_side", false) == true and not Builder.build(none, catalogue, right, {}, {}).frame.rolls[0].has("left_side"),
		"FrameBuilder copies the log's flag only when it is set", failures)

static func _with_lane(catalogue: Dictionary, reports: Array, loadout: Dictionary, lane: String) -> Dictionary:
	var built := Builder.build(loadout, catalogue, reports, {}, {"lane_condition": lane})
	return Rules.resolve(built.frame) if built.ok else {"ok": false, "mult": -1.0}

static func _lane_reader(catalogue: Dictionary, failures: Array[String]) -> void:
	var none: Dictionary = SliceTest._loadout()
	var reader: Dictionary = SliceTest._loadout({}, ["charm.lane_reader"])
	var strike := [C15._rep(1, ALL, ALL)]
	for lane in ["lane_condition.long_oil", "lane_condition.two_tone", "lane_condition.dry_backend", "lane.dry"]:
		var got := _with_lane(catalogue, strike, reader, lane)
		_expect(got.ok and got.mult == _with_lane(catalogue, strike, none, lane).mult * 1.5, "Lane Reader: ×1.5 on a strike on %s" % lane, failures)
	for lane in ["lane.house", "lane_condition.house_oil"]:
		_expect(_with_lane(catalogue, strike, reader, lane).mult == _with_lane(catalogue, strike, none, lane).mult, "nothing on House Oil (%s)" % lane, failures)
	var no_lane: Dictionary = C15._resolve(catalogue, strike, reader)
	_expect(no_lane.ok and no_lane.mult == C15._resolve(catalogue, strike, none).mult, "a frame with no lane in its context reads as House Oil", failures)
	var spare := [C15._rep(1, [1, 2, 3, 4, 5, 6], ALL), C15._rep(2, REST, REST)]
	_expect(_with_lane(catalogue, spare, reader, "lane_condition.long_oil").mult == _with_lane(catalogue, spare, none, "lane_condition.long_oil").mult, "nothing on a spare off House Oil", failures)

static func _line_call(catalogue: Dictionary, failures: Array[String]) -> void:
	var straight := [C15._rep(1, ALL, ALL)]
	var called: Dictionary = C15._resolve(catalogue, straight, SliceTest._loadout(), {1: ["consumable.line_call"]})
	_expect(called.ok and called.mult == C15._resolve(catalogue, straight).mult + 4.0 and called.lines.any(func(l): return l.contains("Line Call")), "Line Call: +4 Mult when the frame is straight", failures)
	var curved_other := [C15._rep(1, [1, 2, 3, 4, 5, 6], ALL), C15._rep(2, REST, REST, "ball.house", CURVE)]
	_expect(C15._resolve(catalogue, curved_other, SliceTest._loadout(), {1: ["consumable.line_call"]}).mult == C15._resolve(catalogue, curved_other).mult,
		"a curved roll later in the frame wastes it", failures)

static func _payouts(result: Dictionary) -> float:
	var total := 0.0
	for effect in result.get("future_effects", []):
		if effect.get("op") == "payout":
			total += float(effect.amount)
	return total

static func _money(catalogue: Dictionary, failures: Array[String]) -> void:
	var bounce: Dictionary = SliceTest._loadout({}, ["charm.bounce_back"])
	var rebound := [C15._rep(1, [1, 2, 3], ALL, "ball.house", 0.0, "clean", true), C15._rep(2, [4, 5, 6], [4, 5, 6, 7, 8, 9, 10])]
	_expect(_payouts(C15._resolve(catalogue, rebound, bounce)) == 3.0, "Bounce Back: +$3 after a frame with a rebound", failures)
	_expect(_payouts(C15._resolve(catalogue, [C15._rep(1, ALL, ALL)], bounce)) == 0.0, "nothing without one", failures)
	var money: Dictionary = SliceTest._loadout({}, ["charm.straight_money"])
	_expect(_payouts(C15._resolve(catalogue, [C15._rep(1, ALL, ALL)], money)) == 2.0, "Straight Money: +$2 after a straight strike", failures)
	_expect(_payouts(C15._resolve(catalogue, [C15._rep(1, ALL, ALL, "ball.house", CURVE)], money)) == 0.0, "nothing for a curved strike", failures)
	_expect(_payouts(C15._resolve(catalogue, [C15._rep(1, [1, 2, 3, 4, 5, 6], ALL), C15._rep(2, REST, REST)], money)) == 0.0, "nor a spare", failures)

## The new pieces are closed vocabularies: anything else is refused.
static func _validation(failures: Array[String]) -> void:
	var frame := {"schema_version": 2, "pins": [], "rolls": [], "charms": [], "context": {"lane_condition": "neon"}}
	_expect(Rules.validate(frame).any(func(e): return e.contains("lane_condition")), "a context lane that is not a lane condition id is refused", failures)
	var bad: Dictionary = {}
	for item in ContentSet.load_set("slice").catalogue.items:
		if item.id == "consumable.hook_shot": bad = item.duplicate(true)
	bad.physics = {"mass_scale": 2.0}
	var errors: Array[String] = []
	Contracts._catalogue([bad], 2, errors)
	_expect(errors.any(func(e): return e.contains("spin_response")), "a tactical card's physics is only spin_response", failures)
