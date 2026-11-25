extends Control
## UI-A8 (Claude, 2026-11-24; owner: "The background needs to be ambient but pushing the
## theme forward visually"): the shared frame for a League's backdrop, the space
## beside and behind the lane.
## The League paints its layers at 1/PX of the screen (pixel art, like the rooms)
## into its own small view, which is scaled up crisp. The view redraws only on a
## REDRAW_HZ tick, so the per-frame cost is small on a phone. `reduced` (reduced motion,
## or reduced flash) paints one still picture. A League script overrides
## `paint(canvas, size, time)`; `division` and `championship` say which room the match
## is in (set_stage).
const PX := 2
const REDRAW_HZ := 20.0
@export var reduced := false:
	set(value):
		reduced = value
		_refresh()
var option := 0 # kept for the House sky's old callers (unused by the painters)
var division := 1
var championship := false
## Where the camera's eye line meets the screen (0 top, 1 bottom): the far ground
## meets the sky here, so the scenery lines up with the alley's floor (throw_lab sets it
## each frame from the 3D camera).
var horizon := 0.47
var time := 0.0
## The old backdrops' clock name (J22L02ART and the art inspectors set it): the same clock.
var phase: float:
	get: return time
	set(value):
		time = value
		_refresh()
var _view: SubViewport
var _canvas: Control
var _since := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := SubViewportContainer.new()
	box.name = "Pixels"
	box.stretch = true
	box.stretch_shrink = PX
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(box)
	_view = SubViewport.new()
	_view.name = "View"
	_view.transparent_bg = false
	_view.render_target_update_mode = SubViewport.UPDATE_ONCE
	box.add_child(_view)
	_canvas = Control.new()
	_canvas.name = "Canvas"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_paint)
	_view.add_child(_canvas)
	_view.size_changed.connect(_refresh)

## The camera's eye line on screen (a fraction of the height); redraws when it moves.
func set_horizon(at: float) -> void:
	if absf(at - horizon) < 0.002: return
	horizon = clampf(at, 0.08, 0.9)
	_refresh()

## The room the match is in: Division 1–8, and the Championship stage.
func set_stage(at_division: int, at_championship: bool) -> void:
	division = clampi(at_division, 1, 8)
	championship = at_championship
	_refresh()

func _process(delta: float) -> void:
	if reduced or _view == null: return
	time += delta
	_since += delta
	if _since >= 1.0 / REDRAW_HZ:
		_since = 0.0
		_refresh()

func _refresh() -> void:
	if _canvas == null: return
	_canvas.queue_redraw()
	_view.render_target_update_mode = SubViewport.UPDATE_ONCE

func _paint() -> void:
	var size_now := Vector2(_view.size)
	_canvas.size = size_now
	paint(_canvas, size_now, 0.0 if reduced else time)

## Override: draw the League's layers on `c` (canvas pixels), at `t` seconds.
func paint(_c: CanvasItem, _s: Vector2, _t: float) -> void:
	pass

# --- Helpers for the painters ------------------------------------------------------

## A fixed pseudo-random number in [0, 1) for index i (no runtime randomness, so the
## same room always looks the same).
static func rnd(i: float, salt: float = 0.0) -> float:
	return fposmod(sin(i * 12.9898 + salt * 78.233) * 43758.5453, 1.0)

static func px(c: CanvasItem, x: float, y: float, w: float, h: float, color: Color) -> void:
	c.draw_rect(Rect2(floorf(x), floorf(y), w, h), color)

## A soft glow: a few faint discs.
static func glow(c: CanvasItem, p: Vector2, radius: float, color: Color, strength: float = 1.0) -> void:
	for k in 3:
		c.draw_circle(p.floor(), radius * (1.0 - k * 0.3), Color(color, 0.07 * strength))

## A vertical gradient in hard bands (dithered steps, pixel art), from y0 to y1.
static func bands(c: CanvasItem, width: float, y0: float, y1: float, from: Color, to: Color, steps: int = 14) -> void:
	var h := (y1 - y0) / steps
	for i in steps:
		px(c, 0, y0 + i * h, width, ceilf(h) + 1.0, from.lerp(to, float(i) / maxf(steps - 1, 1)))
