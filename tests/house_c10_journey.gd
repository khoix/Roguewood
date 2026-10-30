extends "res://tests/house_c08_journey.gd"
## J03C10 (E18-C10, DC-H3): House's two balls, two pins and two Charms bought through
## the real Pro Shop and played on the production slice in Practice, with direct
## equipment chosen in Options so both new balls are always in the bag. Fixture setup
## (logged, as J05 does): a $2000 wallet grant after the opener; offers, rerolls,
## purchases, placements and card taps are real input.
##   shop:  Spare Ball and Workhorse to the deck, Oak Pin at rack 1 and Tin Pin at
##          rack 6 (each moving its Wood Pin to a reserve), Spare Jar and Consolation
##          Prize to the Charms;
##          The kit's ball cards are sold, so the new balls are the direct bag's specials.
##   match 2: a Workhorse strike (the Oak Pin falls); a leave and a Spare Ball cleanup
##            spare, which fills the Spare Jar;
##   match 3: a leave and a gutter, an open frame with the Tin Pin standing (Consolation
##            Prize and Tin Pin each pay $1); then a strike with one spare in the jar.
## Every bank and every frame's income equal an independent resolution; each item's
## effect is seen in the explanation.
## Run with --fixed-fps 60.
const ITEMS := {"ball.spare_ball": "card:new", "ball.workhorse": "card:new", "pin.oak": "rack:1", "pin.tin": "rack:6",
	"charm.spare_jar": "charm:new", "charm.consolation_prize": "charm:new"}

func _run() -> void:
	tag = "J03C10"
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
	lab.settings_panel.equipment.grab_focus()
	await _action("ui_accept")
	await _action("ui_down")
	await _action("ui_accept")
	await _focus_accept(lab.settings_panel.close)
	_check(lab.division.practice and lab.equipment.MODEL == "direct", "Practice with direct selection")
	await _play_out()
	lab.run.credit(2000, "fixture: C10 item sampling")
	lab._refresh_shop()
	print("J03C10 fixture: $2000 granted after the opener; offers, rerolls, purchases and placements follow")
	await _buy_items()
	await _sell_kit_balls()
	await _capture("c10_shop")
	await _leave_shop()
	_check(_bag("ball.workhorse") != null and _bag("ball.spare_ball") != null, "the bag holds both new balls")
	var strike := await _armed_frame("ball.workhorse", [STRIKE], "Workhorse strike")
	_check(strike.result.category == "strike" and _logged("Workhorse") and _logged("Oak Pin"), "a Workhorse strike: Workhorse and the Oak Pin at 1 apply")
	await _capture("c10_strike")
	await _focus_accept(lab.next_rack)
	var spare := await _armed_frame("ball.spare_ball", [LEAVE, CLEANUP], "leave, Spare Ball cleanup")
	_check(spare.result.category == "spare" and _logged("Spare Ball") and int(_charm("charm.spare_jar").growth) == 1,
		"a Spare Ball cleanup converts the spare: +4 Mult, and the Spare Jar fills")
	await _capture("c10_spare")
	await _next()
	var open := await _armed_frame("", [LEAVE, GUTTER], "leave and gutter")
	var tin_standing: bool = not open.frame.rolls.any(func(r): return 6 in r.fallen_positions.map(func(p): return int(p)))
	_check(open.result.category == "open" and _logged("Consolation Prize") and tin_standing and _logged("Tin Pin") and open.income >= 2,
		"an open frame with the Tin Pin standing: Consolation Prize and the Tin Pin each pay $1 ($%d)" % open.income)
	await _capture("c10_open")
	await _focus_accept(lab.next_rack)
	var jar := await _armed_frame("", [STRIKE], "strike with the Spare Jar")
	_check(jar.result.category == "strike" and _logged("Spare Jar"), "one spare in the jar adds its Value to a strike")
	await _capture("c10_jar")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C10_OK")
	quit(0 if failures.is_empty() else 1)

func _charm(id: String) -> Dictionary:
	return lab.run.charms.filter(func(e): return e.item_id == id)[0]

## The bag option for an item, or null.
func _bag(item_id: String) -> Variant:
	for option in lab.equipment.options():
		if option.item_id == item_id:
			return option
	return null

## Direct selection keeps the first few ball cards; the kit's Hook, Hammer and Echo
## cards are sold (real taps) so the new balls are the bag's specials.
func _sell_kit_balls() -> void:
	for owned in lab.run.entries():
		if owned.ref.begins_with("card:") and owned.entry.item_id in ["ball.hook", "ball.hammer", "ball.echo"]:
			var button: Node = lab.shop_panel.owned_list.get_node_or_null("Sell_" + String(owned.ref).replace(":", "_").replace("-", "_"))
			if button == null:
				_check(false, "a Sell button for " + owned.ref)
				continue
			await _tap(button)
			await process_frame
	_check(not lab.run.cards.values().any(func(e): return e.item_id in ["ball.hook", "ball.hammer", "ball.echo"]), "the kit's ball cards are sold")

## Rerolls (real taps) until every item is offered, bought and placed where ITEMS says.
func _buy_items() -> void:
	var bought := {}
	for visit in 150:
		for i in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[i]
			if not ITEMS.has(offer.item_id) or bought.has(offer.item_id) or offer.sold or offer.price > lab.run.money:
				continue
			var target: String = ITEMS[offer.item_id]
			var targets: Array = lab.run.placements(offer.item_id).map(func(o): return o.target)
			var before: int = lab.run.money
			await _tap(lab.shop_panel.button_for_offer(i))
			await process_frame
			if lab.shop_panel.choice_sheet.visible:
				await _tap(lab.shop_panel.choice_button(targets.find(target)))
				await process_frame
			_check(lab.run.money == before - int(offer.price) and lab.run.owned_count(offer.item_id) == 1, "bought %s for $%d" % [offer.item_id, offer.price])
			bought[offer.item_id] = true
		if bought.size() == ITEMS.size() or lab.run.money < lab.shop.reroll_cost(lab.run):
			break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	print("J03C10 bought: %s" % str(bought.keys()))
	_check(bought.size() == ITEMS.size(), "all six items offered and bought (%d)" % bought.size())
	_check(lab.run.rack[1].item_id == "pin.oak" and lab.run.rack[6].item_id == "pin.tin" and lab.run.reserves.all(func(e): return e != null and e.item_id == "pin.wood"),
		"Oak at 1 and Tin at 6, their Wood Pins in reserve")

## Arms `ball` (a real tap; "" throws House) before the last shot, then checks the frame.
func _armed_frame(ball: String, shots: Array, label: String) -> Dictionary:
	var context: Dictionary = lab.frame_context()
	var loadout: Dictionary = lab.run.loadout()
	var before: int = lab.history.size()
	if shots.size() == 1 and not ball.is_empty():
		await _tap_ball(ball)
	await _throw(shots[0])
	if shots.size() > 1 and await _second_roll():
		if not ball.is_empty():
			await _tap_ball(ball)
		await _throw(shots[1])
	var scored := await _scored()
	var reports: Array = lab.history.slice(before)
	var built := Builder.build(loadout, lab.content.catalogue, reports, {}, context)
	var expected := Rules.resolve(built.frame) if built.ok else {"score": -1, "future_effects": []}
	var payouts: int = expected.future_effects.filter(func(e): return e.op == "payout").reduce(func(n, e): return n + int(e.amount), 0)
	print("J03C10 %s: category=%s banked=%d expected=%d income=%d expected_income=%d balls=%s" % [label, scored.result.category, scored.banked, expected.score, scored.income, payouts,
		str(reports.map(func(r): return r.launch.ball_id))])
	_check(built.ok and scored.banked == expected.score and scored.income == payouts, "%s banks the independent resolution and its income" % label)
	return scored

func _tap_ball(ball: String) -> void:
	await _aim()
	var option = _bag(ball)
	if option == null:
		_check(false, "%s is in the bag" % ball)
		return
	await _tap(lab.card_hand.button_for(option.uid))
	_check(lab.armed_ball_id() == ball, "armed %s" % ball)

## After roll 1 settles: true when roll 2 is to be thrown, false when the frame scores.
func _second_roll() -> bool:
	await _wait_for(func(): return lab.state == "scoring" or (lab.state == "aim" and lab.lane.state == "ready"), "roll 2 or scoring", ROLL_FRAMES)
	return lab.state == "aim"

func _capture(label: String) -> void:
	print("J03C10 %s lab=%s money=%d charms=%s rack1=%s rack6=%s" % [label, lab.state, lab.run.money, str(lab.run.charms.map(func(e): return "%s:%d" % [e.item_id, int(e.growth)])),
		lab.run.rack[1].item_id, lab.run.rack[6].item_id])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)
