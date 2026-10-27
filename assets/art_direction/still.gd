extends SceneTree
## Isolated E11 art-review fixture. No simulation, input, or catalogue integration.
const INK = Color("101326")
const CREAM = Color("f5e4bf")
const TEAL = Color("64dbcc")
const GOLD = Color("e9b768")
const MUTED = Color("aaa7bd")
const NAMES = ["House pin", "Brass pin", "Ghost ball", "Resonance", "Kingpin"]
const RARITIES = ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"]
const TYPES = ["PIN / I", "PIN / II", "BALL / III", "CHARM / IV", "CHARM / V"]
const EFFECTS = ["Steady value", "Metallic finish", "Phase study", "Echo study", "Crown study"]
const COLORS = [Color("c4b69b"), Color("bb935b"), Color("75cbd1"), Color("c691d9"), GOLD]
var canvas: Control
var font: Font = ThemeDB.fallback_font
var landscape := false
var capture_path := ""
var card_rects: Array[Rect2] = []

func lane(rect: Rect2) -> void:
	var container := SubViewportContainer.new()
	container.position = rect.position
	container.size = rect.size
	container.stretch = true
	container.stretch_shrink = 2
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(rect.size / 2)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	viewport.add_child(load("res://assets/art_direction/runtime_lane.gd").new())

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--landscape": landscape = true
		if arg.begins_with("--capture="): capture_path = arg.trim_prefix("--capture=")
	call_deferred("build")

func box(rect: Rect2, fill: Color, edge: Color = Color.TRANSPARENT, thickness: int = 2) -> void:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(thickness)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = rect.position
	panel.size = rect.size
	canvas.add_child(panel)

func label_at(text: String, rect: Rect2, size_px: int, color: Color = CREAM) -> void:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	canvas.add_child(label)

func picture(texture: Texture2D, rect: Rect2) -> void:
	var view := TextureRect.new()
	view.texture = texture
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view.position = rect.position
	view.size = rect.size
	canvas.add_child(view)

func card(index: int, rect: Rect2) -> void:
	card_rects.append(rect)
	var color: Color = COLORS[index]
	box(Rect2(rect.position + Vector2(4, 6), rect.size), Color("070a16"))
	box(rect, Color("1c2037"), color, 2 if index < 3 else 3)
	# Rarity uses words, roman marks and frame geometry, never hue alone.
	if index >= 2:
		for k in range(5):
			box(Rect2(rect.position + Vector2(8 + k * (rect.size.x - 16) / 5, 5), Vector2((rect.size.x - 16) / 5, 3)), COLORS[(k + index) % 5])
	if index == 4:
		for offset in [Vector2.ZERO, Vector2(rect.size.x - 10, 0), Vector2(0, rect.size.y - 10), rect.size - Vector2(10, 10)]:
			box(Rect2(rect.position + offset, Vector2(10, 10)), GOLD)
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/art_direction/card-art.png")
	var slice_width := atlas.atlas.get_width() / 5.0
	atlas.region = Rect2(index * slice_width, 0, slice_width, atlas.atlas.get_height())
	picture(atlas, Rect2(rect.position + Vector2(10, 37), Vector2(rect.size.x - 20, rect.size.y - 119)))
	label_at(RARITIES[index], Rect2(rect.position + Vector2(9, 12), Vector2(rect.size.x - 18, 22)), 16, color)
	label_at(NAMES[index], Rect2(rect.position + Vector2(9, rect.size.y - 78), Vector2(rect.size.x - 18, 24)), 19)
	label_at(TYPES[index], Rect2(rect.position + Vector2(9, rect.size.y - 49), Vector2(rect.size.x - 18, 20)), 14, color)
	var glyph := Polygon2D.new()
	glyph.position = rect.position + Vector2(rect.size.x - 18, rect.size.y - 40)
	glyph.color = color
	if index < 2:
		glyph.polygon = PackedVector2Array([Vector2(-2,-8),Vector2(2,-8),Vector2(3,-5),Vector2(2,-2),Vector2(5,4),Vector2(3,8),Vector2(-3,8),Vector2(-5,4),Vector2(-2,-2),Vector2(-3,-5)])
	elif index == 2:
		var points := PackedVector2Array()
		for angle in range(12): points.append(Vector2.from_angle(angle*TAU/12)*6)
		glyph.polygon = points
	else:
		glyph.polygon = PackedVector2Array([Vector2(0,-8),Vector2(6,0),Vector2(0,8),Vector2(-6,0)])
	canvas.add_child(glyph)
	label_at(EFFECTS[index], Rect2(rect.position + Vector2(9, rect.size.y - 28), Vector2(rect.size.x - 18, 20)), 14, MUTED)

func build() -> void:
	var viewport_size := Vector2i(1280, 720) if landscape else Vector2i(720, 1280)
	root.size = viewport_size
	root.content_scale_size = viewport_size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	canvas = Control.new()
	canvas.size = viewport_size
	root.add_child(canvas)
	box(Rect2(Vector2.ZERO, viewport_size), INK)
	if landscape:
		lane(Rect2(284, 0, 480, 720))
		label_at("ROGUEWOOD", Rect2(24, 24, 250, 40), 30)
		label_at("HOUSE LEAGUE", Rect2(24, 74, 240, 24), 18, GOLD)
		label_at("DIVISION 01 / MATCH 01", Rect2(24, 105, 250, 24), 16, MUTED)
		box(Rect2(24, 151, 236, 2), GOLD)
		label_at("TARGET", Rect2(24, 175, 200, 24), 17, MUTED)
		label_at("1,200", Rect2(24, 201, 240, 64), 52, GOLD)
		label_at("CURRENT SCORE", Rect2(24, 284, 220, 24), 17, MUTED)
		label_at("480", Rect2(24, 310, 230, 56), 44, TEAL)
		label_at("FRAMES LEFT   2\nBANK                 $12", Rect2(24, 390, 230, 90), 22)
		label_at("VALUE  120  ×  MULT  4", Rect2(24, 495, 240, 25), 18, GOLD)
		label_at("MARBLED HOUSE BALL", Rect2(24, 548, 245, 25), 17, TEAL)
		label_at("Hold · spin · flick", Rect2(24, 580, 240, 30), 22)
		label_at("STILL ART STUDY / E11\nFixture values · no live play", Rect2(24, 652, 250, 48), 15, MUTED)
		label_at("COLLECTION / MATERIAL STUDIES", Rect2(796, 20, 460, 30), 20, GOLD)
		for i in range(5):
			card(i, Rect2(796 + (i % 3) * 154, 70 + (i / 3) * 291, 142, 272))
		label_at("I–V\nRARITY\nSTUDIES", Rect2(1120, 430, 140, 100), 22, MUTED)
		label_at("Static foil / reduced-motion reference", Rect2(796, 671, 460, 24), 18, MUTED)
	else:
		lane(Rect2(56, 140, 608, 808))
		box(Rect2(0, 0, 720, 140), INK)
		label_at("ROGUEWOOD", Rect2(24, 16, 320, 40), 32)
		label_at("HOUSE / DIVISION 01", Rect2(411, 24, 290, 26), 20, GOLD)
		label_at("TARGET  1,200", Rect2(24, 67, 310, 36), 28, GOLD)
		label_at("SCORE  480", Rect2(410, 67, 285, 36), 28, TEAL)
		label_at("2 FRAMES LEFT     /     $12", Rect2(24, 111, 400, 24), 18)
		label_at("STILL STUDY · E11", Rect2(499, 111, 210, 24), 17, MUTED)
		box(Rect2(140, 895, 440, 38), INK, Color("3e465c"))
		label_at("VALUE  120  ×  MULT  4", Rect2(214, 902, 330, 24), 22, GOLD)
		box(Rect2(16, 947, 688, 50), INK, Color("3e465c"))
		label_at("MARBLED HOUSE BALL", Rect2(28, 960, 328, 24), 20, TEAL)
		label_at("Hold · spin · flick", Rect2(468, 960, 230, 24), 20)
		for i in range(5): card(i, Rect2(16 + i * 140, 1013, 132, 230))
		label_at("MATERIAL STUDIES / Fixture values · static foil · no live play", Rect2(18, 1251, 690, 22), 17, MUTED)
	await process_frame
	await process_frame
	for rect in card_rects:
		assert(Rect2(Vector2.ZERO, viewport_size).encloses(rect), "Card outside viewport")
	for child in canvas.get_children():
		if child is Label:
			assert(child.get_minimum_size().x <= child.size.x + 1, "Text overflow: " + child.text)
	if not capture_path.is_empty():
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png(capture_path)
		assert(result == OK, "Capture failed")
		print("ROGUEWOOD_E11_STILL_OK ", viewport_size)
		quit()
