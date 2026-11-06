extends "res://tests/house_c08_journey.gd"
## J03C11 (E18-C11, DC-H4): House's last five items bought through the real Pro Shop
## and played on the production slice in Practice, with direct equipment chosen in
## Options so the three cards are always in the bag. Fixture setup (logged, as J05
## does): an $8000 wallet grant after the opener; offers, rerolls, purchases and card
## taps are real input.
##   Called Shot armed with a strike: ×2;
##   Double Take armed with a strike: its first direct pin repeats once;
##   Pin Count armed with roll 2: +5 Value per pin down;
##   Cleanup Crew: a leave of 2+ and a cleanup spare;
##   Lucky Seven: first-roll shots are tried, each followed by a gutter, until an open
##   frame ends with exactly three pins standing.
## Every bank equals an independent resolution with the played card as that roll's extra.
## Run with --fixed-fps 60.
const ITEMS := ["consumable.double_take", "consumable.called_shot", "consumable.pin_count", "charm.cleanup_crew", "charm.lucky_seven"]
## First-roll shots tried for a seven-pin frame (position, aim, power), each followed by a gutter.
const SEVEN_SHOTS := [[-0.4, 0.0, 0.6], [-0.3, 0.0, 0.6], [-0.5, 0.0, 0.6], [0.3, 0.0, 0.6], [-0.4, 0.0, 0.5], [0.4, 0.0, 0.6], [-0.2, 0.0, 0.6], [0.2, 0.0, 0.6]]

func _run() -> void:
	tag = "J03C11"
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
	lab.settings_panel.use_equipment("direct") # fixture: direct selection is no longer a player option (ADR 004)
	print("%s fixture: direct selection set through settings_panel.use_equipment (not a player option since UI-1)" % get_script().resource_path.get_file())
	await _focus_accept(lab.settings_panel.close)
	_check(lab.division.practice and lab.equipment.MODEL == "direct", "Practice with direct selection")
	await _play_out()
	lab.run.credit(8000, "fixture: C11 item sampling")
	lab._refresh_shop()
	print("J03C11 fixture: $8000 granted after the opener; offers, rerolls and purchases follow")
	await _buy_items()
	await _capture("c11_shop")
	await _leave_shop()
	var called := await _card_frame("consumable.called_shot", 1, [STRIKE], "Called Shot strike")
	_check(called.result.category == "strike" and _logged("Called Shot"), "Called Shot doubles a strike")
	await _capture("c11_called_shot")
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.close)
	await _focus_accept(lab.next_rack)
	var echo := await _card_frame("consumable.double_take", 1, [STRIKE], "Double Take strike")
	_check(echo.result.category == "strike" and int(echo.result.retriggers) >= 1 and _logged("Double Take"), "Double Take repeats the first direct pin (%d repeat)" % int(echo.result.retriggers))
	await _capture("c11_double_take")
	await _next()
	var spare := await _card_frame("consumable.pin_count", 2, [LEAVE, CLEANUP], "Pin Count on the cleanup")
	_check(spare.result.category == "spare" and _logged("Pin Count") and _logged("Cleanup Crew"), "a cleanup spare: Pin Count's Value and Cleanup Crew's Mult")
	await _capture("c11_spare")
	var lucky := false
	for shot in SEVEN_SHOTS:
		await _focus_accept(lab.next_rack)
		if lab.state == "shop":
			await _leave_shop()
		var open := await _card_frame("", 0, [shot, GUTTER], "seven-pin attempt %s" % str(shot))
		var standing: int = 10 - open.frame.rolls.reduce(func(n, r): return n + r.fallen_positions.size(), 0)
		if open.result.category == "open" and standing == 3:
			_check(_logged("Lucky Seven"), "an open frame with seven down: Lucky Seven +7 Mult")
			lucky = true
			break
		_check(not _logged("Lucky Seven"), "Lucky Seven stays silent with %d standing" % standing)
	_check(lucky, "a seven-pin open frame was thrown")
	await _capture("c11_lucky_seven")
	for label in ["cleanup_crew","lucky_seven"]:_check(art_captures.has(label),"native H4-B capture: "+label)
	await _tactical_miss()
	for label in ["called_shot_ball","double_take_retrigger","pin_count_ball","called_shot_missed"]:_check(art_captures.has(label),"native tactical capture: "+label)
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C11_OK")
	quit(0 if failures.is_empty() else 1)

## Rerolls (real taps) until all five are offered and bought.
func _buy_items() -> void:
	var bought := {}
	for visit in 150:
		for i in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[i]
			if offer.item_id not in ITEMS or bought.has(offer.item_id) or offer.sold or offer.price > lab.run.money:
				continue
			var before: int = lab.run.money
			await _tap(lab.shop_panel.button_for_offer(i))
			await process_frame
			_check(lab.run.money == before - int(offer.price) and lab.run.owned_count(offer.item_id) == 1, "bought %s for $%d" % [offer.item_id, offer.price])
			bought[offer.item_id] = true
		if bought.size() == ITEMS.size() or lab.run.money < lab.shop.reroll_cost(lab.run):
			break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	print("J03C11 bought: %s" % str(bought.keys()))
	_check(bought.size() == ITEMS.size(), "all five items offered and bought (%d)" % bought.size())

## Arms `card` (a real tap) before roll `roll` (0: none), throws, then checks the
## frame against an independent resolution with the card as that roll's extra.
func _card_frame(card: String, roll: int, shots: Array, label: String) -> Dictionary:
	var context: Dictionary = lab.frame_context()
	var loadout: Dictionary = lab.run.loadout()
	var before: int = lab.history.size()
	if roll == 1:
		await _arm_card(card)
	await _throw(shots[0])
	if shots.size() > 1 and await _second_roll():
		if roll == 2:
			await _arm_card(card)
		await _throw(shots[1])
	var scored := await _scored()
	var reports: Array = lab.history.slice(before)
	var extras := {roll: [card]} if roll > 0 and reports.size() >= roll else {}
	var built := Builder.build(loadout, lab.content.catalogue, reports, extras, context)
	var expected := Rules.resolve(built.frame) if built.ok else {"score": -1}
	print("J03C11 %s: category=%s banked=%d expected=%d played=%s" % [label, scored.result.category, scored.banked, expected.score, str(lab.equipment.exhausted)])
	_check(built.ok and scored.banked == expected.score, "%s banks the independent resolution (%d vs %d)" % [label, scored.banked, expected.score])
	return scored

func _arm_card(card: String) -> void:
	await _aim()
	for option in lab.equipment.options():
		if option.item_id == card:
			await _tap(lab.card_hand.button_for(option.uid))
			_check(lab.armed_tactical == option.uid, "armed %s" % card)
			return
	_check(false, "%s is in the bag" % card)

func _second_roll() -> bool:
	await _wait_for(func(): return lab.state == "scoring" or (lab.state == "aim" and lab.lane.state == "ready"), "roll 2 or scoring", ROLL_FRAMES)
	return lab.state == "aim"

func _capture(label: String) -> void:
	print("J03C11 %s lab=%s money=%d charms=%s bag=%s" % [label, lab.state, lab.run.money, str(lab.run.charms.map(func(e): return e.item_id)),
		str(lab.equipment.options().map(func(o): return o.item_id))])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)

# AV-H4-A: observe the existing reveal; all amounts remain resolver-owned.
func _scored() -> Dictionary:
	for tick in ROLL_FRAMES*3:
		if lab.state in ["scoring","frame_done"]:
			var glyph:Control=lab.motion.abilities.glyph
			if glyph.style!=null and glyph.age<glyph.style.duration and glyph.style.item_id in preload("res://src/presentation/house_tactical_events.gd").IDS:
				var id:String=glyph.style.item_id
				var key:=id.get_slice(".",1)+"_"+String(glyph.details.phase)
				if not art_captures.has(key):
					art_captures[key]=true
					var scored:Dictionary=lab.scored_frames[-1]
					_check(glyph.still==bool(lab.settings.reduced_motion or lab.settings.reduced_flash),"tactical respects reduced setting")
					var missed:bool=glyph.details.get("zero",false)
					_check(lab.motion.abilities.history.any(func(e):return e.id==id and e.event==glyph.details.phase and e.audio_played!=missed),"tactical sound follows success, never miss")
					if id=="consumable.pin_count":
						var count:int=preload("res://src/presentation/house_tactical_events.gd").fallen_positions(scored.frame).size()
						_check(int(glyph.details.count)==count and int(glyph.details.amount)==5*count,"Pin Count ticks match resolver count and Value")
						_check(lab.motion.abilities.counted_rack_positions().size()==count,"counted rack marks exactly the paid pins")
					elif id=="consumable.double_take":
						_check(glyph.details.positions==[scored.frame.rolls[0].first_direct],"doubled outline over actual first direct pin")
					elif missed:
						await process_frame # allow the rack child to consume the newly revealed cue
						_check(scored.result.category!="strike" and not glyph.details.lit,"Called Shot is grey when spent without strike")
						_check(glyph.material is ShaderMaterial and lab.motion.abilities.tactical_hand.material is ShaderMaterial,"miss desaturates both hand annotations")
					else:_check(scored.result.category=="strike" and glyph.details.lit,"Called Shot lights on strike")
					await _capture("h4_"+key)
		await _capture_h4_charms()
		if lab.state=="frame_done":return lab.scored_frames[-1]
		await process_frame
	_check(false,"H4-A score reveal timeout")
	return lab.scored_frames[-1]

func _tactical_miss() -> void:
	# Buy a fresh copy through the shop: the successful card is exhausted.
	await _focus_accept(lab.next_rack)
	for frame in 5:
		if lab.state=="shop":break
		await _card_frame("",0,[GUTTER,GUTTER],"advance to tactical rebuy")
		await _focus_accept(lab.next_rack)
	_check(lab.state=="shop","fresh tactical shop")
	var bought:=false
	for visit in 150:
		for i in lab.shop.offers.size():
			var offer:Dictionary=lab.shop.offers[i]
			if offer.item_id!="consumable.called_shot" or offer.sold:continue
			await _tap(lab.shop_panel.button_for_offer(i));bought=true;break
		if bought:break
		await _tap(lab.shop_panel.reroll_button)
	_check(bought,"fresh Called Shot bought for negative case")
	await _leave_shop()
	var missed:=await _card_frame("consumable.called_shot",1,[LEAVE,CLEANUP],"Called Shot spent on spare")
	_check(missed.result.category=="spare" and not _logged("Called Shot"),"miss gives no multiplier")

# AV-H4-B: first-roll leave and exact-seven feedback from resolved frames.
func _capture_h4_charms() -> void:
	if lab.state not in ["scoring","frame_done"] or lab.scored_frames.is_empty():return
	var glyph:Control=lab.motion.abilities.glyph
	if glyph.style==null or glyph.age>=glyph.style.duration:return
	var id:String=glyph.style.item_id
	if id not in ["charm.cleanup_crew","charm.lucky_seven"]:return
	var key:=id.get_slice(".",1)
	if art_captures.has(key):return
	if id=="charm.lucky_seven" and not glyph.still:
		while glyph.age<glyph.style.duration*.28:await process_frame
	art_captures[key]=true
	var scored:Dictionary=lab.scored_frames[-1]
	_check(glyph.still==bool(lab.settings.reduced_motion or lab.settings.reduced_flash),"H4-B reduced setting")
	_check(lab.motion.abilities.history.any(func(e):return e.id==id and e.audio_played),"H4-B native sound")
	if id=="charm.cleanup_crew":
		var leave:int=10-scored.frame.rolls[0].fallen_positions.size()
		_check(scored.result.category=="spare" and leave>=2 and int(glyph.details.leave)==leave and int(glyph.details.required)==2 and int(glyph.details.amount)==5,"Crew shows actual first leave against two, with +5 Mult")
		_check(lab.motion.abilities.counted_rack_positions()==range(1,11).filter(func(p):return p not in scored.frame.rolls[0].fallen_positions),"Crew sweeps the actual first-roll leave")
	else:
		var down:int=scored.frame.rolls.reduce(func(n,r):return n+r.fallen_positions.size(),0)
		_check(scored.result.category=="open" and down==7 and int(glyph.details.down)==7 and int(glyph.details.standing)==3 and int(glyph.details.face)==7 and int(glyph.details.amount)==7,"Lucky Seven lands on seven only for seven down on an open frame")
	await _capture("h4_"+key)
