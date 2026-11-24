extends VBoxContainer
## UI-43 (owner, 2026-11-23): "The text for the throw instructions/alerts need to be
## cleaned up instead of a wall of text under the ball. They should not obstruct
## gameplay view, and be temporary instruction." Owner's direction: brief toasts just
## above the cards at the start of every aim; the aim hint stays until the player
## touches the ball.
## Just above the hand: one brief toast at a time (rules, the lane, tactics in play,
## alerts), each for SECONDS, the rest queued (an alert goes first); under it the aim
## hint (the lab's Prompt label) in a pill, shown while the lab asks for it. One toast
## and the hint fit between the ball and the cards on a phone.
const SECONDS := 2.2
const FADE := 0.35
const INK := Color("f4e9cf")
const ALERT := Color("ffb08a")

var reduced_motion := false
var hint_pill: PanelContainer
var hint: Label
var _toasts: Array = [] # the toast showing: [{node, left}] or []
var _queue: Array = [] # [{text, alert}] waiting their turn
var _bottom := 0.0
var top_limit := -INF # the ball's lower edge: the stack never rises above it
var hint_wanted := false # the lab asks for the hint; it shows unless a toast needs its room
var avoid: Control # the assist panel: the stack keeps to the free side beside it
var _base := Rect2()
var _width := 0.0 # the span's width, which lines wrap to

func _init(prompt: Label) -> void:
	name = "ThrowToasts"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_END
	add_theme_constant_override("separation", 6)
	hint = prompt
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF # wrapped here (_wrap), so its size is known at once
	hint_pill = _pill("PromptPill", Color("64dacb"))
	hint_pill.add_child(hint)
	add_child(hint_pill)

func _pill(node_name: String, edge: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.name = node_name
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.08, 0.84)
	style.border_color = Color(edge, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	pill.add_theme_stylebox_override("panel", style)
	return pill

## A brief notice; `alert` marks one the player caused (a refused card, no throw).
func show_toast(text: String, alert: bool = false) -> void:
	if alert:
		_queue.push_front({"text": text, "alert": true})
		clear_showing()
	else:
		_queue.append({"text": text, "alert": false})
	if _toasts.is_empty(): _next()

func _next() -> void:
	if _queue.is_empty(): return
	var waiting: Dictionary = _queue.pop_front()
	var text: String = waiting.text
	var alert: bool = waiting.alert
	var pill := _pill("Toast", ALERT if alert else Color("c9a45c"))
	var label := Label.new()
	label.name = "ToastText"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_meta("words", text)
	label.add_theme_font_size_override("font_size", hint.get_theme_font_size("font_size"))
	label.add_theme_color_override("font_color", ALERT if alert else INK)
	pill.add_child(label)
	add_child(pill)
	move_child(hint_pill, get_child_count() - 1)
	_toasts.append({"node": pill, "left": SECONDS})
	_fit()

## The toast showing now, then those waiting, as written (tests read them).
func texts() -> Array:
	return _toasts.map(func(t): return String(t.node.get_node("ToastText").get_meta("words"))) + _queue.map(func(q): return q.text)

## The aim hint as the lab wrote it (before it was broken into lines).
func hint_text() -> String:
	return String(hint.get_meta("words", hint.text)) if hint.text == String(hint.get_meta("wrapped", "")) else hint.text

func clear_showing() -> void:
	while not _toasts.is_empty():
		_drop(0)

func clear_toasts() -> void:
	_queue.clear()
	clear_showing()

func _drop(index: int) -> void:
	var node: Control = _toasts[index].node
	_toasts.remove_at(index)
	remove_child(node)
	node.queue_free()
	_fit()

## Width and bottom edge: the stack sits on the line just above the hand.
func place(rect: Rect2) -> void:
	_base = rect
	_bottom = rect.position.y
	_span()
	_fit()

## Where the stack goes across: the given line, less the side the assist panel
## takes when it stands beside the stack (read each frame; the panel moves).
func _span() -> bool:
	var r := _base
	if avoid != null and avoid.visible and avoid.get_parent() == get_parent():
		var a := avoid.get_rect()
		if a.position.y < _bottom and a.end.y > _bottom - 160.0:
			if a.position.x > r.position.x + r.size.x * 0.25:
				r.size.x = maxf(a.position.x - r.position.x - 8.0, 120.0)
			else:
				r.size.x = maxf(r.end.x - a.end.x - 8.0, 120.0)
				r.position.x = a.end.x + 8.0
	var moved := not is_equal_approx(r.size.x, _width) or not is_equal_approx(r.position.x, position.x)
	_width = r.size.x
	custom_minimum_size.x = r.size.x
	size.x = r.size.x
	position.x = r.position.x
	return moved

func _fit() -> void:
	# A label wraps within the stack's width, less its pill's margins.
	# Each line is broken here to the stack's width (less the pill's margins), so a
	# pill's size is exact as soon as it is made (a wrapping label's is not until it
	# has been laid out).
	var room := maxf(_width - 28.0, 60.0)
	for pill in get_children():
		var label: Label = pill.get_child(0)
		var words: String = label.get_meta("words", "") if label.has_meta("words") else label.text
		if label == hint: words = String(hint.get_meta("words", hint.text)) if hint.text == String(hint.get_meta("wrapped", "")) else hint.text
		var wrapped := _wrap(words, label.get_theme_font("font"), label.get_theme_font_size("font_size"), room)
		if label == hint:
			hint.set_meta("words", words)
			hint.set_meta("wrapped", wrapped)
		label.text = wrapped
	_settle()

## Breaks `text` into lines no wider than `room` at word boundaries (its own line
## breaks kept).
static func _wrap(text: String, font: Font, font_size: int, room: float) -> String:
	if font == null: return text
	var out: Array = []
	for paragraph in text.split("\n"):
		var line := ""
		for word in paragraph.split(" ", false):
			var tried: String = word if line.is_empty() else line + " " + word
			if line.is_empty() or font.get_string_size(tried, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= room:
				line = tried
			else:
				out.append(line)
				line = word
		out.append(line)
	return "\n".join(out)

## Keeps the stack's bottom on the line above the hand as its contents change.
## The height is the visible pills' own (a container's cached minimum can lag a
## frame behind a label that just wrapped).
func _settle() -> void:
	# The hint and a toast together may not fit between the ball and the cards (a
	# short screen, the hand raised): the toast then takes the hint's place while it
	# shows, so the ball is never covered.
	var crowded := false
	if hint_wanted and not _toasts.is_empty():
		var both: float = hint_pill.get_combined_minimum_size().y + _toasts[0].node.get_combined_minimum_size().y + get_theme_constant("separation")
		crowded = _bottom - both < top_limit
	hint_pill.visible = hint_wanted and not crowded
	var height := 0.0
	var shown := 0
	for pill in get_children():
		if not (pill as Control).visible: continue
		height += (pill as Control).get_combined_minimum_size().y
		shown += 1
	height += maxf(shown - 1, 0) * get_theme_constant("separation")
	size = Vector2(size.x, height)
	position.y = _bottom - height

func _process(delta: float) -> void:
	if visible:
		if _span(): _fit()
		else: _settle()
	var i := 0
	while i < _toasts.size():
		var toast: Dictionary = _toasts[i]
		toast.left -= delta
		if toast.left <= 0.0:
			_drop(i)
			_next()
			continue
		if not reduced_motion and toast.left < FADE:
			toast.node.modulate.a = toast.left / FADE
		i += 1
