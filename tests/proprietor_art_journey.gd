extends "res://tests/house_rival_art_journey.gd"
## J21R03: the real game with C05's low-target first Division and the authored
## Proprietor encounter substituted in memory. No production League edits.
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.enter.has_focus(), "menu focus")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "lab ready")
	lab = scene.lab
	lab.trial_log_path = ""
	var house: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/leagues/house.json"))
	var proprietor: Dictionary = house.divisions[2].rivals[0].duplicate(true)
	_check(proprietor.id == "rival.proprietor", "fixture reads exact authored Proprietor")
	# The future first-clear gate is deliberately not awarded by this art fixture.
	proprietor.first_clear.unlocks = []
	lab.division.spec.rivals = [proprietor]
	lab.division.spec.matches[2].rival = proprietor.id
	print("J21R03 fixture: authored Proprietor identity/rule in C05 Division 1; target 500 retained; future unlocks suppressed")
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.close)
	await _to_boss("Proprietor")
	await _focus_accept(lab.hud.intro_button)
	await _wait_for(func(): return lab.state == "aim", "Proprietor ready")
	_check(lab.division.rules() == ["boss_rule.house_rules"], "Proprietor has only House Rules")
	_check(lab.hud.badge.icon == Art.rule_badge("boss_rule.house_rules"), "Proprietor rule badge")
	await _capture("proprietor_reduced")
	# Exercise normal idle motion through the real settings control.
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.close)
	var open := await _rule_frame([LEAVE, GUTTER], "Proprietor open")
	_check(open.banked > 0, "House Rules allows an open frame to bank")
	await _capture("proprietor_reaction")
	await _focus_accept(lab.next_rack)
	await _rule_frame([STRIKE], "Proprietor winning strike")
	_check(lab.division.match_score >= lab.division.target(), "native target victory")
	_check(lab.hud.reaction.visible, "defeat reaction remains non-blocking on the lane")
	_check(lab.hud.reaction_portrait.texture == Art.portrait("rival.proprietor", "defeated"), "actual Proprietor defeat reaction")
	await super._capture("proprietor_defeated")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J21R03_OK")
	quit(0 if failures.is_empty() else 1)
