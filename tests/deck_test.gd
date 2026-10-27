extends RefCounted
## E07 equipment models: the proposed seeded draw/retain/cycle deck and the
## direct-selection comparison, plus tactical hydration into frame scoring.
const Deck = preload("res://src/rules/card_deck.gd")
const Direct = preload("res://src/rules/direct_loadout.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const ScoringTest = preload("res://tests/scoring_test.gd")
const STARTER := ["ball.lab_value", "ball.lab_value", "ball.lab_mult", "ball.lab_mult", "ball.lab_coin", "ball.lab_coin"]

static func conserved(deck) -> bool:
	var seen: Array = deck.hand + deck.draw_pile + deck.discard + deck.exhausted
	var unique := {}
	for uid in seen:
		unique[uid] = true
	return seen.size() == deck.cards.size() and unique.size() == deck.cards.size()

static func run() -> Array[String]:
	var failures: Array[String] = []
	var deck = Deck.create(STARTER + ["consumable.lab_focus"], 7)
	deck.start_frame()
	_expect(deck.hand.size() == 4 and deck.draw_pile.size() == 3 and conserved(deck), "first frame draws four", failures)
	var twin = Deck.create(STARTER + ["consumable.lab_focus"], 7)
	twin.start_frame()
	_expect(twin.hand == deck.hand and twin.draw_pile == deck.draw_pile, "same seed, same order", failures)
	var orders := {}
	for seed_value in range(1, 9):
		var other = Deck.create(STARTER + ["consumable.lab_focus"], seed_value)
		other.start_frame()
		orders[str(other.hand)] = true
	_expect(orders.size() > 1, "different seeds shuffle differently", failures)
	# Play, tactical limits and cycle.
	var ball_uid := ""
	var tactical_uid := ""
	var probe = Deck.create(["ball.lab_value", "consumable.lab_focus", "consumable.lab_focus", "ball.lab_mult", "ball.lab_coin"], 3)
	probe.start_frame()
	for option in probe.options():
		if option.kind == "ball" and ball_uid.is_empty(): ball_uid = option.uid
		if option.kind == "tactical" and tactical_uid.is_empty(): tactical_uid = option.uid
	_expect(not ball_uid.is_empty() and not tactical_uid.is_empty(), "hand offers ball and tactical cards", failures)
	_expect(probe.play(ball_uid, 1).is_empty() and ball_uid in probe.discard, "ball card goes to discard", failures)
	_expect(probe.play(tactical_uid, 1).is_empty() and tactical_uid in probe.exhausted, "tactical card is exhausted", failures)
	var second_tactical := ""
	for option in probe.options():
		if option.kind == "tactical": second_tactical = option.uid
	if not second_tactical.is_empty():
		_expect(not probe.play(second_tactical, 1).is_empty(), "one tactical per roll", failures)
		_expect(probe.play(second_tactical, 2).is_empty(), "tactical allowed on the next roll", failures)
	_expect(not probe.play("card-99", 1).is_empty(), "unknown card refused", failures)
	var before: int = deck.hand.size()
	var cycled_uid: String = deck.hand[0]
	_expect(deck.cycle(cycled_uid).is_empty() and deck.hand.size() == before and cycled_uid in deck.discard and conserved(deck), "cycle swaps one card", failures)
	_expect(not deck.cycle(deck.hand[0]).is_empty(), "cycle once per frame", failures)
	# Retain one, discard the rest.
	var keep: String = deck.hand[1]
	_expect(not deck.start_frame("card-99").is_empty(), "cannot retain a card not in hand", failures)
	_expect(deck.start_frame(keep).is_empty() and keep in deck.hand and deck.hand.size() == 4, "retained card stays in hand", failures)
	var big = Deck.create(STARTER + STARTER, 5)
	big.start_frame()
	var held: String = big.hand[2]
	var dropped: Array = big.hand.filter(func(uid): return uid != held)
	big.start_frame(held)
	_expect(big.reshuffles == 0 and dropped.all(func(uid): return uid in big.discard) and big.hand[0] == held and big.hand.size() == 4, "retain keeps one, discards three, draws three", failures)
	_expect(deck.can_cycle() and conserved(deck), "cycle resets each frame", failures)
	# Reshuffle when the draw pile empties; exhausted cards never return.
	var cycle_deck = Deck.create(STARTER + ["consumable.lab_focus"], 11)
	var exhausted_uid := ""
	for frame in 6:
		cycle_deck.start_frame()
		for option in cycle_deck.options():
			if option.kind == "tactical" and exhausted_uid.is_empty():
				cycle_deck.play(option.uid, 1)
				exhausted_uid = option.uid
	_expect(cycle_deck.reshuffles > 0 and conserved(cycle_deck), "empty draw pile reshuffles discard", failures)
	_expect(exhausted_uid in cycle_deck.exhausted and exhausted_uid not in cycle_deck.hand + cycle_deck.draw_pile + cycle_deck.discard, "exhausted cards never reshuffle", failures)
	cycle_deck.start_match()
	_expect(cycle_deck.hand.is_empty() and cycle_deck.discard.is_empty() and cycle_deck.draw_pile.size() == 6 and cycle_deck.frame == 0, "match start recombines non-exhausted cards", failures)
	# Only tactical cards, all exhausted: no options, House is still throwable.
	var spent = Deck.create(["consumable.lab_focus"], 1)
	spent.start_frame()
	spent.play(spent.hand[0], 1)
	spent.start_frame()
	_expect(spent.options().is_empty() and spent.counts().exhausted == 1, "empty deck leaves House as the only ball", failures)
	# Saves: a JSON round trip continues identically.
	var saved = JSON.parse_string(JSON.stringify(cycle_deck.to_dict()))
	var restored = Deck.from_dict(saved)
	for frame in 4:
		cycle_deck.start_frame()
		restored.start_frame()
	_expect(restored.hand == cycle_deck.hand and restored.draw_pile == cycle_deck.draw_pile and restored.reshuffles == cycle_deck.reshuffles, "JSON-restored deck continues identically", failures)
	_direct_cases(failures)
	_scoring_cases(failures)
	_experiment_cases(failures)
	return failures

static func _direct_cases(failures: Array[String]) -> void:
	var direct = Direct.create(["ball.lab_value", "ball.lab_mult", "ball.lab_coin"], ["consumable.lab_focus"])
	direct.start_frame()
	_expect(direct.specials.size() == 2 and direct.options().size() == 3, "direct bag: two specials and one tactical", failures)
	_expect(direct.play("ball.lab_value", 1).is_empty() and direct.uses["ball.lab_value"] == 1, "special use consumed", failures)
	direct.play("ball.lab_value", 2)
	_expect(not direct.options().any(func(o): return o.item_id == "ball.lab_value"), "special unavailable after two uses", failures)
	_expect(not direct.play("ball.lab_value", 1).is_empty(), "no third use", failures)
	_expect(direct.play("tactical-1", 1).is_empty() and direct.tacticals.is_empty() and direct.exhausted == ["tactical-1"], "direct tactical exhausts", failures)
	direct.start_match()
	_expect(direct.uses["ball.lab_value"] == 2 and direct.tacticals.is_empty(), "match restores uses, not exhausted tacticals", failures)
	_expect(not direct.can_cycle() and not direct.can_retain() and not direct.cycle("ball.lab_mult").is_empty(), "direct model has no cycle or retain", failures)

static func _scoring_cases(failures: Array[String]) -> void:
	var catalogue = Contracts.read_json(Builder.LAB_CATALOGUE)
	_expect(Contracts.validate("catalogue", catalogue).is_empty(), "lab catalogue with card fixtures validates", failures)
	var all := range(1, 11)
	var strike: Dictionary = ScoringTest.report(1, all, all)
	strike.launch.ball_id = "ball.lab_mult"
	strike.roll_result.ball_id = "ball.lab_mult"
	strike.knockdown_log.ball_id = "ball.lab_mult"
	var built := Builder.build(Builder.lab_loadout(), catalogue, [strike], {1: ["consumable.lab_focus"]})
	var result := Rules.resolve(built.frame) if built.ok else {}
	_expect(built.ok and result.score == 140 * (4 + 2 + 3), "card ball and tactical effects score", failures)
	var steps := ScoreLog.steps(result, built.frame, {"ball.lab_mult": "Lab Mult", "consumable.lab_focus": "Lab Focus"}, built.owners)
	var texts: Array = steps.map(func(s): return s.text)
	_expect("Roll 1 Lab Mult +2 Mult" in texts and "Roll 1 Lab Focus +3 Mult" in texts, "log names the tactical card, not the ball", failures)
	_expect(not Builder.build(Builder.lab_loadout(), catalogue, [strike], {1: ["ball.lab_value"]}).ok, "only consumables are tactical", failures)
	# A payout ball with a tactical: each effect is credited to its own card, and the
	# after-bank payout keeps the banked score on show.
	for key in ["launch", "roll_result", "knockdown_log"]:
		strike[key].ball_id = "ball.lab_coin"
	var coin := Builder.build(Builder.lab_loadout(), catalogue, [strike], {1: ["consumable.lab_focus"]})
	var coin_result := Rules.resolve(coin.frame) if coin.ok else {}
	var coin_steps := ScoreLog.steps(coin_result, coin.frame, {"ball.lab_coin": "Lab Coin", "consumable.lab_focus": "Lab Focus"}, coin.owners)
	var coin_texts: Array = coin_steps.map(func(s): return s.text)
	_expect(coin.ok and coin_result.score == 140 * (4 + 3), "payout ball adds no score", failures)
	_expect("Roll 1 Lab Focus +3 Mult" in coin_texts and coin_texts[-1] == "After bank: Roll 1 Lab Coin +$1 (roll)", "payout and tactical credited to their own cards", failures)
	_expect(coin_steps[-1].score == coin_result.score, "after-bank steps keep the banked score", failures)

## The ADR 004 experiment is deterministic and plays both models through the scorer.
static func _experiment_cases(failures: Array[String]) -> void:
	var experiment = load("res://tools/deck_experiment.gd")
	var first: Dictionary = experiment.simulate(12)
	var second: Dictionary = experiment.simulate(12)
	_expect(JSON.stringify(first) == JSON.stringify(second), "experiment is seeded and repeatable", failures)
	var policies: Dictionary = first.summary.policies
	_expect(policies.deck_greedy.match_score_mean > policies.house.match_score_mean and policies.direct_greedy.match_score_mean > policies.house.match_score_mean,
		"special balls lift the House baseline in both models", failures)
	_expect(policies.deck_greedy.cycles_per_run > 0 and policies.direct_greedy.cycles_per_run == 0, "only the deck cycles", failures)

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition: failures.append(label)
