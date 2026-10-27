extends RefCounted
## E13 vertical slice (ADR 008): the catalogue v2 extension (conditions, per-count
## scaling, Echo's first-direct-pin retrigger, run growth, the strike streak and
## match-end growth), every slice item's rule against hand-computed scores, refusals
## of malformed v2 content and frames, the two-Division League, Dead Straight, item
## physics profiles, content sets and kits, and run-state round trips.
const Contracts = preload("res://src/contracts/contracts.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
const League = preload("res://src/rules/league_run.gd")
const RivalRules = preload("res://src/rules/rival_rules.gd")
const RunInventory = preload("res://src/rules/run_inventory.gd")
const ContentSet = preload("res://src/rules/content_set.gd")
const ItemPhysics = preload("res://src/simulation/item_physics.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const ScoringTest = preload("res://tests/scoring_test.gd")
const ALL := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var content := ContentSet.load_set("slice")
	_expect(content.errors.is_empty(), "the slice content set validates: %s" % str(content.errors), failures)
	var catalogue: Dictionary = content.catalogue
	_catalogue_counts(catalogue, failures)
	_frame_scores(catalogue, failures)
	_echo(catalogue, failures)
	_growth(catalogue, failures)
	_catalogue_refusals(catalogue, failures)
	_frame_refusals(catalogue, failures)
	_league(content, failures)
	_rules(failures)
	_physics(catalogue, failures)
	_content_sets(content, failures)
	return failures

## Rack: Wood everywhere except the given positions.
static func _loadout(overrides: Dictionary = {}, charms: Array = []) -> Dictionary:
	var pins := {}
	for position in ALL:
		pins[position] = overrides.get(position, "pin.wood")
	return {"pins": pins, "charms": charms}

## A synthetic roll report (ScoringTest's contracts) thrown with one ball and spin.
static func _rep(roll_index: int, fallen: Array, racked: Array, ball: String = "ball.house", spin: float = 0.0) -> Dictionary:
	var r := ScoringTest.report(roll_index, fallen, racked)
	r.launch.ball_id = ball
	r.launch.spin = spin
	r.roll_result.ball_id = ball
	r.knockdown_log.ball_id = ball
	return r

static func _strike(ball: String = "ball.house", spin: float = 0.0) -> Array:
	return [_rep(1, ALL.duplicate(), ALL, ball, spin)]

static func _spare(first: Array) -> Array:
	var rest: Array = ALL.filter(func(p): return p not in first)
	return [_rep(1, first, ALL), _rep(2, rest, rest)]

static func _open(first: Array, second: Array) -> Array:
	var rest: Array = ALL.filter(func(p): return p not in first)
	return [_rep(1, first, ALL), _rep(2, second, rest)]

## Builds and resolves; returns the result with the frame and readable steps.
static func _score(catalogue: Dictionary, loadout: Dictionary, reports: Array, context: Dictionary = {}) -> Dictionary:
	var built := Builder.build(loadout, catalogue, reports, {}, context)
	if not built.ok:
		return {"ok": false, "score": -1, "errors": built.errors}
	var result := Rules.resolve(built.frame)
	if not result.ok:
		return result
	result.frame = built.frame
	var names := {}
	for entry in catalogue.items:
		names[entry.id] = entry.name
	result.lines = ScoreLog.steps(result, built.frame, names, built.owners).map(func(s): return s.text)
	return result

static func _catalogue_counts(catalogue: Dictionary, failures: Array[String]) -> void:
	var by := {}
	for entry in catalogue.items:
		by[entry.category] = by.get(entry.category, []) + [entry.id]
		_expect(entry.completeness.authored and entry.completeness.mechanics and not entry.completeness.artwork and not entry.completeness.effects_audio
			and not entry.completeness.integrated, "%s: completeness is honest (no art or effects yet)" % entry.id, failures)
	_expect(by.ball.size() == 4 and by.pin.size() == 6 and by.charm.size() == 12 and by.boss_rule.size() == 2 and by.kit.size() == 1,
		"batch E13-S01: four balls, six pins, twelve Charms, two boss rules, one kit", failures)

static func _frame_scores(catalogue: Dictionary, failures: Array[String]) -> void:
	var r := _score(catalogue, _loadout(), _strike())
	_expect(r.score == 560 and r.frame.schema_version == 2, "a base Wood strike is 560 in a v2 frame", failures)
	# Design §6 worked build, and Finisher's condition.
	var rubies := {4: "pin.ruby", 9: "pin.ruby"}
	_expect(_score(catalogue, _loadout(rubies, ["charm.flat_bonus", "charm.finisher"]), _strike()).score == 3360, "strike, two Ruby, Flat Bonus then Finisher: 3360", failures)
	_expect(_score(catalogue, _loadout(rubies, ["charm.finisher", "charm.flat_bonus"]), _strike()).score == 2800, "reversed Charm order: 2800", failures)
	var spare := _score(catalogue, _loadout(rubies, ["charm.flat_bonus", "charm.finisher"]), _spare([1, 2, 3, 4, 5, 6, 7]))
	_expect(spare.score == 120 * 10 and not spare.lines.any(func(l): return l.contains("Finisher")), "Finisher stays silent on a spare (1200)", failures)
	var finisher := _score(catalogue, _loadout({}, ["charm.finisher"]), _strike())
	_expect(finisher.score == 1120 and finisher.lines.any(func(l): return l.contains("Finisher ×2 Mult (strike)")), "the log says why Finisher applied", failures)
	_expect(_score(catalogue, _loadout({}, ["charm.spare_change"]), _spare([1, 2, 3])).score == 120 * 8, "Spare Change: +6 Mult on a spare", failures)
	_expect(_score(catalogue, _loadout({}, ["charm.spare_change"]), _strike()).score == 560, "Spare Change ignores strikes", failures)
	# Lone Survivor: an open frame with exactly one pin standing.
	_expect(_score(catalogue, _loadout({}, ["charm.lone_survivor"]), _open([1, 2, 3, 4, 5, 6, 7, 8], [9])).score == 90 * 3, "Lone Survivor ×3 with one pin standing (270)", failures)
	_expect(_score(catalogue, _loadout({}, ["charm.lone_survivor"]), _open([1, 2, 3, 4, 5, 6, 7], [8])).score == 80, "Lone Survivor needs exactly one standing", failures)
	# Hook Artist: either roll curved past the documented threshold.
	var curved: Array = _spare([1, 2, 3, 4, 5])
	curved[1] = _rep(2, [6, 7, 8, 9, 10], [6, 7, 8, 9, 10], "ball.house", 0.5)
	_expect(_score(catalogue, _loadout({}, ["charm.hook_artist"]), curved).score == 120 * 6, "Hook Artist +4 Mult when a roll curved", failures)
	_expect(_score(catalogue, _loadout({}, ["charm.hook_artist"]), _strike("ball.house", Lane.CURVE_SPIN_THRESHOLD - 0.01)).score == 560, "below the curve threshold is straight", failures)
	# House Favorite: every roll used the House ball.
	_expect(_score(catalogue, _loadout({}, ["charm.house_favorite"]), _strike()).score == 200 * 4, "House Favorite +60 Value on an all-House frame", failures)
	_expect(_score(catalogue, _loadout({}, ["charm.house_favorite"]), _strike("ball.hammer")).score == 560, "House Favorite needs every roll on House", failures)
	# Gold Rush counts Gold pins down this frame; Gold pins pay once each.
	var golds := {2: "pin.gold", 3: "pin.gold", 10: "pin.gold"}
	var rush := _score(catalogue, _loadout(golds, ["charm.gold_rush"]), _open([1, 2, 3, 4, 5, 6], [7]))
	_expect(rush.score == 70 * (1 + 4) and rush.future_effects.filter(func(e): return e.op == "payout").size() == 2
		and rush.lines.any(func(l): return l.contains("Gold Rush +4 Mult (2 × +2 per Gold Pin down)")), "Gold Rush +2 Mult per Gold pin down, explained", failures)
	_expect(_score(catalogue, _loadout({}, ["charm.gold_rush"]), _strike()).score == 560, "Gold Rush is nothing without Gold pins", failures)
	# Turkey Club: from the third consecutive strike; the streak is frame context.
	var turkey := _score(catalogue, _loadout({}, ["charm.turkey_club"]), _strike(), {"strike_streak": 2})
	_expect(turkey.score == 1120 and turkey.strike_streak == 3, "Turkey Club ×2 on the third strike in a row", failures)
	_expect(_score(catalogue, _loadout({}, ["charm.turkey_club"]), _strike(), {"strike_streak": 1}).score == 560, "Turkey Club waits for the third strike", failures)
	_expect(_score(catalogue, _loadout({}, ["charm.turkey_club"]), _spare([1]), {"strike_streak": 5}).strike_streak == 0, "a non-strike resets the streak", failures)
	# Last Chance: the second frame of a match.
	_expect(_score(catalogue, _loadout({}, ["charm.last_chance"]), _strike(), {"match_frame": 2}).score == 1120, "Last Chance ×2 in frame 2", failures)
	_expect(_score(catalogue, _loadout({}, ["charm.last_chance"]), _strike(), {"match_frame": 1}).score == 560, "Last Chance idle in frame 1", failures)
	# Anchor (+3 Mult standing) and Standing Order (+2 Mult per standing Anchor).
	var anchors := {7: "pin.anchor", 10: "pin.anchor"}
	var standing := _score(catalogue, _loadout(anchors, ["charm.standing_order"]), _open([1, 2, 3, 4, 5, 6], [8, 9]))
	_expect(standing.score == 80 * (1 + 3 + 3 + 4), "two standing Anchors with Standing Order: 80 × 11", failures)
	_expect(_score(catalogue, _loadout(anchors, ["charm.standing_order"]), _strike()).score == 560, "fallen Anchors add only Value", failures)

## Echo: the first pin the ball knocks down directly scores again, in its slot.
static func _echo(catalogue: Dictionary, failures: Array[String]) -> void:
	var order: Array = [5, 1, 2, 3, 4, 6, 7, 8, 9, 10] # pin 5 is the first direct knockdown
	var reports := [_rep(1, order, ALL, "ball.echo")]
	var r := _score(catalogue, _loadout({5: "pin.ruby"}, ["charm.encore"]), reports)
	_expect(r.frame.rolls[0].first_direct == 5 and r.retriggers == 1, "Echo targets the first direct knockdown", failures)
	_expect(r.score == (40 + 100 + 10) * (4 + 2 + 2 + 3), "Echo repeats Ruby's Value and Mult; Encore +3 per retrigger (1650)", failures)
	_expect(r.lines.any(func(l): return l.contains("Pin 5 Ruby Pin +2 Mult (retrigger 1 · Roll 1 Echo Ball)")), "the retrigger names its ball", failures)
	var gold := _score(catalogue, _loadout({5: "pin.gold"}), reports)
	_expect(gold.score == 150 * 4 and gold.future_effects.filter(func(e): return e.op == "payout").size() == 1, "income is never retriggered", failures)
	var plain := _score(catalogue, _loadout({5: "pin.ruby"}, ["charm.encore"]), [_rep(1, order, ALL)])
	_expect(plain.retriggers == 0 and plain.score == 140 * 6, "without Echo there is no retrigger and Encore is silent", failures)
	# A pin knocked down by another pin is not a direct hit.
	var chain := _rep(1, [1, 2], ALL, "ball.echo")
	chain.knockdown_log.knockdowns[0].merge({"cause": "pin", "source_position": 2, "chain_depth": 2}, true)
	chain.knockdown_log.knockdowns[1].sequence = 2
	_expect(Builder.first_direct(chain.knockdown_log) == 2, "pin-caused knockdowns are skipped", failures)

## Grower and Patient Investor grow in the run; the run applies the growth.
static func _growth(catalogue: Dictionary, failures: Array[String]) -> void:
	var run = RunInventory.create(catalogue, ["pin.grower"] + _woods(9), ["ball.echo"])
	run.charms.append(RunInventory._entry("charm.patient_investor", 6))
	var first := _score(catalogue, run.loadout(), _strike())
	_expect(first.score == 560 and first.future_effects.any(func(e): return e.op == "grow_value" and e.source == "pin:1"), "a fresh Grower adds 10 and grows once", failures)
	var grown: Array = run.apply_frame(first, first.frame)
	_expect(grown.size() == 1 and run.rack[1].growth == 1 and run.strike_streak == 1, "the run banks Grower's growth and the streak", failures)
	var echoed := _score(catalogue, run.loadout(), [_rep(1, ALL.duplicate(), ALL, "ball.echo")])
	_expect(echoed.score == (40 + 100 + 5 + 15) * 4, "grown Grower +15 Value, repeated by Echo (growth not repeated)", failures)
	_expect(echoed.future_effects.filter(func(e): return e.op == "grow_value").size() == 1, "a retrigger never grows twice", failures)
	_expect(echoed.lines.any(func(l): return l.contains("Grower Pin +5 Value (1 × +5 per growth)")), "growth scaling is explained", failures)
	var settled: Dictionary = run.settle_match(2)
	_expect(settled.grown.size() == 1 and run.charms[0].growth == 1, "Patient Investor grows after a completed match", failures)
	_expect(_score(catalogue, run.loadout(), _spare([1])).mult == 2 + 1, "Patient Investor then adds +1 Mult", failures)
	var back = RunInventory.from_dict(JSON.parse_string(JSON.stringify(run.to_dict())), catalogue)
	_expect(back.rack[1].growth == 1 and back.charms[0].growth == 1 and back.strike_streak == 1, "growth and the streak survive JSON", failures)
	var old: Dictionary = run.to_dict()
	old.erase("strike_streak")
	for key in old.rack:
		old.rack[key].erase("growth")
	_expect(RunInventory.from_dict(old, catalogue).rack[1].growth == 0, "older run saves load with no growth", failures)

static func _woods(n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append("pin.wood")
	return out

static func _catalogue_refusals(catalogue: Dictionary, failures: Array[String]) -> void:
	var mutations := {
		"a v1 catalogue cannot use conditions": func(c): c.schema_version = 1,
		"a retrigger belongs to a ball": func(c): _find(c, "pin.wood").effects[0].op = "retrigger",
		"match end only grows": func(c): _find(c, "charm.patient_investor").effects[1].op = "add_mult",
		"multipliers do not scale per count": func(c): _find(c, "charm.finisher").effects[0]["per"] = "growth",
		"per needs a known item": func(c): _find(c, "charm.gold_rush").effects[0].per = "fallen:pin.platinum",
		"per needs a known count": func(c): _find(c, "charm.gold_rush").effects[0].per = "rolls",
		"only balls and pins have physics": func(c): _find(c, "charm.flat_bonus")["physics"] = {"mass_scale": 1.2},
		"pins have no spin response": func(c): _find(c, "pin.anchor").physics["spin_response"] = 1.2,
		"physics stays within bounds": func(c): _find(c, "ball.hammer").physics.mass_scale = 5.0,
		"conditions use the closed vocabulary": func(c): _find(c, "charm.finisher").effects[0].condition["weather"] = "rain",
		"deferred effects are unconditional": func(c): _find(c, "pin.gold").effects[1].merge({"trigger": "after_bank", "condition": {"curved": true}}, true),
		"a retrigger is a whole count": func(c): _find(c, "ball.echo").effects[0].amount = 1.5,
	}
	for label in mutations:
		var bad: Dictionary = catalogue.duplicate(true)
		mutations[label].call(bad)
		_expect(not Contracts.validate("catalogue", bad).is_empty(), "refused: " + label, failures)

static func _find(catalogue: Dictionary, id: String) -> Dictionary:
	for entry in catalogue.items:
		if entry.id == id:
			return entry
	return {}

static func _frame_refusals(catalogue: Dictionary, failures: Array[String]) -> void:
	var built := Builder.build(_loadout(), catalogue, _strike())
	var v1: Dictionary = built.frame.duplicate(true)
	v1.schema_version = 1
	_expect(not Rules.validate(v1).is_empty(), "a v1 frame cannot carry v2 fields", failures)
	var bad: Dictionary = built.frame.duplicate(true)
	bad.rolls[0].fallen_positions = [1, 2]
	bad.rolls.append({"roll_index": 2, "ball_id": "ball.house", "fallen_positions": [], "accuracy": "miss", "effects": [], "first_direct": 0, "curved": false})
	bad.rolls[0].first_direct = 7
	_expect(Rules.validate(bad).any(func(e): return e.contains("first_direct")), "first_direct must have fallen that roll", failures)
	bad = built.frame.duplicate(true)
	bad.context.match_frame = 0
	_expect(not Rules.validate(bad).is_empty(), "context is bounded", failures)
	bad = built.frame.duplicate(true)
	bad.charms.append({"item_id": "charm.x", "effects": [{"op": "add_mult", "amount": 1, "trigger": "charm", "scope": "frame", "condition": {"category": ["gutter"]}}]})
	_expect(not Rules.validate(bad).is_empty(), "unknown categories in conditions are refused", failures)

## Two Divisions chained: a non-final boss win continues; the last boss wins.
static func _league(content: Dictionary, failures: Array[String]) -> void:
	var specs: Array = content.divisions
	var league = League.create(specs)
	_expect(league.division_count() == 2 and league.division_number() == 1 and league.current().kind == "opener", "the League starts at Division 1's opener", failures)
	for m in 3:
		league.record_frame(league.target())
		if m < 2:
			league.next_match()
	_expect(league.match_over() and league.division_cleared() and league.outcome == "" and not league.is_finished(), "beating Division 1's boss continues the attempt", failures)
	_expect(league.rival().id == "rival.surveyor" and league.next_division().division == 2, "the cleared boss and the next Division are known", failures)
	league.next_match()
	_expect(league.division_number() == 2 and league.current().kind == "opener" and league.rules().is_empty() and league.boss().rival == "rival.custodian", "Division 2 starts at its opener with its own boss", failures)
	league.record_frame(league.target())
	var saved = League.from_dict(JSON.parse_string(JSON.stringify(league.to_dict())), specs)
	_expect(saved.division_number() == 2 and saved.results.size() == 4 and saved.results[0].division == 1 and saved.results[3].division == 2
		and JSON.stringify(saved.to_dict()) == JSON.stringify(league.to_dict()), "the League survives JSON mid-Division", failures)
	league.next_match()
	league.record_frame(league.target())
	league.next_match()
	_expect(league.rules() == ["boss_rule.clean_sweep"], "the Custodian's rule applies in its boss match", failures)
	var losing = League.from_dict(league.to_dict(), specs)
	losing.record_frame(0)
	losing.record_frame(league.target() - 1)
	_expect(losing.outcome == "lost" and losing.is_finished(), "missing the last boss ends the attempt", failures)
	league.record_frame(league.target())
	_expect(league.outcome == "won" and league.is_finished() and not league.division_cleared() and league.results.size() == 6, "beating the last boss wins the attempt", failures)
	var early = League.create(specs)
	early.record_frame(0)
	early.record_frame(0)
	_expect(early.outcome == "lost", "losing Division 1's opener ends the attempt", failures)
	var practice = League.create(specs, true)
	for i in 8:
		practice.record_frame(10000)
		practice.next_match()
	_expect(practice.division_number() == 1 and practice.outcome == "", "practice never leaves Division 1", failures)
	# League refusals.
	var bad := {"schema_version": 1, "divisions": specs.duplicate(true)}
	bad.divisions[1].rivals[0].rule = "boss_rule.dead_straight"
	_expect(League.validate(bad, content.catalogue).any(func(e): return e.contains("repeated")), "a boss rule cannot repeat within the attempt", failures)
	bad = {"schema_version": 1, "divisions": specs.duplicate(true)}
	bad.divisions[1].matches[0].target = 400
	_expect(League.validate(bad, content.catalogue).any(func(e): return e.contains("rise")), "targets keep rising across Divisions", failures)
	bad = {"schema_version": 1, "divisions": specs.duplicate(true)}
	bad.divisions[1].division = 3
	_expect(not League.validate(bad, content.catalogue).is_empty(), "Divisions are numbered in order", failures)

static func _rules(failures: Array[String]) -> void:
	var launch := {"spin": 0.8, "power": 0.6}
	_expect(RivalRules.spin_disabled(["boss_rule.dead_straight"]) and RivalRules.constrain_launch(["boss_rule.dead_straight"], launch).spin == 0.0
		and launch.spin == 0.8, "Dead Straight commits zero spin (without changing the input)", failures)
	_expect(RivalRules.constrain_launch(["boss_rule.clean_sweep"], launch).spin == 0.8 and not RivalRules.spin_disabled([]), "other rules leave spin alone", failures)
	_expect(RivalRules.bank(["boss_rule.clean_sweep"], {"score": 90, "category": "open"}).score == 0, "production Clean Sweep banks open frames as 0", failures)
	_expect(RivalRules.bank(["boss_rule.dead_straight"], {"score": 90, "category": "open"}).score == 90, "Dead Straight never changes banking", failures)
	_expect(RivalRules.summary("boss_rule.dead_straight").contains("spin is disabled") and RivalRules.unknown(["boss_rule.dead_straight", "boss_rule.clean_sweep"]).is_empty(), "both slice rules are known", failures)

static func _physics(catalogue: Dictionary, failures: Array[String]) -> void:
	var p := ItemPhysics.profiles(catalogue, {1: "pin.wood", 2: "pin.anchor", 3: "pin.rubber"})
	_expect(p.balls["ball.house"] == ItemPhysics.BALL_DEFAULT and p.balls["ball.echo"] == ItemPhysics.BALL_DEFAULT, "House and Echo keep House physics", failures)
	_expect(p.balls["ball.hook"].spin_response > 1.0 and p.balls["ball.hammer"].mass_scale > 1.0 and p.balls["ball.hammer"].spin_response < 1.0, "Hook hooks more; Hammer is heavier and hooks less", failures)
	_expect(p.pins[1].mass_scale == 1.0 and p.pins[1].bounce == Lane.PIN_BOUNCE and p.pins[2].mass_scale > 1.0 and p.pins[3].bounce > Lane.PIN_BOUNCE,
		"Wood keeps the lab pin; Anchor is heavier; Rubber is bouncier", failures)

static func _content_sets(content: Dictionary, failures: Array[String]) -> void:
	_expect(content.kit.pins == _woods(10) and content.kit.deck.size() == 6 and int(content.kit.money) == 6 and content.divisions.size() == 2,
		"the slice kit: ten Wood pins, six special-ball cards (two each), $6; two Divisions", failures)
	var lab := ContentSet.load_set("lab")
	_expect(lab.errors.is_empty() and lab.divisions.size() == 1 and lab.kit.deck == ContentSet.LAB_KIT.deck, "the lab content set keeps the E09 Division and lab kit", failures)
	_expect(not ContentSet.load_set("nonsense").errors.is_empty(), "unknown content sets are refused", failures)
	var kit: Dictionary = content.kit.duplicate(true)
	kit.deck.append("ball.hook")
	_expect(not ContentSet.validate_kit(kit, content.catalogue).is_empty(), "a kit holds at most two copies of a card", failures)
	kit = content.kit.duplicate(true)
	kit.deck.append("ball.house")
	_expect(not ContentSet.validate_kit(kit, content.catalogue).is_empty(), "the House ball stays outside the deck", failures)
	kit = content.kit.duplicate(true)
	kit.pins[0] = "charm.flat_bonus"
	_expect(not ContentSet.validate_kit(kit, content.catalogue).is_empty(), "kit pins are catalogue pins", failures)

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)
