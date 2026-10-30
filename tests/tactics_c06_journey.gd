extends "res://tests/charm_c01_journey.gd"
## J03C06 (E18-C06): Nudge, Reserve Call and Rule Waiver bought through the real Pro
## Shop and played in real matches on the production slice (not Practice), with the
## direct equipment model chosen in Options so every tactical card is in the bag.
## Fixture setup (logged, as J05 does): a wallet grant after the opener; offers,
## rerolls, purchases, placements, card taps and the chooser are real input.
##   shop:     the three cards and a pin placed in reserve 1;
##   feature:  Rule Waiver and Nudge are refused (not a boss; not before roll 2) and
##             nothing is spent; Reserve Call racks the reserve pin at position 1 and
##             survives a save and resume; Nudge moves a standing pin to an adjacent
##             fallen spot before roll 2; the bank equals an independent resolution of
##             the frame's rack, and both pins return after it;
##   Surveyor: Rule Waiver lifts Dead Straight for the frame (the badge says so and a
##             spun launch is committed with its spin); the next frame is straight again.
## Run with --fixed-fps 60.
const ScoreLog = preload("res://src/rules/score_log.gd")
const RivalRules = preload("res://src/rules/rival_rules.gd")
const Tactics = preload("res://src/rules/tactics.gd")
const LaneSpec = preload("res://src/simulation/lane_spec.gd")
const CARDS := ["consumable.nudge", "consumable.reserve_call", "consumable.rule_waiver"]

var called_pin := ""

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
	lab.settings_panel.equipment.grab_focus()
	await _action("ui_accept")
	await _action("ui_down")
	await _action("ui_accept")
	await _focus_accept(lab.settings_panel.close)
	_check(not lab.division.practice and lab.equipment.MODEL == "direct", "a real match with direct selection")
	await _strike_out()
	await _to_shop("opener")
	lab.run.credit(300, "fixture: C06 tactical sampling")
	lab._refresh_shop()
	print("J03C06 fixture: $300 granted after the opener; offers, rerolls and purchases follow")
	await _buy()
	await _capture("c06_shop")
	await _leave_shop()
	await _feature()
	await _surveyor()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C06_OK")
	quit(0 if failures.is_empty() else 1)

## Rerolls (real taps) until the three cards and one pin for reserve 1 are bought.
func _buy() -> void:
	var bought := {}
	for visit in 120:
		for index in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[index]
			if offer.sold or bought.has(offer.item_id):
				continue
			var before: int = lab.run.money
			if offer.item_id in CARDS:
				await _tap(lab.shop_panel.button_for_offer(index))
				await process_frame
				_check(lab.run.cards.values().any(func(e): return e.item_id == offer.item_id) and lab.run.money == before - int(offer.price), "bought %s for $%d" % [offer.item_id, offer.price])
				bought[offer.item_id] = true
			elif called_pin.is_empty() and lab.run.item(offer.item_id).get("category", "") == "pin" and offer.item_id != "pin.wood":
				var targets: Array = lab.run.placements(offer.item_id).map(func(o): return o.target)
				await _tap(lab.shop_panel.button_for_offer(index))
				await process_frame
				_check(lab.shop_panel.choice_sheet.visible, "a pin opens the placement sheet")
				await _tap(lab.shop_panel.choice_button(targets.find("reserve:1")))
				await process_frame
				_check(lab.run.reserves[0] != null and lab.run.reserves[0].item_id == offer.item_id, "%s placed in reserve 1" % offer.item_id)
				called_pin = offer.item_id
		if bought.size() == CARDS.size() and not called_pin.is_empty():
			break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	print("J03C06 bought: %s and %s in reserve 1" % [str(bought.keys()), called_pin])
	_check(bought.size() == CARDS.size() and not called_pin.is_empty(), "the three tactical cards and a reserve pin were offered and bought")

func _option(item_id: String) -> Dictionary:
	for option in lab.equipment.options():
		if option.item_id == item_id:
			return option
	return {}

## Taps a card in the bag; true when its chooser opened.
func _play(item_id: String) -> bool:
	var option := _option(item_id)
	if option.is_empty():
		_check(false, "%s is in the bag" % item_id)
		return false
	await _tap(lab.card_hand.button_for(option.uid))
	await process_frame
	return lab.state == "tactic" and lab.tactic_sheet.visible

func _choose(index: int) -> void:
	await _tap(lab.tactic_sheet.button(index))
	await process_frame
	await process_frame

func _feature() -> void:
	await _aim()
	_check(lab.match_number == 2 and not lab.division.is_boss(), "the feature match")
	var bag: int = lab.equipment.options().size()
	_check(not await _play("consumable.rule_waiver") and lab.status.text.contains("Rule Waiver is only played in a boss match.") and lab.equipment.options().size() == bag,
		"Rule Waiver is refused outside a boss match, with a note, and nothing is spent")
	_check(not await _play("consumable.nudge") and lab.status.text.contains("Nudge is played before roll 2.") and lab.equipment.options().size() == bag,
		"Nudge is refused before roll 1")
	# Reserve Call: reserve 1 (the bought pin) into position 1 for this frame.
	var wood: Dictionary = lab.run.rack[1]
	_check(await _play("consumable.reserve_call") and lab.tactic_sheet.prompt.text.contains("which reserve pin"), "Reserve Call opens its chooser")
	await _choose(0)
	_check(lab.tactic_sheet.prompt.text.contains("replaces which rack pin") and lab.tactic_sheet.choices.get_child_count() == 10, "it then lists the ten rack positions")
	await _choose(0)
	_check(lab.state == "aim" and lab.run.rack[1].item_id == called_pin and lab.run.reserves[0] == wood and lab.frame_actions.size() == 1
		and _option("consumable.reserve_call").is_empty() and lab.status.text.contains("Reserve Call: %s played at position 1" % lab.run.name_of(called_pin)),
		"Reserve Call racks %s at position 1 for the frame and the card is spent" % called_pin)
	await _capture("c06_reserve_call")
	# Save and resume: the swap and its action come back exactly as saved.
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu" and scene.continue_button.visible and scene.continue_button.has_focus(), "Continue Attempt offered")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "the attempt resumes before roll 1")
	lab = scene.lab
	lab.trial_log_path = ""
	_check(lab.run.rack[1].item_id == called_pin and lab.run.reserves[0].item_id == wood.item_id and lab.frame_actions.size() == 1 and not lab.frame_actions[0].restored
		and _option("consumable.reserve_call").is_empty(), "the resumed frame keeps the called pin, its action and the spent card")
	var loadout: Dictionary = lab.run.loadout()
	var context: Dictionary = lab.frame_context()
	var before: int = lab.history.size()
	await _throw(LEAVE)
	_check(lab.state != "scoring" and not lab.rack.standing.is_empty(), "roll 1 leaves pins standing")
	await _aim()
	# Nudge before roll 2: the first standing pin with a free neighbour moves.
	var options := Tactics.nudge_options(lab.rack)
	_check(not options.is_empty() and await _play("consumable.nudge") and lab.tactic_sheet.choices.get_child_count() == options.size(), "Nudge lists the standing pins that can move")
	await _choose(0)
	var pin: int = options[0].position
	var spot: int = options[0].to[0]
	_check(lab.tactic_sheet.prompt.text.contains("move pin %d" % pin) and lab.tactic_sheet.choices.get_child_count() == options[0].to.size(), "then its adjacent fallen spots")
	_check(lab.tactic_sheet.rack_diagram.visible and lab.tactic_sheet.rack_diagram.get_child_count() == 10, "Nudge shows the ten rack spots")
	var enabled: Array = lab.tactic_sheet.rack_diagram.get_children().filter(func(b): return not b.disabled)
	_check(enabled.map(func(b): return b.get_meta("rack_position")) == options[0].to, "diagram highlights exactly the legal adjacent empty spots")
	await _capture("c06_nudge_chooser")
	await _tap(enabled[0])
	await process_frame
	await process_frame
	var moved: Dictionary = lab.rack.standing.filter(func(e): return int(e.position) == pin)[0]
	var body: Vector3 = lab.lane.pins[pin].global_position
	_check(lab.state == "aim" and is_equal_approx(moved.x, LaneSpec.spot(spot).x) and absf(body.x - LaneSpec.spot(spot).x) < 0.01 and absf(-body.z - LaneSpec.spot(spot).y) < 0.01,
		"Nudge moves pin %d onto spot %d, on the lane before the throw" % [pin, spot])
	await _capture("c06_nudge")
	await _throw(STRIKE)
	var scored := await _scored()
	var reports: Array = lab.history.slice(before)
	var built := Builder.build(loadout, lab.content.catalogue, reports, {1: ["consumable.reserve_call"], 2: ["consumable.nudge"]}, context)
	var expected := Rules.resolve(built.frame) if built.ok else {"score": -1}
	print("J03C06 feature frame: category=%s banked=%d expected=%d fallen=%s pin1=%s nudged=%d->%d" % [scored.result.category, scored.banked, expected.score,
		str(reports.map(func(r): return r.roll_result.fallen_positions)), called_pin, pin, spot])
	_check(built.ok and scored.banked == expected.score and scored.frame.pins.any(func(p): return int(p.position) == 1 and p.item_id == called_pin),
		"the frame banks the independent resolution with %s at position 1 (%d vs %d)" % [called_pin, scored.banked, expected.score])
	_check(_logged("Reserve Call: ") and _logged("Nudge: pin %d moved to spot %d" % [pin, spot]), "the explanation names both tactics")
	_check(lab.run.rack[1].item_id == wood.item_id and lab.run.reserves[0].item_id == called_pin and lab.frame_actions[0].restored, "after the frame both pins are back in place")
	await _capture("c06_feature_frame")
	while not lab.division.match_over():
		await _focus_accept(lab.next_rack)
		_check(lab.frame_actions.is_empty() and lab.run.rack[1].item_id == wood.item_id, "a new frame starts with no tactics in force")
		await _throw(STRIKE)
		if await _second_roll():
			await _throw(STRIKE)
		await _scored()
	_check(lab.division.results[-1].won, "the feature is won (%d of %d)" % [lab.division.results[-1].score, lab.division.results[-1].target])
	await _to_shop("feature")
	await _leave_shop()

func _surveyor() -> void:
	await _wait_for(func(): return lab.state == "intro" and lab.hud.intro.visible, "The Surveyor's introduction")
	await _focus_accept(lab.hud.intro_button)
	await _aim()
	_check(lab.spin_disabled() and lab.division.rules() == ["boss_rule.dead_straight"], "Dead Straight is in force")
	_check(await _play("consumable.rule_waiver") and lab.tactic_sheet.prompt.text.contains("Dead Straight will not apply"), "Rule Waiver asks to confirm the waiver")
	await _choose(0)
	_check(lab.state == "aim" and not lab.spin_disabled() and lab.assist_panel.spin_slider.editable and lab.hud.badge.text.contains("waived this frame")
		and lab.status.text.contains("Rule Waiver: Dead Straight waived for this frame."), "the waiver lifts Dead Straight; the badge and status say so")
	await _capture("c06_rule_waiver")
	var context: Dictionary = lab.frame_context()
	var loadout: Dictionary = lab.run.loadout()
	var before: int = lab.history.size()
	var roll := await _throw(STRIKE, 0.3)
	_check(float(roll.launch.spin) > 0.0 and is_equal_approx(float(roll.launch.spin), lab.assist_panel.spin_slider.value), "a spun launch is committed with its spin under the waiver (%.2f)" % float(roll.launch.spin))
	if await _second_roll():
		await _throw(STRIKE, 0.0)
	var scored := await _scored()
	var built := Builder.build(loadout, lab.content.catalogue, lab.history.slice(before), {1: ["consumable.rule_waiver"]}, context)
	var expected := Rules.resolve(built.frame) if built.ok else {"score": -1}
	_check(built.ok and scored.banked == expected.score and _logged("Rule Waiver: Dead Straight waived"), "the waived frame banks the independent resolution (%d vs %d)" % [scored.banked, expected.score])
	if not lab.division.match_over():
		await _focus_accept(lab.next_rack)
		await _aim()
		_check(lab.spin_disabled() and not lab.hud.badge.text.contains("waived") and _option("consumable.rule_waiver").is_empty(), "the next frame is under Dead Straight again; the card is spent")
		var straight := await _throw(STRIKE, 0.3)
		_check(float(straight.launch.spin) == 0.0, "and its launch is committed straight")
	await _capture("c06_surveyor")

## After roll 1 settles: true when roll 2 is to be thrown, false when the frame scores.
func _second_roll() -> bool:
	await _wait_for(func(): return lab.state == "scoring" or (lab.state == "aim" and lab.lane.state == "ready"), "roll 2 or scoring", ROLL_FRAMES)
	return lab.state == "aim"

func _capture(label: String) -> void:
	print("J03C06 %s lab=%s money=%d actions=%s rules=%s" % [label, lab.state, lab.run.money, str(lab.frame_actions.map(func(a): return a.kind)), str(lab.active_rules())])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)
