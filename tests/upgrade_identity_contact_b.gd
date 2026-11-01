extends SceneTree
const Assets = preload("res://src/presentation/item_assets.gd")
var artifact_dir := ""
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = Vector2i(900,480)
	root.content_scale_size = root.size
	var bg := ColorRect.new()
	bg.color = Color("101820")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var index := 0
	for suffix in ["savings_book", "extra_shelf", "spotlight_sign"]:
		var id: String = "shop_upgrade." + suffix
		var panel := PanelContainer.new()
		panel.position = Vector2(16+index*296,16)
		panel.size = Vector2(280,448)
		panel.add_theme_stylebox_override("panel",Assets.slot(id,"rarity_treatment"))
		bg.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation",16)
		panel.add_child(box)
		var title := Label.new()
		title.text = suffix.capitalize() + "\nSHOP LICENSE · " + Assets.rarity_mark(id)
		box.add_child(title)
		for slot in ["card", "icon", "reduced_motion"]:
			var view := TextureRect.new()
			view.texture = Assets.slot(id,slot)
			if view.texture == null:
				push_error("Missing identity " + id + ":" + slot)
				quit(1)
				return
			var pixels := 180 if slot == "card" else 48
			view.custom_minimum_size = Vector2(pixels,pixels)
			view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			box.add_child(view)
		index += 1
	for i in 12: await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(artifact_dir.path_join("contact.png")) != OK:
			quit(1)
			return
	print("ROGUEWOOD_UPGRADE_IDENTITY_OK")
	quit(0)
