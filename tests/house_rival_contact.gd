extends SceneTree
## Actual-size six-state contact sheets; capture output is never a resource.
const Art = preload("res://src/presentation/rival_art.gd")
var artifact_dir := ""
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = Vector2i(1280, 480)
	root.content_scale_size = root.size
	for id in ["rival.proprietor", "rival.old_lou"]:
		var bg := ColorRect.new()
		bg.color = Color("101820")
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(bg)
		for index in 6:
			var box := VBoxContainer.new()
			box.position = Vector2(10 + index * 212, 24)
			box.size = Vector2(200, 440)
			box.add_theme_constant_override("separation", 24)
			bg.add_child(box)
			var title := Label.new()
			title.text = Art.STATES[index].capitalize()
			box.add_child(title)
			for pixels in [180, 72]:
				var view := TextureRect.new()
				view.texture = Art.portrait(id, Art.STATES[index])
				if view.texture == null:
					push_error("Missing portrait " + id)
					quit(1)
					return
				view.custom_minimum_size = Vector2(pixels, pixels)
				view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				box.add_child(view)
		for i in 12: await process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(artifact_dir.path_join(id + ".png")) != OK:
				quit(1)
				return
		root.remove_child(bg)
		bg.queue_free()
	print("ROGUEWOOD_HOUSE_RIVAL_CONTACT_OK")
	quit(0)
