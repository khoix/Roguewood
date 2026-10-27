extends SceneTree
## E07 structural experiment (ADR 004): plays the real draw/retain/cycle deck and the
## real direct-selection bag through many seeded runs and scores every frame with
## FrameRules. Pinfall comes from a synthetic, seeded outcome stream that is
## identical for every policy on a seed, so differences come only from equipment.
## It measures structure (availability, choice breadth, decision leverage,
## variance), not fun: that is the human vertical-slice playtest's call.
## Usage: godot --headless --script res://tools/deck_experiment.gd -- [--runs=N] [--out=path]
const Deck = preload("res://src/rules/card_deck.gd")
const Direct = preload("res://src/rules/direct_loadout.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const DECK := ["ball.lab_value", "ball.lab_value", "ball.lab_mult", "ball.lab_mult", "ball.lab_coin", "ball.lab_coin", "consumable.lab_focus"]
const DIRECT_BALLS := ["ball.lab_value", "ball.lab_mult"]
const DIRECT_TACTICALS := ["consumable.lab_focus"]
const MATCHES := 8 # one run of eight two-frame matches
const MATCH_FRAMES := 2
## Greedy preference for score: Mult first, then Value; Coin pays money, not score.
const RANK := {"ball.lab_mult": 3, "ball.lab_value": 2, "ball.lab_coin": 1}
## house throws only the House ball; greedy plays the best card, cycles away its
## weakest ball without a Mult card and keeps its best; random picks uniformly
## (House included) and cycles/keeps on a coin flip.
const POLICIES := ["house", "deck_greedy", "deck_random", "direct_greedy", "direct_random"]
const STRIKE_CHANCE := 0.3
const SPARE_CHANCE := 0.4
const GRADES := ["miss", "clean", "clean", "sweet", "perfect"]

func _init() -> void:
	var runs := 1000
	var out := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="): runs = int(arg.get_slice("=", 1))
		if arg.begins_with("--out="): out = arg.get_slice("=", 1)
	var report := simulate(runs)
	print(JSON.stringify(report.summary, "  "))
	if not out.is_empty():
		var file := FileAccess.open(out, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "  "))
	print("ROGUEWOOD_EXPERIMENT_OK")
	quit(0)

## Seeded synthetic pinfall for a whole run: [match][frame] -> [{fallen, accuracy}].
static func outcomes(seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + 17
	var run: Array = []
	for m in MATCHES:
		var frames: Array = []
		for f in MATCH_FRAMES:
			var order: Array = range(1, 11)
			for i in range(9, 0, -1):
				var j := rng.randi_range(0, i)
				var swap = order[i]
				order[i] = order[j]
				order[j] = swap
			var first: int = 10 if rng.randf() < STRIKE_CHANCE else rng.randi_range(5, 9)
			var rolls: Array = [{"fallen": order.slice(0, first), "accuracy": GRADES[rng.randi_range(0, GRADES.size() - 1)]}]
			if first < 10:
				var second: int = 10 - first if rng.randf() < SPARE_CHANCE else rng.randi_range(0, 9 - first)
				rolls.append({"fallen": order.slice(first, first + second), "accuracy": GRADES[rng.randi_range(0, GRADES.size() - 1)]})
			frames.append(rolls)
		run.append(frames)
	return run

static func simulate(runs: int) -> Dictionary:
	var catalogue: Dictionary = Contracts.read_json(Builder.LAB_CATALOGUE)
	var per: Dictionary = {}
	for policy in POLICIES:
		per[policy] = {"scores": [], "money": [], "special_rolls": 0, "tactical_rolls": 0, "rolls": 0, "frames": 0,
			"choices": 0, "ball_types_offered": 0, "mult_available": 0, "no_ball_frames": 0, "cycles": 0, "retains": 0, "reshuffles": 0}
	for seed_value in range(1, runs + 1):
		var run := outcomes(seed_value)
		for policy in POLICIES:
			_play_run(policy, seed_value, run, catalogue, per[policy])
	var summary := {"runs": runs, "matches_per_run": MATCHES, "frames_per_match": MATCH_FRAMES,
		"outcome_model": {"strike": STRIKE_CHANCE, "spare": SPARE_CHANCE, "first_roll_count": "5-9 uniform", "accuracy": GRADES}, "policies": {}}
	var house_mean := _mean(per.house.scores)
	for policy in POLICIES:
		var p: Dictionary = per[policy]
		var mean := _mean(p.scores)
		summary.policies[policy] = {"match_score_mean": snappedf(mean, 0.01), "match_score_sd": snappedf(_sd(p.scores, mean), 0.01),
			"match_score_p10": _percentile(p.scores, 0.1), "match_score_p90": _percentile(p.scores, 0.9),
			"uplift_vs_house": snappedf(mean / house_mean - 1.0, 0.001), "money_per_match": snappedf(_mean(p.money), 0.001),
			"special_ball_roll_rate": snappedf(float(p.special_rolls) / p.rolls, 0.001), "tactical_plays_per_run": snappedf(float(p.tactical_rolls) / runs, 0.001),
			"choices_per_frame": snappedf(float(p.choices) / p.frames, 0.001), "ball_types_offered_per_roll": snappedf(float(p.ball_types_offered) / p.rolls, 0.001),
			"best_ball_available_rate": snappedf(float(p.mult_available) / p.rolls, 0.001), "frames_without_ball_card": snappedf(float(p.no_ball_frames) / p.frames, 0.001),
			"cycles_per_run": snappedf(float(p.cycles) / runs, 0.001), "retains_per_run": snappedf(float(p.retains) / runs, 0.001),
			"reshuffles_per_run": snappedf(float(p.reshuffles) / runs, 0.001)}
		if policy == "house": # the deck is dealt but never played: only the score baseline means anything
			for key in summary.policies.house.keys():
				if not key.begins_with("match_score") and key != "uplift_vs_house":
					summary.policies.house.erase(key)
	for model in ["deck", "direct"]:
		var greedy: float = summary.policies[model + "_greedy"].match_score_mean
		var random: float = summary.policies[model + "_random"].match_score_mean
		summary[model + "_decision_leverage"] = snappedf(greedy / random - 1.0, 0.001)
	return {"summary": summary}

static func _play_run(policy: String, seed_value: int, run: Array, catalogue: Dictionary, stats: Dictionary) -> void:
	var rng := RandomNumberGenerator.new() # policy choices only; never the deck's stream
	rng.seed = seed_value * 104729 + POLICIES.find(policy)
	var model = Direct.create(DIRECT_BALLS, DIRECT_TACTICALS) if policy.begins_with("direct") else Deck.create(DECK, seed_value)
	var greedy := policy.ends_with("greedy")
	for m in MATCHES:
		if m > 0:
			model.start_match()
		var match_score := 0
		var money := 0.0
		var keep := ""
		for f in MATCH_FRAMES:
			model.start_frame(keep)
			keep = ""
			stats.frames += 1
			if not model.options().any(func(o): return o.kind == "ball"):
				stats.no_ball_frames += 1
			if model.can_cycle() and policy != "house":
				stats.choices += 1
				var cycle_uid := _cycle_choice(model, greedy, rng)
				if not cycle_uid.is_empty() and model.cycle(cycle_uid).is_empty():
					stats.cycles += 1
			var frame_rolls: Array = run[m][f]
			var rolls: Array = []
			for r in frame_rolls.size():
				var options: Array = model.options()
				var balls: Array = options.filter(func(o): return o.kind == "ball")
				var types := {}
				for o in balls:
					types[o.item_id] = true
				stats.rolls += 1
				stats.ball_types_offered += types.size()
				if types.has("ball.lab_mult"):
					stats.mult_available += 1
				var ball_id := "ball.house"
				var tactical_ids: Array = []
				if policy != "house":
					if not types.is_empty():
						stats.choices += 1
					var pick := _ball_choice(balls, greedy, rng)
					if not pick.is_empty() and model.play(pick.uid, r + 1).is_empty():
						ball_id = pick.item_id
						stats.special_rolls += 1
					var tacticals: Array = options.filter(func(o): return o.kind == "tactical")
					if not tacticals.is_empty():
						stats.choices += 1
						if (greedy or rng.randf() < 0.5) and model.play(tacticals[0].uid, r + 1).is_empty():
							tactical_ids.append(tacticals[0].item_id)
							stats.tactical_rolls += 1
				var effects: Array = Builder.item(catalogue, ball_id).effects.duplicate(true)
				for tactical_id in tactical_ids:
					effects.append_array(Builder.item(catalogue, tactical_id).effects.duplicate(true))
				rolls.append({"roll_index": r + 1, "ball_id": ball_id, "fallen_positions": frame_rolls[r].fallen, "accuracy": frame_rolls[r].accuracy, "effects": effects})
			var result := Rules.resolve(_frame(catalogue, rolls))
			assert(result.ok)
			match_score += int(result.score)
			for event in result.future_effects:
				if event.op == "payout":
					money += float(event.amount)
			if f < MATCH_FRAMES - 1 and model.can_retain() and not model.hand.is_empty() and policy != "house":
				stats.choices += 1
				keep = _retain_choice(model, greedy, rng)
				if not keep.is_empty():
					stats.retains += 1
		stats.scores.append(match_score)
		stats.money.append(money)
	if model.MODEL == "deck":
		stats.reshuffles += model.reshuffles

static func _ball_choice(balls: Array, greedy: bool, rng: RandomNumberGenerator) -> Dictionary:
	if balls.is_empty():
		return {}
	if greedy:
		var best: Dictionary = balls[0]
		for o in balls:
			if RANK[o.item_id] > RANK[best.item_id]:
				best = o
		return best
	var pick := rng.randi_range(0, balls.size()) # the last index is House
	return {} if pick == balls.size() else balls[pick]

## Greedy cycles away its weakest ball when no Mult card is in hand.
static func _cycle_choice(model, greedy: bool, rng: RandomNumberGenerator) -> String:
	var balls: Array = model.options().filter(func(o): return o.kind == "ball")
	if greedy:
		if balls.is_empty() or balls.any(func(o): return o.item_id == "ball.lab_mult"):
			return ""
		var worst: Dictionary = balls[0]
		for o in balls:
			if RANK[o.item_id] < RANK[worst.item_id]:
				worst = o
		return worst.uid
	return model.hand[rng.randi_range(0, model.hand.size() - 1)] if rng.randf() < 0.5 else ""

static func _retain_choice(model, greedy: bool, rng: RandomNumberGenerator) -> String:
	if greedy:
		var best := ""
		for uid in model.hand:
			var id: String = model.cards[uid]
			if best.is_empty() or RANK.get(id, 4) > RANK.get(model.cards[best], 4):
				best = uid
		return best
	return model.hand[rng.randi_range(0, model.hand.size() - 1)] if rng.randf() < 0.5 else ""

static func _frame(catalogue: Dictionary, rolls: Array) -> Dictionary:
	var pins: Array = []
	var wood := Builder.item(catalogue, "pin.wood")
	for position in range(1, 11):
		pins.append({"position": position, "item_id": wood.id, "effects": wood.effects.duplicate(true)})
	return {"schema_version": 1, "pins": pins, "rolls": rolls, "charms": []}

static func _mean(values: Array) -> float:
	var total := 0.0
	for v in values:
		total += float(v)
	return total / maxf(values.size(), 1)

static func _sd(values: Array, mean: float) -> float:
	var total := 0.0
	for v in values:
		total += pow(float(v) - mean, 2)
	return sqrt(total / maxf(values.size(), 1))

static func _percentile(values: Array, q: float) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[clampi(int(q * (sorted.size() - 1)), 0, sorted.size() - 1)])
