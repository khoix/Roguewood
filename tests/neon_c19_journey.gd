extends "res://tests/neon_c17_journey.gd"
## J03C19 (E18-C19, DC-N5): Neon's last five items, the mastery rewards, bought through
## the real Pro Shop and played in real throws on the production slice with the deck,
## in Practice (each match plays its whole budget). Fixture setup (logged, as J05
## does): after the opener, a wallet grant, Division 2 shop eligibility and the gates
## of Both Halves, Rebound Rescue and the Neon rivals (for Bumper Guard); for each
## frame the lane is set (Practice plays House Oil). Offers, rerolls, purchases,
## placements, sales and card taps are real input.
##   shop:       Compass Pin at rack 1; Split Pattern, Dry Run, Long Game and Second
##               Chance to the Charms; Bumper Guard on a Hook card; the kit's Hammer
##               and Echo cards are sold;
##   match 2 f1: on Two-Tone, a strike from the left at 34 ft: Split Pattern ×2 and
##               Dry Run +1 Mult per pin; the Compass Pin pays off House Oil;
##   match 2 f2: on Long Oil, a curved strike: Long Game ×1.5 and the Compass Pin;
##               Split Pattern and Dry Run stay silent;
##   match 3 f1: on House Oil, the Bumper Guard card at the gutter rebounds and the
##               frame ends in a spare or strike: Second Chance ×1.5; the Compass Pin
##               is worth nothing on House Oil.
## Every bank equals an independent resolution. Run with --fixed-fps 60.
const N5 := {"pin.compass": "rack:1", "charm.split_pattern": "charm:new", "charm.dry_run": "charm:new", "charm.long_game": "charm:new",
	"charm.second_chance": "charm:new", "ball_mod.bumper_guard": "ball.hook"}
const N5_NAMES := ["Compass Pin", "Split Pattern", "Dry Run", "Long Game", "Second Chance", "Bumper Guard"]
const LaneSpecC19 = preload("res://src/simulation/lane_spec.gd")
const N5_GATES := ["gate.mastery_both_halves", "gate.mastery_rebound_rescue"]
## Found by rolling the real lanes (handoffs/E18-C19.md): on Two-Tone, from -0.4 at
## 0.5° a straight ball strikes and is left of centre at 34 ft; on Long Oil, from -0.4
## with a 0.75 charge the House Ball strikes; on House Oil, a Bumper Guard card from
## 0.7 at 2° rebounds off the gutter edge and takes eight pins.
const TWO_TONE_LEFT := [-0.4, 0.5, 0.7]
const LONG_CURVE := [-0.4, 0.0, 0.7]
const LONG_SPIN := 0.75
const RESCUE := [0.7, 2.0, 0.6]

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
	lab.settings_panel.use_practice()
	await process_frame
	await _focus_accept(lab.settings_panel.close);await _focus_accept(scene.resume)
	_check(lab.division.practice and lab.equipment.MODEL == "deck", "Practice with the deck")
	await _strike_out()
	await _to_shop("opener")
	lab.run.credit(8000, "fixture: C19 item sampling")
	lab.shop.division = 2
	for gate in NEON_GATES + N5_GATES:
		if gate not in lab.shop.unlocked: lab.shop.unlocked.append(gate)
	lab._refresh_shop()
	print("J03C19 fixture: $8000, Division 2 shop eligibility and the Neon rival and mastery gates after the opener")
	var guard := await _buy_n5()
	await _sell_kit()
	await _capture("c19_shop")
	await _leave_shop()
	# Match 2 frame 1: Two-Tone, a strike from the left.
	await _aim()
	_lane("lane_condition.two_tone")
	var split := await _tactic_frame("", "", [TWO_TONE_LEFT], 0.0, "match 2 frame 1: Two-Tone, from the left")
	_check(split.scored.result.category == "strike" and split.reports[0].knockdown_log.get("left_side", false) == true, "a strike from the left of centre at 34 ft")
	_check(_logged("Split Pattern") and _logged("Dry Run") and _logged("Compass Pin") and not _logged("Long Game") and not _logged("Second Chance"),
		"Split Pattern, Dry Run and the Compass Pin apply; Long Game and Second Chance stay silent")
	await _capture("c19_two_tone")
	await _focus_accept(lab.next_rack)
	# Match 2 frame 2: Long Oil, a curved strike.
	await _aim()
	_lane("lane_condition.long_oil")
	var long_game := await _tactic_frame("", "", [LONG_CURVE], LONG_SPIN, "match 2 frame 2: Long Oil, curved")
	_check(long_game.scored.result.category == "strike" and long_game.reports[0].launch.spin == LONG_SPIN, "a curved strike on Long Oil")
	_check(_logged("Long Game") and _logged("Compass Pin") and not _logged("Split Pattern"), "Long Game and the Compass Pin apply; Split Pattern stays silent")
	await _capture("c19_long_oil")
	await _to_shop("match 2")
	await _leave_shop()
	# Match 3 frame 1: House Oil, the Bumper Guard rescue.
	await _aim()
	_lane("lane.house")
	await _tap(lab.card_hand.button_for(guard))
	var rescue := await _rescue_frame(guard)
	_check(rescue.reports[0].knockdown_log.get("rebounded", false) == true and rescue.scored.result.category in ["spare", "strike"], "the rebound ends in a %s" % rescue.scored.result.category)
	_check(_logged("Second Chance") and not _logged("Compass Pin"), "Second Chance applies; the Compass Pin is worth nothing on House Oil")
	await _capture("c19_rescue")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C19_OK")
	quit(0 if failures.is_empty() else 1)

## The Bumper Guard card at the gutter; roll 2 is aimed straight at the pins the
## rebound left standing, as a player lines up a spare.
func _rescue_frame(guard: String) -> Dictionary:
	var context: Dictionary = lab.frame_context()
	var loadout: Dictionary = lab.run.loadout()
	_check(lab.armed_ball == guard and bool(lab.card_rules().get("gutter_rebound", false)), "the Bumper Guard card is armed")
	await _throw(RESCUE, 0.0)
	await _wait_for(func(): return lab.state in ["scoring", "aim"], "the rebound roll resolves", ROLL_FRAMES)
	if lab.state == "aim":
		var standing: Array = lab.frame_reports[0].knockdown_log.standing
		var mean := 0.0
		for position in standing:
			mean += LaneSpecC19.spot(int(position)).x
		mean /= maxf(standing.size(), 1)
		var start := clampf(mean / LaneSpecC19.LANE_HALF_WIDTH, -0.6, 0.6)
		print("J03C19 roll 2 at the standing pins %s: start %.2f" % [str(standing), start])
		await _aim()
		await _throw([start, 0.0, 0.7], 0.0)
	var scored := await _scored()
	return await _verify("match 3 frame 1: Bumper Guard rescue", scored, lab.frame_reports.duplicate(true), loadout, context, {1: ["ball_mod.bumper_guard"]})

## Practice plays House Oil; the frame's lane is set here (fixture, logged).
func _lane(id: String) -> void:
	lab.lane.lane_condition = id
	print("J03C19 fixture: the lane set to %s" % id)
	_check(lab.frame_context().lane_condition == id, "the frame context carries %s" % id)

## Rerolls (real taps) until all six are offered, bought and placed. Returns the
## Bumper Guard card's uid.
func _buy_n5() -> String:
	var bought := {}
	for visit in 300:
		for index in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[index]
			if not N5.has(offer.item_id) or bought.has(offer.item_id) or offer.sold or offer.price > lab.run.money:
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
				target = N5[offer.item_id]
			if target.is_empty() or target not in options:
				continue
			var before: int = lab.run.money
			await _tap(lab.shop_panel.button_for_offer(index))
			await process_frame
			if lab.shop_panel.choice_sheet.visible:
				await _tap(lab.shop_panel.choice_button(options.find(target)))
				await process_frame
			_check(lab.run.money == before - int(offer.price), "bought %s for $%d" % [offer.item_id, offer.price])
			bought[offer.item_id] = target
		if bought.size() == N5.size() or lab.run.money < lab.shop.reroll_cost(lab.run):
			break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	print("J03C19 bought: %s" % str(bought))
	_check(bought.size() == N5.size(), "all six offered and bought (%d)" % bought.size())
	_check(lab.run.rack[1].item_id == "pin.compass", "the Compass Pin is at rack 1")
	for uid in lab.run.cards:
		if lab.run.cards[uid].item_id == "ball.hook" and String(lab.run.cards[uid].mod) == "ball_mod.bumper_guard":
			return uid
	_check(false, "a Hook card carries Bumper Guard")
	return ""

func _sell_kit() -> void:
	for owned in lab.run.entries():
		if owned.ref.begins_with("card:") and owned.entry.item_id in ["ball.hammer", "ball.echo"]:
			var button: Button = lab.shop_panel.sell_button(owned.ref)
			if button != null:
				await _tap(button)
				await process_frame
	_check(not lab.run.cards.values().any(func(e): return e.item_id in ["ball.hammer", "ball.echo"]), "the kit's Hammer and Echo cards are sold")

func _verify(label: String, scored: Dictionary, reports: Array, loadout: Dictionary, context: Dictionary, extras: Dictionary) -> Dictionary:
	var out := await super._verify(label, scored, reports, loadout, context, extras)
	print("J03C19 %s: %s" % [label, str(out.lines.filter(func(l): return N5_NAMES.any(func(n): return l.contains(n))))])
	return out
