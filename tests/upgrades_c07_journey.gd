extends "res://tests/charm_c01_journey.gd"
## J03C07 (E18-C07): the Pro Shop's License offer and the six House upgrades in the
## real game, on the production slice (not Practice). Real input throughout, with
## two logged fixtures: a wallet grant after the opener, and the five upgrades the
## Division 1 License did not offer, placed through the inventory API (one License
## per Division means a two-Division slice can only sell two).
##   opener shop:  the License offer is shown, kept through a real reroll, bought
##                 with a real tap and shown sold; it cannot be sold back. With all
##                 six owned: offers show $1 off (Clearance Tag); a pin is placed in
##                 the third reserve slot (Pin Caddy); the attempt is saved and
##                 resumed with its upgrades.
##   feature shop: the settlement pays $5 interest (Savings Book); the first reroll is
##                 free and shows "Reroll free" (Punch Card); the new stock has a sixth
##                 Extra Shelf offer before the License (Extra Shelf).
##   Division 2:   after The Surveyor, the License offer is redrawn for Division 2 and,
##                 with every House upgrade owned, offers nothing.
## Spotlight Sign's odds are a statistical property, covered by mechanics_c07_test.
## Run with --fixed-fps 60.
const Shop = preload("res://src/rules/shop.gd")
const Upgrades = preload("res://src/rules/upgrades.gd")
const IDS := ["shop_upgrade.punch_card", "shop_upgrade.pin_caddy", "shop_upgrade.clearance_tag", "shop_upgrade.savings_book", "shop_upgrade.extra_shelf", "shop_upgrade.spotlight_sign"]

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
	await _focus_accept(lab.settings_panel.close)
	_check(not lab.division.practice, "a real match, not Practice")
	await _strike_out()
	await _to_shop("opener")
	await _opener_shop()
	await _leave_shop()
	await _strike_out()
	await _to_shop("feature")
	await _feature_shop()
	await _leave_shop()
	await _surveyor()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C07_OK")
	quit(0 if failures.is_empty() else 1)

func _license_index() -> int:
	for i in lab.shop.offers.size():
		if lab.shop.offers[i].slot == Shop.LICENSE: return i
	return -1

func _button(index: int) -> Button:
	return lab.shop_panel.button_for_offer(index)

func _opener_shop() -> void:
	lab.run.credit(100, "fixture: C07 upgrade sampling")
	lab._refresh_shop()
	print("J03C07 fixture: $100 granted after the opener")
	var index := _license_index()
	var license: Dictionary = lab.shop.offers[index]
	_check(index == 5 and license.division == 1 and Upgrades.kind(license.item_id) != "" and _button(index).visible and _button(index).text.begins_with("License"),
		"the shop shows a Division 1 License offer: %s" % license.item_id)
	await _tap(lab.shop_panel.reroll_button)
	await process_frame
	_check(lab.shop.offers[_license_index()].item_id == license.item_id and not lab.shop.offers[_license_index()].sold, "a real reroll keeps the License offer")
	var before: int = lab.run.money
	await _tap(_button(_license_index()))
	await process_frame
	_check(lab.run.upgrades.size() == 1 and lab.run.upgrades[0].item_id == license.item_id and lab.run.money == before - int(license.price)
		and lab.shop.offers[_license_index()].sold and _button(_license_index()).text.contains("SOLD"), "%s bought for $%d with a real tap" % [license.item_id, license.price])
	_check(not lab.shop_panel.owned_list.get_children().any(func(c): return c is Button and c.name.begins_with("Sell_upgrade")) and lab.shop_panel.rack_label.text.contains("Upgrades (kept for the attempt): "),
		"an upgrade is listed as kept and offers no sale")
	if license.item_id in IDS:
		_check(lab.motion.upgrades.history.back().id == license.item_id and lab.motion.upgrades.history.back().audio, "real License purchase activates art and sound")
	await _capture("c07_license")
	var granted: Array = []
	for id in IDS:
		if id != license.item_id:
			# Fixture grants are faster than real purchases; let the bounded mixer drain.
			var audio_until := Time.get_ticks_msec() + 450
			while Time.get_ticks_msec() < audio_until: await process_frame
			lab.run.place(id, 0, "upgrade:new")
			granted.append(id)
			if id in IDS:
				await process_frame
				await process_frame
				_check(lab.motion.upgrades.history.back().id == id and lab.motion.upgrades.history.back().audio, "upgrade has a native activation and mixer cue " + id)
				await _capture(id + "_activation")
	lab.shop.reprice(lab.run)
	lab._refresh_shop()
	print("J03C07 fixture: %s placed through the inventory API" % str(granted))
	# Clearance Tag: every unsold offer at $1 off (never under $1), shown on its button.
	var cheap := true
	for i in lab.shop.offers.size():
		var offer: Dictionary = lab.shop.offers[i]
		if offer.sold or offer.item_id.is_empty(): continue
		var base := int(lab.run.item(offer.item_id).purchase_price)
		cheap = cheap and offer.price == maxi(1, base - 1) and _button(i).text.contains("\n$%d" % offer.price)
	_check(cheap, "Clearance Tag: the offers cost $1 less: %s" % str(lab.shop.offers.map(func(o): return o.price)))
	# Pin Caddy: three reserve slots; a pin goes into the third through the placement sheet.
	_check(lab.run.reserves.size() == 3 and lab.shop_panel.rack_label.text.contains("Reserves: empty, empty, empty"), "Pin Caddy: three reserve slots")
	var placed := ""
	for visit in 40:
		for i in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[i]
			if placed.is_empty() and not offer.sold and lab.run.item(offer.item_id).get("category", "") == "pin" and offer.price <= lab.run.money:
				var targets: Array = lab.run.placements(offer.item_id).map(func(o): return o.target)
				await _tap(_button(i))
				await process_frame
				await _tap(lab.shop_panel.choice_button(targets.find("reserve:3")))
				await process_frame
				placed = offer.item_id
		if not placed.is_empty(): break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	_check(not placed.is_empty() and lab.run.reserves[2] != null and lab.run.reserves[2].item_id == placed, "a pin bought into reserve 3 (%s)" % placed)
	await _capture("c07_upgrades")
	# Save and resume in the shop: upgrades, the third reserve and the sold License return.
	var money: int = lab.run.money
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu" and scene.continue_button.visible and scene.continue_button.has_focus(), "Continue Attempt offered")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "shop", "the attempt resumes in the shop")
	lab = scene.lab
	lab.trial_log_path = ""
	_check(lab.run.upgrades.map(func(e): return e.item_id).size() == 6 and lab.run.reserves.size() == 3 and lab.run.reserves[2].item_id == placed
		and lab.shop.offers[_license_index()].sold and lab.run.money == money, "the resumed shop keeps the six upgrades, the third reserve and the sold License")

func _feature_shop() -> void:
	await process_frame
	await process_frame
	_check(lab.motion.upgrades.history.is_empty(), "restored upgrades do not replay purchase sound")
	var settlement: Dictionary = lab.settlement
	var expected := mini(floori(int(settlement.balance_before) / float(Economy.INTEREST_STEP)), Economy.INTEREST_CAP + Upgrades.INTEREST_BONUS)
	_check(int(settlement.balance_before) >= 25 and int(settlement.interest) == 5 and expected == 5 and lab.shop_panel.summary.text.contains("interest $5")
		and lab.shop_panel.summary.text.contains("Savings Book"), "Savings Book: $%d held pays $5 interest" % int(settlement.balance_before))
	_check(lab.shop_panel.reroll_button.text == "Reroll free", "Punch Card: the first reroll of the visit is free")
	await _capture("c07_free_reroll")
	var money: int = lab.run.money
	await _tap(lab.shop_panel.reroll_button)
	await process_frame
	_check(lab.run.money == money and lab.shop_panel.reroll_button.text == "Reroll $2", "the free reroll costs nothing; the next costs $2")
	var regular: Array = lab.shop.offers.filter(func(o): return o.slot != Shop.LICENSE)
	_check(regular.size() == 6 and regular[5].slot == Shop.EXTRA and _button(5).visible and _button(5).text.begins_with("Extra Shelf") and _license_index() == 6 and _button(6).visible,
		"Extra Shelf: a sixth offer before the License")
	_check(lab.motion.upgrades.passbook.visible and lab.motion.upgrades.cap_label.text.contains("$5"), "Savings Book passbook and raised cap beside settlement")
	_check(lab.motion.upgrades.spotlight.visible, "Spotlight Sign above offer grid")
	_check(_button(5).get_node("ShelfFrame").get_meta("extra_shelf"), "sixth shelf has a distinct shelf lip")
	for i in lab.shop.offers.size():
		var offer: Dictionary = lab.shop.offers[i]
		if not offer.sold and not offer.item_id.is_empty():
			_check(_button(i).get_node("ShelfFrame").get_meta("spotlit"), "Spotlight brightens unsold rarity frame")
	await _capture("c07_feature_shop")

func _surveyor() -> void:
	await _wait_for(func(): return lab.state == "intro" and lab.hud.intro.visible, "The Surveyor's introduction")
	await _focus_accept(lab.hud.intro_button)
	var boss := await _strike_out()
	_check(boss.match_won and lab.division.division_cleared(), "The Surveyor is beaten")
	await _to_shop("division cleared")
	var index := _license_index()
	_check(index >= 0 and lab.shop.offers[index].division == 2 and lab.shop.offers[index].item_id.is_empty() and _button(index).text.begins_with("License\nNothing available"),
		"Division 2's License offer is redrawn, and offers nothing once every House upgrade is owned")
	await _capture("c07_division_two")

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	if label == "c07_upgrades":
		_check(lab.motion.upgrades.caddy.get_child_count() == 3 and lab.motion.upgrades.caddy.get_child(2).visible, "caddy shows the added third pocket")
		for index in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[index]
			if offer.sold or offer.item_id.is_empty(): continue
			var tag: RichTextLabel = _button(index).get_node("ClearancePrice")
			_check(tag.visible and tag.get_meta("original_price") == lab.run.item(offer.item_id).purchase_price and tag.get_meta("price") == offer.price, "clearance tag pairs original with authoritative discounted price")
		_check(lab.motion.upgrades.glyph.still == (lab.settings.reduced_motion or lab.settings.reduced_flash), "upgrade activation follows reduced motion")
	print("J03C07 %s lab=%s money=%d upgrades=%s offers=%s" % [label, lab.state, lab.run.money, str(lab.run.upgrades.map(func(e): return e.item_id)),
		str(lab.shop.offers.map(func(o): return "%d:%s:$%d%s" % [o.slot, o.item_id, o.price, " sold" if o.sold else ""]))])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)
