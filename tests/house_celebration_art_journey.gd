extends "res://tests/scoring_journey.gd"
## UI-A9-H preproduction review: real game + real AlleyScreen, test-only selection.
## Deterministic story frames do not alter the production picker or live manifest.
const CASES := [
	["strike", "strike_pinwheel", 1.8],
	["strike", "strike_domino", 1.8],
	["strike", "strike_curtain", 1.8],
	["strike", "strike_score_stamp", 1.8],
	["strike", "strike_constellation", 1.8],
	["spare", "spare_last_chair", 1.6],
	["spare", "spare_magnet", 1.6],
	["spare", "spare_bookend", 1.6],
	["spare", "spare_delivery", 1.6],
	["spare", "spare_lasso", 1.6],
	["boss_defeated", "boss_surveyor_tape", 3.0],
	["boss_defeated", "boss_surveyor_level", 3.0],
	["boss_defeated", "boss_custodian_sweep", 3.0],
	["boss_defeated", "boss_custodian_polish", 3.0],
	["boss_defeated", "boss_proprietor_receipt", 3.0],
	["boss_defeated", "boss_proprietor_keys", 3.0],
	["boss_defeated", "boss_old_lou_record", 3.0],
	["boss_defeated", "boss_old_lou_encore", 3.0],
	["boss_defeated", "boss_custodian_champion_crown", 3.0],
	["boss_defeated", "boss_custodian_champion_house_lights", 3.0],
]
var _measure := ""
var _last_sample := 0
var _last_bucket := ""
var _samples: Dictionary = {}
var _completed := false

func _process(_delta: float) -> bool:
	var bucket := _measure
	if bucket.is_empty() and is_instance_valid(lab) and lab.state == "rolling": bucket = "ordinary_roll"
	var now := Time.get_ticks_usec()
	if not bucket.is_empty() and bucket == _last_bucket:
		if not _samples.has(bucket): _samples[bucket] = []
		_samples[bucket].append((now-_last_sample)/1000.0)
	_last_sample = now
	_last_bucket = bucket
	return false

func _write_frame_times() -> void:
	var report := {"complete":_completed, "failures":failures, "renderer":RenderingServer.get_video_adapter_name(), "display":DisplayServer.get_name(),
		"draw_all":not "--qa-render-on-demand" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless", "measurement":"wall milliseconds between native process frames; includes CPU/render scheduling, not GPU timing or physical-phone evidence", "samples":{}}
	for key in _samples:
		var values: Array = _samples[key]
		values.sort()
		report.samples[key] = {"count":values.size(),"p50_ms":values[int((values.size()-1)*0.5)],"p95_ms":values[int((values.size()-1)*0.95)],"p99_ms":values[int((values.size()-1)*0.99)]}
	if not artifact_dir.is_empty():
		var file := FileAccess.open(artifact_dir.path_join("frame-times.json"),FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(report,"\t"))

func orientations() -> Array: return ["portrait", "landscape"]

func reduced() -> bool: return false

func _rival_context(key: String) -> Dictionary:
	var names := {"custodian_champion":"The Custodian, House Champion", "custodian":"The Custodian", "surveyor":"The Surveyor", "proprietor":"The Proprietor", "old_lou":"Old Lou"}
	for id in names:
		if key.begins_with("boss_" + id + "_"):
			return {"rival_id":"rival."+id, "rival_name":names[id], "championship":id == "custodian_champion"}
	return {}

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.enter.has_focus(), "menu focus")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "real lab ready")
	lab = scene.lab
	lab.trial_log_path = ""
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_flash)
	if reduced(): await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.close)
	await _focus_accept(scene.resume)
	var alley = lab.alley_screen
	_check(not alley.has_art("strike"), "unfinished set remains absent from live manifest")
	for orientation in orientations():
		root.size = Vector2i(450,800) if orientation == "portrait" else Vector2i(800,450)
		for i in 12: await process_frame
		for spec in CASES:
			var path := "res://assets/ui/alley_screen/house/" + String(spec[1]) + ".tscn"
			alley.variants_override = {spec[0]: [path]}
			var ctx := _rival_context(spec[1])
			ctx.merge({"reduced_motion":reduced(), "reduced_flash":true})
			_check(alley.celebrate(spec[0],ctx), "native screen accepts " + spec[1])
			var art = alley.current
			_check(art != null and is_equal_approx(art.duration(), spec[2]), "scene duration " + spec[1])
			if art == null: continue
			if spec[0] == "boss_defeated":
				var expected: AtlasTexture = art.RivalArt.portrait(ctx.rival_id,"defeated")
				_check(art.texture is AtlasTexture and art.texture.atlas == expected.atlas and art.texture.region == expected.region and art.texture.filter_clip == expected.filter_clip, "correct rival portrait source and region " + spec[1])
			art.set_process(false)
			# Let the production power-on finish; the scene clock alone is held.
			for i in 14: await process_frame
			var first: Image
			for fraction in [0.1,0.45,0.9]:
				art.elapsed = art.duration()*fraction
				art.queue_redraw()
				await process_frame
				await _capture("%s_%s_%02d" % [spec[1],orientation,int(fraction*100)])
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					var pixels: Image = alley.view.get_texture().get_image()
					if first == null: first = pixels
					elif reduced(): _check(first.get_data() == pixels.get_data(), "reduced still pixels " + spec[1])
					elif fraction == 0.9: _check(first.get_data() != pixels.get_data(), "distinct moving story frames " + spec[1])
			_check(alley.view.size == Vector2i(252,90), "display-sized render target")
			_check(float(alley.crt.get_shader_parameter("flicker")) == 0.0, "reduced flash disables flicker")
			# Let each scene finish through its real process/finished path.
			# Measure a complete natural playback with capture readbacks excluded.
			art.play(ctx)
			_measure = spec[1] + "_" + orientation
			await _wait_for(func(): return not alley.playing(), "natural completion " + spec[1])
			_measure = ""
			_write_frame_times()
			_check(not alley.visible and alley.view.render_target_update_mode == SubViewport.UPDATE_DISABLED, "hidden screen stops rendering")
			alley.celebrate(spec[0],ctx)
			alley.skip()
			_check(not alley.playing(), "replay and skip " + spec[1])
	# Exercise shipping strike/spare triggers and tap-to-skip with this art, while
	# retaining J03's independent score assertions and no-celebration open frame.
	await _focus_accept(scene.options)
	if not lab.settings.reduced_motion: await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.assist)
	lab.settings_panel.use_practice()
	await process_frame
	await _focus_accept(lab.settings_panel.close)
	await _focus_accept(scene.resume)
	alley.variants_override = {
		"strike":["res://assets/ui/alley_screen/house/strike_pinwheel.tscn"],
		"spare":["res://assets/ui/alley_screen/house/spare_last_chair.tscn"]}
	await _strike_frame()
	await _spare_frame()
	await _open_frame()
	alley.variants_override = {}
	_completed = failures.is_empty()
	_write_frame_times()
	if failures.is_empty(): print("ROGUEWOOD_UIA9H_OK")
	quit(0 if failures.is_empty() else 1)

func _check_celebration(event: String) -> void:
	var alley = lab.alley_screen
	await _wait_for(func(): return alley.playing(), "authored " + event + " trigger")
	var path: String = alley.variants_override[event][0]
	_check(alley.current_path == path and alley.visible, "real roll selects authored " + event)
	_check(alley.view.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "real celebration renders")
	_check(alley.current_context.reduced_motion == lab.settings.reduced_motion, "real trigger follows settings")
