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
	if batch in ["E20-V05","E20-V07"]: scene.throw_settings = {"practice":true}
	root.add_child(scene)
	await process_frame
	await _focus_accept(scene.enter)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim","production ready")
	lab = scene.lab
	await _toggle_assist()
	for id in wanted:
		if id.begins_with("charm."):
			_check(lab.run.place(id,0,"charm:new").is_empty(),"fixture equips " + id)
	if batch == "E20-V02": _check(lab.run.place("pin.grower",0,"rack:1").is_empty(),"fixture Grower")
	if batch == "E20-V03":
		for position in [1,3]: _check(lab.run.place("pin.gold",0,"rack:%d" % position).is_empty(),"fixture Gold")
	if batch == "E20-V04": _check(lab.run.place("pin.anchor",0,"rack:8").is_empty(),"fixture Anchor")
	if batch == "E20-V05": lab.run.strike_streak = 2 # declared prior-streak fixture
	if batch == "E20-V07":
		_check(lab.run.place("pin.ruby",0,"rack:4").is_empty(),"fixture Ruby")
		_check(lab.run.place("pin.rubber",0,"rack:7").is_empty(),"fixture Rubber")
	lab._new_roll(false)
	await _aim()
	if batch == "E20-V01": _check(await _arm("ball.echo"),"actual Echo card arms")
	if batch == "E20-V07":
		_check(await _arm("ball.hook"),"actual Hook card arms")
		await _throw(STRIKE,0.25)
		if lab.history[-1].roll_result.fallen_positions.size() < 10:
			await _focus_accept(lab.next_rack)
			await _throw([0.0,0.0,0.6])
	elif batch == "E20-V04":
		var first := await _throw([-0.1,0.0,0.7],0.25)
		_check(first.knockdown_log.standing == [8],"real nine-pin leave is the Anchor")
		await _focus_accept(lab.next_rack)
		await _throw(GUTTER)
	elif batch == "E20-V06":
		await _throw(LEAVE)
		await _focus_accept(lab.next_rack)
		await _throw([0.0,0.0,0.6])
	else:
		await _throw(STRIKE)
	var scored := await _scored()
	if batch == "E20-V05":
		_check(scored.banked == 2240 and not lab.motion.abilities.history.any(func(e): return e.id == "charm.last_chance"),"third strike activates Turkey and Finisher, not Last Chance in frame one")
		await _focus_accept(lab.next_rack)
		await _throw(STRIKE)
		scored = await _scored()
		_check(scored.banked == 4480 and lab.match_frame == 2,"real second frame activates Last Chance")
	if batch == "E20-V07":
		_check(lab.motion.abilities.history.any(func(e): return e.id == "ball.hook" and e.event == "committed_curve"),"actual committed Hook curve")
		await _focus_accept(lab.next_rack)
		var armed := await _arm("ball.hammer")
		for i in 6:
			if armed: break
			await _focus_accept(lab.card_hand.cycle_button)
			armed = await _arm("ball.hammer")
		_check(armed,"actual Hammer card arms")
		await _throw(STRIKE)
		if lab.history[-1].roll_result.fallen_positions.size() < 10:
			await _focus_accept(lab.next_rack)
			await _throw([0.0,0.0,0.6])
		scored = await _scored()
		_check(lab.motion.abilities.history.any(func(e): return e.id == "ball.hammer" and e.event == "physical_impact"),"actual Hammer contact cue")
		_check(lab.motion.abilities.history.any(func(e): return e.id == "pin.rubber" and e.event == "physical_contact"),"actual Rubber contact cue")
	if batch == "E20-V06": _check(scored.result.category == "spare" and scored.banked == 2160,"real all-House spare: 180 Value times 12 Mult")
	if batch == "E20-V04": _check(scored.result.category == "open" and scored.banked == scored.result.score,"one real standing Anchor frame banks unchanged")
	if batch == "E20-V01": _check(scored.result.retriggers == 1 and scored.banked == 1050,"real Echo and Encore bank 1050")
	if batch == "E20-V03": _check(scored.banked == 1120 and scored.income == 2 and lab.run.money == 8,"two real Gold payouts and Gold Rush bank")
	if batch == "E20-V02":
		_check(scored.banked == 560 and lab.run.rack[1].growth == 1,"Grower grows after unchanged bank")
		_check(not lab.motion.abilities.history.any(func(e): return e.id == "charm.patient_investor"),"zero-growth Investor stays silent before settlement")
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
	if batch == "E20-V02":
		await _to_shop("growth")
		await _wait_for(func(): return lab.motion.abilities.growth_row.visible,"actual settlement growth")
		_check(lab.run.charms[0].growth == 1 and lab.total_score == bank,"Investor grows after match without rescoring")
		await _capture("charm_patient_investor_activation")
	for id in wanted:
		_check(lab.motion.abilities.history.any(func(e): return e.id == id),"actual ability observed: " + id)
	metrics.append(lab.motion.metrics())
	var file := FileAccess.open(artifact_dir.path_join("metrics.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"batch":batch,"motion":metrics,"audio":{"played":lab.motion.sound.played,"max_active":lab.motion.sound.max_active,"suppressed":lab.motion.sound.suppressed},"history":lab.motion.abilities.history},"\t"))
	if failures.is_empty(): print("ROGUEWOOD_ABILITY_OK")
	else: await _capture("failure")
	# Flush deferred log scrolling before SceneTree teardown.
	for i in 6: await process_frame
	quit(0 if failures.is_empty() else 1)
func _scored() -> Dictionary:
	for tick in ROLL_FRAMES * 3:
		if lab.state in ["scoring","frame_done"]:
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

func _wait_for(predicate: Callable, label: String, frames: int = 240) -> bool:
	for i in frames:
		if lab != null and lab.state == "rolling":
			for marker in lab.motion.abilities.world_glyphs:
				if marker.style == null or marker.age > marker.style.duration: continue
				var id: String = marker.style.item_id
				if id in wanted and not captures.has(id):
					captures[id] = true
					await _capture(id.replace(".","_")+"_activation")
		if predicate.call(): return true
		await process_frame
	if predicate.call(): return true
	_check(false,"Timeout: " + label)
	return false
