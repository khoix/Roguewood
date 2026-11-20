extends Control
## Inspection never plays cards or changes their rarity. It shows the card in its own
## finish, which tilts with the pointer (owner, 2026-11-18: no finish preview, no reveal).
const ItemAssets = preload("res://src/presentation/item_assets.gd")
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
const CardView = preload("res://src/presentation/card_view.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
var _item_texture: Texture2D
var _default_frame: StyleBox
signal closed
const COLORS = [Color("c4b69b"),Color("bb935b"),Color("75cbd1"),Color("c691d9"),Color("e9b768")]
var panel: PanelContainer
var art: TextureRect # the card's illustration (UI-1: inside the full-size card)
var card_view: CardView
var title: Label
var detail: Label
var close_button: Button
## The whole card tilts as one unit (owner, 2026-11-19): it renders into its own
## view, which a perspective shader turns toward the pointer.
const TILT_RADIANS := 0.3 # at the card's edge
const TILT_PAD := 0.08 # empty share of the view on each side, room for the nearer corners
var card_slot: Control # the card's place in the layout
var tilt_view: SubViewportContainer
var card_port: SubViewport
var tilt_material: ShaderMaterial
## UI-A2: the card's own rarity material (the old illustration foil is off, so the
## two never double up). Tilt drives its phase.
var foil: ShaderMaterial:
	get: return card_view.sheen.material if card_view else null
var tilt := Vector2.ZERO
var reduced := false
var selected_uid := ""
var _origin: Control

func _ready() -> void:
	name = "CardInspector"
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = UiTheme.SCRIM # UI-35: one scrim behind every overlay
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
	card_slot = Control.new()
	card_slot.name = "CardSlot"
	card_slot.custom_minimum_size = Vector2(240, 344)
	card_slot.mouse_filter = MOUSE_FILTER_IGNORE
	card_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(card_slot)
	tilt_view = SubViewportContainer.new()
	tilt_view.name = "TiltView"
	tilt_view.mouse_filter = MOUSE_FILTER_IGNORE
	tilt_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tilt_material = ShaderMaterial.new()
	tilt_material.shader = preload("res://src/presentation/card_tilt.gdshader")
	tilt_view.material = tilt_material
	card_slot.add_child(tilt_view)
	card_port = SubViewport.new()
	card_port.transparent_bg = true
	card_port.size_2d_override_stretch = true
	tilt_view.add_child(card_port)
	card_view = CardView.new()
	card_view.name = "InspectedCard"
	card_view.custom_minimum_size = Vector2(240, 344)
	card_view.focus_mode = Control.FOCUS_NONE
	card_view.mouse_filter = MOUSE_FILTER_IGNORE
	card_port.add_child(card_view)
	art = card_view.art
	detail = Label.new()
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size",20)
	box.add_child(detail)
	var hint := Label.new()
	# A phone has no Escape key; Close is the button below.
	hint.text = "Drag the card to tilt it" + ("" if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") else " · Escape to close")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size",17)
	box.add_child(hint)
	close_button = Button.new()
	close_button.name = "CloseInspection"
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(170,52)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(dismiss)
	box.add_child(close_button)
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
	# The card's own finish (a card without its own art keeps the plain one).
	art.texture = _item_texture if _item_texture else illustration(int(card.get("art_index", 0)))
	card_view.preview_material(str(card.get("rarity", "common")) if _item_texture else "common")
	_settle()
	close_button.grab_focus()

func _settle() -> void:
	tilt = Vector2.ZERO
	if art:
		art.scale = Vector2.ONE
		art.modulate = Color.WHITE
		art.rotation = 0
	_apply_tilt()

## Turns the whole card toward the pointer (none under reduced motion), and moves
## its rarity material's phase with it (UI-A2).
func _apply_tilt() -> void:
	if tilt_material:
		tilt_material.set_shader_parameter("tilt", Vector2(-tilt.x, tilt.y) * TILT_RADIANS)
	if card_view:
		card_view.tilt_material(tilt)

## Where a drag tilts the card: the card's place on screen.
func tilt_area() -> Rect2:
	return card_slot.get_global_rect()

func dismiss() -> void:
	_settle()
	hide()
	if is_instance_valid(_origin) and not _origin.disabled: _origin.grab_focus()
	closed.emit()

func _process(_delta: float) -> void:
	if not visible: return
	_fit_card(Vector2(210, 300) if size.x > size.y else Vector2(240, 344))
	panel.size = panel.get_combined_minimum_size()
	panel.position = (size-panel.size)/2

## Lays the card out at `card` (its inspection size) inside a view TILT_PAD larger
## on each side, rendered at the screen's own pixel density so it stays sharp.
func _fit_card(card: Vector2) -> void:
	card_slot.custom_minimum_size = card
	var pad := (card * TILT_PAD).round()
	var logical := card + pad * 2.0
	var density := clampf(get_viewport().get_final_transform().get_scale().x, 1.0, 4.0)
	var pixels := Vector2i((logical * density).ceil())
	if card_port.size != pixels:
		card_port.size = pixels
	card_port.size_2d_override = Vector2i(logical)
	tilt_view.size = Vector2(pixels)
	tilt_view.scale = logical / Vector2(pixels)
	tilt_view.position = -pad
	card_view.custom_minimum_size = card
	card_view.position = pad
	card_view.size = card
	tilt_material.set_shader_parameter("margin", pad / logical)
	tilt_material.set_shader_parameter("card_aspect", card.x / card.y)

func _input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("ui_cancel"):
		dismiss()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		var at: Vector2 = event.position
		var area := tilt_area()
		if area.has_point(at):
			tilt = (((at - area.position) / area.size - Vector2.ONE * 0.5) * 2).clamp(-Vector2.ONE, Vector2.ONE)
			if reduced: tilt = Vector2.ZERO
			_apply_tilt()
			get_viewport().set_input_as_handled()
		elif tilt != Vector2.ZERO:
			# Off the card: it settles flat, and its material to its rest phase (UI-A2).
			tilt = Vector2.ZERO
			_apply_tilt()
