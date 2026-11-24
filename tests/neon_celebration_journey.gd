extends SceneTree
## UI-A9-N (Claude, 2026-11-24): every Neon celebration listed in the live Neon
## manifest, on the UI-A9-H contract. Each plays in a 252 x 90 view with its rival's
## context: the right duration, `finished` once on its natural end and once on skip,
## and under reduced motion a still final tableau. Rendered, its picture changes over
## a normal play, the reduced tableau's early and late frames are identical, and
## contact frames are saved (not committed).
const LeagueTheme = preload("res://src/presentation/league_theme.gd")
const NAMES := {"rival.slick": "Slick", "rival.laser_lena": "Laser Lena", "rival.dj_flicker": "DJ Flicker", "rival.dj_flicker_champion": "DJ Flicker, Neon Champion"}
var failures: Array = []
var artifact_dir := ""
var view: SubViewport

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	_run.call_deferred()

func _rendered() -> bool:
	return DisplayServer.get_name() != "headless"

func _run() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LeagueTheme.MANIFESTS["league.neon"]))
	_check(bool(manifest.get("celebrations_complete", false)), "the Neon set is declared complete")
	var cases: Array = []
	for event in ["strike", "spare"]:
		var list := LeagueTheme.celebrations_in(manifest, event)
		_check(list.size() >= 5, "%s: %d variants" % [event, list.size()])
		for path in list: cases.append([event, path, {}])
	for rival in NAMES:
		var list := LeagueTheme.celebrations_in(manifest, "boss_defeated", rival)
		_check(list.size() == 2, "%s: two endings" % rival)
		for path in list: cases.append(["boss_defeated", path, {"rival_id": rival, "rival_name": NAMES[rival], "championship": rival.ends_with("_champion")}])
	_check(cases.size() == 18, "eighteen Neon celebrations (%d)" % cases.size())
	var paths := cases.map(func(c): return c[1])
	for p in paths: _check(paths.count(p) == 1, "each variant listed once: " + p)
	for event in ["strike", "spare", "boss_defeated"]:
		var sound: String = manifest.get("celebration_sounds", {}).get(event, "")
		_check(ResourceLoader.exists(sound) and load(sound) is AudioStream, "the Neon %s sting loads" % event)
		if ResourceLoader.exists(sound):
			var length: float = (load(sound) as AudioStream).get_length()
			_check(length > 0.3 and length <= 1.5, "the %s sting is short (%.2f s)" % [event, length])
	view = SubViewport.new()
	view.size = Vector2i(252, 90)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	for c in cases:
		await _case(c[0], c[1], c[2])
	if failures.is_empty(): print("ROGUEWOOD_UIA9N_OK")
	quit(0 if failures.is_empty() else 1)

func _scene(path: String) -> Control:
	var node: Control = load(path).instantiate()
	view.add_child(node)
	return node

func _case(event: String, path: String, context: Dictionary) -> void:
	var name := path.get_file().get_basename()
	var expected: float = {"strike": 1.8, "spare": 1.6, "boss_defeated": 3.0}[event]
	# Natural end: real frames until `finished`, once.
	var node := _scene(path)
	var ends := [0]
	node.finished.connect(func(): ends[0] += 1)
	var ctx := context.merged({"event": event, "reduced_motion": false, "reduced_flash": false})
	node.play(ctx)
	_check(is_equal_approx(node.duration(), expected), "%s lasts %.1f s (%.2f)" % [name, expected, node.duration()])
	if event == "boss_defeated":
		_check(node.texture != null, name + " shows its rival's portrait")
	var shots: Array = []
	for at in [0.1, 0.45, 0.9]:
		node.set_process(false)
		node.elapsed = node.duration() * at
		node.queue_redraw()
		shots.append(await _shot())
	if _rendered():
		_check(shots[0].get_data() != shots[2].get_data() and shots[1].get_data() != shots[2].get_data(), name + " moves over its play")
		_save(name, shots)
	node.elapsed = 0.0
	var frames := 0
	while ends[0] == 0 and frames < 600:
		node._process(1.0 / 60.0)
		frames += 1
	_check(ends[0] == 1 and absf(frames / 60.0 - expected) < 0.05, "%s finishes once at its end (%d frames)" % [name, frames])
	node.skip()
	_check(ends[0] == 1, name + " finishes only once")
	node.queue_free()
	# Skip mid-play: finished at once.
	node = _scene(path)
	var skipped := [0]
	node.finished.connect(func(): skipped[0] += 1)
	node.play(ctx)
	node._process(0.2)
	node.skip()
	_check(skipped[0] == 1 and is_equal_approx(node.elapsed, node.duration()), name + " skips to its end")
	node.queue_free()
	# Reduced motion and flash: the final tableau, still.
	node = _scene(path)
	node.play(context.merged({"event": event, "reduced_motion": true, "reduced_flash": true}))
	node.set_process(false)
	node.elapsed = node.duration() * 0.1
	node.queue_redraw()
	var early: Image = await _shot()
	node.elapsed = node.duration() * 0.9
	node.queue_redraw()
	var late: Image = await _shot()
	if _rendered():
		_check(early.get_data() == late.get_data(), name + " holds one still tableau under reduced motion")
		if not artifact_dir.is_empty(): late.save_png(artifact_dir.path_join(name + "_reduced.png"))
	node.queue_free()
	await process_frame

func _shot() -> Image:
	await process_frame
	if not _rendered(): return Image.new() # headless draws nothing; the contract checks still run
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()

func _save(name: String, shots: Array) -> void:
	if artifact_dir.is_empty(): return
	DirAccess.make_dir_recursive_absolute(artifact_dir)
	var sheet := Image.create(252 * 3, 90, false, shots[0].get_format())
	for i in 3: sheet.blit_rect(shots[i], Rect2i(0, 0, 252, 90), Vector2i(252 * i, 0))
	sheet.resize(252 * 3 * 2, 180, Image.INTERPOLATE_NEAREST)
	sheet.save_png(artifact_dir.path_join(name + ".png"))
