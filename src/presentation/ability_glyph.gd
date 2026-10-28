extends Control
## A bounded 64px annotation next to the score header; never covers a log row.
var style: Resource
var age := 10.0
var still := false
var enabled := true
var identity: Texture2D
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(64,64)
	texture_filter = TEXTURE_FILTER_NEAREST
func show_cue(recipe: Resource, reduced: bool, texture: Texture2D) -> void:
	style = recipe
	age = 0
	still = reduced
	identity = texture
	queue_redraw()
func _process(delta: float) -> void:
	age += delta
	queue_redraw()
func _draw() -> void:
	if not enabled or style == null or age > style.duration: return
	var c := size * 0.5
	var t: float = 0.5 if still else clampf(age / style.duration,0,1)
	var ink: Color = style.ink
	if identity: draw_texture_rect(identity,Rect2(c - Vector2(18,18),Vector2(36,36)),false)
	match style.shape:
		"lock":
			for x in [-24,0,24]: draw_line(c+Vector2(x,-26),c+Vector2(x,26),ink,2)
			draw_rect(Rect2(c+Vector2(-8,-7),Vector2(16,14)),ink,false,3)
		"sweep":
			for j in 3: draw_line(c+Vector2(-26,-22+j*7+t*30),c+Vector2(26,-28+j*7+t*30),ink,2)
