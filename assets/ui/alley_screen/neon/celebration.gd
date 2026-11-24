extends Control
## UI-A9-N preview (Claude, 2026-11-24, at the owner's request while Codex is away):
## Neon alley-screen storyboards on the UI-A9-H contract (play, skip, duration,
## finished; 252 x 90; reduced motion holds the final tableau). Not listed in the Neon
## manifest: a preview for the owner, three of the eighteen.
signal finished
const Kit = preload("res://assets/ui/alley_screen/neon/neon_kit.gd")
const RivalArt = preload("res://src/presentation/rival_art.gd")
@export var variant := "strike.laser_sweep"
var context: Dictionary = {}
var elapsed := 0.0
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
	var t := 1.0 if reduced else clampf(elapsed / (duration() * 0.7), 0.0, 1.0)
	Kit.stage(self, 0.0 if reduced else elapsed)
	match variant:
		"strike.laser_sweep": _laser_sweep(t)
		"spare.bank_shot": _bank_shot(t)
		_: if variant.begins_with("boss."): _lights_out(t, reduced)

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
func _lights_out(t: float, reduced: bool) -> void:
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
	Kit.word(self, String(context.get("rival_name", "Laser Lena")).to_upper(), Rect2(92, 18, 144, 14), 13, Kit.VIOLET, 1.0)
	# The sign buzzes on: two short flickers, then steady (none under reduced motion).
	var lit := 1.0 if reduced else (0.0 if t < 0.5 else (0.35 if t < 0.56 else (1.0 if t < 0.62 else (0.3 if t < 0.66 else 1.0))))
	Kit.word(self, "DEFEATED!", Rect2(92, 36, 144, 24), 24, Kit.MAGENTA, lit)
	Kit.word(self, "LINE BROKEN", Rect2(96, 62, 136, 12), 10, Kit.CYAN, smoothstep(0.7, 0.9, t))
