extends Control
var count := 0
func _ready() -> void:
	custom_minimum_size = Vector2(45,32)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	draw_rect(Rect2(0,0,45,32),Color("153b3e"))
	draw_rect(Rect2(0,0,45,32),Color("b48b4b"),false,1)
	draw_line(Vector2(1,15),Vector2(44,15),Color("75998d"),1)
	for i in mini(count,6):
		var at := Vector2(7+(i%3)*15,5+(i/3)*16)
		var ink := Color("e8c875")
		draw_colored_polygon(PackedVector2Array([at+Vector2(-4,0),at+Vector2(4,0),at+Vector2(2,5),at+Vector2(-2,5)]),ink)
		draw_arc(at+Vector2(-4,1),2,0,PI,8,ink,1)
		draw_arc(at+Vector2(4,1),2,0,PI,8,ink,1)
		draw_line(at+Vector2(0,5),at+Vector2(0,8),ink,2)
		draw_line(at+Vector2(-3,9),at+Vector2(3,9),ink,2)
