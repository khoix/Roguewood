extends "res://tests/ability_journey.gd"
## J12: dense production chain, native sound controls, real Skip, static mode.
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _focus_accept(scene.enter)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim","ready")
	lab = scene.lab
	await _toggle_assist()
	wanted = ["ball.echo","pin.ruby","pin.gold","pin.grower","charm.encore","charm.flat_bonus","charm.finisher","charm.gold_rush","charm.patient_investor"]
	for id in wanted:
		if id.begins_with("charm."): _check(lab.run.place(id,0,"charm:new").is_empty(),"dense fixture charm " + id)
	for entry in [[1,"pin.ruby"],[3,"pin.gold"],[4,"pin.grower"]]:
		_check(lab.run.place(entry[1],0,"rack:%d" % entry[0]).is_empty(),"dense fixture pin")
	lab._new_roll(false)
	await _aim()
	_check(await _arm("ball.echo"),"actual Echo")
	await _throw(STRIKE)
	var scored := await _scored()
	_check(scored.result.category == "strike" and scored.result.retriggers == 1,"dense real strike and causal Echo")
	_check(lab.motion.abilities.world_glyphs.size() == 4 and lab.motion.sound.max_active <= 4,"bounded visual/audio pools")
	_check(lab.motion.sound.played > 0,"native foley playback")
	await _capture("dense")
	var report: Dictionary = lab.motion.metrics()
	var unchanged := JSON.stringify({"total":lab.total_score,"inventory":lab.run.to_dict(),"result":scored.result})
	root.size = Vector2i(800,450)
	for i in 12: await process_frame
	await _capture("landscape")
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.find_child("SoundAndEffects",true,false))
	var sound: Node = lab.motion.sound
	_check(sound.panel.visible and Rect2(Vector2.ZERO,lab.size).encloses(sound.panel.get_rect()),"sound controls fit landscape")
	await _focus_accept(sound.mute_button)
	var count: int = sound.played
	sound.cue("muted_probe",preload("res://src/presentation/item_assets.gd").slot("ball.echo","sound"),3)
	_check(sound.muted and sound.played == count,"native Mute suppresses playback")
	await _focus_accept(sound.mute_button)
	await _slide(sound.volume_slider,0)
	sound.cue("zero_probe",preload("res://src/presentation/item_assets.gd").slot("ball.echo","sound"),3)
	_check(sound.volume == 0 and sound.played == count,"native zero volume suppresses playback")
	await _slide(sound.volume_slider,0.65)
	await _focus_accept(sound.effects_button)
	await process_frame
	_check(not lab.motion.abilities.glyph.enabled,"native effects toggle")
	await _capture("controls")
	await _focus_accept(sound.effects_button)
	await _focus_accept(sound.panel.get_child(0).get_child(sound.panel.get_child(0).get_child_count()-1))
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.reduced_flash)
	await _focus_accept(lab.settings_panel.close)
	root.size = PORTRAIT
	for i in 12: await process_frame
	# Isolated replay of already-banked presentation; no second flow notification.
	lab.score_panel.finished.disconnect(lab._on_scored)
	lab.score_panel.reduced_motion = true
	lab.score_panel.play(scored.steps,lab.frame_reports,scored.title,4)
	await _wait_for(func(): return lab.score_panel.shown >= 3,"4x replay",600)
	_check(lab.motion.abilities.glyph.still,"reduced mode removes spatial motion")
	await _capture("reduced")
	count = sound.played
	await _focus_accept(lab.score_panel.skip_button)
	_check(not lab.score_panel.playing and sound.played == count,"native Skip is silent")
	_check(JSON.stringify({"total":lab.total_score,"inventory":lab.run.to_dict(),"result":scored.result}) == unchanged,"speed, reduced and skip never mutate bank or inventory")
	lab.score_panel.finished.connect(lab._on_scored)
	await _to_shop("dense settlement")
	await _wait_for(func(): return lab.motion.abilities.growth_row.visible,"Investor settlement")
	await _capture("settlement")
	var file := FileAccess.open(artifact_dir.path_join("metrics.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"motion":report,"max_voices":sound.max_active,"played":sound.played,"suppressed":sound.suppressed,"fixed_world_glyphs":lab.motion.abilities.world_glyphs.size(),"events":lab.motion.abilities.history},"\t"))
	file.close()
	file = null
	scene.queue_free()
	scene = null
	lab = null
	for i in 6: await process_frame
	if failures.is_empty(): print("ROGUEWOOD_DENSE_ABILITY_OK")
	quit(0 if failures.is_empty() else 1)
