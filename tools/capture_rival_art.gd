extends SceneTree
const Art = preload("res://src/presentation/rival_art.gd")
var id := "rival.surveyor"
func _initialize() -> void: call_deferred("_capture")
func _capture() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--rival="): id = arg.trim_prefix("--rival=")
	root.size = Vector2i(1280,720)
	root.content_scale_size = root.size
	var bg := ColorRect.new()
	bg.color = Color("101820")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	for i in 6:
		var box := VBoxContainer.new()
		box.position = Vector2(10+i*212,24)
		box.size = Vector2(200,680)
		box.add_theme_constant_override("separation",24)
		bg.add_child(box)
		var title := Label.new()
		title.text = Art.STATES[i].capitalize()
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(title)
		for pixels in [180,72]:
			var texture := TextureRect.new()
			texture.texture = Art.portrait(id,Art.STATES[i])
			texture.custom_minimum_size = Vector2(pixels,pixels)
			texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			box.add_child(texture)
		var label := Label.new()
		label.text = "180 / 72 px\nStatic reduced-motion"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(label)
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/e21-" + ("r01" if id == "rival.surveyor" else "r02") + "/contact.png"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var result := root.get_texture().get_image().save_png(path)
	print("ROGUEWOOD_RIVAL_CONTACT_OK" if result == OK else "CONTACT_FAILED")
	quit(0 if result == OK else 1)
