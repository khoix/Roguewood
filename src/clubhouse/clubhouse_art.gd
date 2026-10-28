extends RefCounted
## Clubhouse art by asset ID, with E16-ART originals and explicit missing-art fallback.
## A slot draws res://assets/clubhouse/<asset id>.png when that file exists, or the
## path itself when the catalogue already names one (res://...). Otherwise it draws
## a marked placeholder that shows the asset ID, so missing art is visible, never
## silently passed off as finished. No code changes are needed when art lands.
const DIRECTORY := "res://assets/clubhouse/"
const STATE_MARKS := {"locked": "×", "available": "○", "discovered": "◆", "mastered": "♛"}

static func panel_style(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	return style

static func button_style(button: Button, state: String = "available") -> void:
	button.add_theme_stylebox_override("normal", panel_style(Color("182b32"), Color("697a7b")))
	button.add_theme_stylebox_override("hover", panel_style(Color("263e45"), Color("d8b873"), 2))
	button.add_theme_stylebox_override("pressed", panel_style(Color("30454a"), Color("f0d99b"), 3))
	var focus := panel_style(Color(0,0,0,0), Color("fff1c9"), 3)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color("f4e9cf"))
	button.add_theme_color_override("font_pressed_color", Color("fff3d6"))
	if state == "mastered":
		button.add_theme_stylebox_override("normal", panel_style(Color("283332"), Color("d8b873"), 3))
	elif state == "locked":
		button.add_theme_stylebox_override("normal", panel_style(Color("191f29"), Color("8c939e")))
	elif state == "discovered":
		button.add_theme_stylebox_override("normal", panel_style(Color("203239"), Color("a1c5c5"), 2))

static func mastered_finish(picture: Control) -> void:
	if not picture is TextureRect: return
	var foil := ShaderMaterial.new()
	foil.shader = preload("res://assets/motion/foil.gdshader")
	foil.set_shader_parameter("strength", 0.55)
	foil.set_shader_parameter("border_only", true)
	foil.set_shader_parameter("tilt", Vector2.ZERO)
	picture.material = foil

static func path_for(asset: String) -> String:
	if asset.begins_with("res://"):
		return asset
	return DIRECTORY + asset + ".png"

static func has_art(asset: String) -> bool:
	return ResourceLoader.exists(path_for(asset))

## A square slot: the texture, or a placeholder panel naming the asset ID.
static func slot(asset: String, side: float, earned: bool = true) -> Control:
	if has_art(asset):
		var picture := TextureRect.new()
		picture.texture = load(path_for(asset))
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size = Vector2(side, side)
		picture.modulate = Color.WHITE if earned else Color(1, 1, 1, 0.35)
		picture.name = "Art"
		return picture
	var box := PanelContainer.new()
	box.name = "Placeholder"
	box.custom_minimum_size = Vector2(side, side)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.15, 0.22) if earned else Color(0.09, 0.09, 0.12)
	style.border_color = Color(0.95, 0.75, 0.35) if earned else Color(0.4, 0.4, 0.48)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	box.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "placeholder\n" + asset
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.82))
	box.add_child(label)
	return box
