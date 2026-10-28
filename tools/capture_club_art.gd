extends SceneTree
const Art = preload("res://src/clubhouse/clubhouse_art.gd")
const IDS = preload("res://tests/art_club_journey.gd").CLUB_IDS
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	var bg := ColorRect.new()
	bg.color = Color("101d25")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	for i in IDS.size():
		var box := VBoxContainer.new()
		box.position = Vector2(20 + (i % 5) * 250, 30 + (i / 5) * 330)
		box.size = Vector2(230,290)
		bg.add_child(box)
		var center := CenterContainer.new()
		box.add_child(center)
		center.add_child(Art.slot(IDS[i],120))
		var label := Label.new()
		label.text = IDS[i].replace(".","\n") + "\n120 px"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",20)
		box.add_child(label)
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/e16-art")
	var result := root.get_texture().get_image().save_png("res://artifacts/e16-art/contact.png")
	print("ROGUEWOOD_CLUB_CONTACT_OK" if result == OK else "CONTACT_FAILED")
	quit(0 if result == OK else 1)
