extends SceneTree
## UI-A8 (Claude, 2026-11-24): the League backdrops in the real game. For House and
## Neon it checks that:
## - the new backdrop is in place behind the lane;
## - it follows the match's room (set_stage: Division 1–8 and the Championship), whose
##   picture changes from room to room;
## - reduced motion holds one still picture;
## - normal play moves slowly (a small share of the screen changes);
## - its cost per frame is small (rendered: wall time with the backdrop against hidden).
## Captures every room in portrait and landscape (not committed).
const SCRIPTS := {"house": "res://assets/ui/backdrops/house_night.gd", "neon": "res://assets/ui/backdrops/neon_city.gd"}
var failures: Array = []
var artifact_dir := ""
var report := {}

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

func _wait(cond: Callable, frames := 900) -> bool:
	for i in frames:
		if cond.call(): return true
		await process_frame
	return false

func _shot() -> Image:
	await process_frame
	if not _rendered(): return Image.new()
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _changed_share(a: Image, b: Image) -> float:
	var changed := 0
	var total := 0
	for y in range(0, a.get_height(), 3):
		for x in range(0, a.get_width(), 3):
			total += 1
			if absf(a.get_pixel(x, y).get_luminance() - b.get_pixel(x, y).get_luminance()) > 0.06: changed += 1
	return float(changed) / maxf(total, 1)

func _run() -> void:
	for league in ["house", "neon"]:
		await _league(league)
	if not artifact_dir.is_empty():
		var file := FileAccess.open(artifact_dir.path_join("report.json"), FileAccess.WRITE)
		if file: file.store_string(JSON.stringify(report, "\t"))
	if failures.is_empty(): print("ROGUEWOOD_UIA8_OK")
	quit(0 if failures.is_empty() else 1)

func _league(league: String) -> void:
	root.size = Vector2i(540, 960)
	var scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await _wait(func(): return scene.get("enter") != null and scene.enter.is_visible_in_tree())
	for i in 5: await process_frame
	if league == "neon":
		var index: int = scene.league_sets.find("neon")
		_check(index >= 0, "the board lists the Neon League")
		scene.league.select(index)
		scene.league.item_selected.emit(index)
		for i in 5: await process_frame
	scene._begin_attempt(1)
	_check(await _wait(func(): return scene.lab != null and scene.lab.state == "aim"), league + ": the match reaches aim")
	var lab = scene.lab
	var backdrop: Control = lab.backdrop
	_check(backdrop != null and backdrop.get_script() != null and backdrop.get_script().resource_path == SCRIPTS[league], "%s: the UI-A8 backdrop is behind the lane (%s)" % [league, backdrop.get_script().resource_path if backdrop and backdrop.get_script() else "none"])
	_check(backdrop.get_index() < lab._viewport.get_parent().get_index() if lab._viewport.get_parent().get_parent() == lab else true, league + ": the backdrop draws under the lane")
	_check(backdrop.division == lab.division.division_number() and not backdrop.championship, "%s: the backdrop follows the match's Division (%d)" % [league, backdrop.division])
	var reduced_before: bool = backdrop.reduced
	backdrop.reduced = false
	# Each room: the backdrop changes with it; captures in both orientations.
	var pictures := {}
	for spec in [[1, false], [2, false], [3, false], [4, false], [5, false], [6, false], [7, false], [8, false], [8, true]]:
		lab.league_theme.show_stage(lab._viewport, spec[0], spec[1])
		backdrop.set_stage(spec[0], spec[1])
		backdrop.phase = 7.0
		var key := "d%d%s" % [spec[0], "c" if spec[1] else ""]
		for size in [Vector2i(540, 960), Vector2i(1280, 720)]:
			root.size = size
			for i in 6: await process_frame
			var image := await _shot()
			if size.x == 540: pictures[key] = image
			if _rendered() and not artifact_dir.is_empty():
				image.save_png(artifact_dir.path_join("%s_%s_%s.png" % [league, key, "portrait" if size.x == 540 else "landscape"]))
	if _rendered():
		var distinct := {}
		for key in pictures: distinct[hash(pictures[key].get_data())] = true
		_check(distinct.size() == pictures.size(), "%s: every room's backdrop differs (%d of %d)" % [league, distinct.size(), pictures.size()])
	root.size = Vector2i(540, 960)
	backdrop.set_stage(3, false)
	# Normal: it moves, slowly.
	backdrop.phase = 2.0
	var a := await _shot()
	backdrop.phase = 3.5
	var b := await _shot()
	if _rendered():
		var share := _changed_share(a, b)
		report[league + "_drift_share_1_5s"] = share
		_check(a.get_data() != b.get_data() and share < 0.05, "%s: the backdrop moves, ambient (%.2f%% of the screen over 1.5 s)" % [league, share * 100.0])
	# Reduced: one still picture whatever the clock says.
	backdrop.reduced = true
	backdrop.phase = 1.0
	var still_a := await _shot()
	backdrop.phase = 9.0
	var still_b := await _shot()
	_check(not _rendered() or still_a.get_data() == still_b.get_data(), league + ": reduced motion holds one still picture")
	if _rendered() and not artifact_dir.is_empty(): still_b.save_png(artifact_dir.path_join(league + "_reduced.png"))
	backdrop.reduced = reduced_before
	# Cost: wall time per frame with the backdrop live against hidden (rendered only;
	# software rendering here, so this compares, it does not measure a phone).
	if _rendered():
		backdrop.reduced = false
		var live := await _frame_ms(120)
		backdrop.visible = false
		var hidden := await _frame_ms(120)
		backdrop.visible = true
		report[league + "_frame_ms_live"] = live
		report[league + "_frame_ms_hidden"] = hidden
		print("UIA8 %s frame ms: live %.2f, hidden %.2f" % [league, live, hidden])
		_check(live < hidden * 1.5 + 2.0, "%s: the backdrop costs little per frame (%.2f against %.2f ms)" % [league, live, hidden])
	scene.queue_free()
	for i in 5: await process_frame

func _frame_ms(frames: int) -> float:
	var start := Time.get_ticks_usec()
	for i in frames: await process_frame
	return (Time.get_ticks_usec() - start) / 1000.0 / frames
