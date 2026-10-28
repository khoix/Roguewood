extends RefCounted
## Clubhouse art by asset ID (E16; the files arrive with E16-ART, owned by Codex).
## A slot draws res://assets/clubhouse/<asset id>.png when that file exists, or the
## path itself when the catalogue already names one (res://...). Otherwise it draws
## a marked placeholder that shows the asset ID, so missing art is visible, never
## silently passed off as finished. No code changes are needed when art lands.
const DIRECTORY := "res://assets/clubhouse/"

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
