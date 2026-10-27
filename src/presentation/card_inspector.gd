extends Control
## Inspection never plays cards or changes their rarity. Finish samples are visual only.
signal closed
const FINISHES = ["Common — matte", "Uncommon — metal", "Rare — border foil", "Epic — full foil", "Legendary — crown reveal"]
const COLORS = [Color("c4b69b"),Color("bb935b"),Color("75cbd1"),Color("c691d9"),Color("e9b768")]
var panel: PanelContainer
var art: TextureRect
var title: Label
var detail: Label
var finish: OptionButton
var close_button: Button
var skip_button: Button
var foil: ShaderMaterial
var reduced := false
var revealing := false
var reveal_count := 0
var selected_uid := ""
var _origin: Control
var _tween: Tween
var _base_index := 0

func _ready() -> void:
	name = "CardInspector"
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.03,0.07,0.96)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	shade.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(shade)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(PRESET_CENTER)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101820")
	style.border_color = Color("e7bc70")
	style.set_border_width_all(3)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	panel.add_child(box)
	title = Label.new()
	title.add_theme_font_size_override("font_size",28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	art = TextureRect.new()
	art.custom_minimum_size = Vector2(280,300)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = TEXTURE_FILTER_NEAREST
	art.mouse_filter = MOUSE_FILTER_IGNORE
	foil = ShaderMaterial.new()
	foil.shader = load("res://assets/motion/foil.gdshader")
	art.material = foil
	box.add_child(art)
	detail = Label.new()
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size",20)
	box.add_child(detail)
	finish = OptionButton.new()
	finish.name = "FinishSample"
	for label in FINISHES: finish.add_item(label)
	finish.custom_minimum_size.y = 48
	finish.item_selected.connect(_finish_selected)
	box.add_child(finish)
	var hint := Label.new()
	hint.text = "Finish preview · item stats stay unchanged\nDrag artwork to tilt · Escape to close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size",17)
	box.add_child(hint)
	var row := HBoxContainer.new()
	box.add_child(row)
	skip_button = Button.new()
	skip_button.name = "SkipReveal"
	skip_button.text = "Skip reveal"
	skip_button.custom_minimum_size = Vector2(170,52)
	skip_button.pressed.connect(skip_reveal)
	row.add_child(skip_button)
	close_button = Button.new()
	close_button.name = "CloseInspection"
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(170,52)
	close_button.pressed.connect(dismiss)
	row.add_child(close_button)
	hide()

static func illustration(index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/art_direction/card-art.png")
	var width := atlas.atlas.get_width()/5.0
	atlas.region = Rect2(index*width,0,width,atlas.atlas.get_height())
	return atlas

func inspect(card: Dictionary, origin: Control, reduce: bool) -> void:
	_origin = origin
	reduced = reduce
	selected_uid = card.uid
	_base_index = int(card.get("art_index",0))
	title.text = card.title
	detail.text = "%s · %s\n%s" % [card.kind.capitalize(),card.get("rarity","common").capitalize(),card.detail]
	show()
	finish.select(0)
	_finish_selected(0)
	close_button.grab_focus()

func _finish_selected(index: int) -> void:
	skip_reveal()
	art.texture = illustration(4 if index == 4 else _base_index)
	foil.set_shader_parameter("strength",[0.0,0.15,0.65,0.8,0.9][index])
	foil.set_shader_parameter("border_only",index <= 2)
	foil.set_shader_parameter("tilt",Vector2.ZERO)
	if index == 4:
		reveal_count += 1
		if not reduced:
			revealing = true
			skip_button.disabled = false
			art.pivot_offset = art.size/2
			art.scale = Vector2.ONE*0.9
			art.modulate.a = 0.2
			_tween = create_tween().set_parallel(true)
			_tween.tween_property(art,"scale",Vector2.ONE,0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_tween.tween_property(art,"modulate:a",1.0,0.32)
			_tween.chain().tween_callback(skip_reveal)

func skip_reveal() -> void:
	if _tween and _tween.is_running(): _tween.kill()
	revealing = false
	if art:
		art.scale = Vector2.ONE
		art.modulate = Color.WHITE
		art.rotation = 0
	if skip_button: skip_button.disabled = true

func dismiss() -> void:
	skip_reveal()
	hide()
	if is_instance_valid(_origin) and not _origin.disabled: _origin.grab_focus()
	closed.emit()

func _process(_delta: float) -> void:
	if not visible: return
	art.custom_minimum_size.y = 250 if size.x > size.y else 330
	panel.size = panel.get_combined_minimum_size()
	panel.position = (size-panel.size)/2

func _input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("ui_cancel"):
		dismiss()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		var at: Vector2 = event.position
		if art.get_global_rect().has_point(at):
			var tilt := ((at-art.global_position)/art.size-Vector2.ONE*0.5)*2
			if reduced: tilt = Vector2.ZERO
			foil.set_shader_parameter("tilt",tilt)
			if not revealing:
				art.pivot_offset = art.size/2
				art.rotation = tilt.x*0.045
			get_viewport().set_input_as_handled()
