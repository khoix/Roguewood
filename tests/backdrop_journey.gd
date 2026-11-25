extends SceneTree
## UI-A8 (Claude, 2026-11-24/25): the League backdrops and the alley around the lane
## in the real game. For House and Neon it checks that:
## - the new backdrop is in place behind the lane, and the alley's structure (the T:
##   alley_interior.gd) stands round the lane, built for the match's League and room;
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
	var alley = lab.alley
	_check(alley != null and alley.get_parent() == lab._viewport and alley.league == league and alley.division == lab.division.division_number() and alley.get_child_count() > 0,
		"%s: the alley stands round the lane, built for its room" % league)
	_check(alley == null or alley.find_children("*", "CollisionObject3D", true, false).is_empty(), league + ": the alley has no collision (cosmetic only)")
	_check_no_shared_faces(league, lab, alley)
	for i in 3: await process_frame # the lab tracks the horizon and the HUD edge each frame
	if league == "house": await _check_moon(backdrop)
	var reduced_before: bool = backdrop.reduced
	backdrop.reduced = false
	# Each room: the backdrop changes with it; captures in both orientations.
	var pictures := {}
	for spec in [[1, false], [2, false], [3, false], [4, false], [5, false], [6, false], [7, false], [8, false], [8, true]]:
		lab.dress_stage(spec[0], spec[1])
		_check(alley.division == spec[0] and alley.championship == spec[1] and backdrop.division == spec[0], "%s: room %s dresses the alley and the backdrop" % [league, str(spec)])
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
	lab.dress_stage(3, false)
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
		alley.visible = false
		var hidden := await _frame_ms(120)
		backdrop.visible = true
		alley.visible = true
		report[league + "_frame_ms_live"] = live
		report[league + "_frame_ms_hidden"] = hidden
		print("UIA8 %s frame ms: live %.2f, hidden %.2f" % [league, live, hidden])
		_check(live < hidden * 1.5 + 2.0, "%s: the backdrop and alley cost little per frame (%.2f against %.2f ms)" % [league, live, hidden])
	scene.queue_free()
	for i in 5: await process_frame

## UI-A8c (owner, 2026-11-25: "Have the moon arch across the sky"): the House moon
## rises from the trees at the left, climbs high, sets behind the trees at the right,
## then rises again; a match starts with it partway up, where reduced motion holds it.
func _check_moon(backdrop) -> void:
	var script = backdrop.get_script()
	var w := 270.0
	var h := 480.0
	var hz: float = h * backdrop.horizon
	var crossing: float = script.MOON_CROSSING
	var start: float = script.moon_along(0.0)
	_check(absf(start - script.MOON_START) < 0.001, "house: a match starts with the moon partway up (%.2f)" % start)
	var rise: Vector2 = script.moon_at(0.0, w, h, hz)
	var high: Vector2 = script.moon_at(0.5, w, h, hz)
	var down: Vector2 = script.moon_at(1.0, w, h, hz)
	_check(rise.x < w * 0.1 and down.x > w * 0.9 and rise.y > hz and down.y > hz, "house: the moon rises and sets behind the trees at the edges (%s, %s)" % [rise, down])
	_check(high.y < hz * 0.35 and absf(high.x - w * 0.5) < 2.0, "house: the moon climbs high mid-sky (%s)" % high)
	# Under a HUD, the arch keeps the whole moon below it, still well clear of the trees.
	var under: Vector2 = script.moon_at(0.5, w, h, hz, 40.0)
	_check(under.y - script.MOON_RADIUS >= 40.0 and under.y < hz - 20.0, "house: under the HUD the moon peaks below it, clear of the trees (%s)" % under)
	_check(absf(backdrop.sky_top - backdrop.get_parent().regions.lane.position.y / backdrop.get_parent().size.y) < 0.01 if backdrop.get_parent().get("regions") else true, "house: the backdrop knows where the HUD over the sky ends (%.3f)" % backdrop.sky_top)
	var last := -1.0
	var climbing := true
	for k in range(1, 20):
		var at: Vector2 = script.moon_at(k / 20.0, w, h, hz)
		climbing = climbing and at.x > last
		last = at.x
	_check(climbing, "house: the moon moves steadily left to right")
	var below_at: float = crossing * (1.0 - script.MOON_START) + script.MOON_BELOW * 0.5
	_check(script.moon_along(below_at) < 0.0 and script.moon_along(below_at + script.MOON_BELOW) >= 0.0, "house: the moon is down a while, then rises again")
	if not _rendered(): return
	backdrop.reduced = false
	var frames := {}
	for size in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(390, 844), Vector2i(540, 960)]:
		root.size = size
		for i in 6: await process_frame
		for spec in [["rising", 0.05], ["high", 0.5], ["setting", 0.95]]:
			backdrop.phase = (spec[1] - script.MOON_START) * crossing
			frames[spec[0]] = await _shot()
			if not artifact_dir.is_empty(): frames[spec[0]].save_png(artifact_dir.path_join("house_moon_%s_%dx%d.png" % [spec[0], size.x, size.y]))
	_check(frames.rising.get_data() != frames.high.get_data() and frames.high.get_data() != frames.setting.get_data(), "house: the sky changes as the moon crosses")

## UI-A8b (owner, 2026-11-25: "The pin walls are flickering rapidly while the ball is in
## motion toward it"): no alley face may lie on (within 5 mm of) a face of the pin
## deck's walls (kickbacks and cushion) where they overlap, or the two fight for depth.
func _check_no_shared_faces(league: String, lab, alley) -> void:
	var walls: Array = []
	for body in lab.lane.get_children():
		if body is StaticBody3D and (String(body.name).begins_with("Kickback") or body.name == "Cushion"):
			for child in body.get_children():
				if child is MeshInstance3D: walls.append(child.global_transform * child.get_aabb())
	_check(walls.size() >= 3, "%s: the pin deck's walls are found (%d)" % [league, walls.size()])
	var shared := 0
	for part in alley.get_children():
		if not part is MeshInstance3D: continue
		var faces: PackedVector3Array = part.mesh.get_faces()
		for i in range(0, faces.size(), 3):
			var tri := AABB(faces[i], Vector3.ZERO).expand(faces[i + 1]).expand(faces[i + 2])
			for axis in 3:
				if tri.size[axis] > 0.0001: continue # not a face across this axis
				for box in walls:
					for plane in [box.position[axis], box.end[axis]]:
						if absf(tri.position[axis] - plane) > 0.005: continue
						var overlap := true
						for other in 3:
							if other == axis: continue
							overlap = overlap and minf(tri.end[other], box.end[other]) - maxf(tri.position[other], box.position[other]) > 0.01
						if overlap: shared += 1
	_check(shared == 0, "%s: no alley face lies on a pin-deck wall's face (%d found)" % [league, shared])

func _frame_ms(frames: int) -> float:
	var start := Time.get_ticks_usec()
	for i in frames: await process_frame
	return (Time.get_ticks_usec() - start) / 1000.0 / frames
