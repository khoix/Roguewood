extends "res://tests/neon_c15_journey.gd"
## J03C17 (E18-C17, DC-N3): the rest of Neon's opening pool bought through the real
## Pro Shop and played in real throws on the production slice with the deck, in
## Practice (each match plays its whole budget, so two scoring frames fit in one
## match). Fixture setup (logged, as J05 does): a wallet grant, Division 2 shop
## eligibility and the Neon reward gates after the opener (for Bumper Guard), and,
## for Lane Reader, the third match's lane set to Long Oil (Practice plays House Oil);
## offers, rerolls, purchases, placements, sales and card taps are real input.
##   shop:       Dry Side, Lane Reader, Bounce Back and Straight Money to the Charms;
##               Hook Shot and Line Call to the deck; Bumper Guard on a Hook card;
##               the kit's Hammer and Echo cards are sold, so the hand is the four cards;
##   match 2 f1: Line Call played with a straight strike: Line Call +4 Mult and
##               Straight Money's $2; Dry Side, Lane Reader and Bounce Back stay silent;
##   match 2 f2: Hook Shot played with the other Hook card, curved from the left: the
##               armed pair hooks 1.5 times as far, and the roll is left of the centre
##               board at 34 ft, so Dry Side applies;
##   match 3 f1: on Long Oil, a straight strike: Lane Reader ×1.5 and Straight Money;
##   match 3 f2: the Bumper Guard card thrown at the gutter rebounds: Bounce Back's $3.
## Every bank equals an independent resolution, and the explanation contains every
## independent line. Run with --fixed-fps 60.
const N3 := {"charm.dry_side": "charm:new", "charm.lane_reader": "charm:new", "charm.bounce_back": "charm:new", "charm.straight_money": "charm:new",
	"consumable.hook_shot": "card:new", "consumable.line_call": "card:new", "ball_mod.bumper_guard": "ball.hook"}
const N3_NAMES := ["Dry Side", "Lane Reader", "Hook Shot", "Line Call", "Bounce Back", "Straight Money"]
## From the left with a half charge: the ball is still left of the centre board at 34 ft.
const LEFT_CURVE := [-0.6, 0.0, 0.7]
const LEFT_SPIN := 0.5

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.enter.has_focus(), "menu focus")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "throw lab ready")
	lab = scene.lab
	lab.trial_log_path = ""
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.practice)
	await _focus_accept(lab.settings_panel.close)
	_check(lab.division.practice and lab.equipment.MODEL == "deck", "Practice with the deck")
	await _strike_out()
	await _to_shop("opener")
	lab.run.credit(8000, "fixture: C17 item sampling")
	lab.shop.division = 2 # Bumper Guard is offered from Division 2
	for gate in NEON_GATES:
		if gate not in lab.shop.unlocked: lab.shop.unlocked.append(gate)
	lab._refresh_shop()
	print("J03C17 fixture: $8000, Division 2 shop eligibility and the Neon reward gates after the opener; offers, rerolls, purchases, placements and sales follow")
	var cards := await _buy_n3()
	await _sell_all_but_hooks()
	await _capture("c17_shop")
	await _leave_shop()
	await _aim()
	var hand: Array = lab.equipment.options().map(func(o): return o.uid)
	_check(cards.values().all(func(uid): return uid in hand), "the hand holds the four cards: %s" % str(lab.equipment.options().map(func(o): return o.item_id)))
	# Match 2 frame 1: Line Call with a straight strike.
	var money: int = lab.run.money
	var called := await _tactic_frame("", cards.line_call, [STRIKE], 0.0, "match 2 frame 1: Line Call, straight")
	_check(called.scored.result.category == "strike" and _logged("Line Call") and _logged("Straight Money"), "a straight strike with Line Call: Line Call +4 Mult and Straight Money pay")
	_check(not _logged("Dry Side") and not _logged("Lane Reader") and not _logged("Bounce Back"), "Dry Side, Lane Reader and Bounce Back stay silent")
	_check(lab.run.money >= money + 2, "Straight Money's $2 reaches the wallet ($%d to $%d)" % [money, lab.run.money])
	_check(cards.line_call in lab.equipment.exhausted, "the Line Call card is spent for the attempt")
	await _capture("c17_line_call")
	await _focus_accept(lab.next_rack)
	# Match 2 frame 2: Hook Shot with the plain Hook card, curved from the left.
	await _aim()
	await _tap(lab.card_hand.button_for(cards.hook))
	await _tap(lab.card_hand.button_for(cards.hook_shot))
	_check(lab.armed_ball_id() == "ball.hook" and lab.armed_tactical == cards.hook_shot and lab.card_rules() == {"spin_scale": 1.5} and is_equal_approx(lab.hook_scale(), 1.5),
		"the armed Hook Shot hooks 1.5 times as far, and the aim guide knows: %s" % str(lab.card_rules()))
	var shot := await _tactic_frame(cards.hook, "", [LEFT_CURVE], LEFT_SPIN, "match 2 frame 2: Hook Shot, curved from the left", {1: ["consumable.hook_shot"]})
	_check(shot.reports[0].launch.spin == LEFT_SPIN and shot.reports[0].knockdown_log.get("left_side", false) == true and _logged("Dry Side"),
		"a roll left of the centre board at 34 ft: Dry Side applies")
	_check(_log_lines().any(func(l): return l.contains("Dry Side") and l.contains("left of centre at 34 ft")), "the explanation says why Dry Side applied")
	_check(cards.hook_shot in lab.equipment.exhausted, "the Hook Shot card is spent for the attempt")
	await _capture("c17_dry_side")
	await _to_shop("match 2")
	await _leave_shop()
	await _aim()
	# Match 3: Practice plays House Oil, so the lane is set to Long Oil (fixture).
	lab.lane.lane_condition = "lane_condition.long_oil"
	print("J03C17 fixture: the third match's lane set to Long Oil")
	_check(lab.frame_context().lane_condition == "lane_condition.long_oil", "the frame context carries the match's lane")
	var reader := await _tactic_frame("", "", [STRIKE], 0.0, "match 3 frame 1: Long Oil, straight")
	_check(reader.scored.result.category == "strike" and _logged("Lane Reader") and _logged("Straight Money"), "a strike off House Oil: Lane Reader ×1.5 and Straight Money")
	_check(_log_lines().any(func(l): return l.contains("Lane Reader") and l.contains("on Long Oil")), "the explanation names the match's lane")
	await _capture("c17_lane_reader")
	await _focus_accept(lab.next_rack)
	# Match 3 frame 2: the Bumper Guard card at the gutter.
	await _aim()
	await _tap(lab.card_hand.button_for(cards.guard))
	_check(lab.armed_ball == cards.guard and bool(lab.card_rules().get("gutter_rebound", false)), "the Bumper Guard card is armed")
	money = lab.run.money
	var bounce := await _tactic_frame(cards.guard, "", [STRAY, STRAY], 0.0, "match 3 frame 2: Bumper Guard rescue", {1: ["ball_mod.bumper_guard"]})
	_check(bounce.reports[0].knockdown_log.get("rebounded", false) == true and _logged("Bounce Back"), "the roll rebounds off the gutter edge: Bounce Back pays")
	_check(lab.run.money >= money + 3, "Bounce Back's $3 reaches the wallet ($%d to $%d)" % [money, lab.run.money])
	await _capture("c17_bounce_back")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C17_OK")
	quit(0 if failures.is_empty() else 1)

## A frame with an optional ball card and tactical card already armed or to arm
## (uids), thrown with the assist panel; verified against an independent resolution.
func _tactic_frame(ball_uid: String, tactic_uid: String, shots: Array, spin: float, label: String, extras: Dictionary = {}) -> Dictionary:
	await _aim()
	if not ball_uid.is_empty() and lab.armed_ball != ball_uid:
		await _tap(lab.card_hand.button_for(ball_uid))
	if not tactic_uid.is_empty():
		await _tap(lab.card_hand.button_for(tactic_uid))
		_check(lab.armed_tactical == tactic_uid, "%s: the tactical card is armed" % label)
		extras = extras.duplicate(true)
		extras[1] = extras.get(1, []) + [lab._item_of(tactic_uid)]
	var context: Dictionary = lab.frame_context()
	var loadout: Dictionary = lab.run.loadout()
	await _throw(shots[0], spin)
	await _wait_for(func(): return lab.state in ["scoring", "aim"], label + " roll 1 resolves", ROLL_FRAMES)
	if lab.state == "aim":
		await _throw(shots[1] if shots.size() > 1 else [0.0, 0.0, 0.6])
	var scored := await _scored()
	return await _verify(label, scored, lab.frame_reports.duplicate(true), loadout, context, extras)

## Rerolls (real taps) until all seven are offered, bought and placed. Returns the
## uids of the cards the frames use: {hook, guard, hook_shot, line_call}.
func _buy_n3() -> Dictionary:
	var bought := {}
	for visit in 300:
		for index in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[index]
			if not N3.has(offer.item_id) or bought.has(offer.item_id) or offer.sold or offer.price > lab.run.money:
				continue
			var target := ""
			var options: Array = []
			if offer.item_id == "ball_mod.bumper_guard":
				options = lab.run.mod_hosts(offer.item_id)
				for ref in options:
					if target.is_empty() and lab.run.entry_at(ref).item_id == "ball.hook" and String(lab.run.entry_at(ref).mod).is_empty():
						target = ref
			else:
				options = lab.run.placements(offer.item_id).map(func(o): return o.target)
				target = N3[offer.item_id]
			if target.is_empty() or target not in options:
				continue
			var before: int = lab.run.money
			await _tap(lab.shop_panel.button_for_offer(index)) # opens the offer; Buy follows, as a player presses it
			await process_frame
			if lab.shop_panel.choice_sheet.visible:
				await _tap(lab.shop_panel.choice_button(options.find(target)))
				await process_frame
			_check(lab.run.money == before - int(offer.price), "bought %s for $%d" % [offer.item_id, offer.price])
			bought[offer.item_id] = target
		if bought.size() == N3.size() or lab.run.money < lab.shop.reroll_cost(lab.run):
			break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	print("J03C17 bought: %s" % str(bought))
	_check(bought.size() == N3.size(), "all seven items offered and bought (%d)" % bought.size())
	var cards := {}
	for uid in lab.run.cards:
		var entry: Dictionary = lab.run.cards[uid]
		match [entry.item_id, String(entry.mod)]:
			["ball.hook", ""]: cards["hook"] = uid
			["ball.hook", "ball_mod.bumper_guard"]: cards["guard"] = uid
			["consumable.hook_shot", ""]: cards["hook_shot"] = uid
			["consumable.line_call", ""]: cards["line_call"] = uid
	_check(cards.size() == 4, "the Hook, Bumper Guard, Hook Shot and Line Call cards are in the deck: %s" % str(cards))
	return cards

func _sell_all_but_hooks() -> void:
	for owned in lab.run.entries():
		if owned.ref.begins_with("card:") and owned.entry.item_id in ["ball.hammer", "ball.echo"]:
			var button: Button = lab.shop_panel.sell_button(owned.ref)
			_check(button != null, "a Sell row for " + owned.ref)
			if button != null:
				await _tap(button)
				await process_frame
	_check(lab.run.cards.size() == 4 and not lab.run.cards.values().any(func(e): return e.item_id in ["ball.hammer", "ball.echo"]), "four cards left in the deck")

func _verify(label: String, scored: Dictionary, reports: Array, loadout: Dictionary, context: Dictionary, extras: Dictionary) -> Dictionary:
	var out := await super._verify(label, scored, reports, loadout, context, extras)
	print("J03C17 %s: %s left_side=%s" % [label, str(out.lines.filter(func(l): return N3_NAMES.any(func(n): return l.contains(n)))),
		str(reports.map(func(r): return r.knockdown_log.get("left_side", false)))])
	return out
