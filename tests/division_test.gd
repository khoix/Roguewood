extends RefCounted
## E09 Division loop: the fixture spec, match targets and budgets, early victory,
## loss, boss victory, practice mode, Clean Sweep banking, reaction precedence and
## cooldown, and save round trips.
const Division = preload("res://src/rules/division_run.gd")
const RivalRules = preload("res://src/rules/rival_rules.gd")
const Reactions = preload("res://src/presentation/rival_reactions.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const ScoringTest = preload("res://tests/scoring_test.gd")
const SPEC := "res://content/fixtures/lab_division.json"

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = Contracts.read_json(Builder.LAB_CATALOGUE)
	var spec: Dictionary = Contracts.read_json(SPEC)
	_expect(Contracts.validate("catalogue", catalogue).is_empty(), "lab catalogue with the boss rule validates", failures)
	_expect(Division.validate_spec(spec, catalogue).is_empty(), "lab Division spec validates: %s" % str(Division.validate_spec(spec, catalogue)), failures)
	_spec_refusals(spec, catalogue, failures)
	_flow(spec, failures)
	_practice(spec, failures)
	_clean_sweep(catalogue, failures)
	_reactions(failures)
	return failures

static func _spec_refusals(spec: Dictionary, catalogue: Dictionary, failures: Array[String]) -> void:
	var bad: Dictionary = spec.duplicate(true)
	bad.matches[1].target = 100
	_expect(not Division.validate_spec(bad, catalogue).is_empty(), "targets must rise", failures)
	bad = spec.duplicate(true)
	bad.matches[2].erase("rival")
	_expect(not Division.validate_spec(bad, catalogue).is_empty(), "the boss needs a rival", failures)
	bad = spec.duplicate(true)
	bad.rivals[0].rule = "charm.lab_tally"
	_expect(not Division.validate_spec(bad, catalogue).is_empty(), "a rival's rule must be a catalogue boss_rule", failures)
	bad = spec.duplicate(true)
	bad.matches.reverse()
	_expect(not Division.validate_spec(bad, catalogue).is_empty(), "opener, feature, boss order", failures)

static func _flow(spec: Dictionary, failures: Array[String]) -> void:
	var d = Division.create(spec)
	_expect(d.current().kind == "opener" and d.target() == 300 and d.frames_left() == 2 and d.rules().is_empty(), "the attempt opens with the opener", failures)
	_expect(d.boss().target == 800 and d.rival_for(d.boss()).name == "The Custodian", "the boss and its rival are known from the start", failures)
	# A frame that crosses the target ends the match at once, with a frame unused.
	var first: Dictionary = d.record_frame(560)
	_expect(first.over and first.won and d.match_over() and d.frames_left() == 1 and d.results[0].frames == 1, "crossing the target ends the match after that frame", failures)
	_expect(d.record_frame(100).has("error") and d.match_score == 560, "no frames after the match is over", failures)
	_expect(d.next_match().is_empty() and d.current().kind == "feature" and d.match_score == 0 and d.frames_left() == 2, "next match: the feature", failures)
	_expect(not d.next_match().is_empty(), "cannot skip a match in progress", failures)
	var a: Dictionary = d.record_frame(240)
	_expect(not a.over and d.match_score == 240, "below target, the match continues", failures)
	var b: Dictionary = d.record_frame(260)
	_expect(b.over and b.won and d.match_score == 500, "reaching the target exactly wins", failures)
	d.next_match()
	_expect(d.is_boss() and d.rules() == [RivalRules.CLEAN_SWEEP] and d.target() == 800, "the boss match carries its rule", failures)
	d.record_frame(560)
	var lost: Dictionary = d.record_frame(0)
	_expect(lost.over and not lost.won and d.outcome == "lost" and d.is_finished(), "falling short after the budget loses the attempt", failures)
	_expect(not d.next_match().is_empty(), "nothing follows a lost attempt", failures)
	var w = Division.create(spec)
	for score in [560]: w.record_frame(score)
	w.next_match()
	w.record_frame(560)
	w.next_match()
	w.record_frame(560)
	var win: Dictionary = w.record_frame(560)
	_expect(win.won and w.outcome == "won" and w.results.size() == 3, "defeating the boss wins the Division", failures)
	var early = Division.create(spec)
	early.record_frame(70)
	early.record_frame(70)
	_expect(early.outcome == "lost" and early.results[0].score == 140, "an opener loss ends the attempt", failures)
	var saved = Division.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())), spec)
	_expect(JSON.stringify(saved.to_dict()) == JSON.stringify(d.to_dict()), "Division state round-trips through JSON", failures)
	var mid = Division.create(spec)
	mid.record_frame(120)
	var mid_saved = Division.from_dict(JSON.parse_string(JSON.stringify(mid.to_dict())), spec)
	_expect(mid_saved.record_frame(200).won and mid_saved.match_score == 320, "a restored match continues", failures)

static func _practice(spec: Dictionary, failures: Array[String]) -> void:
	var p = Division.create(spec, true)
	var huge: Dictionary = p.record_frame(5000)
	_expect(not huge.over and p.target() == 0, "practice has no target", failures)
	_expect(p.record_frame(0).over and p.outcome == "" and p.next_match().is_empty(), "practice matches play their budget and never end the attempt", failures)
	_expect(p.current().kind == "practice" and p.rules().is_empty(), "practice has no rival rule", failures)

static func _clean_sweep(catalogue: Dictionary, failures: Array[String]) -> void:
	var all := range(1, 11)
	var strike := _resolve(catalogue, [ScoringTest.report(1, all, all)])
	var open := _resolve(catalogue, [ScoringTest.report(1, [1, 2, 3], all), ScoringTest.report(2, [4, 5], range(4, 11))])
	_expect(strike.category == "strike" and open.category == "open", "fixture frames", failures)
	var kept: Dictionary = RivalRules.bank([RivalRules.CLEAN_SWEEP], strike)
	var swept: Dictionary = RivalRules.bank([RivalRules.CLEAN_SWEEP], open)
	_expect(kept.score == strike.score and kept.notes.is_empty(), "Clean Sweep banks strikes in full", failures)
	_expect(swept.score == 0 and swept.notes.size() == 1 and swept.notes[0].contains("Clean Sweep") and open.score > 0, "Clean Sweep banks nothing for an open frame", failures)
	_expect(RivalRules.bank([], open).score == open.score, "without a rule, open frames bank", failures)
	_expect(not RivalRules.unknown(["boss_rule.mystery"]).is_empty() and RivalRules.unknown([RivalRules.CLEAN_SWEEP]).is_empty(), "unknown rules are refused", failures)

static func _resolve(catalogue: Dictionary, reports: Array) -> Dictionary:
	var built := Builder.build(Builder.lab_loadout(), catalogue, reports)
	return Rules.resolve(built.frame) if built.ok else {"category": "invalid: " + str(built.errors), "score": -1}

static func _reactions(failures: Array[String]) -> void:
	var r = Reactions.new()
	var second := 1000000
	_expect(r.react("entrance", 0) == "entrance", "entrance shows", failures)
	_expect(r.react("strike", 1 * second) == "", "same-rank reactions wait for the cooldown", failures)
	_expect(r.react("near_victory", 1 * second + 1) == "threatened", "higher precedence interrupts", failures)
	_expect(r.react("gutter", 2 * second) == "", "lower precedence is suppressed while cooling", failures)
	_expect(r.react("victory", 2 * second + 1) == "defeated", "the result reaction always shows", failures)
	_expect(r.react("strike", 5 * second + 2) == "impressed", "after the cooldown play reactions return", failures)
	_expect(r.visible_at(5 * second + 2) == "impressed" and r.visible_at(9 * second) == "", "a reaction shows briefly", failures)
	var spam = Reactions.new()
	var shown := 0
	for i in 20:
		if not spam.react("strike", i * 100000).is_empty(): shown += 1
	_expect(shown == 1, "a burst of events cannot spam reactions (%d shown)" % shown, failures)
	_expect(r.react("unknown", 0) == "", "unknown events are ignored", failures)

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition: failures.append(label)
