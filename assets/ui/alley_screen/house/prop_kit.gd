extends RefCounted
## Original UI-A9-H pixel geometry, authored at the 252 x 90 display resolution.
## Palette and clusters are source art: no external images or runtime randomness.
const INK := Color("142b30")
const WOOD := Color("603c32")
const GOLD := Color("d5a35a")
const LIGHT := Color("ffdf99")
const IVORY := Color("f4e4c0")
const TEAL := Color("55aaa1")

static func rect(c: CanvasItem, x: float, y: float, w: float, h: float, color: Color) -> void:
	c.draw_rect(Rect2(roundf(x), roundf(y), w, h), color)

static func stage(c: CanvasItem) -> void:
	rect(c, 0, 0, 252, 90, INK)
	rect(c, 3, 3, 246, 84, WOOD)
	rect(c, 6, 6, 240, 78, GOLD)
	rect(c, 8, 8, 236, 74, INK)
	for y in range(12, 78, 8):
		rect(c, 10, y, 232, 1, Color("20373a"))
	rect(c, 10, 71, 232, 10, Color("714b37"))
	rect(c, 10, 71, 232, 2, GOLD)
	for x in range(16, 245, 31):
		rect(c, x, 76, 18, 1, Color("9a6945"))
	for x in [4, 245]:
		for y in [4, 83]:
			rect(c, x, y, 3, 3, LIGHT)

static func pin(c: CanvasItem, p: Vector2, angle: float = 0.0, surprised: bool = false, scale_factor: float = 1.0) -> void:
	c.draw_set_transform(p.round(), angle, Vector2.ONE*scale_factor)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-3,-22),Vector2(3,-22),Vector2(5,-19),Vector2(4,-14),Vector2(3,-11),Vector2(6,-6),Vector2(7,0),Vector2(5,3),Vector2(-5,3),Vector2(-7,0),Vector2(-6,-6),Vector2(-3,-11),Vector2(-4,-14),Vector2(-5,-19)]), INK)
	rect(c,-3,-21,6,8,IVORY)
	rect(c,-2,-13,4,5,IVORY)
	rect(c,-4,-8,8,10,IVORY)
	rect(c,-6,-4,12,4,IVORY)
	rect(c,3,-7,2,8,Color("c4ae88"))
	rect(c,-2,-13,4,2,Color("ad5442"))
	rect(c,-2,-10,4,1,GOLD)
	rect(c,-2,-19,1,2,INK)
	rect(c,2,-19,1,2,INK)
	rect(c,0,-16,2 if surprised else 3,2 if surprised else 1,INK)
	rect(c,-3,-6,2,5,Color("fff5dc"))
	c.draw_set_transform(Vector2.ZERO)

static func ball(c: CanvasItem, p: Vector2, angle: float = 0.0) -> void:
	c.draw_set_transform(p.round(), angle)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-7,-10),Vector2(7,-10),Vector2(11,-6),Vector2(11,6),Vector2(7,10),Vector2(-7,10),Vector2(-11,6),Vector2(-11,-6)]), INK)
	rect(c,-7,-9,14,18,Color("347d79"))
	rect(c,-10,-5,20,10,Color("347d79"))
	rect(c,-7,-7,9,3,TEAL)
	rect(c,-9,-4,3,7,TEAL)
	rect(c,-5,6,12,2,Color("245754"))
	for q in [Vector2(1,-4),Vector2(5,-2),Vector2(2,1)]:
		rect(c,q.x,q.y,2,2,INK)
	c.draw_set_transform(Vector2.ZERO)

static func chair(c: CanvasItem, p: Vector2) -> void:
	for x in [0,17]:
		rect(c,p.x+x,p.y-28,3,35,WOOD)
		rect(c,p.x+x,p.y-27,1,33,GOLD)
	rect(c,p.x,p.y-26,20,9,WOOD)
	rect(c,p.x+2,p.y-24,16,2,GOLD)
	rect(c,p.x-2,p.y-6,24,4,GOLD)
	rect(c,p.x-2,p.y-2,24,2,WOOD)

static func tape(c: CanvasItem, points: PackedVector2Array) -> void:
	c.draw_polyline(points, INK, 7.0)
	c.draw_polyline(points, GOLD, 5.0)
	c.draw_polyline(points, LIGHT, 1.0)
	for p in points:
		rect(c,p.x-1,p.y-2,1,4,WOOD)

static func sparkle(c: CanvasItem, p: Vector2) -> void:
	rect(c,p.x-3,p.y,7,1,LIGHT)
	rect(c,p.x,p.y-3,1,7,LIGHT)
