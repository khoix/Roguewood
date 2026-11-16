extends "res://tests/neon_c15_journey.gd"
## J03C18 (E18-C18, DC-N4): Neon's two shop upgrades and the Controlled Curve items,
## in the Neon League (`--content=neon`) with real targets. Fixture setup (logged, as
## J05 does): after the opener, a wallet grant, the Controlled Curve gate (so its three
## items are in the pool), and the Division's License offer set to each upgrade in
## turn (the License is one random upgrade per Division). Offers, rerolls, purchases,
## sales and card taps are real input.
##   shop:      Trade-In bought from the License offer: a kit card sold through the
##              Sell sheet returns $1 more. Specialist Shelf bought the same way: after
##              a reroll the shop shows a Specialist offer, a curve, hook, accuracy,
##              precision or straight item. Comet Ball and Steady Hand to the deck and
##              Metronome to the Charms, through rerolls; the rest of the kit is sold;
##   feature 1: the Comet Ball card with Steady Hand, curved from the left, released
##              in the sweet window: a curved strike graded sweet or perfect, so Comet
##              Ball, Steady Hand and Metronome all apply, and the Career counts one
##              controlled curve towards the mastery.
## Every bank equals an independent resolution. Run with --fixed-fps 60.
const Shop = preload("res://src/rules/shop.gd")
const GATE := "gate.mastery_controlled_curve"
const N4 := {"ball.comet": "card:new", "consumable.steady_hand": "card:new", "charm.metronome": "charm:new"}
const N4_NAMES := ["Comet Ball", "Steady Hand", "Metronome", "Trade-In", "Specialist Shelf"]
## Found by rolling the real lane with the Comet Ball (spin response 1.2): from -0.4
## with a half charge it strikes and crosses the target plane at +0.03.
const COMET_STRIKE := [-0.4, 0.0, 0.7]
const COMET_SPIN := 0.5
const COMET_TARGET := 0.03

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.enter.has_focus(), "menu focus")
	_check(scene.content.id == "neon", "the Neon League is the content (%s)" % scene.content.id)
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "throw lab ready")
	lab = scene.lab
	lab.trial_log_path = ""
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.close)
	_check(not lab.division.practice and lab.equipment.MODEL == "deck" and not lab.settings.reduced_motion, "a real Neon match with the deck and the contracting ring")
	await _strike_out()
	await _to_shop("opener")
	lab.run.credit(8000, "fixture: C18 item sampling")
	if GATE not in lab.shop.unlocked: lab.shop.unlocked.append(GATE)
	print("J03C18 fixture: $8000 and the Controlled Curve gate after the opener")
	await _trade_in()
	await _specialist_shelf()
	await _buy_n4()
	await _sell_rest_of_kit()
	await _capture("c18_shop")
	await _leave_shop()
	await _aim()
	var cards := _cards()
	_check(cards.size() == 2 and cards.values().all(func(uid): return uid in lab.equipment.options().map(func(o): return o.uid)), "the hand holds the Comet Ball and Steady Hand cards")
	await _tap(lab.card_hand.button_for(cards.comet))
	await _tap(lab.card_hand.button_for(cards.steady))
	_check(lab.armed_ball_id() == "ball.comet" and lab.armed_tactical == cards.steady, "the Comet Ball and Steady Hand are armed")
	var before: int = int(scene.career.tally.get("counts", {}).get("controlled_curves", 0))
	var context: Dictionary = lab.frame_context()
	var loadout: Dictionary = lab.run.loadout()
	await _timed_throw(COMET_STRIKE, COMET_SPIN, COMET_TARGET)
	await _wait_for(func(): return lab.state in ["scoring", "aim"], "the Comet roll resolves", ROLL_FRAMES)
	if lab.state == "aim":
		await _throw([0.0, 0.0, 0.6])
	var scored := await _scored()
	var report: Dictionary = lab.frame_reports[0]
	await _verify("feature 1: Comet Ball with Steady Hand", scored, lab.frame_reports.duplicate(true), loadout, context, {1: ["consumable.steady_hand"]})
	var grade: String = report.roll_result.accuracy
	_check(scored.result.category == "strike" and report.launch.spin == COMET_SPIN and grade in ["sweet", "perfect"],
		"a curved strike released in the sweet window (graded %s, crossing %.3f)" % [grade, float(report.knockdown_log.target_offset)])
	_check(_logged("Comet Ball") and _logged("Steady Hand") and _logged("Metronome"), "Comet Ball, Steady Hand and Metronome all apply")
	_check(int(scene.career.tally.counts.get("controlled_curves", 0)) == before + 1, "the Career counts one controlled curve towards the mastery")
	_check(cards.steady in lab.equipment.exhausted, "the Steady Hand card is spent")
	await _capture("c18_controlled_curve")
	await _sound_sliders()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if lab.league_theme != null and lab.league_theme.music != null:
		lab.league_theme.music.stop() # the audio thread lets go of a playing loop after a few frames (as J22L02)
	for i in 5: await process_frame
	if failures.is_empty(): print("ROGUEWOOD_J03C18_OK")
	quit(0 if failures.is_empty() else 1)

func _license_index() -> int:
	for i in lab.shop.offers.size():
		if lab.shop.offers[i].slot == Shop.LICENSE: return i
	return -1

## The Division's License offer becomes `id` (fixture), then a player buys it.
func _buy_license(id: String) -> void:
	var index := _license_index()
	_check(index >= 0, "the shop has a License offer")
	var offer: Dictionary = lab.shop.offers[index]
	offer.item_id = id
	offer.sold = false
	offer.price = int(lab.run.item(id).purchase_price)
	lab._refresh_shop()
	print("J03C18 fixture: the License offer set to %s" % id)
	var before: int = lab.run.money
	await _tap(lab.shop_panel.button_for_offer(index))
	await process_frame
	_check(lab.run.upgrades.any(func(e): return e.item_id == id) and lab.run.money == before - int(offer.price), "bought %s for $%d" % [id, offer.price])

func _trade_in() -> void:
	var ref := ""
	for owned in lab.run.entries():
		if ref.is_empty() and owned.ref.begins_with("card:") and owned.entry.item_id == "ball.spare_ball": ref = owned.ref
	var base: int = lab.run.sale_value(ref)
	await _buy_license("shop_upgrade.trade_in")
	_check(lab.run.sale_value(ref) == base + 1, "with Trade-In the kit's Spare Ball card sells for $%d, not $%d" % [lab.run.sale_value(ref), base])
	var money: int = lab.run.money
	var button: Button = lab.shop_panel.sell_button(ref)
	_check(button != null and button.text.contains("$%d" % (base + 1)), "the Sell row shows the raised value (%s)" % (button.text if button != null else "none"))
	if button != null:
		await _tap(button)
		await process_frame
	_check(lab.run.money == money + base + 1, "the sale pays $%d ($%d to $%d)" % [base + 1, money, lab.run.money])

func _specialist_shelf() -> void:
	await _buy_license("shop_upgrade.specialist_shelf")
	await _tap(lab.shop_panel.reroll_button)
	await process_frame
	var index := -1
	for i in lab.shop.offers.size():
		if lab.shop.offers[i].slot == Shop.SPECIALIST: index = i
	var item: Dictionary = lab.run.item(lab.shop.offers[index].item_id) if index >= 0 else {}
	_check(index >= 0 and lab.shop.is_specialist(item) and lab.shop_panel.button_for_offer(index).is_visible_in_tree(),
		"after a reroll the shop shows a Specialist offer, a specialist item: %s %s" % [item.get("id", "none"), str(item.get("synergy_tags", []))])

## Rerolls (real taps) until the three Controlled Curve items are offered and bought.
func _buy_n4() -> void:
	var bought := {}
	for visit in 300:
		for index in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[index]
			if not N4.has(offer.item_id) or bought.has(offer.item_id) or offer.sold or offer.price > lab.run.money:
				continue
			var options: Array = lab.run.placements(offer.item_id).map(func(o): return o.target)
			if N4[offer.item_id] not in options:
				continue
			var before: int = lab.run.money
			await _tap(lab.shop_panel.button_for_offer(index))
			await process_frame
			if lab.shop_panel.choice_sheet.visible:
				await _tap(lab.shop_panel.choice_button(options.find(N4[offer.item_id])))
				await process_frame
			_check(lab.run.money == before - int(offer.price), "bought %s for $%d" % [offer.item_id, offer.price])
			bought[offer.item_id] = true
		if bought.size() == N4.size() or lab.run.money < lab.shop.reroll_cost(lab.run):
			break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	print("J03C18 bought: %s" % str(bought.keys()))
	_check(bought.size() == N4.size(), "the three Controlled Curve items offered and bought (%d)" % bought.size())

func _sell_rest_of_kit() -> void:
	for owned in lab.run.entries():
		if owned.ref.begins_with("card:") and owned.entry.item_id not in ["ball.comet", "consumable.steady_hand"]:
			var button: Button = lab.shop_panel.sell_button(owned.ref)
			if button != null:
				await _tap(button)
				await process_frame
	_check(lab.run.cards.size() == 2, "two cards left in the deck: %s" % str(lab.run.cards.values().map(func(e): return e.item_id)))

func _cards() -> Dictionary:
	var out := {}
	for uid in lab.run.cards:
		match String(lab.run.cards[uid].item_id):
			"ball.comet": out["comet"] = uid
			"consumable.steady_hand": out["steady"] = uid
	return out

func _verify(label: String, scored: Dictionary, reports: Array, loadout: Dictionary, context: Dictionary, extras: Dictionary) -> Dictionary:
	var out := await super._verify(label, scored, reports, loadout, context, extras)
	print("J03C18 %s: %s" % [label, str(out.lines.filter(func(l): return N4_NAMES.any(func(n): return l.contains(n))))])
	return out

## UI-11 (owner, 2026-11-16): Options -> Sound & effects has a music slider and a
## sound-effects slider; the music slider sets the League music's level, and Mute
## silences the music too. Throw settings has no vibration toggle, and Done sits
## centred below the Sound & effects row.
func _sound_sliders() -> void:
	var music: AudioStreamPlayer = lab.league_theme.music if lab.league_theme != null else null
	_check(music != null and music.playing, "the Neon League's music is playing")
	if music == null: return
	await _focus_accept(scene.options)
	var panel = lab.settings_panel
	var sound_row: Button = panel.find_child("SoundAndEffects", true, false)
	_check(panel.find_child("Haptics", true, false) == null and sound_row != null and sound_row.get_parent() == panel.close.get_parent()
		and sound_row.get_index() == panel.close.get_index() - 1 and panel.close.size_flags_horizontal == Control.SIZE_SHRINK_CENTER,
		"no vibration toggle; Sound & effects has its own row above a centred Done")
	await _focus_accept(sound_row)
	var sound = lab.motion.sound
	var base: float = lab.league_theme.MUSIC_DB
	# UI-12: with Options open the music has eased to half its level.
	await _wait_for(func(): return is_equal_approx(sound.duck, sound.MENU_DUCK), "the music eases down under Options")
	_check(absf(music.volume_db - (base + linear_to_db(sound.MENU_DUCK))) < 0.01, "Options halves the music (%.1f dB)" % music.volume_db)
	sound.music_slider.value = 0.5
	await process_frame
	_check(absf(music.volume_db - (base + linear_to_db(0.5 * sound.MENU_DUCK))) < 0.01 and absf(sound.volume_slider.value - 0.65) < 0.01, "the music slider sets the music to half (%.1f dB); effects stay at 0.65" % music.volume_db)
	sound.mute_button.button_pressed = true
	await process_frame
	_check(music.volume_db < -60.0, "Mute silences the music too")
	sound.mute_button.button_pressed = false
	sound.music_slider.value = 1.0
	await process_frame
	_check(absf(music.volume_db - (base + linear_to_db(sound.MENU_DUCK))) < 0.01, "back to the slider's full level, still dipped under Options")
	sound.panel.hide()
	panel.hide()
	await _wait_for(func(): return is_equal_approx(sound.duck, 1.0), "the music eases back when Options closes")
	_check(absf(music.volume_db - base) < 0.01, "back to the music's own level")
