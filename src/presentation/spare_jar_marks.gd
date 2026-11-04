extends Control
## Compact live jar. Count is supplied by the authoritative reveal adapter.
var count := 0
var drop_age := 2.0
var reduced := true
func _ready() -> void:
	custom_minimum_size = Vector2(54,48)
	mouse_filter = MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	drop_age += delta
	queue_redraw()
func _pin(at: Vector2) -> void:
	draw_circle(at,2.0,Color("f3dfb4"))
	draw_rect(Rect2(at+Vector2(-1,1),Vector2(2,4)),Color("f3dfb4"))
	draw_rect(Rect2(at+Vector2(-2,5),Vector2(4,6)),Color("f3dfb4"))
	draw_line(at+Vector2(-1,3),at+Vector2(1,3),Color("9b432b"),1)
func _draw() -> void:
	draw_style_box(_glass(),Rect2(5,10,44,36))
	draw_line(Vector2(9,10),Vector2(45,10),Color("c3a064"),3)
	# Up to nine readable specimens; the adjacent numeral is never capped.
	for i in mini(count,9):
		var at := Vector2(15+(i%3)*12,31-(i/3)*11)
		if i == mini(count,9)-1 and not reduced and drop_age < .55:
			at.y = lerpf(-1,at.y,clampf(drop_age/.55,0,1))
		_pin(at)
func _glass() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("143638")
	style.border_color = Color("7dafa2")
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	return style
