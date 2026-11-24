extends Control
## UI-A9-N (Claude, 2026-11-24; the owner moved it from Codex the same day): the Neon
## League's eighteen alley-screen storyboards on the UI-A9-H contract (play, skip,
## duration, finished; 252 x 90; reduced motion holds the final tableau; reduced flash
## keeps every light steady). Five strikes, five spares and two endings per rival;
## the champion's two add a gold flourish. Names come from `context`.
signal finished
const Kit = preload("res://assets/ui/alley_screen/neon/neon_kit.gd")
const RivalArt = preload("res://src/presentation/rival_art.gd")
@export var variant := "strike.laser_sweep"
var context: Dictionary = {}
var elapsed := 0.0
var _clock := 0.0 # what the variants animate by (fixed under reduced motion)
var _done := true
var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()

func _ready() -> void:
	size = Vector2(252, 90)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)

func duration() -> float:
	return 3.0 if variant.begins_with("boss.") else (1.6 if variant.begins_with("spare.") else 1.8)

func play(with: Dictionary) -> void:
	context = with.duplicate(true)
	elapsed = 0.0
	_done = false
	texture = RivalArt.portrait(String(context.get("rival_id", "")), "defeated") if variant.begins_with("boss.") else null
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed = minf(elapsed + delta, duration())
	if not bool(context.get("reduced_motion", false)): queue_redraw()
	if elapsed >= duration(): _finish()

func skip() -> void:
	elapsed = duration()
	queue_redraw()
	_finish()

func _finish() -> void:
	if _done: return
	_done = true
	set_process(false)
	finished.emit()

func _draw() -> void:
	var reduced := bool(context.get("reduced_motion", false))
	_clock = duration() if reduced else elapsed # reduced motion: one still frame
	var t := 1.0 if reduced else clampf(elapsed / (duration() * 0.7), 0.0, 1.0)
	Kit.stage(self, 0.0 if reduced else elapsed)
	match variant:
		"strike.laser_sweep": _laser_sweep(t)
		"strike.tube_sign": _tube_sign(t)
		"strike.equalizer": _equalizer(t)
		"strike.skyline": _skyline(t)
		"strike.mirror_ball": _mirror_ball(t)
		"spare.bank_shot": _bank_shot(t)
		"spare.laser_slash": _laser_slash(t)
		"spare.claw": _claw(t)
		"spare.spotlight": _spotlight(t)
		"spare.split_bridge": _split_bridge(t)
		"boss.slick_slip": _slick_slip(t)
		"boss.slick_squeegee": _slick_squeegee(t)
		"boss.laser_lena_tangle": _lena_tangle(t)
		"boss.dj_flicker_power_down": _power_down(t)
		"boss.dj_flicker_scratch": _scratch(t)
		"boss.dj_flicker_champion_headline": _headline(t)
		"boss.dj_flicker_champion_encore": _encore(t)
		_: if variant.begins_with("boss."): _lights_out(t)

## The rack as a neon sign; the ball streaks in and the pins scatter as sparks.
func _laser_sweep(t: float) -> void:
	var hit := 0.35
	var ball_x := lerpf(-10.0, 200.0, minf(t / hit, 1.0)) if t < hit else lerpf(200.0, 262.0, (t - hit) / (1.0 - hit))
	var scatter := smoothstep(hit, 0.75, t)
	for row in 4:
		for i in row + 1:
			var n := row * (row + 1) / 2 + i
			var home := Vector2(196 + row * 10, 42 + (i - row * 0.5) * 11)
			var away := Vector2(cos(n * 1.7), sin(n * 1.7) - 0.6) * 60.0
			var color: Color = Kit.MAGENTA if n % 2 == 0 else Kit.CYAN
			Kit.pin(self, home + away * scatter, color, scatter * (n - 4.5) * 0.6, 1.0 - scatter * 0.6)
	if t < 0.9: Kit.ball(self, Vector2(ball_x, 50), Vector2(28, 0))
	var lit := smoothstep(hit, hit + 0.25, t)
	Kit.word(self, "STRIKE!", Rect2(16, 30, 150, 28), 30, Kit.MAGENTA, lit)
	Kit.word(self, "PERFECT SWEEP", Rect2(20, 60, 140, 12), 10, Kit.CYAN, smoothstep(hit + 0.2, hit + 0.45, t))
	if scatter > 0.3:
		for i in 5:
			Kit.spark(self, Vector2(180 + i * 14, 20 + (i * 17) % 50), Kit.GOLD if i % 2 else Kit.WHITE, 2.0 + (i % 3))

## A bank shot: the ball comes off a neon bumper rail to clip the last pin.
func _bank_shot(t: float) -> void:
	Kit.tube(self, PackedVector2Array([Vector2(140, 18), Vector2(236, 18)]), Kit.VIOLET, 3.0)
	var bounce := Vector2(188, 22)
	var target := Vector2(222, 58)
	var p: Vector2
	if t < 0.45: p = Vector2(132, 74).lerp(bounce, t / 0.45)
	else: p = bounce.lerp(target + Vector2(14, 6), (t - 0.45) / 0.55)
	if t > 0.42 and t < 0.6: Kit.tube(self, PackedVector2Array([Vector2(176, 18), Vector2(200, 18)]), Kit.WHITE, 3.0)
	var knock := smoothstep(0.75, 1.0, t)
	Kit.pin(self, target + Vector2(10, -4) * knock, Kit.MAGENTA, knock * 1.3, 1.0)
	if t < 0.98: Kit.ball(self, p, (p - Vector2(132, 74)).normalized() * 18.0 if t < 0.45 else (target - bounce).normalized() * 18.0)
	var lit := smoothstep(0.7, 0.9, t)
	Kit.word(self, "SPARE!", Rect2(16, 30, 112, 26), 28, Kit.CYAN, lit)
	Kit.word(self, "BANK SHOT", Rect2(20, 60, 104, 12), 10, Kit.MAGENTA, smoothstep(0.82, 1.0, t))

## The rival's laser sputters and breaks; the DEFEATED sign buzzes on.
func _lights_out(t: float) -> void:
	var frame := Rect2(18, 14, 60, 60)
	Kit.tube_rect(self, frame, Kit.MAGENTA, 2.0)
	if texture != null:
		draw_texture_rect(texture, frame.grow(-3), false)
	var origin := Vector2(78, 40)
	var reach := lerpf(0.0, 150.0, smoothstep(0.0, 0.3, t))
	var breaking := smoothstep(0.35, 0.6, t)
	if breaking < 1.0:
		for i in 10: # the beam, in segments that drop out as it breaks
			var a := origin + Vector2(reach * i / 10.0, 0)
			var b := origin + Vector2(reach * (i + 1) / 10.0, 0)
			if fposmod(i * 0.37 + breaking * 3.1, 1.0) > breaking:
				draw_line(a, b, Color(Kit.CYAN, 0.35), 5.0)
				draw_line(a, b, Kit.WHITE, 1.0)
	if breaking > 0.0:
		for i in 6:
			Kit.spark(self, origin + Vector2(30 + i * 22, sin(i * 2.3) * 8 * breaking), Kit.CYAN if i % 2 else Kit.GOLD, 1.0 + breaking * 2.0)
	_name(Kit.VIOLET)
	# The sign buzzes on: two short flickers, then steady (none under reduced motion).
	var lit := smoothstep(0.5, 0.62, t) if _steady() else (0.0 if t < 0.5 else (0.35 if t < 0.56 else (1.0 if t < 0.62 else (0.3 if t < 0.66 else 1.0))))
	Kit.word(self, "DEFEATED!", Rect2(92, 36, 144, 24), 24, Kit.MAGENTA, lit)
	Kit.word(self, "LINE BROKEN", Rect2(96, 62, 136, 12), 10, Kit.CYAN, smoothstep(0.7, 0.9, t))

# --- Shared pieces -----------------------------------------------------------------

## No flicker or blink: reduced flash, or the held tableau of reduced motion.
func _steady() -> bool:
	return bool(context.get("reduced_flash", false)) or bool(context.get("reduced_motion", false))

## The rival's name from context ("DJ Flicker, Neon Champion" takes two lines).
func _name(color: Color) -> void:
	var parts := String(context.get("rival_name", "")).to_upper().split(",", false, 1)
	if parts.is_empty(): parts = PackedStringArray(["RIVAL"])
	if parts.size() == 2:
		Kit.word(self, parts[0], Rect2(92, 21, 144, 12), 11, color, 1.0)
		Kit.word(self, parts[1].strip_edges(), Rect2(92, 31, 144, 9), 8, Kit.GOLD, 1.0)
	else:
		Kit.word(self, parts[0], Rect2(92, 18, 144, 14), 13, color, 1.0)

## The rival's portrait in its tube frame, moved, turned or dimmed for the gag.
func _portrait(offset: Vector2 = Vector2.ZERO, angle: float = 0.0, tint: Color = Color.WHITE, frame_color: Color = Kit.MAGENTA) -> void:
	var frame := Rect2(18, 14, 60, 60)
	Kit.tube_rect(self, frame, frame_color, 2.0)
	if texture == null: return
	var center := frame.get_center() + offset
	draw_set_transform(center, angle, Vector2.ONE)
	draw_texture_rect(texture, Rect2(-27, -27, 54, 54), false, tint)
	draw_set_transform(Vector2.ZERO)

func _defeated(lit: float, color: Color = Kit.MAGENTA, always: bool = true) -> void:
	if always or lit > 0.0: Kit.word(self, "DEFEATED!", _big(), 24, color, lit)

## The big word's place: lower when the name takes two lines.
func _big() -> Rect2:
	return Rect2(92, 51, 144, 24) if String(context.get("rival_name", "")).contains(",") else Rect2(92, 37, 144, 24)

## The champion's flourish: a gold inner tube and slow gold sparks.
func _crown_flourish(t: float) -> void:
	var on := smoothstep(0.55, 0.8, t)
	if on <= 0.0: return
	Kit.tube_rect(self, Rect2(12, 12, 228, 66), Kit.GOLD, 1.0, on)
	for i in 7:
		var p := Vector2(96 + i * 21, 12 + fposmod(i * 9.0 + t * 30.0, 64.0))
		Kit.spark(self, p, Kit.GOLD if i % 2 else Kit.WHITE, 1.0 + on * (1 + i % 2))

## Where a ray from `from` along `dir` meets the inner frame.
func _inside(from: Vector2, dir: Vector2) -> Vector2:
	var reach := 999.0
	if dir.x > 0.0: reach = minf(reach, (241.0 - from.x) / dir.x)
	elif dir.x < 0.0: reach = minf(reach, (11.0 - from.x) / dir.x)
	if dir.y > 0.0: reach = minf(reach, (79.0 - from.y) / dir.y)
	elif dir.y < 0.0: reach = minf(reach, (11.0 - from.y) / dir.y)
	return from + dir * maxf(reach, 0.0)

func _rack(i: int) -> Vector2: # pin i (0..9) of a small rack, head pin left
	var row := 0
	while (row + 1) * (row + 2) / 2 <= i: row += 1
	var k := i - row * (row + 1) / 2
	return Vector2(row * 10, (k - row * 0.5) * 11)

# --- Strikes -----------------------------------------------------------------------

## The sign lights letter by letter while the ten pins along the floor wink out in
## order; then a soft colour sweep runs through the letters.
func _tube_sign(t: float) -> void:
	for i in 10:
		var out := smoothstep(0.08 + i * 0.05, 0.14 + i * 0.05, t)
		var p := Vector2(32 + i * 21, 76 - out * 6)
		Kit.pin(self, p, Kit.CYAN if i % 2 else Kit.VIOLET, out * 0.4 * (1 if i % 2 else -1), 1.0 - out * 0.85)
	Kit.letters(self, "STRIKE!", Rect2(20, 42, 212, 34), 34, Kit.MAGENTA, Kit.CYAN, smoothstep(0.05, 0.6, t), smoothstep(0.6, 0.65, t) * (0.001 + t))
	Kit.word(self, "ALL TEN, LIGHTS OUT", Rect2(40, 58, 172, 12), 10, Kit.GOLD, smoothstep(0.65, 0.85, t))

## Ten level-meter bars, one per pin, jump to the top and launch their pins.
func _equalizer(t: float) -> void:
	var fade := 1.0 - smoothstep(0.6, 0.8, t) * 0.7
	for i in 10:
		var x := 26.0 + i * 21.0
		var rise := smoothstep(0.04 + i * 0.025, 0.28 + i * 0.025, t)
		var wobble := 0.0 if t > 0.5 else sin(t * 40.0 + i) * 0.08
		var level := clampf(rise + wobble, 0.0, 1.0)
		var blocks := int(level * 8.0)
		for b in blocks:
			var color: Color = Kit.CYAN.lerp(Kit.MAGENTA, b / 7.0)
			Kit.rect(self, x, 74 - b * 6, 13, 4, Color(color, fade))
		var launch := smoothstep(0.3 + i * 0.025, 0.6 + i * 0.025, t)
		var top := Vector2(x + 6, 70 - blocks * 6)
		if launch < 1.0:
			Kit.pin(self, top + Vector2(sin(i * 2.1) * 20.0, -60.0) * launch + Vector2(0, -2), Kit.WHITE, launch * 4.0 * (1 if i % 2 else -1), fade * (1.0 - launch))
	Kit.word(self, "STRIKE!", Rect2(40, 42, 172, 30), 32, Kit.MAGENTA, smoothstep(0.6, 0.8, t))
	Kit.word(self, "MAX LEVEL", Rect2(70, 62, 112, 12), 10, Kit.CYAN, smoothstep(0.7, 0.9, t))

## A neon skyline: the ball crosses the rooftops and every rooftop pin topples; the
## billboard lights.
func _skyline(t: float) -> void:
	var tops := [58, 46, 62, 40, 54, 48, 60, 44, 56, 50]
	for i in 10:
		var x := 136.0 + i * 10.0
		Kit.rect(self, x, tops[i], 9, 84 - tops[i], Color("140e33"))
		Kit.tube(self, PackedVector2Array([Vector2(x, 84), Vector2(x, tops[i]), Vector2(x + 9, tops[i]), Vector2(x + 9, 84)]), Kit.VIOLET if i % 2 else Kit.CYAN, 1.0, 0.6)
		for w in range(tops[i] + 5, 80, 7):
			Kit.rect(self, x + 3, w, 2, 2, Color(Kit.GOLD, 0.5 if (i + w) % 3 else 0.15))
	var ball_x := lerpf(120.0, 250.0, smoothstep(0.1, 0.55, t))
	for i in 10:
		var x := 140.5 + i * 10.0
		var fall := smoothstep(0.0, 0.15, (ball_x - x) / 130.0)
		Kit.pin(self, Vector2(x, tops[i] - 1) + Vector2(4, -6) * fall, Kit.MAGENTA, fall * 1.4, 1.0 - fall * 0.5)
	if t < 0.6: Kit.ball(self, Vector2(ball_x, 30), Vector2(22, 0))
	var board := Rect2(16, 16, 108, 40)
	Kit.tube_rect(self, board, Kit.MAGENTA, 2.0, smoothstep(0.45, 0.6, t))
	Kit.tube(self, PackedVector2Array([Vector2(26, 56), Vector2(26, 80)]), Kit.VIOLET, 1.0, 0.5)
	Kit.tube(self, PackedVector2Array([Vector2(114, 56), Vector2(114, 80)]), Kit.VIOLET, 1.0, 0.5)
	Kit.word(self, "STRIKE!", Rect2(20, 44, 100, 26), 26, Kit.MAGENTA, smoothstep(0.55, 0.75, t))
	Kit.word(self, "CITY CLEARED", Rect2(32, 68, 76, 12), 9, Kit.CYAN, smoothstep(0.7, 0.9, t))

## A mirror ball comes down, its beams turn slowly, and the pins dance off the floor.
func _mirror_ball(t: float) -> void:
	var center := Vector2(186, lerpf(-14.0, 28.0, smoothstep(0.0, 0.3, t)))
	draw_line(Vector2(186, 6), center, Color(Kit.VIOLET, 0.7), 1.0)
	var turn := _clock * 0.9
	for k in 8: # slow beams, never a strobe
		var a := turn + k * TAU / 8.0
		var tip := _inside(center, Vector2(cos(a), sin(a) * 0.6))
		draw_line(center, tip, Color(Kit.CYAN if k % 2 else Kit.MAGENTA, 0.12 * smoothstep(0.2, 0.35, t)), 3.0)
	Kit.glow(self, center, 18.0, Kit.WHITE, 1.0)
	draw_circle(center, 10.0, Color("2b2450"))
	for gx in range(-8, 9, 4):
		for gy in range(-8, 9, 4):
			if Vector2(gx, gy).length() > 9.0: continue
			var shine := 0.5 + 0.5 * sin(turn * 3.0 + gx * 0.7 + gy * 0.4)
			Kit.rect(self, center.x + gx - 1, center.y + gy - 1, 3, 3, Color(Kit.WHITE.lerp(Kit.VIOLET, shine), 0.4 + shine * 0.6))
	for i in 10:
		var x := 140.0 + i * 10.0
		var dance := sin(_clock * 10.0 + i * 1.3) * 3.0 * (1.0 - smoothstep(0.35, 0.5, t))
		var fall := smoothstep(0.4 + i * 0.03, 0.55 + i * 0.03, t)
		Kit.pin(self, Vector2(x, 76 - absf(dance) + fall * 2.0), Kit.MAGENTA if i % 2 else Kit.CYAN, fall * (1.5 if i % 2 else -1.5), 1.0 - fall * 0.5)
	Kit.word(self, "STRIKE!", Rect2(14, 38, 118, 28), 28, Kit.MAGENTA, smoothstep(0.55, 0.75, t))
	Kit.word(self, "FLOOR CLEARED", Rect2(16, 60, 114, 12), 10, Kit.CYAN, smoothstep(0.7, 0.9, t))

# --- Spares ------------------------------------------------------------------------

## The spare's slash draws across the last pins and cuts them clean in two.
func _laser_slash(t: float) -> void:
	var a := Vector2(150, 80)
	var b := Vector2(232, 12)
	var draw_t := smoothstep(0.05, 0.4, t)
	var cut := smoothstep(0.4, 0.75, t)
	var pins := [Vector2(176, 52), Vector2(192, 62), Vector2(206, 46)]
	var normal := (b - a).normalized().orthogonal()
	for i in pins.size():
		var p: Vector2 = pins[i]
		Kit.pin(self, p + normal * 10.0 * cut, Kit.CYAN, -cut * 0.5, 1.0 - cut * 0.8)
		Kit.pin(self, p - normal * 10.0 * cut, Kit.MAGENTA, cut * 0.5, 1.0 - cut * 0.8)
	if draw_t > 0.0:
		Kit.tube(self, PackedVector2Array([a, a.lerp(b, draw_t)]), Kit.WHITE, 3.0, 1.0 - cut * 0.5)
	Kit.word(self, "SPARE!", Rect2(16, 32, 112, 28), 30, Kit.CYAN, smoothstep(0.55, 0.75, t))
	Kit.word(self, "CLEAN CUT", Rect2(20, 58, 104, 12), 10, Kit.MAGENTA, smoothstep(0.7, 0.9, t))

## A prize claw rides its rail, drops, and lifts the last pin away.
func _claw(t: float) -> void:
	Kit.tube(self, PackedVector2Array([Vector2(140, 14), Vector2(238, 14)]), Kit.VIOLET, 2.0)
	var x := lerpf(150.0, 206.0, smoothstep(0.0, 0.28, t))
	var drop := smoothstep(0.28, 0.45, t) - smoothstep(0.55, 0.72, t)
	x = lerpf(x, 232.0, smoothstep(0.72, 0.88, t))
	var y := 18.0 + drop * 34.0
	var grip := smoothstep(0.45, 0.52, t)
	draw_line(Vector2(x, 14), Vector2(x, y), Color(Kit.WHITE, 0.8), 1.0)
	var spread := lerpf(7.0, 3.0, grip)
	Kit.tube(self, PackedVector2Array([Vector2(x - spread - 2, y + 8), Vector2(x - spread, y + 2), Vector2(x + spread, y + 2), Vector2(x + spread + 2, y + 8)]), Kit.GOLD, 1.5)
	var held := grip > 0.5
	var pin_at := Vector2(x, y + 22) if held else Vector2(206, 70)
	if t > 0.88: pin_at = Vector2(232, lerpf(y + 22, 70.0, smoothstep(0.88, 1.0, t)))
	Kit.tube(self, PackedVector2Array([Vector2(222, 56), Vector2(222, 78), Vector2(240, 78), Vector2(240, 56)]), Kit.CYAN, 1.0, 0.7)
	Kit.pin(self, pin_at, Kit.MAGENTA, 0.15 * sin(_clock * 6.0) if held and t < 0.88 else 0.0)
	Kit.word(self, "SPARE!", Rect2(16, 32, 112, 28), 30, Kit.CYAN, smoothstep(0.55, 0.75, t))
	Kit.word(self, "PICKED UP", Rect2(20, 58, 104, 12), 10, Kit.GOLD, smoothstep(0.7, 0.9, t))

## A spotlight searches the dark lane, finds the last pin, and the ball rolls in.
func _spotlight(t: float) -> void:
	var source := Vector2(170, 6)
	var target := Vector2(206, 70)
	var search := Vector2(140 + 70 * sin(t * 9.0), 72) if t < 0.35 else target
	if t >= 0.3 and t < 0.38: search = Vector2(140 + 70 * sin(0.35 * 9.0), 72).lerp(target, (t - 0.3) / 0.08)
	var cone := PackedVector2Array([source, search + Vector2(-16, 8), search + Vector2(16, 8)])
	draw_colored_polygon(cone, Color(Kit.WHITE, 0.10))
	Kit.glow(self, search + Vector2(0, 4), 14.0, Kit.WHITE, 1.2)
	var knock := smoothstep(0.7, 0.85, t)
	Kit.pin(self, target + Vector2(8, -3) * knock, Kit.MAGENTA, knock * 1.4, 0.4 + 0.6 * smoothstep(0.3, 0.4, t))
	if t > 0.42 and t < 0.92:
		var bx := lerpf(132.0, target.x - 6.0, smoothstep(0.42, 0.72, t))
		Kit.ball(self, Vector2(bx, 72), Vector2(16, 0))
	Kit.word(self, "SPARE!", Rect2(16, 32, 112, 28), 30, Kit.CYAN, smoothstep(0.72, 0.85, t))
	Kit.word(self, "FOUND IT", Rect2(20, 58, 104, 12), 10, Kit.VIOLET, smoothstep(0.8, 0.95, t))

## A beam bridges the split; the ball sends one pin sliding along it into the other.
func _split_bridge(t: float) -> void:
	var left := Vector2(146, 68)
	var right := Vector2(216, 68)
	var bridge := smoothstep(0.05, 0.3, t)
	if bridge > 0.0:
		Kit.tube(self, PackedVector2Array([left + Vector2(0, -6), (left + Vector2(0, -6)).lerp(right + Vector2(0, -6), bridge)]), Kit.CYAN, 1.0, 0.8)
	var hit := smoothstep(0.4, 0.5, t)
	var slide := smoothstep(0.5, 0.75, t)
	var meet := smoothstep(0.72, 0.85, t)
	var moving := left.lerp(right - Vector2(10, 0), slide)
	Kit.pin(self, moving + Vector2(0, -2) * meet, Kit.MAGENTA, -1.2 * hit + 0.4 * meet, 1.0 - meet * 0.4)
	Kit.pin(self, right + Vector2(5, -2) * meet, Kit.MAGENTA, meet * 1.4, 1.0 - meet * 0.4)
	if t > 0.3 and t < 0.5:
		Kit.ball(self, Vector2(lerpf(120.0, left.x - 6.0, smoothstep(0.3, 0.42, t)), 72), Vector2(14, 0))
	Kit.word(self, "SPARE!", Rect2(16, 32, 112, 28), 30, Kit.CYAN, smoothstep(0.72, 0.85, t))
	Kit.word(self, "SPLIT SEALED", Rect2(16, 58, 112, 12), 10, Kit.GOLD, smoothstep(0.8, 0.95, t))

# --- Slick -------------------------------------------------------------------------

## Slick's own shine: the oil spreads under the frame and the portrait slides off
## its mark with a wobble.
func _slick_slip(t: float) -> void:
	var spread := smoothstep(0.05, 0.3, t)
	for k in 3:
		var r := (34.0 - k * 9.0) * spread
		if r > 1.0:
			draw_arc(Vector2(48, 82), r, PI, TAU, 24, Color(Kit.VIOLET.lerp(Kit.CYAN, k * 0.5), 0.5), 2.0)
	var slip := smoothstep(0.3, 0.55, t)
	var wobble := sin(t * 40.0) * 0.08 * (smoothstep(0.2, 0.3, t) - slip) if t < 0.55 else 0.0
	_portrait(Vector2(-6, 8) * slip, wobble - 0.35 * slip)
	if slip > 0.2:
		for i in 3: # motion lines
			Kit.tube(self, PackedVector2Array([Vector2(82, 30 + i * 12), Vector2(82 + 10 * slip, 30 + i * 12)]), Kit.CYAN, 1.0, 0.6)
	_name(Kit.VIOLET)
	_defeated(smoothstep(0.55, 0.7, t))
	Kit.word(self, "SLIPPED ON THE SHINE", Rect2(92, 64, 144, 12), 9, Kit.CYAN, smoothstep(0.7, 0.9, t))

## A squeegee wipes the sheen off Slick's sign: the shine goes, the verdict stays.
func _slick_squeegee(t: float) -> void:
	_portrait()
	_name(Kit.VIOLET)
	var wipe_x := lerpf(84.0, 246.0, smoothstep(0.25, 0.65, t))
	for i in 6: # the sheen, only where the squeegee has not been
		var x := 100.0 + i * 24.0 + fposmod(_clock * 30.0, 24.0)
		if x > wipe_x:
			draw_line(Vector2(x, 62), Vector2(x + 10, 38), Color(Kit.WHITE, 0.35), 2.0)
	var shine := (1.0 - smoothstep(0.3, 0.45, t)) * smoothstep(0.0, 0.15, t)
	if t < 0.45: Kit.word(self, "SHINE ON", _big(), 22, Kit.VIOLET, shine)
	_defeated(smoothstep(0.48, 0.62, t), Kit.MAGENTA, false)
	if t < 0.75:
		Kit.tube(self, PackedVector2Array([Vector2(wipe_x, 34), Vector2(wipe_x, 66)]), Kit.GOLD, 2.0)
		Kit.tube(self, PackedVector2Array([Vector2(wipe_x, 50), Vector2(wipe_x + 10, 50)]), Kit.GOLD, 1.5)
	Kit.word(self, "WIPED DRY", Rect2(96, 64, 136, 12), 10, Kit.CYAN, smoothstep(0.7, 0.9, t))

# --- Laser Lena --------------------------------------------------------------------

## Lena's beams wave, cross, and tie themselves into a bow.
func _lena_tangle(t: float) -> void:
	_portrait()
	_name(Kit.VIOLET)
	var knot := smoothstep(0.15, 0.55, t)
	var center := Vector2(106, 48)
	for beam in 2:
		var pts := PackedVector2Array()
		for i in 33:
			var u := i / 32.0
			var straight := Vector2(80 + u * 50.0, 36 + beam * 16 + sin(u * TAU * 2.0 + _clock * 6.0) * 4.0 * (1.0 - knot))
			var s := u * TAU
			var bow := center + Vector2(sin(s) * 15.0, sin(s * 2.0) * 9.0 * (1 if beam == 0 else -1))
			pts.append(straight.lerp(bow, knot))
		Kit.tube(self, pts, Kit.CYAN if beam == 0 else Kit.MAGENTA, 1.0)
	if knot > 0.9:
		Kit.glow(self, center, 6.0, Kit.WHITE, 2.0)
	Kit.word(self, "DEFEATED!", Rect2(134, 37, 104, 24), 22, Kit.MAGENTA, smoothstep(0.55, 0.7, t))
	Kit.word(self, "TIED UP IN LIGHT", Rect2(128, 66, 108, 12), 10, Kit.CYAN, smoothstep(0.7, 0.9, t))

# --- DJ Flicker --------------------------------------------------------------------

## The decks spin down, the meters drop, the power light goes out.
func _power_down(t: float) -> void:
	_portrait()
	_name(Kit.CYAN)
	var spin := 1.0 - smoothstep(0.1, 0.55, t)
	var back := 1.0 - smoothstep(0.5, 0.65, t) * 0.75
	var angle := _clock * 8.0 * spin if t < 0.55 else 2.2
	for d in 2:
		var c := Vector2(122 + d * 82, 52)
		draw_circle(c, 14.0, Color("1a1438", back))
		draw_arc(c, 14.0, 0.0, TAU, 24, Color(Kit.VIOLET, back), 1.5)
		draw_arc(c, 8.0, 0.0, TAU, 20, Color(Kit.VIOLET, 0.5 * back), 1.0)
		var a := angle + d * 1.3
		draw_line(c, c + Vector2(cos(a), sin(a)) * 12.0, Color(Kit.WHITE, back), 1.0)
	for i in 6: # the meter between the decks
		var h := int(maxf(spin * (3 + (i * 7 + int(_clock * 12.0)) % 5), 0.0))
		for b in h:
			Kit.rect(self, 145 + i * 7, 62 - b * 4, 5, 3, Color(Kit.CYAN.lerp(Kit.MAGENTA, b / 6.0), back))
	var power := Vector2(232, 72)
	draw_circle(power, 3.0, Kit.CYAN.lerp(Color("2a2a3a"), smoothstep(0.45, 0.55, t)))
	_defeated(smoothstep(0.6, 0.75, t))
	Kit.word(self, "SET'S OVER", Rect2(96, 64, 128, 12), 10, Kit.VIOLET, smoothstep(0.72, 0.9, t))

## A record scratch: the needle skids across the vinyl and the track stops.
func _scratch(t: float) -> void:
	_portrait()
	_name(Kit.CYAN)
	var gone := smoothstep(0.5, 0.65, t)
	var c := Vector2(164, 50)
	var turning := _clock * 6.0 * (1.0 - smoothstep(0.32, 0.45, t))
	if gone < 1.0:
		draw_set_transform(c, gone * 3.0, Vector2.ONE * maxf(1.0 - gone, 0.01))
		c = Vector2.ZERO
		draw_circle(c, 22.0, Color("0d0a1e"))
		for r in [20.0, 16.0, 12.0]:
			draw_arc(c, r, turning, turning + 4.5, 20, Color(Kit.VIOLET, 0.5), 1.0)
		draw_circle(c, 5.0, Kit.MAGENTA)
		var skid := smoothstep(0.3, 0.42, t)
		var arm := Vector2(48, -24)
		var needle := Vector2(18, -14).lerp(Vector2(2, 10), skid)
		Kit.tube(self, PackedVector2Array([arm, needle]), Kit.WHITE, 1.0)
		if skid > 0.0 and skid < 1.0 or (t > 0.42 and t < 0.5):
			var zig := PackedVector2Array()
			for i in 8: zig.append(Vector2(22 + i * 6, 14 + (4 if i % 2 else -4)))
			Kit.tube(self, zig, Kit.GOLD, 1.0)
		draw_set_transform(Vector2.ZERO)
	_defeated(smoothstep(0.6, 0.75, t))
	Kit.word(self, "RECORD SCRATCHED", Rect2(96, 64, 140, 12), 10, Kit.GOLD, smoothstep(0.72, 0.9, t))

## Title night: the HEADLINER sign goes dark letter by letter and relights in gold
## for the new headliner.
func _headline(t: float) -> void:
	_portrait(Vector2.ZERO, 0.0, Color.WHITE.lerp(Color(0.5, 0.5, 0.6), smoothstep(0.3, 0.5, t)), Kit.GOLD)
	_name(Kit.CYAN)
	var out := smoothstep(0.1, 0.4, t)
	if t < 0.42: Kit.letters(self, "HEADLINER", _big(), 22, Kit.VIOLET, Kit.VIOLET, 1.0 - out)
	_defeated(smoothstep(0.45, 0.6, t), Kit.GOLD.lerp(Kit.MAGENTA, 0.35), false)
	Kit.word(self, "NEW HEADLINER: YOU", Rect2(94, 68, 142, 12), 9, Kit.GOLD, smoothstep(0.65, 0.85, t))
	_crown_flourish(t)

## The crowd's glow sticks rise and call for an encore: for the player.
func _encore(t: float) -> void:
	_portrait(Vector2(0, 4) * smoothstep(0.2, 0.5, t), 0.0, Color.WHITE.lerp(Color(0.45, 0.45, 0.6), smoothstep(0.2, 0.5, t)))
	_name(Kit.CYAN)
	var rise := smoothstep(0.05, 0.35, t)
	for i in 16:
		var x := 90.0 + i * 9.5
		var sway := sin(_clock * 4.0 + i * 0.9) * 0.4
		var base := Vector2(x, 90 - rise * 10.0)
		var color: Color = [Kit.CYAN, Kit.MAGENTA, Kit.GOLD, Kit.VIOLET][i % 4]
		Kit.tube(self, PackedVector2Array([base, base + Vector2(sin(sway), -cos(sway)) * 8.0]), color, 1.0, 0.6 + 0.4 * rise)
	if t > 0.15 and t < 0.5: Kit.word(self, "ENCORE!", _big(), 22, Kit.CYAN, (smoothstep(0.2, 0.35, t) - smoothstep(0.42, 0.5, t)))
	_defeated(smoothstep(0.5, 0.65, t), Kit.GOLD.lerp(Kit.MAGENTA, 0.35), false)
	Kit.word(self, "THE ENCORE IS YOURS", Rect2(94, 66, 142, 10), 8, Kit.GOLD, smoothstep(0.68, 0.85, t))
	_crown_flourish(t)
