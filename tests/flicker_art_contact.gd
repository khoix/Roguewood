extends SceneTree
const Art = preload("res://src/presentation/rival_art.gd")
const Hud = preload("res://src/presentation/division_hud.gd")
const Club = preload("res://src/clubhouse/clubhouse_art.gd")
var artifact_dir := ""
var failed := false
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	for variant in 4:
		var still := variant % 2 == 1
		var rival_id := "rival.dj_flicker_champion" if variant >= 2 else "rival.dj_flicker"
		var bg := ColorRect.new()
		bg.color = Color("101820")
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(bg)
		for index in 6:
			var title := Label.new()
			title.text = Art.STATES[index]
			title.position = Vector2(16 + 210 * index, 12)
			bg.add_child(title)
			for pixels in [180, 72]:
				var view := Hud.Portrait.new()
				view.texture = Art.portrait(rival_id, Art.STATES[index])
				view.still = still
				view.size = Vector2(pixels, pixels)
				view.position = Vector2(16 + index * 210, 48 if pixels == 180 else 252)
				view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				bg.add_child(view)
				if view.texture == null: failed = true
		var ids := ["plaque.dj_flicker", "plaque.dj_flicker_champion"]
		for index in ids.size():
			if not Club.has_art(ids[index]): failed = true
			var slot := Club.slot(ids[index], 180)
			slot.position = Vector2(16 + index * 240, 390)
			slot.size = Vector2(180, 180)
			bg.add_child(slot)
			var small := Club.slot(ids[index], 64)
			small.position = Vector2(16 + index * 240, 600)
			small.size = Vector2(64, 64)
			bg.add_child(small)
		var seal := TextureRect.new()
		# Asset-only preview until the coordinator fits both champion seals (E21-R07).
		seal.texture = load("res://assets/rivals/rules/strobe.svg")
		seal.position = Vector2(1060, 430)
		seal.size = Vector2(64,64)
		bg.add_child(seal)
		if seal.texture == null: failed = true
		for i in 20: await process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(artifact_dir.path_join(("champion_" if variant >= 2 else "") + ("reduced.png" if still else "normal.png"))) != OK: failed = true
		root.remove_child(bg)
		bg.queue_free()
	if not failed: print("ROGUEWOOD_FLICKER_CONTACT_OK")
	quit(1 if failed else 0)
