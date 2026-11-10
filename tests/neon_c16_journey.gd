extends "res://tests/neon_c15_journey.gd"
## J03C16 (E18-C16, DC-N2): Neon's opening pool bought through the real Pro Shop and
## played in real throws on the production slice with the deck, in Practice: each
## match plays its whole budget, so two scoring frames fit in one match (with real
## targets either would end it), and no rule straightens the throws. Fixture setup
## (logged, as J05 does): a wallet grant after the opener; offers, rerolls,
## purchases, placements, sales and card taps are real input.
##   shop:      Glow Ball to the deck, Prism Pin at rack 1 with Spotlight attached
##              there, Grip Tape on a Hook card, Afterimage and Laser Level to the
##              Charms; the kit's Hammer and Echo cards are sold;
##   match 2 f1: a straight leave of 1-3-6 and a curved cleanup: a curved spare, so
##              Afterimage applies, and the Prism Pin pays for the curved roll that
##              took it;
##   match 2 f2: a timed, curved Glow Ball strike that meets the head pin first: Glow
##              Ball, the Prism Pin and Spotlight apply; Laser Level stays silent;
##   match 3 f1: a straight strike: Laser Level pays for ten pins, and the Prism
##              Pin and Spotlight stay silent.
## Every bank equals an independent resolution, and the explanation contains every
## independent line. Run with --fixed-fps 60.
const N2 := {"ball.glow": "card:new", "pin.prism": "rack:1", "charm.afterimage": "charm:new", "charm.laser_level": "charm:new",
	"ball_mod.grip_tape": "ball.hook", "pin_mod.spotlight": "rack:1"}
const N2_NAMES := ["Glow Ball", "Prism Pin", "Grip Tape", "Spotlight", "Afterimage", "Laser Level"]
const LEAVE_136 := [-0.4, 0.0, 0.6] # J03's spare: leaves 1, 3 and 6
const CURVED_CLEANUP := [-0.2, 0.0, 0.6] # with a quarter charge it takes all three
## A House-strength hook with a half charge from -0.4 strikes, meeting the head pin
## first and crossing the target plane at -0.03 (found by rolling the real lane).
const GLOW_STRIKE := [-0.4, 0.0, 0.7]
const GLOW_TARGET := -0.05

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
	_check(lab.division.practice and lab.equipment.MODEL == "deck" and not lab.settings.reduced_motion, "Practice with the deck and the contracting ring")
	await _strike_out()
	await _to_shop("opener")
	lab.run.credit(8000, "fixture: C16 item sampling")
	lab._refresh_shop()
	print("J03C16 fixture: $8000 after the opener; offers, rerolls, purchases, placements and sales follow")
	var cards := await _buy_n2()
	await _sell_kit_cards()
	await _capture("c16_shop")
	await _leave_shop()
	await _aim()
	await _tap(lab.card_hand.button_for(cards.grip))
	_check(lab.armed_ball_id() == "ball.hook" and lab.card_rules() == {"spin_scale": 1.4} and is_equal_approx(lab.hook_scale(), 1.4),
		"the armed Grip Tape card hooks 1.4 times as far, and the aim guide knows: %s" % str(lab.card_rules()))
	await _tap(lab.card_hand.button_for(cards.grip)) # disarm: the leave is a House Ball throw
	_check(lab.armed_ball.is_empty() and lab.card_rules().is_empty(), "tapping the armed card again disarms it")
	# Feature frame 1: a straight leave, then a curved cleanup.
	var context: Dictionary = lab.frame_context()
	var loadout: Dictionary = lab.run.loadout()
	await _throw(LEAVE_136)
	await _aim()
	await _throw(CURVED_CLEANUP, 0.25)
	var spare_scored := await _scored()
	var spare := await _verify("match 2 frame 1: curved spare", spare_scored, lab.frame_reports.duplicate(true), loadout, context, {})
	_check(spare_scored.result.category == "spare" and spare.reports[1].launch.spin == 0.25 and _logged("Afterimage"), "a spare with a curved cleanup: Afterimage applies")
	_check(_logged("Prism Pin") and not _logged("Laser Level"), "the Prism Pin pays for the curved roll that took it; Laser Level is off in a curved frame")
	_check(not spare_scored.match_over, "the match goes on to its second frame")
	await _capture("c16_spare")
	await _focus_accept(lab.next_rack)
	# Feature frame 2: the Glow Ball's curved strike, head pin first.
	var glow := await _card_frame(cards.glow, [GLOW_STRIKE], 0.5, "match 2 frame 2: Glow Ball, curved", GLOW_TARGET)
	_check(glow.scored.result.category == "strike" and glow.scored.frame.rolls[0].first_direct == 1, "a curved strike that meets the head pin first (%d)" % int(glow.scored.frame.rolls[0].first_direct))
	_check(_logged("Glow Ball") and _logged("Prism Pin") and _logged("Spotlight") and not _logged("Laser Level") and not _logged("Afterimage"),
		"Glow Ball, the Prism Pin and Spotlight apply; Laser Level and Afterimage stay silent")
	await _capture("c16_glow_strike")
	await _to_shop("match 2")
	await _leave_shop()
	await _aim()
	var straight := await _card_frame("", [STRIKE], 0.0, "match 3 frame 1: House Ball, straight")
	_check(straight.scored.result.category == "strike" and _log_lines().any(func(l): return l.contains("Laser Level") and l.contains("10 ×")),
		"a straight strike: Laser Level pays for ten pins")
	_check(not _logged("Prism Pin") and not _logged("Spotlight"), "the Prism Pin and Spotlight stay silent on a straight roll")
	await _capture("c16_straight")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C16_OK")
	quit(0 if failures.is_empty() else 1)

## Rerolls (real taps) until all six are offered, bought and placed. Spotlight waits
## for the Prism Pin, so it is attached to that pin's rack position.
func _buy_n2() -> Dictionary:
	var bought := {}
	for visit in 200:
		for index in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[index]
			if not N2.has(offer.item_id) or bought.has(offer.item_id) or offer.sold or offer.price > lab.run.money:
				continue
			if offer.item_id == "pin_mod.spotlight" and not bought.has("pin.prism"):
				continue
			var before: int = lab.run.money
			var target := ""
			var options: Array = []
			if offer.item_id == "ball_mod.grip_tape":
				options = lab.run.mod_hosts(offer.item_id)
				for ref in options:
					if target.is_empty() and lab.run.entry_at(ref).item_id == N2[offer.item_id] and String(lab.run.entry_at(ref).mod).is_empty():
						target = ref
			elif offer.item_id == "pin_mod.spotlight":
				options = lab.run.mod_hosts(offer.item_id)
				target = N2[offer.item_id]
			else:
				options = lab.run.placements(offer.item_id).map(func(o): return o.target)
				target = N2[offer.item_id]
			if target.is_empty() or target not in options:
				continue
			await _tap(lab.shop_panel.button_for_offer(index)) # opens the offer; Buy follows, as a player presses it
			await process_frame
			if lab.shop_panel.choice_sheet.visible:
				await _tap(lab.shop_panel.choice_button(options.find(target)))
				await process_frame
			_check(lab.run.money == before - int(offer.price), "bought %s for $%d" % [offer.item_id, offer.price])
			bought[offer.item_id] = target
		if bought.size() == N2.size() or lab.run.money < lab.shop.reroll_cost(lab.run):
			break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	print("J03C16 bought: %s" % str(bought))
	_check(bought.size() == N2.size(), "all six opening-pool items offered and bought (%d)" % bought.size())
	_check(lab.run.rack[1].item_id == "pin.prism" and String(lab.run.rack[1].mod) == "pin_mod.spotlight", "the Prism Pin at rack 1 carries Spotlight")
	var cards := {}
	for uid in lab.run.cards:
		var entry: Dictionary = lab.run.cards[uid]
		match [entry.item_id, String(entry.mod)]:
			["ball.glow", ""]: cards["glow"] = uid
			["ball.hook", "ball_mod.grip_tape"]: cards["grip"] = uid
	_check(cards.size() == 2, "the Glow Ball and the Grip Tape card are in the deck")
	return cards

func _sell_kit_cards() -> void:
	for owned in lab.run.entries():
		if owned.ref.begins_with("card:") and owned.entry.item_id in ["ball.hammer", "ball.echo"]:
			var button: Button = lab.shop_panel.sell_button(owned.ref)
			_check(button != null, "a Sell row for " + owned.ref)
			if button != null:
				await _tap(button)
				await process_frame
	_check(lab.run.cards.size() == 3 and not lab.run.cards.values().any(func(e): return e.item_id in ["ball.hammer", "ball.echo"]), "three cards left in the deck")

func _verify(label: String, scored: Dictionary, reports: Array, loadout: Dictionary, context: Dictionary, extras: Dictionary) -> Dictionary:
	var out := await super._verify(label, scored, reports, loadout, context, extras)
	print("J03C16 %s: %s" % [label, str(out.lines.filter(func(l): return N2_NAMES.any(func(n): return l.contains(n))))])
	return out
