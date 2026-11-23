extends Control
## UI-22's effects layer for the award ceremony: fireworks, bottle rockets, confetti
## and the sunburst behind a trophy. Original, built from particles and drawing (no
## images); colours come from the ceremony's palette. Respects Reduced Motion (no
## travelling effects at all) and Reduced Flash (no bright bursts or flashes:
## confetti stands in for fireworks).
## UI-31 (owner, 2026-11-20): "The fanfare on the award screen needs to be continuous
## and way more voluminous ... The fireworks should continue to go the whole time."
## The show (start_show) runs from the ceremony's first moment until it is gone:
## shells of five kinds launched all the time, now and then a salvo with bottle
## rockets, confetti falling from the top the whole time, cannons from both bottom
## corners, and paper streamers drifting down. Its sounds are the ceremony's
## (signals launched and exploded).
signal launched(big: bool)
signal exploded(kind: String)

const GOLD := Color("f5cb69")
const SHELLS := ["peony", "ring", "willow", "crossette", "glitter"]
const SHELL_GAP := Vector2(0.2, 0.42) # seconds between shells
const SALVO_GAP := Vector2(2.6, 4.2)
const CANNON_GAP := Vector2(2.2, 3.4)
const STREAMERS := 14
const MAX_SHELLS := 9 # bursts alive at once, for phones

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
var _chip: ImageTexture # a confetti chip, wider than tall
var _rockets: Array = []
var show_on := false
var shells := 0 # shells the show launched (tests)
var salvos := 0
var _shell_wait := 0.0
var _salvo_wait := 0.0
var _cannon_wait := 0.0
var _stream: CPUParticles2D
var _streamers: Array = []
var _glows: Array = [] # UI-31: a soft bloom where each shell bursts

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	_dot = ImageTexture.create_from_image(image)
	var chip := Image.create(6, 3, false, Image.FORMAT_RGBA8)
	chip.fill(Color.WHITE)
	_chip = ImageTexture.create_from_image(chip)

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
			if rocket.big: firework(at, rocket.color, String(rocket.get("kind", "peony")), bool(rocket.get("show", false)))
			else: _pop(at, rocket.color)
	for g in _glows.duplicate():
		g.age += delta
		if g.age > 0.45: _glows.erase(g)
	if show_on and not reduced_motion:
		_run_show(delta)
	queue_redraw()

## UI-31: the continuous show, from the ceremony's first moment until it is gone.
func start_show() -> void:
	show_on = true
	if reduced_motion: return
	_shell_wait = 0.55 # the ceremony's own opening rockets lead
	_salvo_wait = randf_range(SALVO_GAP.x, SALVO_GAP.y)
	_cannon_wait = 0.9
	if _stream == null:
		_stream = _confetti(170)
		_stream.name = "ConfettiFall"
		_stream.one_shot = false
		_stream.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_stream.direction = Vector2.DOWN
		_stream.spread = 25.0
		_stream.initial_velocity_min = 30.0
		_stream.initial_velocity_max = 110.0
		_stream.gravity = Vector2(0, 70)
		_stream.lifetime = 6.5
		_stream.explosiveness = 0.0
		_stream.randomness = 0.6
		add_child(_stream)
	_stream.position = Vector2(size.x * 0.5, -12)
	_stream.emission_rect_extents = Vector2(size.x * 0.55, 6)
	_stream.emitting = true
	_streamers.clear()
	for i in STREAMERS:
		_streamers.append(_streamer(randf_range(-size.y, 0.0)))

func stop_show() -> void:
	show_on = false
	if _stream != null: _stream.emitting = false
	_streamers.clear()

func _run_show(delta: float) -> void:
	if _stream != null:
		_stream.position = Vector2(size.x * 0.5, -12)
		_stream.emission_rect_extents = Vector2(size.x * 0.55, 6)
	_shell_wait -= delta
	if _shell_wait <= 0.0:
		_shell_wait = randf_range(SHELL_GAP.x, SHELL_GAP.y)
		show_shell()
	_salvo_wait -= delta
	if _salvo_wait <= 0.0:
		_salvo_wait = randf_range(SALVO_GAP.x, SALVO_GAP.y)
		salvo()
	_cannon_wait -= delta
	if _cannon_wait <= 0.0:
		_cannon_wait = randf_range(CANNON_GAP.x, CANNON_GAP.y)
		confetti_cannons()
	for s in _streamers:
		s.y += s.speed * delta
		s.phase += delta * s.sway
		if s.y - s.length > size.y:
			var fresh: Dictionary = _streamer(-randf_range(20.0, 160.0))
			s.merge(fresh, true)

## One shell from the show: a random kind, colour and height across the sky.
func show_shell(kind: String = "") -> void:
	if reduced_motion: return
	if alive_bursts() + _rockets.filter(func(r): return r.big).size() >= MAX_SHELLS: return
	shells += 1
	var to := Vector2(size.x * randf_range(0.08, 0.92), size.y * randf_range(0.07, 0.5))
	if reduced_flash:
		confetti_burst(Vector2(to.x, size.y), 34)
		exploded.emit("confetti")
		return
	_rockets.append({"from": Vector2(to.x + randf_range(-40, 40), size.y + 10), "to": to, "flight": randf_range(0.7, 1.0), "age": 0.0,
		"color": palette.pick_random(), "wobble": 1.5, "trail": [], "at": Vector2.ZERO, "big": true,
		"kind": kind if not kind.is_empty() else SHELLS.pick_random(), "show": true})
	launched.emit(true)

## Three shells at once and a fan of bottle rockets.
func salvo() -> void:
	if reduced_motion: return
	salvos += 1
	for i in 3:
		show_shell()
	if reduced_flash: return
	for i in 5:
		bottle_rocket(size.x * randf_range(0.1, 0.9), Vector2(size.x * randf_range(0.1, 0.9), size.y * randf_range(0.15, 0.45)))
	launched.emit(false)

func _streamer(y: float) -> Dictionary:
	return {"x": size.x * randf(), "y": y, "speed": randf_range(45.0, 95.0), "phase": randf() * TAU, "sway": randf_range(2.0, 3.6),
		"length": randf_range(70.0, 140.0), "amp": randf_range(6.0, 14.0), "color": palette.pick_random(), "width": randf_range(3.0, 5.0)}

func _draw() -> void:
	if rays_alpha > 0.0:
		var count := 18
		var reach := maxf(size.x, size.y)
		for i in count:
			var a := rays_angle + TAU * i / count
			var half := TAU / count * 0.28
			var points := PackedVector2Array([rays_center, rays_center + Vector2.from_angle(a - half) * reach, rays_center + Vector2.from_angle(a + half) * reach])
			draw_colored_polygon(points, Color(GOLD, rays_alpha * (0.12 if i % 2 == 0 else 0.06)))
	for g in _glows:
		var k: float = g.age / 0.45
		draw_circle(g.at, lerpf(40.0, 150.0, k), Color(g.color, 0.22 * (1.0 - k)))
		draw_circle(g.at, lerpf(14.0, 50.0, k), Color(1, 0.97, 0.88, 0.35 * (1.0 - k)))
	for s in _streamers:
		var points := PackedVector2Array()
		for i in 12:
			var k := float(i) / 11.0
			points.append(Vector2(s.x + sin(s.phase + k * 5.0) * s.amp, s.y - k * s.length))
		draw_polyline(points, Color(s.color, 0.9), s.width)
	for rocket in _rockets:
		var trail: Array = rocket.trail
		for i in range(1, trail.size()):
			draw_line(trail[i - 1], trail[i], Color(rocket.color, float(i) / trail.size() * 0.9), 3.5 if rocket.big else 2.0)
		draw_circle(rocket.at, 4.0 if rocket.big else 2.5, Color.WHITE)
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

## A firework bursting at `at`: a ring of sparks and a glitter of white. UI-31's
## show adds kinds: a clean double ring, a drooping gold willow, a crossette that
## splits again, and a crackling glitter. The show's own shells flash the screen
## only faintly, as they never stop.
func firework(at: Vector2, color: Color = Color(), kind: String = "peony", from_show: bool = false) -> void:
	if reduced_motion: return
	bursts += 1
	if reduced_flash:
		confetti_burst(at, 30)
		return
	var c: Color = color if color != Color() else palette.pick_random()
	var main: CPUParticles2D
	match kind:
		"ring":
			main = _burst(at, c, 72, 270.0, 278.0, 1.4, 3.6)
			_burst(at, palette.pick_random(), 48, 150.0, 156.0, 1.2, 3.0)
		"willow":
			main = _burst(at, GOLD, 120, 150.0, 290.0, 2.9, 3.2)
			main.gravity = Vector2(0, 55)
			main.damping_min = 80.0
			main.damping_max = 110.0
		"crossette":
			main = _burst(at, c, 40, 200.0, 260.0, 0.8, 4.0)
			for i in 5:
				var off := Vector2.from_angle(TAU * i / 5.0 + randf() * 0.4) * randf_range(90.0, 130.0)
				create_tween().tween_callback(func(): _burst(at + off, c, 26, 80.0, 150.0, 0.9, 3.0)).set_delay(0.42)
		"glitter":
			main = _burst(at, c, 70, 200.0, 300.0, 1.3, 3.4)
			_burst(at, Color(1, 0.95, 0.8), 70, 30.0, 220.0, 1.1, 1.8)
		_:
			main = _burst(at, c, 120, 200.0, 360.0, 1.6, 3.8)
			_burst(at, Color(1, 1, 0.9), 26, 50.0, 140.0, 0.9, 2.2)
	_glows.append({"at": at, "color": c, "age": 0.0})
	main.set_meta("burst", true) # one per shell, for MAX_SHELLS
	flash = maxf(flash, 0.12 if from_show else 0.4)
	exploded.emit(kind)

func _pop(at: Vector2, color: Color) -> void:
	bursts += 1
	if reduced_flash:
		confetti_burst(at, 16)
		return
	_burst(at, color, 24, 70.0, 140.0, 0.7, 2.0)

func _burst(at: Vector2, color: Color, amount: int, speed_min: float, speed_max: float, life: float, scale_px: float) -> CPUParticles2D:
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
	ramp.add_point(0.12, color)
	ramp.add_point(0.7, Color(color, 0.85)) # UI-31: full colour until the sphere has opened
	p.color_ramp = ramp
	_spawn(p, life + 0.2)
	return p

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
		var p := _confetti(120)
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
	p.texture = _chip # UI-31: chips, not specks
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
	p.scale_amount_min = 1.3
	p.scale_amount_max = 2.2
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
	var end := create_tween() # dies with the layer, unlike a tree timer
	end.tween_callback(p.queue_free).set_delay(seconds)

## Firework bursts still glowing.
func alive_bursts() -> int:
	return get_children().filter(func(c): return c.has_meta("burst") and not c.is_queued_for_deletion()).size()

## Rockets still in the air.
func airborne() -> int:
	return _rockets.size()
