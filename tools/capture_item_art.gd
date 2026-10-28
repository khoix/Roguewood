extends SceneTree
## Renders runtime resources at their intended UI sizes. Output is ignored evidence.
const Assets = preload("res://src/presentation/item_assets.gd")
var ids: Array = []
var batch := "E19-A03"
var destination := ""
func _initialize() -> void: call_deferred("_capture")
func _capture() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): destination = arg.trim_prefix("--out=")
		if arg.begins_with("--batch="): batch = arg.trim_prefix("--batch=")
	ids = JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/batches.json"))[batch]
	if destination.is_empty(): destination = "res://artifacts/" + batch.to_lower() + "/contact.png"
	DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(canvas)
	var bg := ColorRect.new()
	bg.color = Color("101820")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)
	for i in ids.size():
		var id: String = ids[i]
		var panel := PanelContainer.new()
		panel.position = Vector2(16 + i * 316, 20)
		panel.size = Vector2(300, 680)
		panel.add_theme_stylebox_override("panel", Assets.slot(id, "rarity_treatment"))
		canvas.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 12)
		panel.add_child(box)
		_label(box, Assets._items[id].name, 24)
		_texture(box, Assets.slot(id, "card"), 192)
		_label(box, String(Assets._items[id].category).to_upper() + " · " + Assets.rarity_mark(id), 18)
		_texture(box, Assets.slot(id, "icon"), 48)
		_label(box, "48 px icon · static / reduced", 16)
		if Assets.slot(id, "in_play") is Material:
			var viewport := SubViewport.new()
			viewport.size = Vector2i(192,192)
			viewport.own_world_3d = true
			viewport.transparent_bg = true
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			canvas.add_child(viewport)
			var body := RigidBody3D.new()
			body.freeze = true
			body.set_meta("item_id", id)
			viewport.add_child(body)
			preload("res://src/presentation/live_dressing.gd").new().dress_pin(body)
			var camera := Camera3D.new()
			camera.position = Vector3(0.03,0.20,0.36)
			viewport.add_child(camera)
			camera.look_at(Vector3(0,0.19,0))
			var light := DirectionalLight3D.new()
			light.rotation_degrees = Vector3(-25,-30,0)
			viewport.add_child(light)
			var environment := WorldEnvironment.new()
			environment.environment = Environment.new()
			environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			environment.environment.ambient_light_color = Color("a8bac2")
			environment.environment.ambient_light_energy = 0.6
			viewport.add_child(environment)
			_texture(box, viewport.get_texture(), 192)
		else:
			_texture(box, Assets.slot(id, "in_play"), 192)
		_label(box, "In play · static / reduced", 16)
	for i in range(20): await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(destination)
	print("ROGUEWOOD_ITEM_CONTACT_OK" if result == OK else "CONTACT_FAILED")
	quit(0 if result == OK else 1)
func _label(parent: Node, text_value: String, font: int) -> void:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font)
	parent.add_child(label)
func _texture(parent: Node, texture: Texture2D, pixels: int) -> void:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(pixels,pixels)
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(rect)
