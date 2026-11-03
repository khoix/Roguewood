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
var tag := "J03C08" # log prefix; extending journeys set their own
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
	lab.run.credit(8000, "fixture: C08 Charm sampling")
	# Wood Grain is Old Lou's first-clear reward (E22-L01); this attempt's pool gets its gate.
	if "gate.old_lou_cleared" not in lab.shop.unlocked: lab.shop.unlocked.append("gate.old_lou_cleared")
	lab._refresh_shop()
	print("J03C08 fixture: $8000 granted and gate.old_lou_cleared added to this attempt's pool after the opener; offers, rerolls and purchases follow")
	await _buy(FIRST)
	await _capture("c08_shop")
	await _leave_shop()
	var strike := await _house_frame([STRIKE], "feature frame 1")
	_check(strike.result.category == "strike" and _logged("Head Pin") and _logged("Wood Grain") and _logged("Opening Act") and not _logged("Open House"),
		"a first-frame strike: Head Pin, Wood Grain and Opening Act apply; Open House stays silent")
	_check(strike.income >= 1, "Strike Fund pays $1 with the strike's income ($%d)" % strike.income)
	await process_frame
	_check(lab.motion.abilities.marquee_lit, "Opening Act marquee lit in frame 1")
	for id in ["charm.head_pin","charm.wood_grain","charm.opening_act"]:
		_check(lab.motion.abilities.history.any(func(e): return e.id == id), "native resolver cue: " + id)
	await _capture("c08_strike")
	await _focus_accept(lab.next_rack)
	var open := await _house_frame([LEAVE, GUTTER], "feature frame 2")
	_check(open.result.category == "open" and _logged("Open House") and not _logged("Opening Act"), "a second-frame open: Open House applies; Opening Act stays silent")
	await process_frame
	_check(not lab.motion.abilities.marquee_lit, "Opening Act marquee dims in frame 2")
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
	for id in ["charm.open_house","charm.strike_fund","charm.holdouts"]:
		_check(art_captures.has(id), "native cue captured: " + id)
		var heard_b: int = lab.motion.sound.played
		lab.motion.abilities.cue(id,"skip_fixture",true)
		_check(lab.motion.sound.played == heard_b,"B skipped cue silent")
		lab.motion.sound.muted = true
		lab.motion.abilities.cue(id,"mute_fixture",false)
		_check(lab.motion.sound.played == heard_b,"B muted cue silent")
		lab.motion.sound.muted = false
	var bank_before: int = lab.total_score
	for id in ["charm.head_pin", "charm.wood_grain", "charm.opening_act"]:
		var heard: int = lab.motion.sound.played
		lab.motion.abilities.cue(id,"skip_fixture",true)
		_check(lab.motion.sound.played == heard, "skipped cue is silent: " + id)
		lab.motion.sound.muted = true
		lab.motion.abilities.cue(id,"mute_fixture",false)
		_check(lab.motion.sound.played == heard, "muted cue is silent: " + id)
		lab.motion.sound.muted = false
	_check(lab.total_score == bank_before, "presentation fixtures cannot rebank")
	_check(art_captures.has("charm.wood_grain_10") and art_captures.has("charm.wood_grain_7"), "full and partial Wood counts captured")
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
		if bought.size() == wanted.size() or lab.run.money < lab.shop.reroll_cost(lab.run):
			break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	print("%s bought: %s" % [tag, str(bought)])
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
	print("%s %s: category=%s banked=%d expected=%d income=%d expected_income=%d frame=%d" % [tag, label, scored.result.category, scored.banked, expected.score, scored.income, payouts, context.match_frame])
	_check(built.ok and scored.banked == expected.score and scored.income == payouts, "%s banks the independent resolution and its income" % label)
	return scored

func _capture(label: String) -> void:
	print("J03C08 %s lab=%s money=%d charms=%s" % [label, lab.state, lab.run.money, str(lab.run.charms.map(func(e): return e.item_id))])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)

# Native cue evidence while the original explanation plays.
var art_captures := {}
func _scored() -> Dictionary:
	for tick in ROLL_FRAMES * 3:
		if lab.state in ["scoring", "frame_done"]:
			var glyph: Control = lab.motion.abilities.glyph
			if glyph.style != null and glyph.age < glyph.style.duration:
				var id: String = glyph.style.item_id
				if id in ["charm.head_pin", "charm.wood_grain", "charm.opening_act"]:
					var count := int(glyph.details.get("count",0))
					var key := id + "_%d" % count
					if not art_captures.has(key):
						art_captures[key] = true
						_check(glyph.still, "native Charm cue respects reduced motion")
						if id == "charm.head_pin":
							_check(lab.motion.abilities.counted_rack_positions() == [1], "Head Pin marks position 1")
						if id == "charm.wood_grain":
							var frame: Dictionary = lab.scored_frames[-1].frame
							var down: Array = []
							for roll in frame.rolls: down.append_array(roll.fallen_positions)
							var expected: int = frame.pins.filter(func(p): return p.item_id == "pin.wood" and p.position in down).size()
							_check(count == expected, "grain count matches fallen Wood Pins")
						await _capture(key.replace(".","_") + "_cue")
		await _capture_house_b_cue()
		if lab.state == "frame_done": return lab.scored_frames[-1]
		await process_frame
	_check(false,"native Charm explanation timeout")
	return lab.scored_frames[-1]

func _capture_house_b_cue() -> void:
	if lab.state not in ["scoring","frame_done"]: return
	var glyph: Control = lab.motion.abilities.glyph
	if glyph.style == null or glyph.age >= glyph.style.duration: return
	var id: String = glyph.style.item_id
	if id not in ["charm.open_house","charm.strike_fund","charm.holdouts"] or art_captures.has(id): return
	art_captures[id] = true
	var scored: Dictionary = lab.scored_frames[-1]
	_check(glyph.still,"B cue is static with reduced motion")
	if id == "charm.open_house": _check(scored.result.category == "open","door only opens on open frame")
	if id == "charm.strike_fund":
		_check(scored.result.category == "strike" and glyph.details.phase == "after_bank" and int(glyph.details.amount) == 1,"one coin on strike income after bank")
	if id == "charm.holdouts":
		var fallen: Array = []
		for roll in scored.frame.rolls: fallen.append_array(roll.fallen_positions)
		_check(int(glyph.details.count) == 10-fallen.size(),"one folded-arm figure per standing pin")
	await _capture(id.replace(".","_")+"_cue")
