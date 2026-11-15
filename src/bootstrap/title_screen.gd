extends Control
## UI-7: the title screen, shown when the game starts (owner's play notes, 2026-11-15:
## the engine's loading screen was standing in for one). The House hall at night,
## the ROGUEWOOD wordmark, the House Ball rolling slowly, and "Tap to start". A
## tap, a click, a key or a gamepad button starts; the Clubhouse is underneath.
## Reduced motion keeps the ball and the prompt still. A view only: the shell
## decides when it shows and what follows (`started`).
## Provisional art (docs/handoffs/UI-7.md): Codex's House backdrop and House Ball
## with the bundled font as lettering, until Codex's logo and key art land.
signal started

const FONT = preload("res://assets/ui/fonts/PixelifySans.ttf")
const BACKDROP = preload("res://assets/leagues/house/backdrop.league.house.division_01.tres")
const BALL_SOURCE = preload("res://assets/items/balls/a01-source.png")
## The House Ball alone (its card art has a shadow fragment below it), so it can roll.
const BALL_REGION := Rect2(52, 45, 538, 538)
const NIGHT := Color("0b1116")
const INK := Color("101820")
const BRASS := Color("e7bc70")
const WALNUT := Color("573a2e")
const IVORY := Color("f4e6cd")
const FADE := 0.3

var reduced_motion := false
var backdrop: TextureRect
var wordmark: Label
var ball: TextureRect
var prompt: Label
## The whole screen is one button, so a tap anywhere, the accept key and focus all start.
var start: Button
var shade: TextureRect
var _clock := 0.0
var _leaving := false

func _ready() -> void:
	name = "TitleScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var fill := ColorRect.new()
	fill.color = NIGHT
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fill)
	backdrop = TextureRect.new()
	backdrop.name = "Backdrop"
	backdrop.texture = BACKDROP
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop.modulate = Color(0.82, 0.82, 0.86)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	# The hall fades into the night below it, where the prompt sits.
	shade = TextureRect.new()
	shade.name = "Shade"
	var gradient := Gradient.new()
	gradient.set_color(0, Color(NIGHT, 0.0))
	gradient.set_color(1, NIGHT)
	var ramp := GradientTexture2D.new()
	ramp.gradient = gradient
	ramp.fill_from = Vector2(0, 0)
	ramp.fill_to = Vector2(0, 1)
	shade.texture = ramp
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	wordmark = Label.new()
	wordmark.name = "Wordmark"
	wordmark.text = "ROGUEWOOD"
	var bold := FontVariation.new()
	bold.base_font = FONT
	bold.variation_opentype = {"wght": 700}
	wordmark.add_theme_font_override("font", bold)
	wordmark.add_theme_color_override("font_color", BRASS)
	wordmark.add_theme_color_override("font_outline_color", INK)
	wordmark.add_theme_color_override("font_shadow_color", WALNUT)
	wordmark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wordmark)
	ball = TextureRect.new()
	ball.name = "Ball"
	var cut := AtlasTexture.new()
	cut.atlas = BALL_SOURCE
	cut.region = BALL_REGION
	ball.texture = cut
	ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ball)
	prompt = Label.new()
	prompt.name = "Prompt"
	prompt.add_theme_color_override("font_color", IVORY)
	prompt.add_theme_color_override("font_outline_color", INK)
	prompt.add_theme_constant_override("outline_size", 6)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(prompt)
	start = Button.new()
	start.name = "TitleStart"
	start.flat = true
	start.focus_mode = Control.FOCUS_ALL
	start.text = "Start"
	start.add_theme_color_override("font_color", Color.TRANSPARENT)
	start.add_theme_color_override("font_focus_color", Color.TRANSPARENT)
	start.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	start.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	for key in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		start.add_theme_stylebox_override(key, StyleBoxEmpty.new())
	start.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start.pressed.connect(begin)
	add_child(start)
	resized.connect(_layout)
	_layout()

## Show it, with keyboard and gamepad focus on the start.
func open(reduced: bool) -> void:
	reduced_motion = reduced
	_leaving = false
	modulate.a = 1.0
	show()
	_layout()
	start.grab_focus()

## Any key or gamepad button starts too; the accept key reaches the button.
func _unhandled_input(event: InputEvent) -> void:
	if not visible or _leaving: return
	if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventJoypadButton and event.pressed):
		get_viewport().set_input_as_handled()
		begin()

func begin() -> void:
	if _leaving: return
	_leaving = true
	if reduced_motion or not is_inside_tree():
		_finish()
		return
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, FADE)
	fade.tween_callback(_finish)

func _finish() -> void:
	hide()
	started.emit()

func _layout() -> void:
	if wordmark == null: return
	var portrait := size.y >= size.x
	var w := size.x
	var h := size.y
	var mark := 76 if portrait else 96
	wordmark.add_theme_font_size_override("font_size", mark)
	wordmark.add_theme_constant_override("outline_size", int(round(mark * 0.18)))
	wordmark.add_theme_constant_override("shadow_offset_x", int(round(mark * 0.09)))
	wordmark.add_theme_constant_override("shadow_offset_y", int(round(mark * 0.09)))
	wordmark.add_theme_constant_override("shadow_outline_size", int(round(mark * 0.18)))
	prompt.add_theme_font_size_override("font_size", 32)
	prompt.text = "Tap to start" if DisplayServer.is_touchscreen_available() or OS.has_feature("web") else "Click or press any key"
	var ball_side := minf(w * 0.42, h * 0.24) if portrait else minf(h * 0.3, w * 0.2)
	var top := h * (0.28 if portrait else 0.16)
	wordmark.position = Vector2(0, top)
	wordmark.size = Vector2(w, mark * 1.4)
	ball.size = Vector2(ball_side, ball_side)
	ball.pivot_offset = ball.size * 0.5
	ball.position = Vector2((w - ball_side) * 0.5, top + mark * 1.6 + (h * 0.04))
	prompt.position = Vector2(0, h * (0.74 if portrait else 0.8))
	prompt.size = Vector2(w, 48)
	# The hall fills the top of the screen (all of it in landscape); the shade blends
	# its lower edge into the night.
	var hall_h := h * (0.62 if portrait else 1.0)
	backdrop.position = Vector2.ZERO
	backdrop.size = Vector2(w, hall_h)
	shade.position = Vector2(0, hall_h * 0.55)
	shade.size = Vector2(w, hall_h * 0.45 + 2.0)


func _process(delta: float) -> void:
	if not visible: return
	_clock += delta
	if reduced_motion:
		ball.rotation = 0.0
		prompt.modulate.a = 1.0
		return
	ball.rotation = _clock * 0.6 # a slow roll
	prompt.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * cos(_clock * TAU / 1.6))
