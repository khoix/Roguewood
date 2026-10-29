extends SceneTree
## E13 slice build-strategy simulation (ADR 008). Plays whole seeded attempts of the
## production slice (two Divisions, six matches) with the real run inventory, shop,
## equipment deck, League, boss rules, frame builder and resolver. Only pinfall is
## synthetic: a documented, seeded model of an ordinary player (below) in which the
## ball, charged spin, Dead Straight and Anchor mass change the odds. Each strategy
## buys, places, orders and throws towards one build; baselines buy nothing or buy
## at random. It measures whether distinct builds can win the slice and how they
## score, not feel or fun: that needs human play on a device.
## Usage: godot --headless --script res://tools/slice_strategies.gd -- [--runs=N] [--out=path] [--unlocked]
const ContentSet = preload("res://src/rules/content_set.gd")
const League = preload("res://src/rules/league_run.gd")
const RunInventory = preload("res://src/rules/run_inventory.gd")
const Shop = preload("res://src/rules/shop.gd")
const Deck = preload("res://src/rules/card_deck.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const RivalRules = preload("res://src/rules/rival_rules.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const ALL := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
## Ordinary-player pinfall model (synthetic, provisional).
const STRIKE := 0.28 # House ball, straight, at the pocket
const BALL_STRIKE := {"ball.hammer": 0.10, "ball.hook": 0.08} # Hook's bonus needs spin
const CURVE_STRIKE := 0.05 # any charged (curved) shot: a better entry angle
const HOOK_OVERCURVE := 0.10 # Hook Ball: chance a charged throw misses the pocket badly
const ANCHOR_STRIKE := -0.03 # per racked Anchor (heavier pins)
const POCKET := 0.75 # the head pin is the first direct knockdown
const SPARE := 0.40
const LEAVE_ONE := 0.50 # an intentional single-pin leave on roll two
const GRADES := ["miss", "clean", "clean", "sweet", "perfect"]
## Strategy: wanted pins (with preferred rack spots), wanted Charms (priority
## order), ball preference, whether it charges spin, and its frame plan.
const STRATEGIES := {
	"strike_chain": {"pins": {"pin.ruby": [1, 2, 3, 5, 4, 6]}, "charms": ["charm.flat_bonus", "charm.finisher", "charm.turkey_club", "charm.last_chance", "charm.spare_change"],
		"balls": ["ball.hammer", "ball.hook", "ball.house"], "spin": true, "plan": "strike"},
	"echo_ruby": {"pins": {"pin.ruby": [1, 3, 2, 5, 4, 6]}, "charms": ["charm.flat_bonus", "charm.encore", "charm.spare_change", "charm.last_chance", "charm.finisher"],
		"balls": ["ball.echo", "ball.hammer", "ball.house"], "spin": false, "plan": "strike"},
	"gold_growth": {"pins": {"pin.grower": [1, 2, 3, 5], "pin.gold": [4, 6, 8, 9, 7, 10]}, "charms": ["charm.gold_rush", "charm.patient_investor", "charm.flat_bonus", "charm.last_chance", "charm.spare_change"],
		"balls": ["ball.hammer", "ball.house"], "spin": false, "plan": "strike"},
	"anchor_survivor": {"pins": {"pin.anchor": [7, 10, 4, 6]}, "charms": ["charm.lone_survivor", "charm.standing_order", "charm.last_chance", "charm.flat_bonus", "charm.spare_change"],
		"balls": ["ball.house", "ball.hammer"], "spin": false, "plan": "leave_one"},
	"hook_artist": {"pins": {"pin.ruby": [1, 2, 3]}, "charms": ["charm.hook_artist", "charm.flat_bonus", "charm.finisher", "charm.last_chance"],
		"balls": ["ball.hook", "ball.hammer", "ball.house"], "spin": true, "plan": "strike"},
	"house_only": {"pins": {}, "charms": [], "balls": ["ball.house"], "spin": false, "plan": "strike"},
	"random_buyer": {"pins": {}, "charms": [], "balls": [], "spin": false, "plan": "strike", "random": true},
}

func _init() -> void:
	var runs := 400
	var out := ""
	var unlocked := "--unlocked" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="): runs = int(arg.get_slice("=", 1))
		if arg.begins_with("--out="): out = arg.get_slice("=", 1)
	var report := simulate(runs, unlocked)
	print(JSON.stringify(report.summary, "  "))
	if not out.is_empty():
		var file := FileAccess.open(out, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "  "))
	print("ROGUEWOOD_SLICE_SIM_OK")
	quit(0)

static func simulate(runs: int, unlocked: bool = false) -> Dictionary:
	var content := ContentSet.load_set("slice")
	var summary := {"runs": runs, "career_unlocks": unlocked, "targets": content.divisions.map(func(d): return d.matches.map(func(m): return int(m.target))),
		"outcome_model": {"strike": STRIKE, "ball_strike": BALL_STRIKE, "curve_strike": CURVE_STRIKE, "hook_overcurve": HOOK_OVERCURVE,
			"anchor_strike": ANCHOR_STRIKE, "pocket": POCKET, "spare": SPARE, "leave_one": LEAVE_ONE, "first_roll_count": "6-9 uniform", "accuracy": GRADES},
		"strategies": {}}
	for name in STRATEGIES:
		var stats := {"won": 0, "d1": 0, "matches": [], "frames": 0, "frame_scores": [], "non_strike_scores": [], "strike_scores": [],
			"money_end": [], "bought": {}, "reached": [0, 0, 0, 0, 0, 0, 0]}
		for seed_value in range(1, runs + 1):
			_attempt(name, seed_value, content, unlocked, stats)
		var bought: Array = stats.bought.keys()
		bought.sort_custom(func(a, b): return stats.bought[a] > stats.bought[b])
		summary.strategies[name] = {"win_rate": snappedf(float(stats.won) / runs, 0.001), "division1_clear_rate": snappedf(float(stats.d1) / runs, 0.001),
			"matches_won_distribution": stats.reached.map(func(n): return snappedf(float(n) / runs, 0.001)),
			"frame_score_mean": snappedf(_mean(stats.frame_scores), 0.1), "strike_frame_mean": snappedf(_mean(stats.strike_scores), 0.1),
			"non_strike_frame_mean": snappedf(_mean(stats.non_strike_scores), 0.1), "money_at_end_mean": snappedf(_mean(stats.money_end), 0.01),
			"top_purchases": bought.slice(0, 6).map(func(id): return "%s×%d" % [id, stats.bought[id]])}
	return {"summary": summary}

## One attempt: shop between matches, deck frames, synthetic pinfall, real scoring.
static func _attempt(name: String, seed_value: int, content: Dictionary, unlocked: bool, stats: Dictionary) -> void:
	var strategy: Dictionary = STRATEGIES[name]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, "pinfall"]) # the same throws for every strategy on a seed
	var policy := RandomNumberGenerator.new()
	policy.seed = hash([seed_value, name])
	var catalogue: Dictionary = content.catalogue
	var run = RunInventory.create(catalogue, content.kit.pins, content.kit.deck, int(content.kit.money))
	var shop = Shop.create(catalogue, hash([seed_value, "shop"]))
	if unlocked:
		shop.unlocked = ["gate.surveyor_cleared", "gate.custodian_cleared"]
	var deck = Deck.create_with(run.deck_cards(), seed_value)
	var league = League.create(content.divisions)
	var won_matches := 0
	while true:
		var match_frame := 0
		var keep := ""
		while not league.match_over():
			match_frame += 1
			deck.start_frame(keep)
			keep = ""
			var reports: Array = []
			var rack: Array = ALL.duplicate()
			for roll_index in [1, 2]:
				var ball := _pick_ball(strategy, deck, policy, league.rules())
				var spin: float = 0.6 if (strategy.spin or ball.item_id == "ball.hook") else 0.0
				spin = RivalRules.constrain_launch(league.rules(), {"spin": spin}).spin
				if not ball.uid.is_empty():
					deck.play(ball.uid, roll_index)
				var plan: String = strategy.plan
				if plan == "leave_one" and not run.charms.any(func(e): return e.item_id == "charm.lone_survivor"):
					plan = "strike" # nothing pays for a leave yet
				if RivalRules.bank(league.rules(), {"score": 1, "category": "open"}).score == 0:
					plan = "strike" # Clean Sweep: a leave banks nothing, so clear the rack
				var fallen := _pinfall(rng, roll_index, rack, ball.item_id, spin, plan, run)
				reports.append(_report(roll_index, fallen, rack, ball.item_id, spin, rng))
				rack = rack.filter(func(p): return p not in fallen)
				if rack.is_empty() or roll_index == 2:
					break
			var built := Builder.build(RivalRules.frame_loadout(league.rules(), run.loadout()), catalogue, reports, {}, {"match_frame": match_frame, "strike_streak": run.strike_streak,
				"match_score": league.match_score, "match_target": league.target()})
			var result := Rules.resolve(built.frame)
			if not result.ok:
				push_error("slice sim frame refused: %s" % str(result.errors))
				return
			run.credit_frame(result, built.frame)
			run.apply_frame(result, built.frame)
			var banked: int = RivalRules.bank(league.rules(), result).score
			league.record_frame(banked)
			stats.frames += 1
			stats.frame_scores.append(banked)
			(stats.strike_scores if result.category == "strike" else stats.non_strike_scores).append(banked)
			var hand: Array = deck.options()
			if not hand.is_empty():
				keep = _pick_ball(strategy, deck, policy, league.rules()).uid
		if league.outcome == "lost":
			break
		won_matches += 1
		if league.division_cleared() and league.division_number() == 1:
			stats.d1 += 1
		if league.outcome == "won":
			stats.won += 1
			break
		var cleared: bool = league.division_cleared()
		run.drop_consumed(deck.exhausted.duplicate())
		run.settle_match(int(league.results[-1].frames))
		shop.open_visit(run, league.division_number() + (1 if cleared else 0))
		_shop(name, strategy, run, shop, policy, stats)
		league.next_match()
		deck.sync(run.deck_cards())
		deck.start_match()
	stats.reached[won_matches] += 1
	stats.money_end.append(run.money)

## The strategy's ball for this roll from the hand ({uid, item_id}); House if none.
static func _pick_ball(strategy: Dictionary, deck, policy: RandomNumberGenerator, rules: Array) -> Dictionary:
	var balls: Array = deck.options().filter(func(o): return o.kind == "ball")
	if strategy.get("random", false):
		balls = balls.filter(func(o): return RivalRules.ball_allowed(rules, o.item_id))
		if balls.is_empty() or policy.randf() < 0.3:
			return {"uid": "", "item_id": "ball.house"}
		return balls[policy.randi_range(0, balls.size() - 1)]
	var order: Array = strategy.balls.duplicate().filter(func(b): return RivalRules.ball_allowed(rules, b))
	if RivalRules.spin_disabled(rules):
		order.erase("ball.hook") # a Hook Ball cannot hook under Dead Straight
	for wanted in order:
		if wanted == "ball.house":
			return {"uid": "", "item_id": "ball.house"}
		for b in balls:
			if b.item_id == wanted:
				return b
	return {"uid": "", "item_id": "ball.house"}

## Seeded pinfall for one roll: which racked pins fall, first direct hit first.
static func _pinfall(rng: RandomNumberGenerator, roll_index: int, rack: Array, ball: String, spin: float, plan: String, run) -> Array:
	var order: Array = rack.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = order[i]
		order[i] = order[j]
		order[j] = swap
	# Anchor pins are heavier: they are the last to go.
	order.sort_custom(func(a, b): return _anchor(run, a) < _anchor(run, b))
	if roll_index == 1:
		if rng.randf() < POCKET:
			order.erase(1)
			order.push_front(1)
		var anchors := 0
		for p in ALL:
			anchors += _anchor(run, p)
		var curved := Lane.is_curved(spin)
		var chance: float = STRIKE + (BALL_STRIKE.get(ball, 0.0) if ball != "ball.hook" or curved else 0.0) + (CURVE_STRIKE if curved else 0.0) + ANCHOR_STRIKE * anchors
		if ball == "ball.hook" and curved and rng.randf() < HOOK_OVERCURVE:
			return order.slice(0, rng.randi_range(3, 6))
		if plan == "strike" and rng.randf() < chance:
			return order
		return order.slice(0, rng.randi_range(6, 9))
	if plan == "leave_one" and order.size() >= 2 and rng.randf() < LEAVE_ONE:
		return order.slice(0, order.size() - 1)
	if rng.randf() < SPARE + (0.05 if ball == "ball.hammer" else 0.0):
		return order
	return order.slice(0, rng.randi_range(0, order.size() - 1))

static func _anchor(run, position: int) -> int:
	return 1 if run.rack[position].item_id == "pin.anchor" else 0

static func _report(roll_index: int, fallen: Array, racked: Array, ball: String, spin: float, rng: RandomNumberGenerator) -> Dictionary:
	var id := "sim-%d-%d" % [roll_index, fallen.size()]
	var knockdowns: Array = []
	for i in fallen.size():
		knockdowns.append({"position": fallen[i], "sequence": i + 1, "tick": 100 + i, "cause": "ball" if i == 0 else "pin",
			"source_position": 0 if i == 0 else fallen[0], "chain_depth": 1 if i == 0 else 2, "reason": "tilt"})
	var accuracy: String = GRADES[rng.randi_range(0, GRADES.size() - 1)]
	return {"launch": {"schema_version": 1, "launch_id": id, "ball_id": ball, "roll_index": roll_index, "start_x": 0.0, "direction_x": 0.0,
			"direction_forward": 1.0, "power": 0.5, "spin": spin, "target_x": 0.11, "ring_radius": 0.3},
		"roll_result": {"schema_version": 1, "launch_id": id, "ball_id": ball, "roll_index": roll_index, "fallen_positions": fallen, "accuracy": accuracy},
		"knockdown_log": {"schema_version": 1, "launch_id": id, "ball_id": ball, "roll_index": roll_index, "knockdowns": knockdowns,
			"standing": racked.filter(func(p): return p not in fallen), "gutter": false, "voided_positions": [], "target_crossed": true,
			"target_offset": 0.05, "settle": "settled", "ticks": 500}}

## Buys towards the build: wanted Charms (into free slots), wanted pins (onto their
## preferred Wood spots), then one reroll if nothing wanted was on offer. Charms are
## kept with additions before multipliers.
static func _shop(name: String, strategy: Dictionary, run, shop, policy: RandomNumberGenerator, stats: Dictionary) -> void:
	for attempt in 2:
		var bought := false
		var progress := true
		while progress:
			progress = false
			for index in shop.offers.size():
				var offer: Dictionary = shop.offers[index]
				if offer.item_id.is_empty() or offer.sold or offer.price > run.money:
					continue
				var target := _target(strategy, run, offer.item_id, policy)
				if target.is_empty() or not shop.buy(index, target, run).is_empty():
					continue
				stats.bought[offer.item_id] = int(stats.bought.get(offer.item_id, 0)) + 1
				bought = true
				progress = true
		if strategy.get("random", false) or bought or run.money < shop.reroll_cost() + 4:
			break
		shop.reroll(run)
	_order_charms(run)

static func _target(strategy: Dictionary, run, item_id: String, policy: RandomNumberGenerator) -> String:
	var options: Array = run.placements(item_id)
	if options.is_empty():
		return ""
	if strategy.get("random", false):
		var free: Array = options.filter(func(o): return o.replaces.is_empty())
		return "" if free.is_empty() or policy.randf() < 0.5 else free[policy.randi_range(0, free.size() - 1)].target
	var category: String = run.item(item_id).category
	if category == "charm":
		return "charm:new" if item_id in strategy.charms and options.any(func(o): return o.target == "charm:new") else ""
	if category == "pin" and strategy.pins.has(item_id):
		for spot in strategy.pins[item_id]:
			if run.rack[spot].item_id != "pin.wood":
				continue
			for o in options:
				if o.target == "rack:%d" % spot:
					return o.target
	return ""

## Additions (+Value, +Mult) before multipliers, as the design's 3360 vs 2800 shows.
static func _order_charms(run) -> void:
	for pass_number in run.charms.size():
		for slot in range(2, run.charms.size() + 1):
			if _multiplies(run, slot - 2) and not _multiplies(run, slot - 1):
				run.move_charm_left(slot)

static func _multiplies(run, index: int) -> bool:
	return run.item(run.charms[index].item_id).effects.any(func(e): return e.op == "multiply_mult")

static func _mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += float(v)
	return total / values.size()
