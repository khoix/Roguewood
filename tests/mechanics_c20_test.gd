extends RefCounted
## E18-C20 (the rules and lanes of E17-L03): the Salvage League's three boss rules
## and two lane conditions.
## - Frugal House: items pay no money in the match; the house keeps the payouts.
## - Dull Pins: every Value a pin adds is halved, rounded down per effect, copies
##   and retriggers included; Charm Value and every Mult are untouched.
## - Rust: every ball and pin modification is off; the hosts work as normal.
## - Grit drags the ball on the front 30 ft; Warped Boards pushes it right between
##   20 and 40 ft. The physics suite rolls both through a real lane (physics_test
##   `_salvage`).
const ContentSet = preload("res://src/rules/content_set.gd")
const RivalRules = preload("res://src/rules/rival_rules.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
const Division = preload("res://src/rules/division_run.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const FRUGAL := "boss_rule.frugal_house"
const DULL := "boss_rule.dull_pins"
const RUST := "boss_rule.rust"
const IDS := [FRUGAL, DULL, RUST, "lane_condition.grit", "lane_condition.warped_boards"]
const WOOD := {"op": "add_value", "amount": 10, "trigger": "fallen", "scope": "frame"}
const TIN := [{"op": "add_value", "amount": 5, "trigger": "fallen", "scope": "frame"}, {"op": "payout", "amount": 1, "trigger": "standing", "scope": "frame"}]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = ContentSet.load_set("slice").catalogue
	var items := {}
	for item in catalogue.items:
		items[item.id] = item
	_expect(IDS.all(func(id): return items.has(id) and items[id].completeness.mechanics and float(items[id].pool_weight) == 0.0),
		"the three Salvage rules and two Salvage lanes are in the catalogue, never sold", failures)
	_expect(RivalRules.unknown([FRUGAL, DULL, RUST]).is_empty(), "the Salvage rules are known rules", failures)
	for rule in [FRUGAL, DULL, RUST]:
		_expect(RivalRules.summary(rule).length() > 30 and RivalRules.summary(rule) != rule, "%s has a summary" % rule, failures)
		_expect(RivalRules.lane_rules([rule]).is_empty(), "%s does not change the roll" % rule, failures)
	_dull(failures)
	_frugal(failures)
	_rust(failures)
	_lanes(failures)
	var salvage: Dictionary = Contracts.read_json("res://content/leagues/salvage.json")
	for d in salvage.divisions:
		var errors := Division.validate_spec(d, catalogue)
		_expect(errors.is_empty(), "Salvage Division %d validates against the shipped catalogue: %s" % [int(d.division), str(errors)], failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _pins(effects: Array = [WOOD], item_id: String = "pin.wood") -> Array:
	var pins: Array = []
	for position in range(1, 11):
		pins.append({"position": position, "item_id": item_id, "effects": effects.duplicate(true)})
	return pins

static func _roll(index: int, fallen: Array, effects: Array = []) -> Dictionary:
	return {"roll_index": index, "ball_id": "ball.house", "fallen_positions": fallen, "accuracy": "clean", "effects": effects.duplicate(true),
		"first_direct": fallen[0] if not fallen.is_empty() else 0, "last_fallen": fallen[-1] if not fallen.is_empty() else 0, "curved": false}

static func _frame(rolls: Array, pins: Array = _pins(), charms: Array = [], rules: Array = []) -> Dictionary:
	return {"schema_version": 2, "pins": pins, "rolls": rolls, "charms": charms,
		"context": RivalRules.frame_context(rules, {"match_frame": 1, "strike_streak": 0})}

static func _dull(failures: Array[String]) -> void:
	var all: Array = range(1, 11)
	_expect(RivalRules.frame_context([DULL], {"match_frame": 1}) == {"match_frame": 1, "pin_value_scale": 0.5} and RivalRules.frame_context([RUST, FRUGAL], {"match_frame": 1}) == {"match_frame": 1},
		"Dull Pins sets the frame's pin_value_scale; no other rule changes the context", failures)
	var plain: Dictionary = Rules.resolve(_frame([_roll(1, all)]))
	var dull: Dictionary = Rules.resolve(_frame([_roll(1, all)], _pins(), [], [DULL]))
	_expect(plain.ok and plain.score == 560 and dull.ok and dull.score == 360, "a Wood strike: (40 + 10 × 10) × 4 = 560; dulled, (40 + 10 × 5) × 4 = 360 (%s)" % str(dull.get("score", dull.get("errors"))), failures)
	var tin: Dictionary = Rules.resolve(_frame([_roll(1, all)], _pins(TIN, "pin.tin"), [], [DULL]))
	_expect(tin.ok and tin.pin_value == 60.0, "each Tin pin's 5 rounds down to 2: 40 + 10 × 2 = 60 (%s)" % str(tin.get("pin_value", tin.get("errors"))), failures)
	var favourite := {"item_id": "charm.house_favorite", "effects": [{"op": "add_value", "amount": 60, "trigger": "charm", "scope": "frame", "condition": {"all_house": true}}], "growth": 0}
	var counter := {"item_id": "charm.pin_counter", "effects": [{"op": "add_mult", "amount": 1, "trigger": "charm", "scope": "frame", "per": "fallen"}], "growth": 0}
	var charmed: Dictionary = Rules.resolve(_frame([_roll(1, all)], _pins(), [favourite, counter], [DULL]))
	_expect(charmed.ok and charmed.pin_value == 150.0 and charmed.mult == 14.0 and charmed.score == 2100, "Charm Value (+60) and Mult (+10) are untouched: 150 × 14 = 2100 (%s)" % str(charmed.get("score", charmed.get("errors"))), failures)
	var retrigger := [{"op": "retrigger", "amount": 1, "trigger": "ball", "scope": "roll"}]
	var echoed: Dictionary = Rules.resolve(_frame([_roll(1, all, retrigger)], _pins(), [], [DULL]))
	_expect(echoed.ok and echoed.pin_value == 95.0, "a retriggered pin's copy is halved too: 40 + 11 × 5 = 95 (%s)" % str(echoed.get("pin_value", echoed.get("errors"))), failures)
	var ball_value := [{"op": "add_value", "amount": 15, "trigger": "ball", "scope": "roll"}]
	var balled: Dictionary = Rules.resolve(_frame([_roll(1, all, ball_value)], _pins(), [], [DULL]))
	_expect(balled.ok and balled.pin_value == 105.0, "a ball's own Value is not a pin's: 40 + 50 + 15 = 105", failures)
	var event: Dictionary = dull.events.filter(func(e): return e.get("op", "") == "add_value")[0] if dull.ok else {}
	_expect(event.get("amount", 0.0) == 5.0 and event.get("dulled_from", 0.0) == 10.0, "the event keeps the full amount it was dulled from", failures)
	var steps := ScoreLog.steps(dull, _frame([_roll(1, all)], _pins(), [], [DULL]))
	_expect(steps.any(func(s): return String(s.text).contains("Dull Pins: Half of 10")), "the log marks each halved step", failures)
	_expect(not RivalRules.bank([DULL], dull).notes.is_empty() and RivalRules.bank([DULL], dull).score == 360, "Dull Pins banks the dulled score, with a rule line", failures)
	var bad := _frame([_roll(1, all)])
	bad.context["pin_value_scale"] = 1.5
	_expect(not Rules.validate(bad).is_empty(), "a pin_value_scale above 1 is refused", failures)

static func _frugal(failures: Array[String]) -> void:
	var fund := {"item_id": "charm.strike_fund", "effects": [{"op": "payout", "amount": 1, "trigger": "charm", "scope": "frame", "condition": {"category": ["strike"]}}], "growth": 0}
	var open: Dictionary = Rules.resolve(_frame([_roll(1, [1, 2, 3, 4, 5, 6]), _roll(2, [7])], _pins(TIN, "pin.tin")))
	var standing: int = open.future_effects.filter(func(e): return e.op == "payout").size()
	var paid: Dictionary = RivalRules.paid([FRUGAL], open)
	_expect(open.ok and standing == 3 and int(paid.kept) == 3 and not paid.result.future_effects.any(func(e): return e.op == "payout"),
		"Frugal House keeps the three standing Tin pins' $1 each", failures)
	_expect(open.future_effects.size() == 3 and paid.result.score == open.score, "the resolved result and its score are unchanged", failures)
	var strike: Dictionary = Rules.resolve(_frame([_roll(1, range(1, 11))], _pins(), [fund]))
	_expect(int(RivalRules.paid([FRUGAL], strike).kept) == 1 and int(RivalRules.paid([], strike).kept) == 0 and RivalRules.paid([], strike).result == strike,
		"a Charm's payout is kept too; without the rule everything is paid", failures)
	var notes: Array = RivalRules.bank([FRUGAL], open).notes
	_expect(notes.size() == 1 and String(notes[0]).contains("$3") and RivalRules.bank([FRUGAL], plain_open()).notes.is_empty(),
		"the log names what the house kept, and says nothing when nothing was paid", failures)

static func plain_open() -> Dictionary:
	return Rules.resolve(_frame([_roll(1, [1, 2, 3]), _roll(2, [])]))

static func _rust(failures: Array[String]) -> void:
	var loadout := {"pins": {1: "pin.wood", 2: "pin.ruby"}, "charms": ["charm.flat_bonus"], "pin_mods": {1: "pin_mod.brass_cap"}, "pin_growth": {2: 3}}
	var rusted := RivalRules.frame_loadout([RUST], loadout)
	_expect(RivalRules.mods_off([RUST]) and not RivalRules.mods_off([DULL, FRUGAL]), "only Rust switches modifications off", failures)
	_expect(rusted.pin_mods.is_empty() and rusted.pins == loadout.pins and rusted.pin_growth == loadout.pin_growth and rusted.charms == loadout.charms and loadout.pin_mods.size() == 1,
		"Rust scores the rack without its pin modifications; pins, growth and Charms stay, and the run keeps its modifications", failures)
	var both := RivalRules.frame_loadout([RUST, "boss_rule.house_pins"], loadout)
	_expect(both.pin_mods.is_empty() and both.pins.values().all(func(p): return p == "pin.wood"), "with House Pins too, the rack is plain Wood without modifications", failures)
	_expect(RivalRules.frame_loadout([DULL], loadout) == loadout, "Dull Pins leaves the loadout as it is", failures)
	_expect(RivalRules.bank([RUST], plain_open()).notes.size() == 1, "Rust adds a rule line", failures)

static func _lanes(failures: Array[String]) -> void:
	var v := Vector3(0.1, 0.0, -6.0)
	_expect(Lane.lane_force("lane_condition.house_oil", 3.0, 0.0, v, Lane.BALL_MASS) == Vector3.ZERO and Lane.lane_force("lane.house", 8.0, 0.0, v, Lane.BALL_MASS) == Vector3.ZERO,
		"House Oil pushes nothing", failures)
	var grit := Lane.lane_force(Lane.GRIT, 3.0, 0.0, v, Lane.BALL_MASS)
	_expect(grit.is_equal_approx(-Vector3(0.1, 0.0, -6.0) * Lane.GRIT_DRAG) and Lane.lane_force(Lane.GRIT, Lane.GRIT_END_F, 0.0, v, Lane.BALL_MASS) == Vector3.ZERO,
		"Grit drags against the ball's travel on the front 30 ft, and stops there", failures)
	_expect(Lane.lane_force(Lane.GRIT, 3.0, 0.0, v, Lane.BALL_MASS * 1.6) == grit, "the drag is a force, so a heavier ball slows less", failures)
	var warp := Lane.lane_force(Lane.WARPED_BOARDS, 8.0, -0.2, v, Lane.BALL_MASS)
	_expect(warp.is_equal_approx(Vector3(Lane.WARP_DRIFT * Lane.BALL_MASS, 0.0, 0.0)) and Lane.lane_force(Lane.WARPED_BOARDS, 5.0, 0.0, v, Lane.BALL_MASS) == Vector3.ZERO
		and Lane.lane_force(Lane.WARPED_BOARDS, 12.5, 0.0, v, Lane.BALL_MASS) == Vector3.ZERO, "Warped Boards pushes right between 20 and 40 ft only", failures)
	_expect(Lane.lane_force(Lane.WARPED_BOARDS, 8.0, Lane.LANE_HALF_WIDTH + 0.05, v, Lane.BALL_MASS) == Vector3.ZERO and Lane.lane_force(Lane.GRIT, 3.0, -0.6, v, Lane.BALL_MASS) == Vector3.ZERO,
		"a ball in the gutter is not pushed", failures)
	_expect(Lane.oil_end(Lane.GRIT) == Lane.OIL_END_F and Lane.oil_end(Lane.WARPED_BOARDS) == Lane.OIL_END_F and Lane.ball_friction(3.0, Lane.GRIT) == Lane.OIL_FRICTION,
		"the oil and its friction are unchanged on both", failures)
