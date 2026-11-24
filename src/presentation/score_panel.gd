extends PanelContainer
## Readable frame resolution: Pin Value × Mult counters, a flat ten-slot rack showing
## which roll took each pin, and the ordered calculation log revealed one step at a
## time at 1×/2×/4× (Skip shows everything). It only replays ScoreLog steps copied
## from the resolver, so nothing here can change the banked score.
## Developmental look; final presentation, VFX and audio are E12/E20.
signal step_revealed(step: Dictionary, index: int, skipped: bool)
signal finished
const Lane = preload("res://src/simulation/lane_spec.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
const STEP_SEC := 0.3
const ROLL_COLORS := [Color(0.95, 0.55, 0.25), Color(0.35, 0.8, 1.0)]
const HIGHLIGHT := Color(1.0, 0.9, 0.3)
const ICONS := "res://assets/ui/cards/"

var steps: Array = []
var shown := 0
var playing := false
var reduced_motion := false
var _accent: Tween
var header: Label
var counters: Label
var rack_view: Control
var log_list: VBoxContainer
var log_scroll: ScrollContainer
var hint: Label
var _taken_frame := -1
var _roll_of: Dictionary = {}
var _standing: Array = []
var _timer := 0.0
var _skipping := false
## UI-8 (owner's play notes, 2026-11-15): the log's text is sized to the review's
## width (the longest line of the frame fills it, between these sizes) instead of a
## fixed 21 px that left half the panel empty.
const LOG_MIN := 21
const LOG_MAX := 32
var log_font := LOG_MIN

func _ready() -> void:
	name = "ScorePanel"
	add_theme_stylebox_override("panel", preload("res://src/presentation/house_ui_theme.gd").frame("menu", 20.0, 16.0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var header_row := HBoxContainer.new()
	header_row.custom_minimum_size.y = 64
	box.add_child(header_row)
	header = Label.new()
	header.name = "ScoreHeader"
	header.add_theme_font_size_override("font_size", 30)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_row.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER # UI-3: the review is centred
	box.add_child(row)
	rack_view = Control.new()
	rack_view.name = "RackDiagram"
	rack_view.custom_minimum_size = Vector2(210, 190)
	rack_view.draw.connect(_draw_rack)
	# UI-49 (owner, 2026-11-24: "the pin status is moving laterally with text changes
	# and needs to be fixed in place"): the rack and the counters each hold half the
	# row, so the rack no longer re-centres as the numbers change width.
	rack_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(rack_view)
	counters = Label.new()
	counters.name = "ScoreCounters"
	counters.add_theme_font_size_override("font_size", 34)
	counters.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	counters.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counters.clip_text = true
	row.add_child(counters)
	log_scroll = ScrollContainer.new()
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	log_scroll.custom_minimum_size = Vector2(0, 150)
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(log_scroll)
	log_list = VBoxContainer.new()
	log_list.name = "CalculationLog"
	log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_scroll.add_child(log_list)
	log_scroll.resized.connect(_fit_log)
	# UI-5 (owner, 2026-11-10): no Speed or Skip buttons. While the chain is still
	# counting, a tap on the review (or the accept key) finishes it at once.
	focus_mode = Control.FOCUS_ALL
	hint = Label.new()
	hint.name = "FinishHint"
	hint.text = "Tap to finish"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hint)

## A press anywhere on the review finishes a reveal that is still counting. The
## press is taken, so it never also lands on a chain line under the finger.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	var press: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not press or not get_global_rect().has_point(event.position):
		return
	if playing:
		_taken_frame = Engine.get_process_frames()
		skip()
		get_viewport().set_input_as_handled()
	elif _taken_frame == Engine.get_process_frames():
		get_viewport().set_input_as_handled() # the mouse press a touch also sends

func _gui_input(event: InputEvent) -> void:
	if playing and event.is_action_pressed("ui_accept"):
		skip()
		accept_event()

## UI-3: a shorter, centred review for portrait phones; the full size otherwise.
func fit(portrait: bool) -> void:
	header.get_parent().custom_minimum_size.y = 40 if portrait else 64
	header.add_theme_font_size_override("font_size", 26 if portrait else 30)
	# UI-49 (owner: the Charm note above "is being overlapped by the pin status"):
	# the back row and its ring are drawn 174 px above the rack's bottom, so the rack
	# is tall enough to hold them (portrait was 160 px; the rings rose above it).
	rack_view.custom_minimum_size = Vector2(190, 184) if portrait else Vector2(210, 190)
	_counter_size = 32 if portrait else 34
	counters.add_theme_font_size_override("font_size", _counter_size)
	log_scroll.custom_minimum_size.y = 72 if portrait else 150

## reports: the frame's LaneWorld reports, used only for roll attribution.
## `_pace` is accepted and ignored: the reveal has one pace since UI-5, and the art
## journeys that replay a frame still pass the speed they used to choose.
func play(frame_steps: Array, reports: Array, title: String, _pace: int = 1) -> void:
	steps = frame_steps
	shown = 0
	_timer = 0.0
	playing = true
	header.text = title
	_roll_of = {}
	for report in reports:
		for position in report.roll_result.fallen_positions:
			_roll_of[int(position)] = int(report.roll_result.roll_index)
	_standing = reports[-1].knockdown_log.standing.duplicate()
	for child in log_list.get_children():
		child.queue_free()
	_fit_log()
	hint.modulate.a = 1.0
	show()
	if is_inside_tree() and get_viewport().gui_get_focus_owner() == null: grab_focus()
	_reveal()

func _process(delta: float) -> void:
	if not playing:
		return
	_timer += delta
	while playing and _timer >= STEP_SEC:
		_timer -= STEP_SEC
		_reveal()

func _reveal() -> void:
	if shown >= steps.size():
		_finish()
		return
	var step: Dictionary = steps[shown]
	step_revealed.emit(step, shown, _skipping)
	log_list.add_child(_chain_line(step))
	var line: Control = log_list.get_child(-1)
	if not reduced_motion:
		line.modulate.a = 0.45
		create_tween().tween_property(line, "modulate:a", 1.0, 0.16)
	_scroll_to_end()
	shown += 1
	_refresh_counters()
	if _accent and _accent.is_running(): _accent.kill()
	counters.modulate = Color.WHITE
	if not reduced_motion:
		counters.modulate = Color(0.65, 1.0, 0.9)
		_accent = create_tween()
		_accent.tween_property(counters, "modulate", Color.WHITE, 0.2)
	rack_view.queue_redraw()
	if shown >= steps.size():
		_finish()

## UI-2: one link of the ordered score chain: the step's icon (pin, Value, Mult or
## $) then its text. A flat, untouchable Button so `text` stays the step's words.
func _chain_line(step: Dictionary) -> Button:
	var line := Button.new()
	line.text = "%s  %s" % [step.symbol, step.text] if not step.symbol.is_empty() else step.text
	line.flat = true
	line.focus_mode = Control.FOCUS_NONE
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.alignment = HORIZONTAL_ALIGNMENT_LEFT
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.icon = load(ICONS + _chain_icon(step) + ".svg")
	_style_line(line)
	for key in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		line.add_theme_stylebox_override(key, StyleBoxEmpty.new())
	var color := Color("f4e6cd")
	if step.symbol == "×":
		color = Color(1.0, 0.45, 0.45)
	elif step.phase == "bank":
		color = HIGHLIGHT
	elif step.phase == "after_bank":
		color = Color("95d9cb")
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
		line.add_theme_color_override(key, color)
	return line

func _style_line(line: Button) -> void:
	line.add_theme_constant_override("icon_max_width", int(round(log_font * ICON_SCALE)))
	line.add_theme_constant_override("h_separation", int(LOG_SEPARATION))
	line.add_theme_font_size_override("font_size", log_font)

## The log's size for this frame: the LOG_FIT_SHARE line, measured at LOG_MIN, scaled to
## the room beside its icon; lines already shown follow.
## UI-9 (owner's play notes, 2026-11-15): the icon grows with the font (ICON_SCALE),
## so it is solved together with the text: at size s a line takes
## s × (longest / LOG_MIN + ICON_SCALE) plus the separation. Before, the icon was
## budgeted at a fixed 24 px, so a scaled-up longest line ran past the room and wrapped.
const ICON_SCALE := 1.15
const LOG_SEPARATION := 10.0
const LOG_SLACK := 6.0 # glyph rounding at larger sizes; a fitted line must never wrap at the chosen size
## UI-12 (owner's play notes, 2026-11-16): sizing by the single longest line let one long
## trigger line in a later frame shrink the whole log. The size now fits the line at this
## share of the frame's lines (shortest first); the few longer lines wrap instead.
const LOG_FIT_SHARE := 0.75
func _fit_log() -> void:
	if steps.is_empty() or log_scroll == null or log_scroll.size.x <= 0.0: return
	var font := get_theme_default_font()
	var widths: Array[float] = []
	for step in steps:
		var text: String = "%s  %s" % [step.symbol, step.text] if not String(step.get("symbol", "")).is_empty() else String(step.text)
		widths.append(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LOG_MIN).x)
	widths.sort()
	var longest := maxf(1.0, widths[int(floor((widths.size() - 1) * LOG_FIT_SHARE))])
	var room := log_scroll.size.x - 16.0 - LOG_SEPARATION - LOG_SLACK # the scroll bar's room and the icon's separation
	var wanted := clampi(int(floor(room / (longest / LOG_MIN + ICON_SCALE))), LOG_MIN, LOG_MAX)
	if wanted == log_font: return
	log_font = wanted
	for line in log_list.get_children():
		if line is Button: _style_line(line)

## The card icon for a chain step (docs/art/ui: the score/category masters).
static func _chain_icon(step: Dictionary) -> String:
	var text := String(step.get("text", ""))
	match String(step.get("phase", "")):
		"category", "fallen": return "pin"
		"bank": return "value"
		"accuracy": return "mult" if text.ends_with("Mult") else "value" # BAL-1: a clean release adds Value
	if text.contains("+$") or text.contains(" $"): return "money"
	if text.ends_with("Mult") or text.contains(" Mult (") or step.get("symbol", "") == "×": return "mult"
	return "value"

## Waits for the new line's layout, then keeps the latest step in view.
func _scroll_to_end() -> void:
	await get_tree().process_frame
	if is_instance_valid(log_scroll):
		log_scroll.scroll_vertical = int(log_scroll.get_v_scroll_bar().max_value)

func skip() -> void:
	_skipping = true
	while playing:
		_reveal()
	_skipping = false

func _finish() -> void:
	if not playing:
		return
	playing = false
	hint.modulate.a = 0.0 # keeps its line, so the review does not jump
	finished.emit()

## Counters show the numbers of the last revealed step, never recomputed ones.
func displayed() -> Dictionary:
	if shown == 0:
		return {}
	var step: Dictionary = steps[shown - 1]
	return {"pin_value": step.pin_value, "mult": step.mult, "score": step.get("score", -1), "step": shown}

func _refresh_counters() -> void:
	var now := displayed()
	if now.is_empty():
		counters.text = ""
		return
	counters.text = "%s Value\n× %s Mult" % [ScoreLog._n(now.pin_value), ScoreLog._n(now.mult)]
	if now.score >= 0:
		counters.text += "\n= %s" % ScoreLog._n(now.score)
	_fit_counters()

var _counter_size := 34
## UI-49: large numbers shrink to fit the counters' half of the row (they ran off
## the panel's edge).
func _fit_counters() -> void:
	var room := counters.size.x
	if room <= 0.0: return
	var font := counters.get_theme_font("font")
	var px := _counter_size
	while px > 16 and font.get_multiline_string_size(counters.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > room:
		px -= 2
	counters.add_theme_font_size_override("font_size", px)

func current_pin() -> int:
	return steps[shown - 1].pin if shown > 0 and playing else 0

## Flat ten-slot rack, head pin nearest: colour shows which roll took each pin,
## an outline means it stood; the pin being scored is ringed.
func _draw_rack() -> void:
	var view_size := rack_view.size
	var font := get_theme_default_font()
	for position in range(1, 11):
		var at := Lane.spot(position)
		var center := Vector2(view_size.x * 0.5 + at.x / Lane.PIN_SPACING * 44.0, view_size.y - 44.0 - (at.y - Lane.HEAD_PIN_F) / Lane.ROW_SPACING * 36.0)
		var roll: int = _roll_of.get(position, 0)
		if roll > 0:
			rack_view.draw_circle(center, 17.0, ROLL_COLORS[roll - 1])
		else:
			rack_view.draw_arc(center, 16.0, 0.0, TAU, 24, Color.WHITE, 3.0, true)
		if current_pin() == position:
			rack_view.draw_arc(center, 22.0, 0.0, TAU, 24, HIGHLIGHT, 4.0, true)
		var label := str(position)
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		rack_view.draw_string(font, center + Vector2(-width * 0.5, 6.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.BLACK if roll > 0 else Color.WHITE)
	var legend := Vector2(4.0, view_size.y - 6.0)
	for roll in 2:
		rack_view.draw_circle(legend + Vector2(6.0 + roll * 70.0, -5.0), 6.0, ROLL_COLORS[roll])
		rack_view.draw_string(font, legend + Vector2(16.0 + roll * 70.0, 0.0), "roll %d" % (roll + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.8))
	rack_view.draw_arc(legend + Vector2(146.0, -5.0), 6.0, 0.0, TAU, 12, Color.WHITE, 2.0, true)
	rack_view.draw_string(font, legend + Vector2(156.0, 0.0), "stood", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.8))
