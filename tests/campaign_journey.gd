extends "res://tests/slice_journey.gd"
const Content = preload("res://src/rules/content_set.gd")
const Generator = preload("res://src/procedural/campaign_generator.gd")
var stage := 1

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
		if arg.begins_with("--stage="): stage = int(arg.trim_prefix("--stage="))
	root.size = Vector2i(800, 450) if stage == 3 else PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _focus_accept(scene.league)
	await _action("ui_down")
	await _action("ui_accept")
	await process_frame
	_check(scene.content.id == "campaign", "campaign selected through menu")
	if stage == 1:
		await _focus_accept(scene.enter)
	else:
		_check(scene.continue_button.visible, "campaign resume available")
		await _focus_accept(scene.continue_button)
	await _wait_for(func(): return scene.lab != null, "campaign loaded")
	lab = scene.lab
	lab.trial_log_path = ""
	await _focus_accept(scene.options)
	if not lab.settings_panel.assist.button_pressed: await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.close)
	_check(Generator.validate_schedule(lab.division.campaign, lab.content.profile, lab.content.catalogue).is_empty(), "saved seeded schedule validated")
	if stage == 1:
		var repeat := Content.load_set("campaign", 1)
		var different := Content.load_set("campaign", 2)
		_check(lab.division.campaign == repeat.campaign, "same seed same schedule")
		_check(repeat.campaign.divisions != different.campaign.divisions, "different seeds vary")
		await _play_matches(12)
		await _focus_accept(lab.next_rack)
		await _wait_for(func(): return lab.state == "shop", "midcampaign shop")
		_check(lab.shop_panel.visible and "Lane:" in lab._next_match_preview(), "lane revealed before purchases")
		await _capture("campaign_shop")
	elif stage == 2:
		_check(lab.state == "shop" and lab.division.results.size() == 12, "real process resumes match 12 shop")
		await _advance()
		await _play_matches(12)
		await _focus_accept(lab.next_rack)
		await _wait_for(func(): return lab.state == "division_over", "championship result")
		_check(lab.division.outcome == "won" and lab.division.results.size() == 24, "24 native matches win championship")
		_check(lab.hud.endless_button.visible, "endless choice available")
		# E15: the championship is banked in the Career at once, with its title gate.
		var title: Dictionary = scene.career.championships.get("league.house_campaign", {})
		_check(int(title.get("wins", 0)) == 1 and "gate.house_campaign_champion" in scene.career.unlocked
			and lab.hud.result_body.text.contains("Champion: first House Campaign title"), "the first campaign title is banked and announced")
		var saved: Dictionary = scene.store.read("career")
		_check(saved.ok and int(saved.payload.championships["league.house_campaign"].wins) == 1, "the title is on disk before the result")
		await _capture("campaign_won")
	else:
		_check(lab.state == "division_over" and lab.hud.endless_button.visible, "championship choice survives restart")
		_check(int(scene.career.championships["league.house_campaign"].wins) == 1 and scene.career.unlocked.count("gate.house_campaign_champion") == 1,
			"the restored result does not count the title again")
		await _focus_accept(lab.hud.endless_button)
		await _wait_for(func(): return lab.state == "shop", "endless preparation")
		_check(lab.division.specs.size() == 9, "one endless Division added")
		await _advance()
		await _capture("campaign_endless")
		# Fail the next match through actual gutter throws (two rolls per frame).
		for frame in range(2):
			await _throw(GUTTER)
			await _throw(GUTTER)
			await _scored()
			if frame == 0: await _focus_accept(lab.next_rack)
		await _focus_accept(lab.next_rack)
		await _wait_for(func(): return lab.state == "division_over", "loss result")
		_check(lab.division.outcome == "lost" and not lab.hud.endless_button.visible, "loss ends endless")
		_check(int(scene.career.championships["league.house_campaign"].wins) == 1 and "gate.house_campaign_champion" in scene.career.unlocked,
			"losing in Endless keeps the title")
		await _capture("campaign_lost")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J09_OK" if stage == 3 else "ROGUEWOOD_J09_STAGE%d_OK" % stage)
	quit(0 if failures.is_empty() else 1)

func _play_matches(count: int) -> void:
	for i in range(count):
		_check(lab.lane.lane_condition == lab.division.current().lane_condition, "selected lane applied to physics")
		await _strike_out()
		_check(lab.division.results.back().won, "posted target beaten")
		if i < count - 1:
			await _focus_accept(lab.next_rack)
			await _wait_for(func(): return lab.state == "shop", "shop after match")
			await _advance()

func _advance() -> void:
	await _focus_accept(lab.shop_panel.continue_button)
	await _wait_for(func(): return lab.state in ["aim", "intro"], "next match")
	if lab.state == "intro": await _focus_accept(lab.hud.intro_button)
	await _aim()

func _capture(label: String) -> void:
	# Container wrapping settles over several frames after replacing a long preview.
	for i in range(12): await process_frame
	await super._capture(label)
