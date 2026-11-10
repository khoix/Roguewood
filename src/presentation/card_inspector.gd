extends Control
## Inspection never plays cards or changes their rarity. Finish samples are visual only.
const ItemAssets = preload("res://src/presentation/item_assets.gd")
const CardView = preload("res://src/presentation/card_view.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
var _item_texture: Texture2D
var _default_frame: StyleBox
signal closed
const FINISHES = ["Common — matte", "Uncommon — metal", "Rare — border foil", "Epic — full foil", "Legendary — crown reveal"]
const COLORS = [Color("c4b69b"),Color("bb935b"),Color("75cbd1"),Color("c691d9"),Color("e9b768")]
var panel: PanelContainer
var art: TextureRect # the card's illustration (UI-1: inside the full-size card)
var card_view: CardView
var title: Label
var detail: Label
var finish: OptionButton
var close_button: Button
var skip_button: Button
## UI-A2: the card's own rarity material (the old illustration foil is off, so the
## two never double up). Tilt drives its phase.
var foil: ShaderMaterial:
	get: return card_view.sheen.material if card_view else null
var tilt := Vector2.ZERO
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
	# UI-2: the House menu frame unless the item has its own rarity treatment.
	var style := preload("res://src/presentation/house_ui_theme.gd").frame("menu", 20.0, 18.0)
	_default_frame = style
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	panel.add_child(box)
	title = Label.new()
	title.add_theme_font_size_override("font_size",28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	# UI-1: inspection shows the whole playing card at its inspection size (UI-A1:
	# 240×344 portrait, 210×300 landscape); tilt drives its UI-A2 rarity material.
	card_view = CardView.new()
	card_view.name = "InspectedCard"
	card_view.custom_minimum_size = Vector2(240, 344)
	card_view.focus_mode = Control.FOCUS_NONE
	card_view.mouse_filter = MOUSE_FILTER_IGNORE
	card_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(card_view)
	art = card_view.art
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
	# A phone has no Escape key; Close is the button below.
	hint.text = "Finish preview · item stats stay unchanged\nDrag artwork to tilt" + ("" if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") else " · Escape to close")
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
	_item_texture = ItemAssets.slot(ItemAssets.identify(card), "reduced_motion" if reduce else "card") as Texture2D
	var frame := ItemAssets.slot(ItemAssets.identify(card), "rarity_treatment") as StyleBox
	panel.add_theme_stylebox_override("panel", frame if frame else _default_frame)
	_origin = origin
	reduced = reduce
	selected_uid = card.uid
	_base_index = int(card.get("art_index",0))
	var item_id := ItemAssets.identify(card)
	title.text = card.title
	card_view.reduced_motion = reduce
	card_view.visible = true
	card_view.set_item(item_id, {}, str(card.title), illustration(int(card.get("art_index", 0))))
	ItemAssets._ensure()
	var rules: String = ScoreLog.item_text(ItemAssets._items.get(item_id, {})) if ItemAssets._items.has(item_id) else str(card.detail)
	# Full rules live here; the card face carries only the short rule.
	detail.text = "%s · %s\n%s" % [card.kind.capitalize(),card.get("rarity","common").capitalize(),rules]
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.x = 420
	show()
	var initial := ["common", "uncommon", "rare", "epic", "legendary"].find(card.get("rarity", "common")) if _item_texture else 0
	finish.select(initial)
	_finish_selected(initial)
	close_button.grab_focus()

func _finish_selected(index: int) -> void:
	skip_reveal()
	art.texture = _item_texture if _item_texture else illustration(4 if index == 4 else _base_index)
	card_view.preview_material(["common", "uncommon", "rare", "epic", "legendary"][index])
	tilt = Vector2.ZERO
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
	card_view.custom_minimum_size = Vector2(210, 300) if size.x > size.y else Vector2(240, 344)
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
			tilt = (((at-art.global_position)/art.size-Vector2.ONE*0.5)*2).clamp(-Vector2.ONE, Vector2.ONE)
			if reduced: tilt = Vector2.ZERO
			card_view.tilt_material(tilt)
			if not revealing:
				art.pivot_offset = art.size/2
				art.rotation = tilt.x*0.045
			get_viewport().set_input_as_handled()
		elif tilt != Vector2.ZERO:
			# Off the art: the material settles to its rest phase (UI-A2).
			tilt = Vector2.ZERO
			card_view.tilt_material(tilt)
			art.rotation = 0
