extends SceneTree
## J05 shop and economy journey (E08), driven through the real lab with touch,
## mouse and keyboard. Plays a match (Lab Coin income), then checks the settlement
## (interest on the held balance, then the $3 payout) and the Pro Shop:
## - five eligible offers in their slots; buying into a free slot; a sold offer;
## - insufficient funds (disabled offer and reroll, no state change);
## - an escalating reroll that replaces the offers;
## - a pin placement that moves the displaced pin to a reserve, and a workshop
##   modification attached to a chosen host;
## - a full slot: Cancel changes nothing, then an explicit replacement sells the old item;
## - the removal service (with a cancelled attempt) and selling;
## - buying then selling never makes money; the balance never goes negative;
## - the shop reflows for landscape.
## The next match then scores with what was bought, checked against an independent
## FrameBuilder/FrameRules resolution.
## Fixture setup (not UI): to reach a full Charm row without many matches, the
## journey grants $30 and seats four reward-only Crown Charms through the inventory
## API, logged as "fixture" in the ledger. Every decision after that is UI input.
## Run with --fixed-fps 60.
const Contracts = preload("res://src/contracts/contracts.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const FrameBuilder = preload("res://src/rules/frame_builder.gd")
const Economy = preload("res://src/rules/economy.gd")
const Shop = preload("res://src/rules/shop.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
const ROLL_FRAMES := 1800
const PORTRAIT := Vector2i(450, 800)
const STRIKE := [0.1, 0.0, 0.7]
const LEAVE := [-0.4, 0.0, 0.6]
const CLEANUP := [0.0, 0.0, 0.6]
var failures: Array[String] = []
var artifact_dir := ""
var scene: Control
var lab: Control
var catalogue: Dictionary

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
		printerr("FAIL: " + label)

func _wait_for(predicate: Callable, label: String, frames: int = 240) -> bool:
	for i in frames:
		if predicate.call():
			return true
		await process_frame
	if predicate.call():
		return true
	_check(false, "Timeout: " + label)
	return false

func _capture(label: String) -> void:
	var run = lab.run
	print("J05 %s lab=%s match=%d money=%d charms=%d deck=%d" % [label, lab.state, lab.match_number, run.money, run.charms.size(), run.cards.size()])
	_check(run.money >= 0, "balance never negative (%s)" % label)
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)

func _action(action: String, times: int = 1) -> void:
	for i in times:
		for pressed in [true, false]:
			var event := InputEventAction.new()
			event.action = action
			event.pressed = pressed
			Input.parse_input_event(event)
			await process_frame

func _focus_accept(control: Control) -> void:
	control.grab_focus()
	await _action("ui_accept")

func _window(canvas: Vector2) -> Vector2:
	return root.get_screen_transform() * canvas

func _tap(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = _window(at)
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame

func _click(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.position = _window(at)
		event.global_position = event.position
		Input.parse_input_event(event)
		await process_frame

func _slide(slider: HSlider, value: float) -> void:
	slider.grab_focus()
	var steps := roundi((value - slider.value) / slider.step)
	await _action("ui_right" if steps > 0 else "ui_left", absi(steps))

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	catalogue = Contracts.read_json(FrameBuilder.LAB_CATALOGUE)
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
	await _focus_accept(lab.settings_panel.close)
	_check(lab.run.money == Economy.STARTING_MONEY and lab.status.text.contains("$%d" % Economy.STARTING_MONEY), "the run starts with $6 on show")
	await _first_match()
	await _settlement()
	await _offers_and_purchase()
	await _reroll_and_funds()
	await _placements()
	await _full_slot()
	await _removal_and_sale()
	await _next_match()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if not failures.is_empty(): await _capture("failure")
	if failures.is_empty(): print("ROGUEWOOD_J05_OK")
	quit(0 if failures.is_empty() else 1)

func _aim() -> void:
	await _wait_for(func(): return lab.state == "aim" and lab.lane.state == "ready", "aim", ROLL_FRAMES)

func _throw(shot: Array) -> Dictionary:
	await _aim()
	var panel: Control = lab.assist_panel
	await _slide(panel.position_slider, shot[0])
	await _slide(panel.aim_slider, shot[1])
	await _slide(panel.power_slider, shot[2])
	await _slide(panel.spin_slider, 0.0)
	var count: int = lab.history.size()
	await _focus_accept(panel.throw_button)
	await _wait_for(func(): return lab.history.size() == count + 1, "roll settles", ROLL_FRAMES)
	return lab.history[-1]

func _finish_frame() -> void:
	await _wait_for(func(): return lab.state == "scoring", "scoring starts", ROLL_FRAMES)
	await _focus_accept(lab.score_panel.skip_button)
	await _wait_for(func(): return lab.state == "frame_done", "scoring finishes", ROLL_FRAMES)

## Arms a Lab Coin card when the hand holds one; returns whether it did.
func _arm_coin() -> bool:
	for option in lab.equipment.options():
		if option.item_id == "ball.lab_coin":
			await _focus_accept(lab.card_hand.button_for(option.uid))
			return lab.armed_ball == option.uid
	return false

func _first_match() -> void:
	var coins := 0
	if await _arm_coin(): coins += 1
	await _throw(STRIKE)
	await _finish_frame()
	_check(lab.run.money == Economy.STARTING_MONEY + coins and int(lab.scored_frames[-1].income) == coins, "Lab Coin income reaches the run wallet ($%d)" % coins)
	await _focus_accept(lab.next_rack)
	await _aim()
	var report := await _throw(LEAVE)
	_check(not report.knockdown_log.standing.is_empty(), "frame 2 leaves pins")
	await _aim()
	if await _arm_coin(): coins += 1
	await _throw(CLEANUP)
	await _finish_frame()
	_check(lab.run.money == Economy.STARTING_MONEY + coins and lab.run.stats(1).gross_income == coins, "item income credited once per Coin roll ($%d)" % coins)

func _settlement() -> void:
	var held: int = lab.run.money
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.state == "shop" and lab.shop_panel.visible, "the Pro Shop opens at match end")
	var summary: Dictionary = lab.settlement
	_check(summary.balance_before == held and summary.interest == Economy.interest(held) and summary.payout == Economy.MATCH_PAYOUT,
		"interest on the $%d held, then the $3 payout" % held)
	_check(lab.run.money == held + summary.interest + summary.payout and lab.shop_panel.money.text == "$%d" % lab.run.money, "the shop shows the settled balance")
	_check(lab.shop_panel.summary.text.contains("payout $3") and lab.shop_panel.summary.text.contains("interest $%d" % summary.interest), "settlement is explained")
	_check(scene.session.money == lab.run.money, "the session tracks the run's money")
	await _capture("shop")

func _offer_of(categories: Array) -> int:
	for i in lab.shop.offers.size():
		var offer: Dictionary = lab.shop.offers[i]
		if not offer.sold and not offer.item_id.is_empty() and lab.run.item(offer.item_id).category in categories:
			return i
	return -1

func _offers_and_purchase() -> void:
	var shop = lab.shop
	var run = lab.run
	_check(shop.offers.size() == 5, "five offers")
	for i in 5:
		var offer: Dictionary = shop.offers[i]
		if offer.item_id.is_empty():
			continue
		var item: Dictionary = run.item(offer.item_id)
		_check(item.category in Shop.SLOTS[i] and shop.ineligibility(item, run).is_empty() and item.rarity != "legendary" and int(item.earliest_division) <= 1,
			"offer %d (%s) is eligible for its slot" % [i, offer.item_id])
	# Buy the cheapest affordable Charm into a free slot by touch.
	var charm := -1
	for i in [0, 1]:
		if shop.offers[i].price <= run.money and (charm < 0 or shop.offers[i].price < shop.offers[charm].price):
			charm = i
	_check(charm >= 0, "an affordable Charm is on offer")
	if charm < 0: return
	var price: int = shop.offers[charm].price
	var money: int = run.money
	var bought: String = shop.offers[charm].item_id
	await _tap(lab.shop_panel.button_for_offer(charm))
	_check(run.money == money - price and run.charms.size() == 1 and run.charms[0].item_id == bought, "touch buys a Charm into a free slot")
	_check(shop.offers[charm].sold and lab.shop_panel.button_for_offer(charm).disabled and lab.shop_panel.button_for_offer(charm).text.contains("SOLD"), "a sold offer is marked and disabled")
	await _capture("bought")

func _reroll_and_funds() -> void:
	var shop = lab.shop
	var run = lab.run
	# Spend down to below the next reroll's price by rerolling with the keyboard.
	var previous: Array = shop.offers.map(func(o): return o.item_id)
	var money: int = run.money
	if money >= 2:
		await _focus_accept(lab.shop_panel.reroll_button)
		_check(run.money == money - 2 and shop.reroll_cost() == 3 and lab.shop_panel.reroll_button.text == "Reroll $3", "reroll costs $2 and the next costs $3")
		_check(shop.offers.map(func(o): return o.item_id) != previous and not shop.offers.any(func(o): return o.sold), "reroll replaces the offers")
	# Insufficient funds: anything priced above the balance is disabled, and a direct
	# request through the shop changes nothing.
	for i in 5:
		var offer: Dictionary = shop.offers[i]
		if not offer.item_id.is_empty() and offer.price > run.money:
			_check(lab.shop_panel.button_for_offer(i).disabled and lab.shop_panel.button_for_offer(i).text.contains("can't afford"), "offer %d is disabled when unaffordable" % i)
			var snapshot: Dictionary = run.to_dict()
			lab._on_offer(i)
			_check(run.to_dict() == snapshot and lab.shop_message.contains("insufficient funds") and lab._choice.is_empty(), "an unaffordable purchase is refused without change")
	if run.money < shop.reroll_cost():
		_check(lab.shop_panel.reroll_button.disabled, "an unaffordable reroll is disabled")
		var before: Array = shop.offers.duplicate(true)
		lab._on_reroll()
		_check(shop.offers == before and lab.shop_message.contains("insufficient funds"), "an unaffordable reroll changes nothing")
	await _capture("funds")

## Fixture setup: grant money so placement flows can be exercised in one visit.
func _grant(amount: int) -> void:
	lab.run.credit(amount, "fixture")
	lab._refresh_shop()

func _placements() -> void:
	var shop = lab.shop
	var run = lab.run
	_grant(30)
	# Reroll (mouse) until a pin and a workshop modification are both on offer.
	for attempt in 6:
		if _pin_offer() >= 0 and _offer_of(["pin_mod", "ball_mod"]) >= 0:
			break
		await _click(lab.shop_panel.reroll_button)
	var pin := _pin_offer()
	_check(pin >= 0, "a pin is on offer")
	if pin >= 0:
		var pin_id: String = shop.offers[pin].item_id
		await _focus_accept(lab.shop_panel.button_for_offer(pin))
		_check(lab.shop_panel.choice_sheet.visible and lab.shop_panel.choice_button(0).text.contains("moves to Reserve 1"), "a pin purchase asks where to place it")
		await _capture("place_pin")
		var money: int = run.money
		await _focus_accept(lab.shop_panel.choice_button(0))
		_check(run.rack[1].item_id == pin_id and run.reserves[0] != null and run.reserves[0].item_id == "pin.wood" and run.money == money - shop.offers[pin].price,
			"the new pin takes rack 1 and Wood moves to a reserve")
	var mod := _offer_of(["pin_mod", "ball_mod"])
	_check(mod >= 0, "a workshop modification is on offer")
	if mod >= 0:
		var mod_id: String = shop.offers[mod].item_id
		var hosts: Array = run.mod_hosts(mod_id)
		await _focus_accept(lab.shop_panel.button_for_offer(mod))
		_check(lab.shop_panel.choice_sheet.visible and lab.shop_panel.choice_list.get_child_count() == hosts.size(), "a modification lists every eligible host")
		await _tap(lab.shop_panel.choice_button(0))
		var host = run.entry_at(hosts[0])
		_check(host.mod == mod_id and hosts[0] not in run.mod_hosts(mod_id), "the modification is attached to the chosen host, one per item")

func _pin_offer() -> int:
	var i := _offer_of(["pin"])
	return i if i >= 0 and lab.run.item(lab.shop.offers[i].item_id).category == "pin" else -1

func _full_slot() -> void:
	var shop = lab.shop
	var run = lab.run
	# Fixture setup: fill the Charm row with reward-only Crowns (never offered).
	while run.charms.size() < Inventory.CHARM_SLOTS:
		run.charms.append(Inventory._entry("charm.lab_crown", 0))
	lab._refresh_shop()
	var charm := -1
	for attempt in 6:
		for i in [0, 1]:
			if charm < 0 and not shop.offers[i].sold and not shop.offers[i].item_id.is_empty() and shop.plan(i, run).ok:
				charm = i
		if charm >= 0:
			break
		await _focus_accept(lab.shop_panel.reroll_button)
	_check(charm >= 0, "a Charm is on offer for the full row")
	if charm < 0: return
	var snapshot: Dictionary = run.to_dict()
	await _focus_accept(lab.shop_panel.button_for_offer(charm))
	_check(lab.shop_panel.choice_sheet.visible and lab.shop_panel.choice_prompt.text.contains("No free slot") and lab.shop_panel.choice_list.get_child_count() == 5,
		"a full Charm row offers five replacements or Cancel")
	_check(lab.shop_panel.button_for_offer(charm).disabled and lab.shop_panel.continue_button.disabled, "the shop waits for the choice")
	await _capture("full_slot")
	await _tap(lab.shop_panel.cancel_choice)
	_check(not lab.shop_panel.choice_sheet.visible and run.to_dict() == snapshot and not shop.offers[charm].sold, "Cancel changes nothing")
	var price: int = shop.offers[charm].price
	var sale: int = run.sale_value("charm:2")
	var money: int = run.money
	var bought: String = shop.offers[charm].item_id
	await _focus_accept(lab.shop_panel.button_for_offer(charm))
	await _click(lab.shop_panel.choice_button(1))
	_check(run.charms[1].item_id == bought and run.charms.size() == 5 and run.money == money - price + sale, "replacing Charm 2 sells it and seats the new Charm")

func _removal_and_sale() -> void:
	var shop = lab.shop
	var run = lab.run
	var cards: int = run.cards.size()
	var snapshot: Dictionary = run.to_dict()
	await _focus_accept(lab.shop_panel.remove_button)
	_check(lab.shop_panel.choice_sheet.visible and lab.shop_panel.choice_list.get_child_count() == cards, "removal lists every deck card")
	await _focus_accept(lab.shop_panel.cancel_choice)
	_check(run.to_dict() == snapshot, "a cancelled removal changes nothing")
	var money: int = run.money
	await _focus_accept(lab.shop_panel.remove_button)
	await _focus_accept(lab.shop_panel.choice_button(0))
	_check(run.cards.size() == cards - 1 and run.money == money - Economy.REMOVAL_PRICE, "removal takes a card for $3")
	await _capture("removed")
	# Selling: a sold card pays its sale value; a bought-then-sold card never profits.
	var card_ref: String = "card:" + run.cards.keys()[0]
	var value: int = run.sale_value(card_ref)
	money = run.money
	await _tap(lab.shop_panel.sell_button(card_ref))
	_check(run.money == money + value and run.entry_at(card_ref) == null, "selling pays the sale value")
	_check(lab.shop_panel.sell_button("rack:1") == null, "rack pins are not for sale")
	var tactical := _offer_of(["consumable"])
	if tactical >= 0 and shop.plan(tactical, run).ok:
		money = run.money
		var cost: int = shop.offers[tactical].price
		await _focus_accept(lab.shop_panel.button_for_offer(tactical))
		var newest: String = "card:" + run.cards.keys()[-1]
		await _focus_accept(lab.shop_panel.sell_button(newest))
		_check(run.money == money - cost + Economy.sale_value(cost, 0) and run.money < money, "buying then selling loses money ($%d → $%d)" % [money, run.money])
	var stats: Dictionary = run.stats()
	_check(run.money == int(run.ledger[0].amount) + stats.net + 30, "the wallet equals the ledger (plus the $30 fixture grant)")

## The shop reflows for landscape: five offers in one row, all on screen.
func _landscape() -> void:
	root.size = Vector2i(PORTRAIT.y, PORTRAIT.x)
	for i in 3: await process_frame
	lab._refresh_shop()
	await process_frame
	var screen := Rect2(Vector2.ZERO, lab.size)
	_check(lab.shop_panel.offers_grid.columns == 5 and lab.shop_panel.offer_buttons.all(func(b): return screen.encloses(b.get_global_rect())), "landscape shows all five offers in one row")
	await _capture("landscape")
	root.size = PORTRAIT
	for i in 3: await process_frame
	lab._refresh_shop()

func _next_match() -> void:
	await _landscape()
	var loadout: Dictionary = lab.run.loadout()
	await _focus_accept(lab.shop_panel.continue_button)
	await _wait_for(func(): return lab.state == "aim" and lab.match_number == 2 and not lab.shop_panel.visible, "match 2 starts", ROLL_FRAMES)
	_check(lab.equipment.cards.size() == lab.run.cards.size(), "the deck follows the run's cards")
	await _throw(STRIKE)
	await _finish_frame()
	var built: Dictionary = FrameBuilder.build(loadout, catalogue, lab.frame_reports, {})
	var expected: Dictionary = Rules.resolve(built.frame) if built.ok else {}
	_check(built.ok and int(lab.scored_frames[-1].result.score) == expected.score, "match 2 scores with the bought Charms and pins (%d)" % expected.get("score", -1))
	var lines: Array = lab.score_panel.log_list.get_children().map(func(c): return c.text)
	_check(lines.any(func(l): return l.contains("Charm 2 " + lab.run.name_of(lab.run.charms[1].item_id))), "the log names the bought Charm")
	await _capture("match2")
	print("J05 match2 score=%d money=%d ledger=%d" % [expected.get("score", -1), lab.run.money, lab.run.ledger.size()])
