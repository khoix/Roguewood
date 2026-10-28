extends SceneTree
## Authored-item preview only. Does not inject definitions into a live game.
var batch := "E19-A08"
var destination := ""
var items: Array = []
var failures: Array[String] = []
var canvas: Control
const GRAY = preload("res://assets/items/d01/preview.gdshader")
const PAIRS := {
"E19-A08":["ball.house","ball.hammer","pin.ruby","pin.gold","charm.gold_rush"],
"E19-A09":["ball.echo","charm.encore","charm.standing_order"],
"E19-A10":["pin.fuse","ball.echo"],
"E19-A11":["pin.glass","ball.splitter"],
"E19-A12":["ball.ghost"]}
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="): batch = arg.trim_prefix("--batch=")
		if arg.begins_with("--artifact-dir="): destination = arg.trim_prefix("--artifact-dir=")
	for candidate in ["E19-A08","E19-A09","E19-A10","E19-A11","E19-A12"]:
		if destination.to_lower().contains(candidate.to_lower()): batch = candidate
	if destination.is_empty(): destination = "res://artifacts/" + batch.to_lower() + "/preview"
	DirAccess.make_dir_recursive_absolute(destination)
	var definitions: Array = JSON.parse_string(FileAccess.get_file_as_string("res://content/catalogue/batches/E17-D01.json")).definitions
	var ids: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/d01/batches.json"))[batch]
	for d in definitions:
		if d.item.id not in ids: continue
		var item: Dictionary = d.item
		items.append(item)
		check(not item.completeness.artwork and not item.completeness.effects_audio and not item.completeness.mechanics,"authored flags unchanged")
		check(item.assets.activation.is_empty() and item.assets.sound.is_empty(),"effects wait for E18/E20")
		for slot in d.design.asset_ids:
			if slot in ["activation","sound"]: continue
			var path: String = item.assets[slot]
			check(path.get_file().get_basename() == d.design.asset_ids[slot],"exact ID " + item.id + "/" + slot)
			check(ResourceLoader.exists(path),"resource " + path)
			var resource = load(path)
			if slot == "in_play":
				check(resource is PackedScene,"cosmetic model resource")
				var model = resource.instantiate()
				root.add_child(model)
				check(model.find_children("*","CollisionObject3D",true,false).is_empty(),"model has no physics")
				check(model.get_child_count()>0,"cosmetic geometry exists")
				model.queue_free()
			elif slot == "rarity_treatment": check(resource is StyleBoxFlat,"rarity border resource")
			else: check(resource is Texture2D,"identity texture")
	if DisplayServer.get_name() != "headless" and failures.is_empty():
		root.size = Vector2i(1280,720)
		root.content_scale_size = Vector2i(1280,720)
		_make_contact(items)
		await capture("contact")
		var compare: Array = items.duplicate()
		var catalogue: Array = JSON.parse_string(FileAccess.get_file_as_string("res://content/catalogue.json")).items
		for id in PAIRS[batch]:
			for d in definitions:
				if d.item.id == id and not d.item.assets.card.is_empty(): compare.append(d.item)
			for item in catalogue:
				if item.id == id: compare.append(item)
		_make_comparison(compare)
		await capture("comparison")
		for item in items:
			for dimensions in [Vector2i(720,1280),Vector2i(1280,720)]:
				root.size = dimensions
				root.content_scale_size = dimensions
				_make_inspector(item,dimensions)
				await capture(item.id.replace(".","_") + "_" + str(dimensions.x))
	if failures.is_empty(): print("ROGUEWOOD_D01_ART_OK " + batch)
	for i in 6: await process_frame
	quit(0 if failures.is_empty() else 1)
func _base() -> Control:
	if is_instance_valid(canvas): root.remove_child(canvas);canvas.queue_free()
	canvas = Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(canvas)
	var bg := ColorRect.new()
	bg.color = Color("101820")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)
	return canvas
func label(parent: Node, text: String, font: int = 20) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",font)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l
func picture(parent: Node, texture: Texture2D, side: int, mode: int = 0) -> TextureRect:
	var r := TextureRect.new()
	r.texture = texture
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(side,side)
	r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if mode > 0:
		var material := ShaderMaterial.new()
		material.shader = GRAY
		material.set_shader_parameter("mode",mode)
		r.material = material
	parent.add_child(r)
	return r
func _make_contact(list: Array) -> void:
	_base()
	for i in list.size():
		var item: Dictionary = list[i]
		var panel := PanelContainer.new()
		panel.position = Vector2(16+i*316,16)
		panel.size = Vector2(300,688)
		panel.add_theme_stylebox_override("panel",load(item.assets.rarity_treatment))
		canvas.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation",10)
		panel.add_child(box)
		label(box,item.name,24)
		label(box,item.category.capitalize()+" · "+item.rarity.capitalize())
		picture(box,load(item.assets.card),192)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation",20)
		box.add_child(row)
		for mode in [0,1,2]: picture(row,load(item.assets.icon),48,mode)
		label(box,"48 px · color / gray / silhouette",16)
		if not item.assets.in_play.is_empty():
			_model(box,item,"ready")
			label(box,"Cosmetic model preview only",16)
		else:
			picture(box,load(item.assets.reduced_motion),96)
			label(box,"Static reduced identity",16)
func _model(parent: Node, item: Dictionary, state: String) -> void:
	var view := SubViewport.new()
	view.size = Vector2i(192,192)
	view.own_world_3d = true
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	canvas.add_child(view)
	var model = load(item.assets.in_play).instantiate()
	model.presentation_state = state
	view.add_child(model)
	model.rotation.y = -0.25
	var center := Vector3(0,0.20,0) if item.category == "pin" else Vector3.ZERO
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 0.52 if item.category == "pin" else 0.31
	if state == "split": camera.size = 0.46
	camera.position = center + Vector3(0.08,0.03,-0.65)
	view.add_child(camera)
	camera.look_at(center)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30,-150,0)
	view.add_child(light)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("c6d8d8")
	env.environment.ambient_light_energy = 0.65
	view.add_child(env)
	picture(parent,view.get_texture(),192)
func _make_comparison(list: Array) -> void:
	_base()
	for i in list.size():
		var box := VBoxContainer.new()
		box.position = Vector2(14+(i%5)*252,16+(i/5)*345)
		box.size = Vector2(240,320)
		canvas.add_child(box)
		label(box,list[i].name,21)
		picture(box,load(list[i].assets.card),128)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation",16)
		box.add_child(row)
		for mode in [1,2]: picture(row,load(list[i].assets.icon),48,mode)
func _make_inspector(item: Dictionary, dimensions: Vector2i) -> void:
	_base()
	var panel := PanelContainer.new()
	panel.position = Vector2(24,24)
	panel.size = Vector2(dimensions)-Vector2(48,48)
	panel.add_theme_stylebox_override("panel",load(item.assets.rarity_treatment))
	canvas.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",16)
	panel.add_child(box)
	label(box,item.name+" · "+item.rarity.capitalize(),30)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",32)
	box.add_child(row)
	picture(row,load(item.assets.card),192)
	if not item.assets.in_play.is_empty():
		_model(row,item,"ready")
		if item.id == "ball.ghost" and dimensions.x > 1000: _model(row,item,"solid")
		if item.id == "ball.splitter" and dimensions.x > 1000: _model(row,item,"split")
	label(box,item.category.capitalize()+" · authored identity preview",22)
	label(box,item.downside,24)
	label(box,"Native in-play and activation checks follow E18.",20)
	picture(box,load(item.assets.reduced_motion),48)
	label(box,"Static reduced identity",18)
func capture(name_value: String) -> void:
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(destination.path_join(name_value+".png"))==OK,"capture "+name_value)
