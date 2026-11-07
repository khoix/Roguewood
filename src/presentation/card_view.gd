extends Button
## UI-1: the one playing card used everywhere (hand, shop, binder, inspection).
## Layout, materials and motion follow docs/art/ui/UI-A1.md: the canonical face is
## 210×300 and every layer is placed from those coordinates at the card's actual
## size (text is laid out at real pixel sizes, never a scaled bitmap). A Button, so
## touch, mouse and keyboard/gamepad focus all work, and `text` carries the card's
## accessible label (status words such as SOLD stay readable to tools) while the
## face draws the card. A view only: callers own every rule and number.
const ItemAssets = preload("res://src/presentation/item_assets.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
const Tactics = preload("res://src/rules/tactics.gd")
const Upgrades = preload("res://src/rules/upgrades.gd")
const FONT = preload("res://assets/ui/fonts/PixelifySans.ttf")
const DIR := "res://assets/ui/cards/"
const NATIVE := Vector2(210, 300)
const ASPECT := 300.0 / 210.0
const RARITIES := ["common", "uncommon", "rare", "epic", "legendary"]
const SEALS := {"common": "■", "uncommon": "Ⅱ", "rare": "◆", "epic": "✦", "legendary": "♛"}
const INK := Color("101820")
const INK_SOFT := Color("573a2e")
const SEA_GLASS := Color("95d9cb")
const BRASS := Color("e7bc70")
## Below this scale a card is "compact": name, art, category and rarity only; the
## short rule moves to inspection (UI-A1: small hand cards keep name, category, rarity).
const COMPACT_SCALE := 0.62

signal long_pressed

var item_id := ""
var face_up := true
## "", "armed", "tactic", "keep", "sold", "locked", "unaffordable"
var state := ""
var tag_text := "" # the small tab above the card (ARMED, KEEP, TACTIC, ...)
var price_text := "" # shop overlay, never part of the permanent face
## Reduced motion (or reduced flash): no lift or tilt, and the rarity material holds
## its rest phase (UI-A2).
var reduced_motion := false:
	set(value):
		reduced_motion = value
		_apply_material()
var art: TextureRect # the item illustration
## UI-A2: the rarity material, an additive overlay over the whole face, above the
## illustration and below every badge and label. Its own duplicated ShaderMaterial.
var sheen: ColorRect
var rarity := "common"
var league := "league.house"
const MATERIALS := "res://assets/ui/materials/manifest.json"
const REST_PHASE := 0.42
static var _manifest: Dictionary = {}
var _face: Control
var _back: TextureRect
var _parts: Dictionary = {}
var _hint := ""
var _detail := ""
var _icon := "value"
var _press_started := 0
var _held := 0.0 # seconds the press has lasted, on the frame clock
var _long_fired := false
var _lift := 0.0
var _tween: Tween

func _init() -> void:
	clip_contents = false
	focus_mode = Control.FOCUS_ALL
	flat = true
	expand_icon = true # the hidden icon must not grow the card's minimum size
	mouse_filter = Control.MOUSE_FILTER_STOP
	for key in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(key, StyleBoxEmpty.new())
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = SEA_GLASS
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(16)
	focus.set_expand_margin_all(4)
	add_theme_stylebox_override("focus", focus)
	# The accessible label stays in `text`; the face draws the visible card.
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
		add_theme_color_override(key, Color.TRANSPARENT)
	add_theme_font_size_override("font_size", 1)
	# `icon` stays set to the item's production icon (art journeys check it); the face draws the card.
	for key in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_disabled_color", "icon_hover_pressed_color"]:
		add_theme_color_override(key, Color.TRANSPARENT)
	_face = Control.new()
	_face.name = "Face"
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_face)
	_back = TextureRect.new()
	_back.name = "Back"
	_back.texture = load(DIR + "back.svg")
	_back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_back.stretch_mode = TextureRect.STRETCH_SCALE
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back.visible = false
	add_child(_back)
	for key in ["frame", "art", "sheen", "badge", "rule_icon", "name", "hint", "detail", "rarity", "hatch", "stamp", "price", "tag"]:
		var node: Control
		if key in ["frame", "art", "badge", "rule_icon"]:
			var image := TextureRect.new()
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_SCALE if key == "frame" else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			node = image
		elif key == "sheen":
			node = ColorRect.new()
			(node as ColorRect).color = Color.WHITE
		elif key == "hatch":
			var shade := ColorRect.new()
			shade.color = Color(0.06, 0.09, 0.12, 0.72)
			node = shade
		else:
			var label := Label.new()
			label.add_theme_font_override("font", FONT)
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.clip_text = true
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			node = label
		node.name = key.capitalize().replace(" ", "")
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_face.add_child(node)
		_parts[key] = node
	art = _parts.art
	sheen = _parts.sheen
	resized.connect(_layout)
	button_down.connect(_on_down)
	button_up.connect(func(): _press_started = 0; _settle())
	mouse_exited.connect(func(): _press_started = 0; _settle())

func _ready() -> void:
	_layout()

## Shows the item's face. Reads the catalogue entry for name, rarity, category and
## rules; `names` turns item ids in rule text into names.
func set_item(id: String, names: Dictionary = {}, title: String = "", fallback_art: Texture2D = null) -> void:
	item_id = id
	ItemAssets._ensure()
	var item: Dictionary = ItemAssets._items.get(id, {})
	rarity = item.get("rarity", "common")
	if rarity not in RARITIES: rarity = "common"
	_apply_material()
	_parts.frame.texture = load(DIR + "face-%s.svg" % rarity)
	_parts.art.texture = ItemAssets.slot(id, "card") as Texture2D
	if _parts.art.texture == null:
		_parts.art.texture = fallback_art # lab fixtures have no catalogue art
	icon = ItemAssets.slot(id, "icon") as Texture2D
	_parts.badge.texture = load(DIR + category_icon(id) + ".svg")
	if names.is_empty():
		for other in ItemAssets._items.values():
			names[other.id] = other.get("name", other.id)
	var summary := summary(item, names)
	_icon = summary.icon
	_hint = summary.hint
	_detail = summary.detail
	_parts.rule_icon.texture = load(DIR + _icon + ".svg")
	_parts.name.text = item.get("name", title if not title.is_empty() else id)
	_parts.rarity.text = "%s %s" % [SEALS.get(rarity, "■"), rarity.to_upper()]
	_layout()

## Card state, tab and shop price overlay; `label` is the accessible text.
func set_state(new_state: String, tag: String = "", price: String = "", label: String = "") -> void:
	state = new_state
	tag_text = tag
	price_text = price
	text = label if not label.is_empty() else "%s%s" % [_parts.name.text, ("\n" + tag) if not tag.is_empty() else ""]
	tooltip_text = text if not text.is_empty() else tooltip_text
	_refresh()

func show_face(up: bool) -> void:
	face_up = up
	_refresh()

## Flip with the swap at the edge-on midpoint (180 ms); immediate under reduced motion.
func flip_to(up: bool) -> void:
	if reduced_motion or not is_inside_tree():
		show_face(up)
		return
	_kill_tween()
	pivot_offset = size * 0.5
	_tween = create_tween()
	_tween.tween_property(self, "scale:x", 0.0, 0.09)
	_tween.tween_callback(func(): show_face(up))
	_tween.tween_property(self, "scale:x", 1.0, 0.09)

## Deal in: 180 ms ease-out from below, after `delay` (35 ms stagger per card).
## UI state never waits for it; the card is usable at once.
func deal_in(delay: float = 0.0) -> void:
	if reduced_motion or not is_inside_tree():
		return
	_kill_tween()
	_face.modulate.a = 0.0
	_face.position.y = 24.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_face, "modulate:a", 1.0, 0.18).set_delay(delay)
	_tween.tween_property(_face, "position:y", -_lift, 0.18).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

## Tilt toward a point (card-local), at most 6°, settling in 150 ms on release.
func tilt_toward(local: Vector2) -> void:
	if reduced_motion: return
	var x := clampf((local.x / maxf(size.x, 1.0) - 0.5) * 2.0, -1.0, 1.0)
	_face.pivot_offset = size * 0.5
	_face.rotation = deg_to_rad(6.0) * x

## True once, after a long press fired: the caller ignores the press that follows.
func consume_long_press() -> bool:
	var fired := _long_fired
	_long_fired = false
	return fired

## The short rule for a card face: an icon (value, mult, money or the category),
## a hint (the headline effect) and a qualifier, bound to the catalogue's rules.
static func summary(item: Dictionary, names: Dictionary = {}) -> Dictionary:
	var id: String = item.get("id", "")
	var category: String = item.get("category", "")
	var tactic: String = Tactics.describe(id)
	if not tactic.is_empty():
		var when := tactic.get_slice(":", 0) if tactic.contains(":") else "Once"
		var what := tactic.get_slice(":", 1).strip_edges() if tactic.contains(":") else tactic
		return {"icon": "consumable", "hint": what.capitalize() if what.length() < 3 else what[0].to_upper() + what.substr(1), "detail": when + " · once"}
	var upgrade: String = Upgrades.describe(id)
	if not upgrade.is_empty():
		return {"icon": "shop_upgrade", "hint": upgrade, "detail": "Kept for the run"}
	var effects: Array = item.get("effects", [])
	var physics: Dictionary = item.get("physics", {})
	var pick: Dictionary = {}
	for op in ["multiply_mult", "add_mult", "payout", "retrigger", "add_value"]:
		for effect in effects:
			if effect.op == op and pick.is_empty():
				pick = effect
	if pick.is_empty():
		if physics.has("spin_response"):
			return {"icon": category_icon(id), "hint": "Hook ×%s" % String.num(physics.spin_response, 2), "detail": ("Mass ×%s" % String.num(physics.mass_scale, 2)) if physics.has("mass_scale") else "Spin response"}
		if id == "ball.house":
			return {"icon": "ball", "hint": "Reliable roll", "detail": "Standard weight"}
		return {"icon": category_icon(id), "hint": item.get("name", id), "detail": category.capitalize().replace("_", " ")}
	var amount := String.num(float(pick.amount), 2).trim_suffix(".00").trim_suffix(".0")
	var hint := ""
	var icon := "value"
	match pick.op:
		"add_value": hint = "+%s Value" % amount
		"add_mult": hint = "+%s Mult" % amount; icon = "mult"
		"multiply_mult": hint = "×%s Mult" % amount; icon = "mult"
		"payout": hint = "+$%s" % amount; icon = "money"
		"retrigger": hint = "Repeat first hit"; icon = category_icon(id)
	var qualifier := ""
	if pick.has("per"):
		qualifier = ScoreLog._per_text(String(pick.per), names).strip_edges()
	elif pick.has("condition"):
		qualifier = ScoreLog.condition_text(pick.condition, {}, names)
	elif pick.trigger == "fallen":
		qualifier = "when down"
	elif pick.trigger == "standing":
		qualifier = "if standing"
	elif pick.trigger == "match_end":
		qualifier = "after each match"
	if qualifier.is_empty():
		for effect in effects:
			if effect != pick and effect.op in ["add_value", "add_mult", "payout"]:
				qualifier = {"add_value": "+%s Value", "add_mult": "+%s Mult", "payout": "+$%s"}[effect.op] % String.num(float(effect.amount), 2).trim_suffix(".00").trim_suffix(".0")
				break
	if qualifier.is_empty() and category == "consumable":
		qualifier = "once"
	return {"icon": icon, "hint": hint, "detail": qualifier[0].to_upper() + qualifier.substr(1) if not qualifier.is_empty() else ""}

static func category_icon(id: String) -> String:
	var prefix := id.get_slice(".", 0)
	return {"ball": "ball", "ball_mod": "ball", "pin": "pin", "pin_mod": "pin", "charm": "charm", "consumable": "consumable", "shop_upgrade": "shop_upgrade"}.get(prefix, "charm")

## Fits the face to the card's rect at the canonical aspect, centered.
func card_rect() -> Rect2:
	var w := minf(size.x, size.y / ASPECT)
	var face_size := Vector2(w, w * ASPECT)
	return Rect2((size - face_size) * 0.5, face_size)

func _layout() -> void:
	var r := card_rect()
	_face.position = Vector2(r.position.x, r.position.y - _lift)
	_face.size = r.size
	_back.position = r.position
	_back.size = r.size
	var s := r.size.x / NATIVE.x
	var compact := s < COMPACT_SCALE
	var place := func(key: String, rect: Rect2) -> void:
		_parts[key].position = rect.position * s
		_parts[key].size = rect.size * s
	place.call("frame", Rect2(Vector2.ZERO, NATIVE))
	place.call("sheen", Rect2(Vector2.ZERO, NATIVE))
	place.call("badge", Rect2(17, 44, 26, 26) if not compact else Rect2(14, 42, 40, 40))
	place.call("rule_icon", Rect2(17, 235, 28, 28))
	place.call("hint", Rect2(51, 228, 144, 18))
	place.call("detail", Rect2(51, 248, 144, 16))
	place.call("rarity", Rect2(18, 268, 174, 18) if not compact else Rect2(14, 258, 182, 30))
	place.call("hatch", Rect2(15, 41, 180, 181))
	place.call("stamp", Rect2(15, 100, 180, 60))
	place.call("price", Rect2(120, 190, 76, 30) if not compact else Rect2(100, 176, 96, 44))
	if compact:
		# Small hand cards: a taller name banner and art filling the face down to the rarity line.
		place.call("name", Rect2(12, 6, 186, 36))
		place.call("art", Rect2(15, 44, 180, 210))
	else:
		place.call("name", Rect2(18, 10, 174, 28))
		place.call("art", Rect2(15, 41, 180, 181))
	_parts.tag.position = Vector2(r.size.x * 0.5 - 48.0, -24.0)
	_parts.tag.size = Vector2(96, 22)
	_font(_parts.name, 20 * s, 12, INK)
	_font(_parts.hint, 16 * s, 11, INK)
	_font(_parts.detail, 14 * s, 10, INK_SOFT)
	_font(_parts.rarity, 14 * s, 10, INK)
	_font(_parts.stamp, 30 * s, 14, Color("b8322a"))
	_font(_parts.price, 20 * s, 12, BRASS)
	_font(_parts.tag, 14, 14, INK)
	for key in ["rule_icon", "hint", "detail"]:
		_parts[key].visible = not compact and face_up
	_refresh()

func _font(label: Label, pixels: float, minimum: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", maxi(int(round(pixels)), minimum))
	label.add_theme_color_override("font_color", color)

func _refresh() -> void:
	if _parts.is_empty(): return
	_face.visible = face_up
	_back.visible = not face_up
	var compact := card_rect().size.x / NATIVE.x < COMPACT_SCALE
	_parts.hint.text = _hint
	_parts.detail.text = _detail
	for key in ["rule_icon", "hint", "detail"]:
		_parts[key].visible = not compact
	# Compact cards use a different art recess: the canonical mask does not fit, so
	# the material is off there (UI-A2). Common is matte everywhere.
	sheen.visible = not compact and rarity != "common"
	_parts.hatch.visible = state in ["locked", "unaffordable", "sold"]
	_parts.hatch.color = Color(0.06, 0.09, 0.12, 0.45 if state == "unaffordable" else 0.72)
	_parts.stamp.visible = state in ["sold", "locked"]
	_parts.stamp.text = "SOLD" if state == "sold" else "LOCKED"
	_parts.stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_parts.stamp.rotation = deg_to_rad(-12.0)
	_parts.price.visible = not price_text.is_empty()
	_parts.price.text = price_text
	_parts.price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not _parts.price.has_theme_stylebox_override("normal"):
		var plate := StyleBoxFlat.new()
		plate.bg_color = Color(0.06, 0.09, 0.12, 0.92)
		plate.border_color = BRASS
		plate.set_border_width_all(2)
		plate.set_corner_radius_all(6)
		_parts.price.add_theme_stylebox_override("normal", plate)
	_parts.tag.visible = not tag_text.is_empty() and face_up
	_parts.tag.text = tag_text
	_parts.tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not _parts.tag.has_theme_stylebox_override("normal"):
		var tab := StyleBoxFlat.new()
		tab.bg_color = SEA_GLASS
		tab.set_corner_radius_all(4)
		_parts.tag.add_theme_stylebox_override("normal", tab)
	var lifted := 8.0 if state in ["armed", "tactic"] and not reduced_motion else 0.0
	if lifted != _lift:
		_lift = lifted
		_face.position.y = card_rect().position.y - _lift
	queue_redraw()

func _draw() -> void:
	# Armed or tactic: a 3 px sea-glass outline around the face (UI-A1 states).
	if (state in ["armed", "tactic", "keep"] or (toggle_mode and button_pressed)) and face_up:
		var r := card_rect()
		r.position.y -= _lift
		draw_rect(r.grow(3.0), BRASS if state == "keep" or (toggle_mode and button_pressed) else SEA_GLASS, false, 3.0)

## The UI-A2 material for a League and rarity, from the manifest (unprovided
## Leagues fall back to House). Always a fresh duplicate, so cards never share one.
static func material_for(rarity_id: String, reduced: bool = false, league_id: String = "league.house") -> ShaderMaterial:
	if _manifest.is_empty():
		_manifest = JSON.parse_string(FileAccess.get_file_as_string(MATERIALS))
	var leagues: Dictionary = _manifest.leagues
	var family: Dictionary = leagues.get(league_id, leagues[_manifest.fallback_league])
	var entry: Dictionary = family.get(rarity_id, family.common)
	return (load(entry.reduced if reduced else entry.overlay) as ShaderMaterial).duplicate()

func _apply_material() -> void:
	if sheen == null: return
	sheen.material = material_for(rarity, reduced_motion, league)
	set_material_phase(REST_PHASE)

## Inspection's finish preview: shows another rarity's material on this face.
func preview_material(rarity_id: String) -> void:
	rarity = rarity_id if rarity_id in RARITIES else "common"
	_apply_material()
	_refresh()

## Inspection drives the phase from tilt; reduced materials ignore it.
func set_material_phase(phase: float) -> void:
	if sheen and sheen.material:
		(sheen.material as ShaderMaterial).set_shader_parameter("progress", clampf(phase, 0.0, 1.0))

## UI-A2's tilt mapping: each axis in [-1, 1]; settles to the rest phase at zero.
func tilt_material(tilt: Vector2) -> void:
	set_material_phase(REST_PHASE + 0.25 * tilt.x + 0.15 * tilt.y)

## One 180 ms sweep when a card is played; never delays game state.
func sweep_material() -> void:
	if reduced_motion or rarity == "common" or not is_inside_tree(): return
	var sweep := create_tween()
	sweep.tween_method(set_material_phase, 0.0, 1.0, 0.18)
	sweep.tween_callback(set_material_phase.bind(REST_PHASE))

func _on_down() -> void:
	sweep_material()
	_press_started = 1
	_held = 0.0
	_long_fired = false
	if not reduced_motion:
		_face.position.y = card_rect().position.y - _lift + 2.0 # pressed: down 2 px

func _settle() -> void:
	if _face == null: return
	_face.position.y = card_rect().position.y - _lift
	if _face.rotation != 0.0 and not reduced_motion and is_inside_tree():
		var settle := create_tween()
		settle.tween_property(_face, "rotation", 0.0, 0.15)
	elif reduced_motion:
		_face.rotation = 0.0

func _process(delta: float) -> void:
	# Long press (450 ms on the frame clock, so a slow frame never turns a tap into
	# one) opens inspection; the release that follows is not a play.
	if _press_started > 0 and not _long_fired:
		_held += delta
		if _held >= 0.45:
			_long_fired = true
			_press_started = 0
			long_pressed.emit()

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion or event is InputEventScreenDrag) and is_pressed():
		tilt_toward(event.position)

func _kill_tween() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
