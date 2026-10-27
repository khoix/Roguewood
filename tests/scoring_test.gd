extends RefCounted
## E06 frame assembly from roll reports, readable calculation steps, and scoring
## bounds. Reports are synthetic but satisfy the same contracts as LaneWorld's.
const Contracts = preload("res://src/contracts/contracts.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")

static func report(roll_index: int, fallen: Array, racked: Array, accuracy: String = "clean") -> Dictionary:
	var id := "t-%d-%s" % [roll_index, str(fallen.size())]
	var launch := {"schema_version": 1, "launch_id": id, "ball_id": "ball.house", "roll_index": roll_index, "start_x": 0.0,
		"direction_x": 0.0, "direction_forward": 1.0, "power": 0.5, "spin": 0.0, "target_x": 0.11, "ring_radius": 0.3}
	var knockdowns: Array = []
	for i in fallen.size():
		knockdowns.append({"position": fallen[i], "sequence": i + 1, "tick": 100 + i, "cause": "ball", "source_position": 0, "chain_depth": 1, "reason": "tilt"})
	var standing: Array = racked.filter(func(p): return p not in fallen)
	return {"launch": launch,
		"roll_result": {"schema_version": 1, "launch_id": id, "ball_id": "ball.house", "roll_index": roll_index, "fallen_positions": fallen, "accuracy": accuracy},
		"knockdown_log": {"schema_version": 1, "launch_id": id, "ball_id": "ball.house", "roll_index": roll_index, "knockdowns": knockdowns,
			"standing": standing, "gutter": false, "voided_positions": [], "target_crossed": true, "target_offset": 0.05, "settle": "settled", "ticks": 500}}

static func scored(reports: Array) -> Dictionary:
	var catalogue = Contracts.read_json(Builder.LAB_CATALOGUE)
	var built := Builder.build(Builder.lab_loadout(), catalogue, reports)
	if not built.ok:
		return built
	var result := Rules.resolve(built.frame)
	result.frame = built.frame
	return result

static func run() -> Array[String]:
	var failures: Array[String] = []
	var all := range(1, 11)
	_expect(Contracts.validate("catalogue", Contracts.read_json(Builder.LAB_CATALOGUE)).is_empty(), "lab catalogue satisfies the catalogue contract", failures)
	var strike := scored([report(1, all, all)])
	_expect(strike.ok and strike.category == "strike" and strike.score == 560, "lab strike scores 560", failures)
	var spare := scored([report(1, [1, 2, 3, 4, 5, 6, 7], all), report(2, [8, 9, 10], [8, 9, 10])])
	_expect(spare.ok and spare.category == "spare" and spare.score == 240, "lab spare scores 240", failures)
	var open := scored([report(1, [1, 2, 3, 4, 5, 6, 7, 8], all), report(2, [9], [9, 10], "miss")])
	_expect(open.ok and open.category == "open" and open.score == 90, "lab open scores 90", failures)
	var precise := scored([report(1, [1, 2, 3, 4, 5, 6, 7, 8], all, "sweet"), report(2, [9], [9, 10], "perfect")])
	_expect(precise.ok and precise.score == 90 * 3, "best accuracy awarded once per frame", failures)
	var gutter := scored([report(1, [], all, "miss"), report(2, [], all, "miss")])
	_expect(gutter.ok and gutter.category == "open" and gutter.score == 0, "double gutter scores 0", failures)
	_expect(not scored([report(1, [1, 2], all)]).ok, "incomplete frame refused", failures)
	_expect(not scored([report(1, all, all), report(2, [], [])]).ok, "strike ends the frame", failures)
	_expect(not scored([report(1, [1, 2], all), report(2, [2, 3], [2, 3, 4])]).ok, "pin credited in two rolls refused", failures)
	var tampered := report(1, all, all)
	tampered.knockdown_log.knockdowns.pop_back()
	_expect(not scored([tampered]).ok, "log must credit exactly the result's pins", failures)
	var catalogue = Contracts.read_json(Builder.LAB_CATALOGUE)
	var bad_loadout := Builder.lab_loadout()
	bad_loadout.pins[4] = "pin.missing"
	_expect(not Builder.build(bad_loadout, catalogue, [report(1, all, all)]).ok, "unknown loadout item refused", failures)
	_log_cases(strike, failures)
	_bounds(failures)
	return failures

static func _log_cases(strike: Dictionary, failures: Array[String]) -> void:
	var steps := ScoreLog.steps(strike, strike.frame, {"pin.wood": "Wood"})
	_expect(steps[0].phase == "category" and steps[0].text.begins_with("Strike") and steps[0].pin_value == 40.0 and steps[0].mult == 4.0, "log opens with the category base", failures)
	var pin_order: Array = steps.filter(func(s): return s.pin > 0).map(func(s): return s.pin)
	_expect(pin_order == range(1, 11), "fallen pins resolve by original position", failures)
	_expect(steps[1].text == "Pin 1 Wood +10 Value" and steps[1].symbol == "+" and steps[1].pin_value == 50.0, "pin step names item, symbol and running value", failures)
	_expect(steps[-1].phase == "bank" and steps[-1].score == 560 and steps[-1].text == "Bank ⌊140 × 4⌋ = 560", "log ends with the single bank", failures)
	_expect(steps[-2].phase == "accuracy" and steps[-2].text == "Accuracy clean +0 Mult", "accuracy step once before Charms and bank", failures)
	# Design's ordering example: Ruby pins and two Charms in both orders.
	var ruby: Dictionary = strike.frame.duplicate(true)
	for index in [8, 9]:
		ruby.pins[index].item_id = "pin.ruby"
		ruby.pins[index].effects.append({"op": "add_mult", "amount": 2, "trigger": "fallen", "scope": "frame"})
	ruby.charms = [{"item_id": "charm.flat_bonus", "effects": [{"op": "add_mult", "amount": 4, "trigger": "charm", "scope": "frame"}]},
		{"item_id": "charm.finisher", "effects": [{"op": "multiply_mult", "amount": 2, "trigger": "charm", "scope": "frame"}]}]
	var forward := ScoreLog.steps(Rules.resolve(ruby), ruby)
	_expect(forward[-1].score == 3360 and forward[-3].text == "Charm 1 +4 Mult" and forward[-2].symbol == "×" and forward[-2].mult == 24.0, "3360 log shows add then multiply", failures)
	ruby.charms.reverse()
	var reverse := ScoreLog.steps(Rules.resolve(ruby), ruby)
	_expect(reverse[-1].score == 2800 and reverse[-3].text == "Charm 1 ×2 Mult" and reverse[-2].mult == 20.0, "2800 log shows multiply then add", failures)
	# Every step mirrors the resolver's running numbers: presentation cannot rescore.
	var result := Rules.resolve(ruby)
	var replay := ScoreLog.steps(result, ruby)
	for i in replay.size():
		var event: Dictionary = result.events[i]
		if event.has("pin_value") and event.phase != "bank":
			_expect(replay[i].pin_value == event.pin_value and replay[i].mult == event.mult, "step %d mirrors event totals" % i, failures)

static func _bounds(failures: Array[String]) -> void:
	var catalogue = Contracts.read_json(Builder.LAB_CATALOGUE)
	var all := range(1, 11)
	var frame: Dictionary = Builder.build(Builder.lab_loadout(), catalogue, [report(1, all, all)]).frame
	var capped: Dictionary = frame.duplicate(true)
	capped.pins[0].retriggers = 8
	_expect(Rules.resolve(capped).get("score") == (140 + 80) * 4, "eight retriggers is the bound", failures)
	capped.pins[0].retriggers = 9
	_expect(not Rules.resolve(capped).ok, "ninth retrigger refused", failures)
	var big: Dictionary = frame.duplicate(true)
	big.pins[0].effects.append({"op": "add_value", "amount": 1000000, "trigger": "fallen", "scope": "frame"})
	big.charms = [{"item_id": "charm.big", "effects": [{"op": "multiply_mult", "amount": 1000000, "trigger": "charm", "scope": "frame"}]}]
	var near := Rules.resolve(big)
	_expect(near.ok and near.score == 1000140 * 4000000, "large exact score banks", failures)
	big.charms[0].effects.append({"op": "multiply_mult", "amount": 1000000, "trigger": "charm", "scope": "frame"})
	_expect(not Rules.resolve(big).ok, "overflow beyond exact range refused, never wrapped", failures)
	_expect(ScoreLog._n(4000560000000) == "4000560000000" and ScoreLog._n(1.5) == "1.50", "log formats large integers exactly", failures)

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition: failures.append(label)
