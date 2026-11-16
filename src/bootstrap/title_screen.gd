extends Control
## UI-7: the title screen, shown when the game starts (owner's play notes, 2026-11-15:
## the engine's loading screen was standing in for one). The House hall at night,
## the ROGUEWOOD wordmark, the House Ball rolling slowly, and "Tap to start". A
## tap, a click, a key or a gamepad button starts; the Clubhouse is underneath.
## Reduced motion keeps the ball and the prompt still. A view only: the shell
## decides when it shows and what follows (`started`).
## UI-A7: stationary architecture, local foliage/sky motion and a pixel 3D ball.
## The first input always works; reduced motion is a completely static layout.
signal started
## The moment of the tap (the owner, 2026-11-16: a sound on the tap); `started`
## follows once the 0.3 s fade ends.
signal tapped

const FONT = preload("res://assets/ui/fonts/PixelifySans.ttf")
const BACKDROP = preload("res://assets/leagues/house/backdrop.league.house.division_01.tres")
## UI-A4 (Codex): brand art, used when present, at fixed paths, so it needs no code.
## The logo replaces the lettered wordmark (whose text stays for tools and tests);
## the key art replaces the House backdrop.
const LOGO_PATH := "res://assets/brand/logo.png"
const KEY_ART_PATH := "res://assets/brand/title_art.png"
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
var logo: TextureRect # null until Codex's logo lands
var prompt: Label
## The whole screen is one button, so a tap anywhere, the accept key and focus all start.
var start: Button
var shade: TextureRect
var _clock := 0.0
var _leaving := false
var _leave_clock := 0.0
var _fade: Tween
var _ball_origin := Vector2.ZERO
var _mark_origin := Vector2.ZERO
var _hall_origin := Vector2.ZERO
var atmosphere: HallAtmosphere
var ball_view: SubViewport
var ball_actor: Node3D
var ball_material: ShaderMaterial
var hall_material: ShaderMaterial
const TURN_SECONDS := 18.0


## Two cached radial lamp pools and the hero halo. Local foliage and stars
## animate in the hall material; there is no drifting dust or architecture.
class HallAtmosphere extends Control:
	var hall: TextureRect
	var hero: TextureRect
	var clock := 0.0
	var still := true
	var light: GradientTexture2D
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ramp := Gradient.new()
		ramp.set_color(0, Color.WHITE)
		ramp.set_color(1, Color(1, 1, 1, 0))
		light = GradientTexture2D.new()
		light.gradient = ramp
		light.width = 64
		light.height = 64
		light.fill = GradientTexture2D.FILL_RADIAL
		light.fill_from = Vector2(0.5, 0.5)
		light.fill_to = Vector2(1.0, 0.5)
	func _hall_point(uv: Vector2) -> Vector2:
		var source := hall.texture.get_size()
		var covered := source * maxf(hall.size.x / source.x, hall.size.y / source.y)
		return hall.position + (hall.size - covered) * 0.5 + covered * uv
	func _draw() -> void:
		if light == null or hall == null: return
		var t := 0.0 if still else clock
		var unit := minf(size.x, size.y) / 540.0
		for side_index in 2:
			var side := 0.14 if side_index == 0 else 0.86
			var at := _hall_point(Vector2(side, 0.42))
			var radius := 90.0 * unit
			var breath := 0.045 + 0.008 * sin(t * 0.7 + side * 4.0)
			draw_texture_rect(light, Rect2(at - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, Color(0.91, 0.74, 0.44, breath))
		# A quiet petrol halo separates the ball's dark edge from the night.
		var center := hero.position + hero.size * 0.5
		var halo := hero.size * 1.35
		draw_texture_rect(light, Rect2(center - halo * 0.5, halo), false, Color(0.15, 0.34, 0.37, 0.12))

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
	backdrop.texture = load(KEY_ART_PATH) if ResourceLoader.exists(KEY_ART_PATH) else BACKDROP
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop.modulate = Color(0.82, 0.82, 0.86)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hall_material = ShaderMaterial.new()
	hall_material.shader = preload("res://assets/brand/title_life.gdshader")
	backdrop.material = hall_material
	add_child(backdrop)
	# The hall fades into the night below it, where the prompt sits.
	shade = TextureRect.new()
	shade.name = "Shade"
	var gradient := Gradient.new()
	gradient.set_color(0, Color(NIGHT, 0.0))
	gradient.set_color(1, NIGHT)
	# Reach opaque night before the stationary hall's lower edge.
	gradient.add_point(0.88, NIGHT)
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
	if ResourceLoader.exists(LOGO_PATH):
		logo = TextureRect.new()
		logo.name = "Logo"
		logo.texture = load(LOGO_PATH)
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(logo)
		wordmark.hide()
	ball = TextureRect.new()
	ball.name = "Ball"
	ball_view = SubViewport.new()
	ball_view.name = "PixelBallViewport"
	ball_view.size = Vector2i(192, 192)
	ball_view.transparent_bg = true
	ball_view.own_world_3d = true
	ball_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(ball_view)
	ball_actor = Node3D.new()
	ball_view.add_child(ball_actor)
	var shell := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.108
	sphere.height = 0.216
	sphere.radial_segments = 64
	sphere.rings = 32
	shell.mesh = sphere
	var enamel := ShaderMaterial.new()
	enamel.shader = preload("res://assets/brand/title_ball.gdshader")
	enamel.set_shader_parameter("illustration", preload("res://assets/items/balls/a01-source.png"))
	ball_material = enamel
	shell.material_override = enamel
	ball_actor.add_child(shell)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 0.22
	ball_view.add_child(camera)
	camera.position = Vector3(0, 0, -0.6)
	camera.look_at(Vector3.ZERO)
	ball.texture = ball_view.get_texture()
	ball.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ball)
	atmosphere = HallAtmosphere.new()
	atmosphere.name = "HallAtmosphere"
	atmosphere.hall = backdrop
	atmosphere.hero = ball
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(atmosphere)
	move_child(atmosphere, shade.get_index())
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
	if _fade != null and _fade.is_valid(): _fade.kill()
	reduced_motion = reduced
	_leaving = false
	_clock = 0.0
	_leave_clock = 0.0
	modulate.a = 1.0
	ball_view.render_target_update_mode = SubViewport.UPDATE_ONCE if reduced_motion else SubViewport.UPDATE_ALWAYS
	set_process(not reduced_motion)
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
	tapped.emit()
	if reduced_motion or not is_inside_tree():
		_finish()
		return
	_leave_clock = 0.0
	# A tiny acknowledgement happens inside the existing 0.3 s, never before
	# accepting input. No extra wait, flash, audio gate or second action.
	_fade = create_tween()
	_fade.tween_interval(0.045)
	_fade.tween_property(self, "modulate:a", 0.0, FADE - 0.045)
	_fade.tween_callback(_finish)

func _finish() -> void:
	if not _leaving: return
	hide()
	ball_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	set_process(false)
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
	# The owner (2026-11-16): "Tap to Play".
	prompt.text = "Tap to Play" if DisplayServer.is_touchscreen_available() or OS.has_feature("web") else "Click or press any key to Play"
	var ball_side := minf(w * 0.42, h * 0.24) if portrait else minf(h * 0.3, w * 0.2)
	var top := h * (0.28 if portrait else 0.16)
	wordmark.position = Vector2(0, top)
	wordmark.size = Vector2(w, mark * 1.4)
	ball.size = Vector2(ball_side, ball_side)
	ball.pivot_offset = ball.size * 0.5
	ball.position = Vector2((w - ball_side) * 0.5, top + mark * 1.6 + (h * 0.04))
	if logo != null:
		# The logo takes the wordmark's band and may be taller; the ball follows it.
		var band := Vector2(w * (0.86 if portrait else 0.6), mark * 2.2)
		logo.size = band
		logo.position = Vector2((w - band.x) * 0.5, top - mark * 0.4)
		ball.position.y = logo.position.y + band.y + h * 0.03
	prompt.position = Vector2(0, maxf(h * (0.68 if portrait else 0.80), ball.position.y + ball_side + h * 0.035))
	prompt.size = Vector2(w, 48)
	# The hall fills the top of the screen (all of it in landscape); the shade blends
	# its lower edge into the night.
	var hall_h := h * (0.70 if portrait else 1.0)
	# The architecture is stationary; only local foliage and sky pixels animate.
	_hall_origin = Vector2.ZERO
	backdrop.position = _hall_origin
	backdrop.size = Vector2(w, hall_h)
	shade.position = Vector2(0, hall_h * 0.52)
	shade.size = Vector2(w, hall_h * 0.48 + 18.0)
	_ball_origin = ball.position
	_mark_origin = logo.position if logo != null else wordmark.position
	if logo != null: logo.pivot_offset = logo.size * 0.5
	_apply_motion()


func _process(delta: float) -> void:
	if not visible: return
	_clock += delta
	if _leaving: _leave_clock += delta
	_apply_motion()

func _apply_motion() -> void:
	if atmosphere == null: return
	var t := 0.0 if reduced_motion else _clock
	var settle := 0.0 if reduced_motion else pow(1.0 - clampf(t / 0.7, 0.0, 1.0), 3.0)
	var unit := minf(size.x, size.y) / 540.0
	var beat := sin(clampf(_leave_clock / 0.16, 0.0, 1.0) * PI) if _leaving and not reduced_motion else 0.0
	ball.position = _ball_origin + Vector2(-18, 8) * settle * unit
	ball.rotation = 0.0
	ball_actor.rotation.y = t * TAU / TURN_SECONDS
	ball_material.set_shader_parameter("turn", ball_actor.rotation.y)
	ball.scale = Vector2.ONE * (1.0 + beat * 0.025)
	var mark: Control = logo if logo != null else wordmark
	mark.position = _mark_origin + Vector2(0, -8 * settle * unit)
	mark.scale = Vector2.ONE * (1.0 + beat * 0.012)
	mark.modulate = Color(1, 1, 1, 1.0 - settle * 0.1)
	prompt.modulate.a = 1.0 if reduced_motion else 0.90 + 0.10 * cos(t * TAU / 3.6)
	backdrop.position = _hall_origin
	hall_material.set_shader_parameter("clock", t)
	atmosphere.clock = t
	atmosphere.still = reduced_motion
	atmosphere.queue_redraw()
