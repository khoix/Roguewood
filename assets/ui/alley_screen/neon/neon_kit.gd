extends RefCounted
## UI-A9-N preview (Claude, 2026-11-24, while Codex is away): the Neon League's alley
## screen kit, at the same 252 x 90 display resolution as UI-A9-H's House kit.
## Neon tubes on a night grid: every glow is a few soft passes under a bright core,
## no runtime randomness, no textures but the rivals' own portraits.
const NIGHT := Color("0b0820")
const GRID := Color("2a1d5c")
const MAGENTA := Color("ff4fd8")
const CYAN := Color("3ff2ff")
const VIOLET := Color("b48cff")
const GOLD := Color("f5cb69")
const WHITE := Color("fff6ff")
const FONT = preload("res://assets/ui/fonts/PixelifySans.ttf")

static func rect(c: CanvasItem, x: float, y: float, w: float, h: float, color: Color) -> void:
	c.draw_rect(Rect2(roundf(x), roundf(y), w, h), color)

## A neon tube: soft wide passes, then the bright core.
static func tube(c: CanvasItem, points: PackedVector2Array, color: Color, width: float = 2.0, lit: float = 1.0) -> void:
	if lit <= 0.0: 
		c.draw_polyline(points, Color(color, 0.18), width)
		return
	for pass_width in [width + 6.0, width + 3.0]:
		c.draw_polyline(points, Color(color, 0.14 * lit), pass_width)
	c.draw_polyline(points, Color(color.lerp(WHITE, 0.35), lit), width)

static func tube_rect(c: CanvasItem, r: Rect2, color: Color, width: float = 2.0, lit: float = 1.0) -> void:
	tube(c, PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]), color, width, lit)

## The stage: the night sky, a perspective floor grid that scrolls toward the viewer,
## and a double tube frame (magenta outside, cyan inside).
static func stage(c: CanvasItem, scroll: float) -> void:
	rect(c, 0, 0, 252, 90, Color("05030f"))
	rect(c, 3, 3, 246, 84, NIGHT)
	var horizon := 52.0
	for i in 9: # horizontal floor lines, closer together toward the horizon
		var f := fposmod(float(i) + scroll * 1.5, 9.0) / 9.0
		var y := horizon + pow(f, 2.0) * 32.0
		rect(c, 6, y, 240, 1, Color(GRID, 0.4 + f * 0.6))
	for i in range(-8, 9): # lines toward the vanishing point
		var bottom := Vector2(126 + i * 30, 84)
		c.draw_line(Vector2(126 + i * 4, horizon), bottom, Color(GRID, 0.7), 1.0)
	for x in range(14, 240, 37): # far stars
		rect(c, x + (x * 7) % 11, 10 + (x * 13) % 30, 1, 1, Color(VIOLET, 0.6))
	tube_rect(c, Rect2(5, 5, 242, 80), MAGENTA, 2.0)
	tube_rect(c, Rect2(9, 9, 234, 72), CYAN, 1.0, 0.7)

## Words in tube lettering: a glow under the letters, then the letters; `lit` 0..1
## turns them on (a half-lit word is dim, as a tube warming up).
static func word(c: CanvasItem, text: String, rect_: Rect2, font_size: int, color: Color, lit: float = 1.0) -> void:
	var fs := font_size
	while fs > 8 and FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > rect_.size.x:
		fs -= 1
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var p := Vector2(roundf(rect_.position.x + (rect_.size.x - width) * 0.5), rect_.position.y)
	if lit > 0.05:
		for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			c.draw_string(FONT, p + o, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(color, 0.35 * lit))
	c.draw_string(FONT, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(color.lerp(WHITE, 0.25), 0.25 + 0.75 * lit))

## A pin drawn as a neon outline (a sign's pin), standing or knocked at `angle`.
static func pin(c: CanvasItem, p: Vector2, color: Color, angle: float = 0.0, lit: float = 1.0) -> void:
	var outline := PackedVector2Array([Vector2(-2,-16),Vector2(2,-16),Vector2(4,-13),Vector2(3,-9),Vector2(5,-4),Vector2(5,1),Vector2(3,3),Vector2(-3,3),Vector2(-5,1),Vector2(-5,-4),Vector2(-3,-9),Vector2(-4,-13),Vector2(-2,-16)])
	var t := Transform2D(angle, p.round())
	tube(c, t * outline, color, 1.0, lit)
	c.draw_line(t * Vector2(-3, -10), t * Vector2(3, -10), Color(MAGENTA if color != MAGENTA else CYAN, lit), 1.0)

## The ball: a cyan disc with a bright rim and a short streak behind it.
static func ball(c: CanvasItem, p: Vector2, streak: Vector2 = Vector2.ZERO) -> void:
	if streak != Vector2.ZERO:
		for i in 4:
			c.draw_line(p - streak * (i + 1) * 0.25, p - streak * i * 0.25, Color(CYAN, 0.5 - i * 0.1), 4.0 - i)
	c.draw_circle(p.round(), 7.0, Color("103a52"))
	c.draw_arc(p.round(), 7.0, 0.0, TAU, 20, Color(CYAN, 0.35), 4.0)
	c.draw_arc(p.round(), 7.0, 0.0, TAU, 20, CYAN, 1.5)
	rect(c, p.x - 3, p.y - 3, 2, 2, WHITE)

static func spark(c: CanvasItem, p: Vector2, color: Color, size: float = 3.0) -> void:
	c.draw_line(p - Vector2(size, 0), p + Vector2(size, 0), color, 1.0)
	c.draw_line(p - Vector2(0, size), p + Vector2(0, size), color, 1.0)
