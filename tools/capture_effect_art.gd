extends SceneTree
const Assets = preload("res://src/presentation/item_assets.gd")
var batch := "E20-V01"
func _initialize() -> void: call_deferred("_capture")
func _capture() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="): batch = arg.trim_prefix("--batch=")
	root.size = Vector2i(1280,720)
	root.content_scale_size = root.size
	var bg := ColorRect.new()
	bg.color = Color("101820")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/effects/batches.json"))[batch]
	for i in rows.size():
		var id: String = rows[i][0]
		var box := VBoxContainer.new()
		box.position = Vector2(36+(i%3)*420,20+(i/3)*350)
		box.custom_minimum_size = Vector2(370,320)
		box.add_theme_constant_override("separation",18)
		bg.add_child(box)
		var label := Label.new()
		label.text = id + "\n" + rows[i][1]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(label)
		for reduced in [false,true]:
			var glyph := preload("res://src/presentation/ability_glyph.gd").new()
			glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			box.add_child(glyph)
			glyph.show_cue(Assets.slot(id,"activation"),reduced,Assets.slot(id,"icon"))
			glyph.set_process(false)
			glyph.age = 0.25
		var caption := Label.new()
		caption.text = "64px activation / static reduced"
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(caption)
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/" + batch.to_lower()+"/contact.png"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var result := root.get_texture().get_image().save_png(path)
	print("ROGUEWOOD_EFFECT_CONTACT_OK" if result == OK else "CONTACT_FAILED")
	quit(0 if result == OK else 1)
