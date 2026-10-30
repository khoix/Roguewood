extends "res://tests/charm_c01_journey.gd"
## J03C08 (E18-C08, DC-H1): the six D07 House Charms bought through the real Pro Shop
## and scored in real throws on the production slice in Practice (each match plays
## its whole budget). Fixture setup (logged, as J05 does): a wallet grant after the
## opener; offers, rerolls, purchases and the sale are real taps.
##   opener shop:  Head Pin, Wood Grain, Opening Act, Open House and Strike Fund;
##   feature f1:   a strike in the match's first frame: Head Pin, Wood Grain and
##                 Opening Act apply, Strike Fund pays $1, Open House stays silent;
##   feature f2:   an open frame: Open House applies, Opening Act stays silent;
##   feature shop: Opening Act is sold to free its slot and Holdouts is bought;
##   match 3 f1:   an open frame: Holdouts adds +8 Value per standing pin (Practice
##                 has no boss match).
## Every bank equals an independent resolution with the run's loadout and context.
## Run with --fixed-fps 60.
const FIRST := ["charm.head_pin", "charm.wood_grain", "charm.opening_act", "charm.open_house", "charm.strike_fund"]

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
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.practice)
	await _focus_accept(lab.settings_panel.close)
	_check(lab.division.practice, "Practice is on before the first throw")
	await _play_out()
	lab.run.credit(200, "fixture: C08 Charm sampling")
	lab._refresh_shop()
	print("J03C08 fixture: $200 granted after the opener; offers, rerolls and purchases follow")
	await _buy(FIRST)
	await _capture("c08_shop")
	await _leave_shop()
	var strike := await _house_frame([STRIKE], "feature frame 1")
	_check(strike.result.category == "strike" and _logged("Head Pin") and _logged("Wood Grain") and _logged("Opening Act") and not _logged("Open House"),
		"a first-frame strike: Head Pin, Wood Grain and Opening Act apply; Open House stays silent")
	_check(strike.income >= 1, "Strike Fund pays $1 with the strike's income ($%d)" % strike.income)
	await _capture("c08_strike")
	await _focus_accept(lab.next_rack)
	var open := await _house_frame([LEAVE, GUTTER], "feature frame 2")
	_check(open.result.category == "open" and _logged("Open House") and not _logged("Opening Act"), "a second-frame open: Open House applies; Opening Act stays silent")
	await _capture("c08_open")
	await _to_shop("feature")
	var index: int = lab.run.charms.map(func(e): return e.item_id).find("charm.opening_act")
	var money: int = lab.run.money
	var sale: int = lab.run.sale_value("charm:%d" % (index + 1))
	await _tap(lab.shop_panel.owned_list.get_node("Sell_charm_%d" % (index + 1)))
	await process_frame
	_check(not lab.run.charms.any(func(e): return e.item_id == "charm.opening_act") and lab.run.money == money + sale, "Opening Act sold for $%d to free a slot" % sale)
	await _buy(["charm.holdouts"])
	await _leave_shop()
	await _aim()
	var holdouts := await _house_frame([LEAVE, GUTTER], "match 3 frame 1")
	var standing: int = 10 - holdouts.frame.rolls.reduce(func(n, r): return n + r.fallen_positions.size(), 0)
	_check(holdouts.result.category == "open" and standing > 0 and _logged("Holdouts"), "Holdouts adds Value for %d standing pins" % standing)
	await _capture("c08_holdouts")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C08_OK")
	quit(0 if failures.is_empty() else 1)

## Strikes through the opener's whole budget (Practice) into its shop.
func _play_out() -> void:
	while true:
		await _throw(STRIKE)
		var scored := await _scored()
		if scored.match_over:
			break
		await _focus_accept(lab.next_rack)
	await _to_shop("opener")

## Rerolls (real taps) until every wanted Charm has been offered and bought.
func _buy(wanted: Array) -> void:
	var bought: Array = []
	for visit in 150:
		for i in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[i]
			if offer.item_id in wanted and offer.item_id not in bought and not offer.sold and offer.price <= lab.run.money:
				var before: int = lab.run.money
				await _tap(lab.shop_panel.button_for_offer(i))
				await process_frame
				_check(lab.run.charms.any(func(e): return e.item_id == offer.item_id) and lab.run.money == before - int(offer.price), "bought %s for $%d" % [offer.item_id, offer.price])
				bought.append(offer.item_id)
		if bought.size() == wanted.size():
			break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	print("J03C08 bought: %s" % str(bought))
	_check(bought.size() == wanted.size(), "every wanted Charm was offered and bought (%s)" % str(bought))

## Throws, then checks the bank and the income against an independent resolution.
func _house_frame(shots: Array, label: String) -> Dictionary:
	var context: Dictionary = lab.frame_context()
	var loadout: Dictionary = lab.run.loadout()
	var before: int = lab.history.size()
	await _throw(shots[0])
	if shots.size() > 1 and lab.state != "scoring":
		await _aim()
		await _throw(shots[1])
	var scored := await _scored()
	var reports: Array = lab.history.slice(before)
	var built := Builder.build(loadout, lab.content.catalogue, reports, {}, context)
	var expected := Rules.resolve(built.frame) if built.ok else {"score": -1, "future_effects": []}
	var payouts: int = expected.future_effects.filter(func(e): return e.op == "payout").reduce(func(n, e): return n + int(e.amount), 0)
	print("J03C08 %s: category=%s banked=%d expected=%d income=%d expected_income=%d frame=%d" % [label, scored.result.category, scored.banked, expected.score, scored.income, payouts, context.match_frame])
	_check(built.ok and scored.banked == expected.score and scored.income == payouts, "%s banks the independent resolution and its income" % label)
	return scored

func _capture(label: String) -> void:
	print("J03C08 %s lab=%s money=%d charms=%s" % [label, lab.state, lab.run.money, str(lab.run.charms.map(func(e): return e.item_id))])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)
