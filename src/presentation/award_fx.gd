extends Control
## UI-22's effects layer for the award ceremony: fireworks, bottle rockets, confetti
## and the sunburst behind a trophy. Original, built from particles and drawing (no
## images); colours come from the ceremony's palette. Respects Reduced Motion (no
## travelling effects at all) and Reduced Flash (no bright bursts or flashes:
## confetti stands in for fireworks).
const GOLD := Color("f5cb69")

var palette: Array = [Color("f5cb69"), Color("ff7a59"), Color("64dacb"), Color("b48cff"), Color("f4ecd8")]
var reduced_motion := false
var reduced_flash := false
var rays_center := Vector2.ZERO
var rays_alpha := 0.0
var rays_speed := 0.25 # radians a second
var rays_angle := 0.0
var flash := 0.0
var bursts := 0 # fireworks and rockets that exploded (for tests)
var confetti_shots := 0
var _dot: ImageTexture
var _rockets: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	_dot = ImageTexture.create_from_image(image)

func _process(delta: float) -> void:
	if not reduced_motion:
		rays_angle = fmod(rays_angle + rays_speed * delta, TAU)
	flash = move_toward(flash, 0.0, delta * 3.0)
	for rocket in _rockets.duplicate():
		rocket.age += delta
		var t: float = minf(1.0, rocket.age / rocket.flight)
		var eased := 1.0 - pow(1.0 - t, 2.0)
		var at: Vector2 = rocket.from.lerp(rocket.to, eased) + Vector2(sin(rocket.age * 22.0) * rocket.wobble, 0)
		rocket.trail.append(at)
		if rocket.trail.size() > 14: rocket.trail.pop_front()
		rocket.at = at
		if t >= 1.0:
			_rockets.erase(rocket)
			if rocket.big: firework(at, rocket.color)
			else: _pop(at, rocket.color)
	queue_redraw()

func _draw() -> void:
	if rays_alpha > 0.0:
		var count := 18
		var reach := maxf(size.x, size.y)
		for i in count:
			var a := rays_angle + TAU * i / count
			var half := TAU / count * 0.28
			var points := PackedVector2Array([rays_center, rays_center + Vector2.from_angle(a - half) * reach, rays_center + Vector2.from_angle(a + half) * reach])
			draw_colored_polygon(points, Color(GOLD, rays_alpha * (0.12 if i % 2 == 0 else 0.06)))
	for rocket in _rockets:
		var trail: Array = rocket.trail
		for i in range(1, trail.size()):
			draw_line(trail[i - 1], trail[i], Color(rocket.color, float(i) / trail.size() * 0.9), 2.5 if rocket.big else 1.5)
		draw_circle(rocket.at, 3.0 if rocket.big else 2.0, Color.WHITE)
	if flash > 0.0 and not reduced_flash:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.96, 0.85, flash * 0.35))

## A white flash over everything (not under Reduced Flash).
func flash_now() -> void:
	if not reduced_flash and not reduced_motion:
		flash = 1.0

## A firework rising from the bottom to `to`, bursting there. Returns its flight time.
func launch_firework(to: Vector2, color: Color = Color()) -> float:
	if reduced_motion: return 0.0
	var c: Color = color if color != Color() else palette.pick_random()
	if reduced_flash:
		confetti_burst(Vector2(to.x, size.y), 40)
		return 0.0
	_rockets.append({"from": Vector2(to.x + randf_range(-30, 30), size.y + 10), "to": to, "flight": 0.8, "age": 0.0, "color": c,
		"wobble": 1.5, "trail": [], "at": Vector2.ZERO, "big": true})
	return 0.8

## A bottle rocket: quicker and smaller, with a wobble, popping into a few sparks.
func bottle_rocket(from_x: float, to: Vector2) -> float:
	if reduced_motion: return 0.0
	_rockets.append({"from": Vector2(from_x, size.y + 10), "to": to, "flight": 0.56, "age": 0.0, "color": palette.pick_random(),
		"wobble": 4.0, "trail": [], "at": Vector2.ZERO, "big": false})
	return 0.56

## A firework bursting at `at`: a ring of sparks and a glitter of white.
func firework(at: Vector2, color: Color = Color()) -> void:
	if reduced_motion: return
	bursts += 1
	if reduced_flash:
		confetti_burst(at, 30)
		return
	var c: Color = color if color != Color() else palette.pick_random()
	_burst(at, c, 70, 150.0, 270.0, 1.4, 2.6)
	_burst(at, Color(1, 1, 0.9), 26, 40.0, 120.0, 0.9, 1.6)
	flash = maxf(flash, 0.4)

func _pop(at: Vector2, color: Color) -> void:
	bursts += 1
	if reduced_flash:
		confetti_burst(at, 16)
		return
	_burst(at, color, 24, 70.0, 140.0, 0.7, 2.0)

func _burst(at: Vector2, color: Color, amount: int, speed_min: float, speed_max: float, life: float, scale_px: float) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.texture = _dot
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = life
	p.spread = 180.0
	p.direction = Vector2.UP
	p.initial_velocity_min = speed_min
	p.initial_velocity_max = speed_max
	p.gravity = Vector2(0, 110)
	p.damping_min = 40.0
	p.damping_max = 70.0
	p.scale_amount_min = scale_px * 0.6
	p.scale_amount_max = scale_px
	var ramp := Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.set_color(1, Color(color, 0.0))
	ramp.add_point(0.25, color)
	p.color_ramp = ramp
	_spawn(p, life + 0.2)

## Confetti from a point, thrown upward and fluttering down in the palette's colours.
func confetti_burst(at: Vector2, amount: int = 70) -> void:
	if reduced_motion: return
	confetti_shots += 1
	var p := _confetti(amount)
	p.position = at
	p.direction = Vector2.UP
	p.spread = 40.0
	p.initial_velocity_min = 360.0
	p.initial_velocity_max = 620.0
	p.explosiveness = 0.95
	_spawn(p, p.lifetime + 0.3)

## Confetti from both bottom corners, angled toward the middle.
func confetti_cannons() -> void:
	if reduced_motion: return
	for side in [-1, 1]:
		var p := _confetti(80)
		p.position = Vector2(size.x * (0.0 if side < 0 else 1.0), size.y)
		p.direction = Vector2(-side * 0.55, -1.0).normalized()
		p.spread = 20.0
		p.initial_velocity_min = 560.0
		p.initial_velocity_max = 900.0
		p.explosiveness = 0.9
		_spawn(p, p.lifetime + 0.3)
	confetti_shots += 1

## Confetti raining from the top edge for a few seconds.
func confetti_rain() -> void:
	if reduced_motion: return
	confetti_shots += 1
	var p := _confetti(110)
	p.one_shot = true
	p.position = Vector2(size.x * 0.5, -10)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(size.x * 0.5, 4)
	p.direction = Vector2.DOWN
	p.spread = 15.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.gravity = Vector2(0, 90)
	p.explosiveness = 0.2
	p.lifetime = 4.0
	_spawn(p, 4.5)

func _confetti(amount: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = _dot
	p.amount = amount
	p.one_shot = true
	p.lifetime = 2.6
	p.gravity = Vector2(0, 520)
	p.damping_min = 30.0
	p.damping_max = 60.0
	p.angle_min = -180.0
	p.angle_max = 180.0
	p.angular_velocity_min = -420.0
	p.angular_velocity_max = 420.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.5
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0])
	colors.colors = PackedColorArray([palette[0]])
	for i in range(1, palette.size()):
		colors.add_point(float(i) / (palette.size() - 1), palette[i])
	colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	p.color_initial_ramp = colors
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.8, Color.WHITE)
	p.color_ramp = fade
	return p

func _spawn(p: CPUParticles2D, seconds: float) -> void:
	add_child(p)
	p.emitting = true
	get_tree().create_timer(seconds).timeout.connect(p.queue_free)

## Rockets still in the air.
func airborne() -> int:
	return _rockets.size()
