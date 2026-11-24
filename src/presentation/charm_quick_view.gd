extends Control
## UI-47 (owner, 2026-11-24): "make the in-game charm column tappable to extend out a
## quick view/bubble overlay with a short description of what that charm is/does."
## A tap on a Charm (or the kit) in the match's Charm rail opens a parchment bubble
## beside the rail, pointing at it: the item's name, its rarity and kind, and its
## rules in a few lines (its card's own text, and any tradeoff). A tap anywhere,
## the same Charm again, or a throw closes it; it also closes on its own after a
## while. It changes nothing in the game.
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
const PAPER := Color("f3e6c8")
const INK := Color("2b1a0e")
const EDGE := Color("8a6420")
const WIDTH := 300.0
const SECONDS := 6.0
signal dismissed(at: Vector2, closed_id: String) # the tap that closed it (global coordinates)

var bubble: PanelContainer
var title: Label
var kind: Label
var body: Label
var item_id := ""
var _anchor := Rect2()
var _toward_left := true
var _left := 0.0

func _init() -> void:
	name = "CharmQuickView"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP # the next tap anywhere closes it, and only that
	hide()
	bubble = PanelContainer.new()
	bubble.name = "Bubble"
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = EDGE
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	bubble.add_theme_stylebox_override("panel", style)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(column)
	title = _label(column, "Name", 22, Color("7a2e1a"))
	kind = _label(column, "Kind", 14, Color("6b5232"))
	body = _label(column, "Rules", 17, INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _label(parent: Control, node_name: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.custom_minimum_size.x = WIDTH - 28.0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

## Opens beside `anchor` (the tapped Charm's rect, in this view's coordinates); a
## second tap on the same Charm closes it.
func open(id: String, heading: String, subtitle: String, rules: String, anchor: Rect2, toward_left: bool) -> void:
	if visible and id == item_id:
		close()
		return
	item_id = id
	_anchor = anchor
	_toward_left = toward_left
	_left = SECONDS
	title.text = heading
	kind.text = subtitle
	kind.visible = not subtitle.is_empty()
	body.text = rules
	show()
	move_to_front()
	_place()

func close() -> void:
	hide()
	item_id = ""

## Beside the rail, toward the lane, level with the Charm, kept on screen.
func _place() -> void:
	bubble.reset_size()
	var size_now := bubble.get_combined_minimum_size()
	bubble.size = size_now
	var gap := 14.0
	var x := _anchor.position.x - gap - size_now.x if _toward_left else _anchor.end.x + gap
	var y := _anchor.get_center().y - size_now.y * 0.5
	x = clampf(x, 8.0, maxf(size.x - size_now.x - 8.0, 8.0))
	y = clampf(y, 8.0, maxf(size.y - size_now.y - 8.0, 8.0))
	bubble.position = Vector2(x, y)
	queue_redraw()

## The pointer from the bubble to the tapped Charm.
func _draw() -> void:
	if not visible: return
	var rect := Rect2(bubble.position, bubble.size)
	var tip_y := clampf(_anchor.get_center().y, rect.position.y + 16.0, rect.end.y - 16.0)
	var base_x := rect.end.x - 2.0 if _toward_left else rect.position.x + 2.0
	var tip_x := base_x + (12.0 if _toward_left else -12.0)
	var points := PackedVector2Array([Vector2(base_x, tip_y - 10.0), Vector2(tip_x, tip_y), Vector2(base_x, tip_y + 10.0)])
	draw_colored_polygon(points, PAPER)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2]]), EDGE, 3.0)

func _gui_input(event: InputEvent) -> void:
	# A touch also arrives as an emulated mouse press; one tap is handled once.
	if event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION: return
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		var closed := item_id
		close()
		accept_event()
		dismissed.emit(get_global_transform() * event.position, closed) # a tap on another Charm opens it

func _process(delta: float) -> void:
	if not visible: return
	_left -= delta
	if _left <= 0.0: close()
