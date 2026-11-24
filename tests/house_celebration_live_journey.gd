extends "res://tests/scoring_journey.gd"
## Real strike/spare/open-frame input uses the shipping House lists and stings.
## The existing independent J03 scoring, native tap-skip and natural-end checks stay.
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.enter.has_focus(),"menu focus")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim","House lab ready")
	lab = scene.lab
	lab.trial_log_path = ""
	_check(lab.league_theme != null and lab.league_theme.manifest.get("league_id","") == "league.house","actual House theme")
	_check(bool(lab.league_theme.manifest.get("celebrations_complete",false)),"live House set complete")
	for event in ["strike","spare"]:
		_check(lab.league_theme.celebrations(event).size() >= 5,"live variants: " + event)
		_check(lab.league_theme.celebration_sound(event) != null,"live sting: " + event)
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.reduced_flash)
	await _focus_accept(lab.settings_panel.assist)
	lab.settings_panel.use_practice()
	await process_frame
	await _focus_accept(lab.settings_panel.close)
	await _focus_accept(scene.resume)
	_check(lab.alley_screen.variants_override.is_empty(),"no variant overrides")
	await _strike_frame()
	await _spare_frame()
	await _open_frame()
	_check(lab.alley_screen.variants_override.is_empty(),"real rolls preserve live selection")
	if failures.is_empty(): print("ROGUEWOOD_UIA9HV_OK")
	quit(0 if failures.is_empty() else 1)

func _check_celebration(event: String) -> void:
	var alley = lab.alley_screen
	await _wait_for(func(): return alley.playing(),"live " + event + " trigger")
	_check(alley.current_event == event and alley.current_path in lab.league_theme.celebrations(event),"real roll selects a shipping " + event)
	_check(alley.visible and alley.view.render_target_update_mode == SubViewport.UPDATE_ALWAYS,"live picture renders")
	_check(alley.current_context.reduced_motion and alley.current_context.reduced_flash,"live trigger carries accessibility settings")
	var stream: AudioStream = lab.league_theme.celebration_sound(event)
	_check(lab.motion.sound.voices.any(func(voice): return voice.playing and voice.stream == stream),"real roll plays the shipping sting: " + event)
	await _capture("live_" + event)
