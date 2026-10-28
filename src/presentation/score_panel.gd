extends PanelContainer
## Readable frame resolution: Pin Value × Mult counters, a flat ten-slot rack showing
## which roll took each pin, and the ordered calculation log revealed one step at a
## time at 1×/2×/4× (Skip shows everything). It only replays ScoreLog steps copied
## from the resolver, so nothing here can change the banked score.
## Developmental look; final presentation, VFX and audio are E12/E20.
signal step_revealed(step: Dictionary, index: int, skipped: bool)
signal finished
signal speed_changed(speed: int)
const Lane = preload("res://src/simulation/lane_spec.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
const STEP_SEC := 0.3
const SPEEDS := [1, 2, 4]
const ROLL_COLORS := [Color(0.95, 0.55, 0.25), Color(0.35, 0.8, 1.0)]
const HIGHLIGHT := Color(1.0, 0.9, 0.3)

var steps: Array = []
var shown := 0
var speed := 1
var playing := false
var reduced_motion := false
var _accent: Tween
var header: Label
var counters: Label
var rack_view: Control
var log_list: VBoxContainer
var log_scroll: ScrollContainer
var speed_button: Button
var skip_button: Button
var _roll_of: Dictionary = {}
var _standing: Array = []
var _timer := 0.0
var _skipping := false

func _ready() -> void:
	name = "ScorePanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.08, 0.98)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel", style)
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
	header_row.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	rack_view = Control.new()
	rack_view.name = "RackDiagram"
	rack_view.custom_minimum_size = Vector2(210, 190)
	rack_view.draw.connect(_draw_rack)
	row.add_child(rack_view)
	counters = Label.new()
	counters.name = "ScoreCounters"
	counters.add_theme_font_size_override("font_size", 34)
	counters.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counters.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(counters)
	log_scroll = ScrollContainer.new()
	log_scroll.custom_minimum_size = Vector2(0, 150)
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(log_scroll)
	log_list = VBoxContainer.new()
	log_list.name = "CalculationLog"
	log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_scroll.add_child(log_list)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	speed_button = Button.new()
	speed_button.name = "ScoreSpeed"
	speed_button.custom_minimum_size = Vector2(150, 56)
	speed_button.pressed.connect(_cycle_speed)
	buttons.add_child(speed_button)
	skip_button = Button.new()
	skip_button.name = "SkipScoring"
	skip_button.text = "Skip"
	skip_button.custom_minimum_size = Vector2(150, 56)
	skip_button.pressed.connect(skip)
	buttons.add_child(skip_button)
	_refresh_speed()

## reports: the frame's LaneWorld reports, used only for roll attribution.
func play(frame_steps: Array, reports: Array, title: String, play_speed: int) -> void:
	steps = frame_steps
	speed = play_speed if play_speed in SPEEDS else 1
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
	skip_button.disabled = false
	_refresh_speed()
	show()
	_reveal()

func _process(delta: float) -> void:
	if not playing:
		return
	_timer += delta * speed
	while playing and _timer >= STEP_SEC:
		_timer -= STEP_SEC
		_reveal()

func _reveal() -> void:
	if shown >= steps.size():
		_finish()
		return
	var step: Dictionary = steps[shown]
	step_revealed.emit(step, shown, _skipping)
	var line := Label.new()
	line.text = "%s  %s" % [step.symbol, step.text] if not step.symbol.is_empty() else step.text
	line.add_theme_font_size_override("font_size", 22)
	if step.symbol == "×":
		line.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	elif step.phase == "bank":
		line.add_theme_color_override("font_color", HIGHLIGHT)
	log_list.add_child(line)
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
	skip_button.disabled = true
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

func _cycle_speed() -> void:
	speed = SPEEDS[(SPEEDS.find(speed) + 1) % SPEEDS.size()]
	_refresh_speed()
	speed_changed.emit(speed)

func _refresh_speed() -> void:
	speed_button.text = "Speed %d×" % speed

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
