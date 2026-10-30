extends RefCounted
## E18-C05: House Rules, House Pins, two-rule champions and the two House lane
## conditions.
## - House Rules: only the House Ball may be armed or committed; tactical cards stay.
## - House Pins: every racked pin scores as plain Wood (own effects, growth, payouts
##   and transforms off); pin modifications still apply; the bank says so.
## - Champions: DivisionRun.rules() carries a rival's extra rules, every rule must be
##   a known catalogue boss rule, and both rules apply together.
## - Lane conditions: Dry Backend is the campaign's dry fixture under its catalogue id;
##   House Oil is the standard pattern.
## - The House League spec (E17-L01) now validates against the shipped catalogue.
const Rules = preload("res://src/rules/frame_rules.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const RivalRules = preload("res://src/rules/rival_rules.gd")
const Division = preload("res://src/rules/division_run.gd")
const League = preload("res://src/rules/league_run.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const ContentSet = preload("res://src/rules/content_set.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const SliceTest = preload("res://tests/slice_test.gd")
const HOUSE_RULES := "boss_rule.house_rules"
const HOUSE_PINS := "boss_rule.house_pins"

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = ContentSet.load_set("slice").catalogue
	var ids: Array = catalogue.items.map(func(i): return i.id)
	_expect([HOUSE_RULES, HOUSE_PINS, "lane_condition.house_oil", "lane_condition.dry_backend"].all(func(id): return id in ids), "the four C05 items are in the catalogue", failures)
	_expect(RivalRules.unknown([HOUSE_RULES, HOUSE_PINS]).is_empty() and not RivalRules.unknown(["boss_rule.oil_slick"]).is_empty(), "House Rules and House Pins are known rules; unbuilt rules stay refused", failures)
	_house_rules(failures)
	_house_pins(catalogue, failures)
	_champion(catalogue, failures)
	_lanes(failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _house_rules(failures: Array[String]) -> void:
	var rules := [HOUSE_RULES]
	_expect(RivalRules.ball_allowed(rules, "ball.house") and not RivalRules.ball_allowed(rules, "ball.hook") and RivalRules.ball_allowed([], "ball.hook"),
		"House Rules allows only the House Ball", failures)
	var launch := RivalRules.constrain_launch(rules, {"ball_id": "ball.echo", "spin": 0.4})
	_expect(launch.ball_id == "ball.house" and is_equal_approx(float(launch.spin), 0.4), "a committed launch is thrown with the House Ball; its spin is kept", failures)
	_expect(RivalRules.constrain_launch(["boss_rule.dead_straight", HOUSE_RULES], {"ball_id": "ball.hook", "spin": 0.4}) == {"ball_id": "ball.house", "spin": 0.0},
		"with Dead Straight as well, both constraints apply", failures)

static func _score(catalogue: Dictionary, rules: Array, pins: Dictionary, reports: Array, pin_mods: Dictionary = {}) -> Dictionary:
	var loadout := SliceTest._loadout(pins)
	loadout["pin_mods"] = pin_mods
	var built := Builder.build(RivalRules.frame_loadout(rules, loadout), catalogue, reports)
	var result := Rules.resolve(built.frame)
	result["frame"] = built.frame
	return result

static func _house_pins(catalogue: Dictionary, failures: Array[String]) -> void:
	var rich := {1: "pin.ruby", 2: "pin.gold", 3: "pin.glass", 4: "pin.grower", 5: "pin.crown"}
	var strike := SliceTest._strike()
	var wood := _score(catalogue, [], {}, strike)
	var plain := _score(catalogue, [HOUSE_PINS], rich, strike)
	_expect(plain.score == wood.score and _score(catalogue, [], rich, strike).score != wood.score, "House Pins: a Ruby, Gold, Glass, Grower and Crown rack scores exactly as Wood", failures)
	_expect(not plain.future_effects.any(func(e): return e.op in ["payout", "transform", "grow_value"]), "no pin payout, break or growth under House Pins", failures)
	var keystone := _score(catalogue, [HOUSE_PINS], rich, strike, {5: "pin_mod.keystone"})
	_expect(keystone.score == int((wood.pin_value + 40) * wood.mult), "pin modifications still apply under House Pins", failures)
	var banked := RivalRules.bank([HOUSE_PINS], plain)
	_expect(banked.score == plain.score and banked.notes.size() == 1 and banked.notes[0].contains("plain Wood"), "the bank is unchanged and says the rack scored as Wood", failures)
	_expect(RivalRules.frame_loadout([], SliceTest._loadout(rich)).pins == SliceTest._loadout(rich).pins, "without House Pins the loadout is untouched", failures)

static func _champion(catalogue: Dictionary, failures: Array[String]) -> void:
	var house: Dictionary = Contracts.read_json("res://content/leagues/house.json")
	var errors: Array[String] = []
	for division in house.divisions:
		errors.append_array(Division.validate_spec(division, catalogue))
		for rival in division.rivals:
			errors.append_array(RivalRules.unknown([rival.rule] + rival.get("extra_rules", [])))
	_expect(errors.is_empty(), "the House League spec's eight Divisions validate against the shipped catalogue: %s" % str(errors), failures)
	var final: Dictionary = house.divisions[7].duplicate(true)
	var run := Division.create(final)
	for i in 2:
		run.record_frame(10000000)
		run.next_match()
	_expect(run.current().kind == "boss" and run.rules() == ["boss_rule.clean_sweep", HOUSE_RULES], "the champion's rules are Clean Sweep and House Rules: %s" % str(run.rules()), failures)
	var open := RivalRules.bank(run.rules(), {"score": 900, "category": "open"})
	_expect(open.score == 0 and not RivalRules.ball_allowed(run.rules(), "ball.hook"), "both champion rules apply together", failures)
	var bad: Dictionary = final.duplicate(true)
	bad.rivals[0].extra_rules = ["boss_rule.nope"]
	_expect(not Division.validate_spec(bad, catalogue).is_empty() and not RivalRules.unknown(bad.rivals[0].extra_rules).is_empty(), "an unknown extra rule is refused", failures)
	_expect(not League.validate({"schema_version": 1, "divisions": [bad]}, catalogue).is_empty(), "LeagueRun refuses it too", failures)

static func _lanes(failures: Array[String]) -> void:
	for f in [14.0, 16.0]:
		_expect(Lane.ball_friction(f, "lane_condition.dry_backend") == Lane.ball_friction(f, "lane.dry") and Lane.ball_friction(f, "lane_condition.dry_backend") > Lane.ball_friction(f),
			"Dry Backend raises backend friction exactly as the campaign's dry lane (f=%.0f)" % f, failures)
		_expect(Lane.ball_friction(f, "lane_condition.house_oil") == Lane.ball_friction(f), "House Oil is the standard pattern (f=%.0f)" % f, failures)
	_expect(Lane.ball_friction(5.0, "lane_condition.dry_backend") == Lane.ball_friction(5.0), "the oiled front lane is unchanged", failures)
