extends "res://tests/slice_journey.gd"
## J10 Career persistence and unlocks (E15, ADR 010) through the real game. Each
## stage is a separate engine process sharing one save directory (tools/qa.py), so
## only what reached the disk survives:
##   1 a fresh Career: Enter League, beat The Surveyor (the unlock is on disk at
##     once while this attempt's pool stays unchanged, even across rerolls), then
##     bank a spare in Division 2 and leave while the frame is shown;
##   2 restart: the Career is intact and the resumed frame is not counted again;
##     lose the attempt (the result names the unlock, kept goals and the next-attempt
##     rule), Retry: the new attempt's pool has Encore; beat The Surveyor again with
##     no duplicate award; leave in the shop;
##   3 restart: nothing duplicated; the saved attempt keeps its Career uid; a new
##     attempt in Practice (the policy shown before throwing) banks a spare that
##     advances no mastery but records a practice best.
## Shots are the deterministic J03 assist throws. Run with --fixed-fps 60.
const CareerProfile = preload("res://src/persistence/career_profile.gd")
const CLEANUP := [0.0, 0.0, 0.6]
var stage := 1
var save_dir := ""

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
		if arg.begins_with("--stage="): stage = int(arg.trim_prefix("--stage="))
		if arg.begins_with("--save-dir="): save_dir = arg.trim_prefix("--save-dir=")
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.screen == "menu" and (scene.enter.has_focus() or scene.continue_button.has_focus()), "menu focus")
	_check(scene.content.id == "slice" and scene.career_graph.errors.is_empty(), "the production unlock graph loads without errors")
	match stage:
		1: await _stage_one()
		2: await _stage_two()
		3: await _stage_three()
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if not failures.is_empty() and lab != null: await _capture("career_failure")
	if failures.is_empty(): print("ROGUEWOOD_J10_OK" if stage == 3 else "ROGUEWOOD_J10_STAGE%d_OK" % stage)
	quit(0 if failures.is_empty() else 1)

func _capture(label: String) -> void:
	var career: Dictionary = scene.career
	print("J10 stage=%d %s screen=%s lab=%s uid=%s attempts=%d unlocked=%s first_clears=%s totals=%s summary=%s" % [stage, label, scene.screen,
		lab.state if lab else "-", str(lab.career_attempt) if lab else "-", int(career.attempts), str(career.unlocked), str(career.first_clears.keys()),
		str(career.totals), scene.career_line.text.replace("\n", " | ")])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)

func _disk() -> Dictionary:
	var read: Dictionary = scene.store.read("career")
	_check(read.ok and read.schema_version == CareerProfile.SCHEMA_VERSION, "the Career file reads as schema 2")
	return read.get("payload", {})

func _encore() -> Dictionary:
	return lab.content.catalogue.items.filter(func(i): return i.id == "charm.encore")[0]

func _enter(button: Button) -> void:
	await _focus_accept(button)
	await _wait_for(func(): return scene.lab != null and scene.lab.state in ["aim", "shop", "scoring", "frame_done", "intro", "division_over"], "the attempt opens")
	lab = scene.lab
	lab.trial_log_path = ""

func _assist_on() -> void:
	await _focus_accept(scene.options)
	if not lab.settings_panel.reduced_motion.button_pressed: await _focus_accept(lab.settings_panel.reduced_motion)
	if not lab.settings_panel.assist.button_pressed: await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.close)

## Division 1 through the shop after The Surveyor: Echo strike, strikes, strikes.
func _beat_surveyor() -> void:
	if await _arm("ball.echo"):
		await _throw(STRIKE)
		await _scored()
	else:
		await _strike_out()
	while not lab.division.match_over():
		await _focus_accept(lab.next_rack)
		await _throw(STRIKE)
		await _scored()
	await _to_shop("opener")
	await _buy_charms()
	await _leave_shop()
	await _strike_out()
	await _to_shop("feature")
	await _buy_charms()
	await _leave_shop()
	await _wait_for(func(): return lab.state == "intro", "The Surveyor's introduction")
	await _focus_accept(lab.hud.intro_button)
	var boss := {}
	while true:
		await _throw(STRIKE)
		if lab.state != "scoring" and not lab.history[-1].knockdown_log.standing.is_empty():
			await _throw(STRIKE)
		boss = await _scored()
		if boss.match_over:
			break
		await _focus_accept(lab.next_rack)
	_check(boss.match_won and lab.division.division_cleared(), "The Surveyor is beaten and Division 1 cleared")
	await _to_shop("division cleared")

## Open frames until the attempt is lost (Clean Sweep makes the boss certain).
func _lose() -> void:
	while lab.division.outcome != "lost":
		if lab.state == "frame_done":
			await _focus_accept(lab.next_rack)
			if lab.state == "shop":
				await _leave_shop()
				if lab.state == "intro": await _focus_accept(lab.hud.intro_button)
			if lab.state == "division_over":
				break
		await _throw(LEAVE)
		await _aim()
		await _throw(GUTTER)
		await _scored()
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.hud.result.visible, "loss screen")

func _stage_one() -> void:
	_check(scene.career.attempts == 0 and scene.career_line.text.begins_with("Career: 0 rivals cleared · 0 championships · 0/3 mastery goals")
		and scene.career_line.text.contains("Goals: Spare Hand 0/10"), "a fresh Career: the menu shows the summary and three goals")
	await _capture("career_fresh")
	await _enter(scene.enter)
	await _assist_on()
	var disk := _disk()
	_check(lab.career_attempt == 1 and int(disk.attempts) == 1 and disk.items.has("ball.echo") and disk.items.has("pin.wood"),
		"the attempt has Career uid 1; its kit is discovered and saved")
	await _beat_surveyor()
	disk = _disk()
	_check("gate.surveyor_cleared" in disk.unlocked and disk.awards["gate.surveyor_cleared"].source == "boss:rival.surveyor"
		and int(disk.awards["gate.surveyor_cleared"].career_attempt) == 1 and int(disk.first_clears["rival.surveyor"].career_attempt) == 1,
		"the first clear and its gate are on disk the moment The Surveyor falls")
	_check(lab.shop.ineligibility(_encore(), lab.run) == "locked" and "gate.surveyor_cleared" not in lab.shop.unlocked,
		"this attempt's pool is unchanged: Encore stays locked")
	if lab.run.money >= lab.shop.reroll_cost():
		await _focus_accept(lab.shop_panel.reroll_button)
		await process_frame
	_check(lab.shop.offers.all(func(o): return o.item_id != "charm.encore") and lab.shop.ineligibility(_encore(), lab.run) == "locked",
		"rerolled offers still never include Encore")
	await _capture("career_unlocked")
	await _leave_shop()
	# A spare in Division 2's opener, counted once and saved before the frame is shown.
	var spares := int(scene.career.totals.get("spares", 0))
	await _throw(LEAVE)
	await _aim()
	await _throw(CLEANUP)
	var spare := await _scored()
	_check(spare.result.category == "spare" and int(scene.career.totals.spares) == spares + 1 and int(_disk().totals.spares) == spares + 1,
		"the spare is counted toward Spare Hand and saved")
	var saved: Dictionary = scene.store.read("attempt")
	_check(saved.ok and saved.payload.phase == "frame_done" and int(saved.payload.career_attempt) == 1, "the attempt is saved at the banked frame with its uid")
	print("J10 memo spares=%d strikes=%d" % [int(scene.career.totals.spares), int(scene.career.totals.get("strikes", 0))])
	await _capture("career_spare")
	# The process ends here: stage 2 is a real restart.

func _stage_two() -> void:
	var career: Dictionary = scene.career
	var spares := int(career.totals.spares)
	_check(career.unlocked == ["gate.surveyor_cleared"] and career.first_clears.size() == 1 and int(career.attempts) == 1
		and scene.career_line.text.begins_with("Career: 1 rival cleared"), "after a restart the Career is intact")
	_check(scene.continue_button.visible and scene.continue_button.has_focus(), "Continue Attempt is offered")
	await _enter(scene.continue_button)
	_check(lab.career_attempt == 1 and lab.restored_phase == "frame_done", "the resumed attempt keeps its Career uid")
	await _wait_for(func(): return lab.state == "frame_done", "the banked frame is shown again")
	_check(int(scene.career.totals.spares) == spares and int(_disk().totals.spares) == spares, "the resumed frame is not counted twice")
	await _assist_on()
	await _lose()
	var body: String = lab.hud.result_body.text
	_check(lab.division.outcome == "lost" and body.contains("Unlocked: Encore joins the shop pool from your next attempt.")
		and body.contains("Career progress kept: 1 rival(s) cleared") and body.contains("Goals: Spare Hand %d/10" % spares),
		"the loss result names the unlock, the kept progress and the goals")
	_check("gate.surveyor_cleared" in _disk().unlocked, "losing later keeps the unlock on disk")
	await _capture("career_lost")
	var old_id: int = lab.get_instance_id()
	await _focus_accept(lab.hud.retry_button)
	await _wait_for(func(): return scene.lab != null and scene.lab.get_instance_id() != old_id and scene.lab.state == "aim", "Retry starts a new attempt")
	lab = scene.lab
	lab.trial_log_path = ""
	_check(lab.career_attempt == 2 and "gate.surveyor_cleared" in lab.shop.unlocked and lab.shop.ineligibility(_encore(), lab.run).is_empty(),
		"the next attempt's pool includes Encore")
	await _beat_surveyor()
	career = scene.career
	_check(career.unlocked.count("gate.surveyor_cleared") == 1 and int(career.first_clears["rival.surveyor"].career_attempt) == 1
		and int(career.awards["gate.surveyor_cleared"].career_attempt) == 1 and not lab.shop_panel.message.text.contains("First clear"),
		"beating The Surveyor again awards nothing twice")
	await _capture("career_no_duplicate")

func _stage_three() -> void:
	var career: Dictionary = scene.career
	var spares := int(career.totals.spares)
	_check(career.unlocked == ["gate.surveyor_cleared"] and career.first_clears.size() == 1 and int(career.attempts) == 2,
		"after another restart nothing is duplicated")
	await _enter(scene.continue_button)
	_check(lab.career_attempt == 2 and lab.state == "shop", "the saved attempt resumes in its shop with uid 2")
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu", "Clubhouse")
	await _enter(scene.enter)
	_check(lab.career_attempt == 3, "Enter League begins attempt uid 3")
	# Practice before the first throw: the policy is on the toggle and the match bar.
	await _focus_accept(scene.options)
	_check(lab.settings_panel.practice.text.contains("no unlocks"), "the Practice toggle states the policy before starting")
	await _focus_accept(lab.settings_panel.practice)
	if not lab.settings_panel.assist.button_pressed: await _focus_accept(lab.settings_panel.assist)
	if not lab.settings_panel.reduced_motion.button_pressed: await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.close)
	_check(lab.division.practice and lab.hud.info.text.contains("no unlocks"), "practice is on; the match bar says no unlocks")
	await _capture("career_practice")
	await _throw(LEAVE)
	await _aim()
	await _throw(CLEANUP)
	var spare := await _scored()
	var disk := _disk()
	_check(spare.result.category == "spare" and int(scene.career.totals.spares) == spares and int(disk.totals.spares) == spares
		and int(disk.records["league.house"].practice_best_frame) == int(spare.banked) and int(disk.records["league.house"].practice_attempts) == 1,
		"a practice spare advances no mastery but records a practice best")
	_check(disk.unlocked == ["gate.surveyor_cleared"] and disk.mastery.is_empty(), "practice grants no unlocks")
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu", "Clubhouse again")
	_check(scene.career_line.text.begins_with("Career: 1 rival cleared · 0 championships · 0/3 mastery goals · 3 attempts"), "the menu summary after three attempts")
	await _capture("career_menu")
