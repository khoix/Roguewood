extends "res://tests/charm_c01_journey.gd"
## J03C04 (E18-C04): the eight landed modifications bought and attached through the
## real Pro Shop, then scored in real throws on the production slice (not Practice).
## Fixture setup (logged, as J05 does): a wallet grant, Division 2 shop eligibility
## and the three unlock gates (True Curve, House League title, Mixed Rack) added to
## this attempt's shop pool;
## offers, rerolls, purchases and host choices are real taps.
##   shop:    every C04 modification is offered, bought and attached to the host the
##            choice sheet lists (ball modifications on Hook and Hammer cards, pin
##            modifications on rack 1, 3, 5 and 6); Echo Charge never lists an Echo card;
##   frame 1: a strike thrown with a modified card; frame 2: a leave and a gutter with
##            the House ball, so Lantern at 6 stands.
## Every bank equals an independent resolution with the lab's context and the thrown
## card's modification; the lab's explanation contains every independent line; each
## pin modification applies exactly when its pin falls (Lantern: when it stands).
## Run with --fixed-fps 60.
const ScoreLog = preload("res://src/rules/score_log.gd")
const GATES := ["gate.mastery_true_curve", "gate.house_champion", "gate.mastery_mixed_rack"]
const BALL_HOSTS := {"ball_mod.chalk_grip": "ball.hook", "ball_mod.spin_wax": "ball.hook", "ball_mod.coin_slot": "ball.hammer", "ball_mod.echo_charge": "ball.hammer"}
const PIN_HOSTS := {"pin_mod.brass_cap": "rack:1", "pin_mod.gilt_leaf": "rack:3", "pin_mod.keystone": "rack:5", "pin_mod.lantern": "rack:6"}

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
	lab.run.credit(5000, "fixture: C04 modification sampling")
	for gate in GATES:
		if gate not in lab.shop.unlocked: lab.shop.unlocked.append(gate)
	lab.shop.division = 2 # Echo Charge and Keystone are offered from Division 2
	lab._refresh_shop()
	print("J03C04 fixture: $5000, Division 2 shop eligibility and gates %s added to this attempt's pool; offers, rerolls and purchases follow" % str(GATES))
	await _buy_all()
	await _capture("c04_shop")
	await _leave_shop()
	var first := await _mod_frame([STRIKE], true, "frame 1")
	await _capture("c04_strike")
	await _next()
	var second := await _mod_frame([LEAVE, GUTTER], false, "frame 2")
	await _capture("c04_open")
	_check(first.lines.any(func(l): return l.contains("Keystone") or l.contains("Brass Cap")) and second.lines.any(func(l): return l.contains("Lantern")),
		"pin modifications applied in real frames")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C04_OK")
	quit(0 if failures.is_empty() else 1)

## Rerolls (real taps) until every C04 modification has been offered, bought and attached.
func _buy_all() -> void:
	var wanted: Array = BALL_HOSTS.keys() + PIN_HOSTS.keys()
	var bought := {}
	var used_cards := {}
	for visit in 120:
		for index in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[index]
			if offer.item_id not in wanted or bought.has(offer.item_id) or offer.sold:
				continue
			var hosts: Array = lab.run.mod_hosts(offer.item_id)
			var target := _host(offer.item_id, hosts, used_cards)
			if offer.item_id == "ball_mod.echo_charge":
				_check(not hosts.any(func(r): return lab.run.entry_at(r).item_id == "ball.echo"), "Echo Charge never lists an Echo Ball card")
			if target.is_empty():
				continue
			var before: int = lab.run.money
			await _tap(lab.shop_panel.button_for_offer(index))
			await process_frame
			_check(lab.shop_panel.choice_sheet.visible and lab.shop_panel.choice_list.get_child_count() == hosts.size(), "%s lists its %d eligible hosts" % [offer.item_id, hosts.size()])
			await _tap(lab.shop_panel.choice_button(hosts.find(target)))
			await process_frame
			_check(lab.run.entry_at(target).mod == offer.item_id and lab.run.money == before - int(offer.price), "%s attached to %s for $%d" % [offer.item_id, target, offer.price])
			bought[offer.item_id] = target
			used_cards[target] = true
		if bought.size() == wanted.size():
			break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	print("J03C04 attached: %s" % str(bought))
	_check(bought.size() == wanted.size(), "all eight C04 modifications offered, bought and attached (%d)" % bought.size())

func _host(mod_id: String, hosts: Array, used: Dictionary) -> String:
	if PIN_HOSTS.has(mod_id):
		return PIN_HOSTS[mod_id] if PIN_HOSTS[mod_id] in hosts else ""
	for ref in hosts:
		if lab.run.entry_at(ref).item_id == BALL_HOSTS[mod_id] and not used.has(ref):
			return ref
	return ""

## Throws (arming a modified card when asked), then checks the bank, the explanation
## and each pin modification against an independent resolution.
func _mod_frame(shots: Array, armed: bool, label: String) -> Dictionary:
	var extras := {}
	if armed:
		var pick := {}
		for preferred in ["ball_mod.coin_slot", "ball_mod.echo_charge", "ball_mod.chalk_grip", "ball_mod.spin_wax"]:
			for option in lab.equipment.options():
				if pick.is_empty() and lab.run.card_mod(option.uid) == preferred:
					pick = option
		if not pick.is_empty():
			var mod: String = lab.run.card_mod(pick.uid)
			await _tap(lab.card_hand.button_for(pick.uid))
			_check(lab.armed_ball_id() == pick.item_id, "armed the %s card carrying %s" % [pick.item_id, mod])
			extras[1] = [mod]
		_check(not extras.is_empty(), "%s: a card with a modification is in hand" % label)
	var context: Dictionary = lab.frame_context()
	var loadout: Dictionary = lab.run.loadout()
	var before: int = lab.history.size()
	await _throw(shots[0])
	if shots.size() > 1 and lab.state != "scoring":
		await _aim()
		await _throw(shots[1])
	var scored := await _scored()
	var reports: Array = lab.history.slice(before)
	var built := Builder.build(loadout, lab.content.catalogue, reports, extras, context)
	var expected := Rules.resolve(built.frame) if built.ok else {"score": -1, "future_effects": []}
	var names := {}
	for item in lab.content.catalogue.items:
		names[item.id] = item.name
	var lines: Array = ScoreLog.steps(expected, built.frame, names, built.owners).map(func(s): return s.text) if built.ok else []
	var payouts: int = expected.future_effects.filter(func(e): return e.op == "payout").reduce(func(n, e): return n + int(e.amount), 0)
	print("J03C04 %s: category=%s banked=%d expected=%d income=%d expected_income=%d" % [label, scored.result.category, scored.banked, expected.score, scored.income, payouts])
	_check(built.ok and scored.banked == expected.score and scored.income == payouts, "%s banks the independent resolution and its payouts" % label)
	_check(lines.all(func(l): return _logged(l)), "%s: the explanation contains every independent line" % label)
	var fallen := {}
	for r in reports:
		for p in r.roll_result.fallen_positions: fallen[int(p)] = true
	for mod_id in PIN_HOSTS:
		var position := int(String(PIN_HOSTS[mod_id]).trim_prefix("rack:"))
		var applies: bool = (not fallen.has(position)) if mod_id == "pin_mod.lantern" else fallen.has(position)
		_check(lines.any(func(l): return l.contains(names[mod_id])) == applies, "%s: %s %s" % [label, names[mod_id], "applies" if applies else "stays silent"])
	return {"lines": lines}

func _capture(label: String) -> void:
	print("J03C04 %s lab=%s money=%d mods=%s" % [label, lab.state, lab.run.money, str(lab.run.entries().filter(func(o): return not String(o.entry.mod).is_empty()).map(func(o): return "%s:%s" % [o.ref, o.entry.mod]))])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)
