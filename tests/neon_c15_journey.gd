extends "res://tests/mods_c04_journey.gd"
## J03C15 (E18-C15, DC-N1): the first six Neon items bought through the real Pro Shop
## and played in real throws on the production slice (real targets, not Practice).
## Fixture setup (logged, as J05 does): a wallet grant and Division 2 shop
## eligibility after the opener; offers, rerolls, purchases, placements, sales and
## card taps are real input.
##   shop:      Oilskin Ball and Laser Ball to the deck, Tempo Pin at rack 1, Neon
##              Sign to the Charms, Bumper Guard on one Hook card and Blacklight on
##              the other; the kit's Hammer and Echo cards are sold through the Sell
##              sheet, so the hand holds exactly the four cards the frames use;
##   feature 1: the Bumper Guard card is thrown at the gutter. The attempt is left
##              for the Clubhouse while the ball rolls and continued, so the saved
##              launch is re-simulated: it rebounds again, pins fall and count, and
##              the rescued roll loses Mult. A second stray throw with the House
##              Ball is a gutter ball (the rebound is the card's, once a frame);
##   feature 2: a curved strike with the Blacklight card: Blacklight applies, and
##              Neon Sign with it when the release is accurate;
##   boss 1:    under Dead Straight, a Laser Ball strike: Laser Ball and the Tempo
##              Pin pay for the accurate roll.
## Every bank equals an independent resolution with the thrown card's modification,
## and the explanation contains every independent line. Run with --fixed-fps 60.
const N1 := {"ball.oilskin": "card:new", "ball.laser": "card:new", "pin.tempo": "rack:1", "charm.neon_sign": "charm:new",
	"ball_mod.bumper_guard": "ball.hook", "ball_mod.blacklight": "ball.hook"}
const STRAY := [0.8, 2.0, 0.6] # the slice journey's gutter throw
## A Hook Ball strike with a half charge: it crosses the target plane at +0.24, so
## the ring is set there (found by rolling the real lane across starts and spins).
const CURVED_STRIKE := [-0.3, 0.0, 0.7]
const CURVED_SPIN := 0.5
const CURVED_TARGET := 0.25
const NAMES := ["Oilskin Ball", "Laser Ball", "Tempo Pin", "Neon Sign", "Bumper Guard", "Blacklight"]

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
	_check(not lab.division.practice and lab.equipment.MODEL == "deck", "a real match with the deck")
	await _strike_out()
	await _to_shop("opener")
	lab.run.credit(8000, "fixture: C15 item sampling")
	lab.shop.division = 2 # the two modifications are offered from Division 2
	lab._refresh_shop()
	print("J03C15 fixture: $8000 and Division 2 shop eligibility after the opener; offers, rerolls, purchases, placements and sales follow")
	var cards := await _buy_n1()
	await _sell_kit_cards()
	await _capture("c15_shop")
	await _leave_shop()
	await _aim()
	var hand: Array = lab.equipment.options().map(func(o): return o.uid)
	_check(cards.size() == 4 and cards.values().all(func(uid): return uid in hand), "the hand holds the four cards: %s" % str(lab.equipment.options().map(func(o): return o.item_id)))
	# What each card brings to its roll, read from the lab as the lane will be told.
	await _tap(lab.card_hand.button_for(cards.oilskin))
	_check(lab.armed_ball_id() == "ball.oilskin" and lab.card_rules() == {"oil_hold": true}, "the armed Oilskin Ball holds its hook on any oil: %s" % str(lab.card_rules()))
	await _tap(lab.card_hand.button_for(cards.guard))
	_check(lab.armed_ball_id() == "ball.hook" and lab.card_rules() == {"gutter_rebound": true}, "the armed Bumper Guard card has a rebound: %s" % str(lab.card_rules()))
	await _rebound_frame(cards)
	await _focus_accept(lab.next_rack)
	# Accurate releases need the contracting ring, so reduced motion goes off from here.
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.close)
	_check(not lab.settings.reduced_motion, "reduced motion is off for the timed releases")
	var curved := await _card_frame(cards.blacklight, [CURVED_STRIKE], CURVED_SPIN, "feature 2: Blacklight card, curved", CURVED_TARGET)
	_check(curved.scored.result.category == "strike" and curved.reports[0].launch.spin == CURVED_SPIN and _logged("Blacklight"), "a curved strike with its card: Blacklight applies")
	var accurate: int = curved.scored.result.facts.accurate
	_check(accurate == 1 and _logged("Neon Sign"), "the curved strike's sweet release lights Neon Sign (%d accurate, graded %s)" % [accurate, curved.reports[0].roll_result.accuracy])
	await _capture("c15_curved_strike")
	await _to_shop("feature")
	await _leave_shop()
	await _wait_for(func(): return lab.state == "intro" and lab.hud.intro.visible, "The Surveyor's introduction")
	await _focus_accept(lab.hud.intro_button)
	await _aim()
	_check(lab.spin_disabled(), "Dead Straight: every roll is straight")
	var laser := await _card_frame(cards.laser, [STRIKE], 0.0, "boss 1: Laser Ball, straight", STRIKE[0])
	var sweet: int = laser.scored.result.facts.accurate
	_check(laser.scored.result.category == "strike" and sweet > 0 and _logged("Laser Ball") and _logged("Tempo Pin"),
		"an accurate Laser Ball strike: Laser Ball and the Tempo Pin at 1 pay (%d accurate)" % sweet)
	await _capture("c15_laser")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C15_OK")
	quit(0 if failures.is_empty() else 1)

## Rerolls (real taps) until all six are offered, bought and placed. Returns the uids
## of the four cards the frames use: {oilskin, laser, guard, blacklight}.
func _buy_n1() -> Dictionary:
	var bought := {}
	for visit in 200:
		for index in lab.shop.offers.size():
			var offer: Dictionary = lab.shop.offers[index]
			if not N1.has(offer.item_id) or bought.has(offer.item_id) or offer.sold or offer.price > lab.run.money:
				continue
			var before: int = lab.run.money
			var target := ""
			var options: Array = []
			if offer.item_id.begins_with("ball_mod."):
				options = lab.run.mod_hosts(offer.item_id)
				for ref in options:
					if target.is_empty() and lab.run.entry_at(ref).item_id == N1[offer.item_id] and String(lab.run.entry_at(ref).mod).is_empty():
						target = ref
			else:
				options = lab.run.placements(offer.item_id).map(func(o): return o.target)
				target = N1[offer.item_id]
			if target.is_empty() or target not in options:
				continue
			await _tap(lab.shop_panel.button_for_offer(index)) # opens the offer; Buy follows, as a player presses it
			await process_frame
			if lab.shop_panel.choice_sheet.visible:
				await _tap(lab.shop_panel.choice_button(options.find(target)))
				await process_frame
			_check(lab.run.money == before - int(offer.price), "bought %s for $%d" % [offer.item_id, offer.price])
			bought[offer.item_id] = target
		if bought.size() == N1.size() or lab.run.money < lab.shop.reroll_cost(lab.run):
			break
		await _tap(lab.shop_panel.reroll_button)
		await process_frame
	print("J03C15 bought: %s" % str(bought))
	_check(bought.size() == N1.size(), "all six Neon items offered and bought (%d)" % bought.size())
	_check(lab.run.rack[1].item_id == "pin.tempo" and lab.run.charms.any(func(e): return e.item_id == "charm.neon_sign"), "Tempo Pin at rack 1 and Neon Sign among the Charms")
	var cards := {}
	for uid in lab.run.cards:
		var entry: Dictionary = lab.run.cards[uid]
		match [entry.item_id, String(entry.mod)]:
			["ball.oilskin", ""]: cards["oilskin"] = uid
			["ball.laser", ""]: cards["laser"] = uid
			["ball.hook", "ball_mod.bumper_guard"]: cards["guard"] = uid
			["ball.hook", "ball_mod.blacklight"]: cards["blacklight"] = uid
	return cards

## The kit's Hammer and Echo cards are sold through the Sell sheet (real taps).
func _sell_kit_cards() -> void:
	for owned in lab.run.entries():
		if owned.ref.begins_with("card:") and owned.entry.item_id in ["ball.hammer", "ball.echo"]:
			var button: Button = lab.shop_panel.sell_button(owned.ref)
			_check(button != null, "a Sell row for " + owned.ref)
			if button != null:
				await _tap(button)
				await process_frame
	_check(lab.run.cards.size() == 4 and not lab.run.cards.values().any(func(e): return e.item_id in ["ball.hammer", "ball.echo"]), "four cards left in the deck")

## Arms a card by uid (a real tap; "" throws the House Ball), throws, and checks the
## bank and the explanation against an independent resolution with the card's modification.
## With `target` the release is timed in the ring's sweet window, with the ring set there.
func _card_frame(uid: String, shots: Array, spin: float, label: String, target: float = NAN) -> Dictionary:
	var extras := {}
	if not uid.is_empty():
		await _aim()
		await _tap(lab.card_hand.button_for(uid))
		_check(lab.armed_ball == uid, "%s: the card is armed" % label)
		if not lab.run.card_mod(uid).is_empty():
			extras[1] = [lab.run.card_mod(uid)]
	var context: Dictionary = lab.frame_context()
	var loadout: Dictionary = lab.run.loadout()
	if is_nan(target):
		await _throw(shots[0], spin)
	else:
		await _timed_throw(shots[0], spin, target)
	await _wait_for(func(): return lab.state in ["scoring", "aim"], label + " roll 1 resolves", ROLL_FRAMES)
	if lab.state == "aim": # pins stand: a plain second roll, so the frame always completes
		await _throw(shots[1] if shots.size() > 1 else [0.0, 0.0, 0.6])
	var scored := await _scored()
	return await _verify(label, scored, lab.frame_reports.duplicate(true), loadout, context, extras)

## An assist throw released while the contracting ring is in its sweet band, with
## the ring set where this throw crosses the target plane (as AV-C03-B times its own).
func _timed_throw(shot: Array, spin: float, target: float) -> void:
	await _aim()
	var panel: Control = lab.assist_panel
	await _slide(panel.position_slider, shot[0])
	await _slide(panel.aim_slider, shot[1])
	await _slide(panel.power_slider, shot[2])
	await _slide(panel.spin_slider, spin)
	await _slide(panel.target_slider, target)
	var count: int = lab.history.size()
	await _wait_for(func(): return lab.ring_radius >= 0.12 and lab.ring_radius <= 0.135, "the contracting ring's sweet window", 300)
	await _focus_accept(panel.throw_button)
	_check(lab.state == "rolling", "the timed Throw commits")
	await _wait_for(func(): return lab.history.size() == count + 1, "the timed roll settles", ROLL_FRAMES)

func _verify(label: String, scored: Dictionary, reports: Array, loadout: Dictionary, context: Dictionary, extras: Dictionary) -> Dictionary:
	var built := Builder.build(loadout, lab.content.catalogue, reports, extras, context)
	var expected := Rules.resolve(built.frame) if built.ok else {"score": -1}
	var names := {}
	for item in lab.content.catalogue.items:
		names[item.id] = item.name
	var lines: Array = ScoreLog.steps(expected, built.frame, names, built.owners).map(func(s): return s.text) if built.ok else []
	print("J03C15 %s: category=%s banked=%d expected=%d rolls=%s neon=%s" % [label, scored.result.category, scored.banked, expected.score,
		str(reports.map(func(r): return "%s%s%s" % [r.launch.ball_id, " rebounded" if r.knockdown_log.get("rebounded", false) else "", " gutter" if r.knockdown_log.gutter else ""])),
		str(lines.filter(func(l): return NAMES.any(func(n): return l.contains(n))))])
	_check(built.ok and scored.banked == expected.score, "%s banks the independent resolution (%d vs %d)" % [label, scored.banked, int(expected.score)])
	_check(lines.all(func(l): return _logged(l)), "%s: the explanation contains every independent line" % label)
	return {"scored": scored, "lines": lines, "reports": reports}

## Feature frame 1: the Bumper Guard card thrown at the gutter, left for the Clubhouse
## while it rolls and continued, so the saved launch is simulated again from the save.
func _rebound_frame(cards: Dictionary) -> void:
	var context: Dictionary = lab.frame_context()
	var loadout: Dictionary = lab.run.loadout()
	_check(lab.armed_ball == cards.guard, "the Bumper Guard card is armed")
	await _aim()
	var panel: Control = lab.assist_panel
	await _slide(panel.position_slider, STRAY[0])
	await _slide(panel.aim_slider, STRAY[1])
	await _slide(panel.power_slider, STRAY[2])
	await _slide(panel.spin_slider, 0.0)
	await _focus_accept(panel.throw_button)
	_check(lab.state == "rolling" and bool(lab.lane.rules.get("gutter_rebound", false)), "the committed roll carries the rebound")
	for i in 20: await process_frame
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu" and scene.continue_button.visible, "the Clubhouse offers Continue while the ball was rolling")
	await _focus_accept(scene.continue_button)
	await _wait_for(func(): return scene.lab != null and scene.lab.state in ["rolling", "result", "aim", "scoring"], "the attempt resumes its committed roll")
	lab = scene.lab
	lab.trial_log_path = ""
	_check(lab.restored_phase == "committed", "resumed from the committed launch (%s)" % lab.restored_phase)
	await _wait_for(func(): return lab.frame_reports.size() >= 1 and lab.state in ["aim", "scoring"], "the resumed roll settles", ROLL_FRAMES)
	var first: Dictionary = lab.frame_reports[0]
	_check(first.knockdown_log.get("rebounded", false) == true and first.knockdown_log.gutter == false and not first.roll_result.fallen_positions.is_empty(),
		"re-simulated from the save, the roll rebounds again and its pins count (%d down)" % first.roll_result.fallen_positions.size())
	await _capture("c15_rebound")
	if lab.state == "aim":
		await _aim()
		_check(lab.card_rules().is_empty(), "no card is armed for roll 2, and the frame's rebound is used")
		await _throw(STRAY)
		_check(lab.history[-1].knockdown_log.gutter == true and not lab.history[-1].knockdown_log.has("rebounded"), "a second stray throw, with the House Ball, is a gutter ball")
	var scored := await _scored()
	await _verify("feature 1: Bumper Guard rescue", scored, lab.frame_reports.duplicate(true), loadout, context, {1: ["ball_mod.bumper_guard"]})
	_check(_logged("Bumper Guard") and _log_lines().any(func(l): return l.contains("never below 1")), "the rescued roll's Mult loss is named in the explanation")
	_check(not scored.match_over, "the feature goes on to its second frame")

func _capture(label: String) -> void:
	print("J03C15 %s lab=%s money=%d score=%d cards=%s" % [label, lab.state, lab.run.money, lab.division.match_score,
		str(lab.run.cards.values().map(func(e): return "%s%s" % [e.item_id, "+" + String(e.mod) if not String(e.mod).is_empty() else ""]))])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)
