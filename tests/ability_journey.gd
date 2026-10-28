extends "res://tests/slice_journey.gd"
## Production game with declared inventory fixtures; physical throws, not results.
var batch := "E20-V01"
var wanted: Array = []
var captures := {}
var metrics: Array = []
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	for part in artifact_dir.split("/"):
		if part.begins_with("e20-v"): batch = part.to_upper()
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/effects/batches.json"))[batch]
	wanted = rows.map(func(row): return row[0])
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _focus_accept(scene.enter)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim","production ready")
	lab = scene.lab
	await _toggle_assist()
	for id in wanted:
		if id.begins_with("charm."):
			_check(lab.run.place(id,0,"charm:new").is_empty(),"fixture equips " + id)
	lab._new_roll(false)
	await _aim()
	_check(await _arm("ball.echo"),"actual Echo card arms")
	await _throw(STRIKE)
	var scored := await _scored()
	_check(scored.result.retriggers == 1 and scored.banked == 1050,"real Echo and Encore bank 1050")
	for id in wanted:
		_check(lab.motion.abilities.history.any(func(e): return e.id == id),"actual ability observed: " + id)
	_check(Rect2(Vector2.ZERO,lab.size).encloses(lab.score_panel.get_rect()),"scoring and skip fit portrait")
	await _capture("resolved")
	root.size = Vector2i(800,450)
	for i in 12: await process_frame
	_check(Rect2(Vector2.ZERO,lab.size).encloses(lab.score_panel.get_rect()),"scoring and skip fit landscape")
	await _capture("landscape")
	root.size = PORTRAIT
	var bank: int = lab.total_score
	# Replaying an explanation is a presentation fixture, never a scoring call.
	lab.score_panel.play(scored.steps,lab.frame_reports,scored.title,4)
	var played: int = lab.motion.sound.played
	lab.score_panel.skip()
	_check(lab.total_score == bank and lab.motion.sound.played == played,"skip changes neither bank nor sound count")
	lab.score_panel.reduced_motion = true
	lab.settings.reduced_motion = true
	lab.settings.reduced_flash = true
	lab.motion.sound.mute_button.button_pressed = true
	lab.score_panel.play(scored.steps,lab.frame_reports,scored.title,1)
	await _wait_for(func(): return lab.motion.abilities.glyph.style != null and lab.motion.abilities.glyph.still,"static reduced cue",600)
	await _capture("reduced")
	lab.score_panel.skip()
	_check(lab.total_score == bank and lab.motion.sound.max_active <= 4,"bounded voices and immutable bank")
	metrics.append(lab.motion.metrics())
	var file := FileAccess.open(artifact_dir.path_join("metrics.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"batch":batch,"motion":metrics,"audio":{"played":lab.motion.sound.played,"max_active":lab.motion.sound.max_active,"suppressed":lab.motion.sound.suppressed},"history":lab.motion.abilities.history},"\t"))
	if failures.is_empty(): print("ROGUEWOOD_ABILITY_OK")
	else: await _capture("failure")
	quit(0 if failures.is_empty() else 1)
func _scored() -> Dictionary:
	for tick in ROLL_FRAMES * 3:
		if lab.state == "scoring":
			var glyph: Control = lab.motion.abilities.glyph
			if glyph.style != null and glyph.age < glyph.style.duration:
				var id: String = glyph.style.item_id
				if id in wanted and not captures.has(id):
					captures[id] = true
					await _capture(id.replace(".","_")+"_activation")
		if lab.state == "frame_done": return lab.scored_frames[-1]
		await process_frame
	_check(false,"scoring completes")
	return lab.scored_frames[-1]
