extends RefCounted
## UI-2: the House interface theme from Codex's UI-A1 frame kit (assets/ui/house/)
## and the bundled Pixelify Sans. One Theme for the whole game, so every panel,
## button and label shares the kit instead of plain flat boxes. Kit textures
## nine-slice; they are never stretched as pictures.
const FONT = preload("res://assets/ui/fonts/PixelifySans.ttf")
const KIT := "res://assets/ui/house/"
## E22-L02: a League may bring its own frame kit (the same five frames by name).
## The kit in use is chosen before an attempt's screens are built and put back to
## the House kit when the attempt's lab is cleared; the Clubhouse is always House.
const KITS := {"league.house": KIT, "league.neon": "res://assets/ui/neon/"}
static var kit := KIT

static func use_kit(league_id: String) -> void:
	kit = KITS.get(league_id, KIT)

static func kit_id() -> String:
	return kit.trim_suffix("/").get_file()
const IVORY := Color("f4e6cd")
const BRASS := Color("e7bc70")
const SEA_GLASS := Color("95d9cb")
const INK := Color("101820")

## A copy of one kit frame ("hud", "panel", "slip", "menu", "shop") with the
## given content margins, so callers can tighten padding without editing the kit.
static func frame(kind: String, margin_x: float = -1.0, margin_y: float = -1.0) -> StyleBox:
	var style: StyleBoxTexture = load(kit + kind + ".tres").duplicate()
	if margin_x >= 0.0:
		style.content_margin_left = margin_x
		style.content_margin_right = margin_x
	if margin_y >= 0.0:
		style.content_margin_top = margin_y
		style.content_margin_bottom = margin_y
	return style

static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 22
	theme.set_stylebox("panel", "PanelContainer", frame("panel", 14.0, 12.0))
	theme.set_stylebox("panel", "Panel", frame("panel"))
	var normal := frame("shop", 14.0, 8.0)
	var pressed := frame("hud", 14.0, 8.0)
	var hover: StyleBoxTexture = normal.duplicate()
	hover.modulate_color = Color(1.12, 1.08, 1.0)
	var disabled: StyleBoxTexture = normal.duplicate()
	disabled.modulate_color = Color(1.0, 1.0, 1.0, 0.45)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = SEA_GLASS
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(8)
	focus.set_expand_margin_all(2)
	for type in ["Button", "OptionButton", "CheckButton"]:
		theme.set_stylebox("normal", type, normal)
		theme.set_stylebox("hover", type, hover)
		theme.set_stylebox("pressed", type, pressed)
		theme.set_stylebox("hover_pressed", type, pressed)
		theme.set_stylebox("disabled", type, disabled)
		theme.set_stylebox("focus", type, focus)
		theme.set_color("font_color", type, IVORY)
		theme.set_color("font_hover_color", type, Color.WHITE)
		theme.set_color("font_pressed_color", type, BRASS)
		theme.set_color("font_focus_color", type, Color.WHITE)
		theme.set_color("font_disabled_color", type, Color(IVORY, 0.5))
	theme.set_color("font_color", "Label", IVORY)
	theme.set_color("font_outline_color", "Label", INK)
	return theme
