extends Control
## UI-2: the approved match screen (docs/art/ui/UI-A1.md, "Wave 10 layout revision —
## UI-A1-C"). Computes the screen regions for both orientations and owns the
## panels that only show information: the last-frame slip, the rival panel and the
## Charms row, plus the two fold toggles that narrow landscape screens use.
## A view only: the lab supplies every value.
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
const ItemAssets = preload("res://src/presentation/item_assets.gd")
const RivalArt = preload("res://src/presentation/rival_art.gd")
const MARGIN := 24.0
const FLANK := 0.19 # of the screen width, landscape
const FLANK_MIN := 240.0 # below this, or under 1.5:1, landscape folds
const FOLD_ASPECT := 1.5
const PORTRAIT_MARGIN := 12.0
const BALL_AT := 0.667 # of the lane region's height
const BALL_AT_PORTRAIT := 0.76
const INK := Color("101820")
## UI-5: the session menu button. UI-8 (owner's play notes, 2026-11-15): it sits
## inside the top bar's top-right corner, so the bar spans the screen; the bar's top
## row keeps MENU_ROOM clear for it (DivisionHud.menu_room).
const MENU_PORTRAIT := Vector2(52, 44)
const MENU_LANDSCAPE := Vector2(56, 48)
const MENU_INSET := Vector2(10, 8) # from the bar's top-right corner
const MENU_GAP := 8.0
const LANDSCAPE_TOP := 16.0

signal fold_changed

var slip: PanelContainer
var slip_text: Label
var rival: PanelContainer
var rival_portrait: TextureRect
var rival_text: Label
var charms: PanelContainer
var charm_icons: HFlowContainer
var charm_count: Label
var charm_heading: Label
var charm_head: BoxContainer
## Portrait's Charm rail leaves while a frame is reviewed: the hand and the review
## take the whole screen below the info row then (the lab sets this before apply).
var rail_hidden := false
var practice := false # UI-39: How to Play's practice lane (no rival, no Charms)
const RAIL_WIDTH := 52.0
var _charm_frame: StyleBox
var _charm_plate: StyleBoxFlat
var fold_bar: PanelContainer
var hand_toggle: Button
var details_toggle: Button
var show_hand := false
var show_details := false
var regions: Dictionary = {}

func _ready() -> void:
	name = "MatchPanels"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	slip = _panel("LastFrameSlip", "slip")
	slip_text = _text(slip, "SlipText", INK)
	rival = _panel("RivalPanel", "panel")
	var rival_row := HBoxContainer.new()
	rival_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rival_row.add_theme_constant_override("separation", 8)
	rival.add_child(rival_row)
	rival_portrait = TextureRect.new()
	rival_portrait.name = "RivalPortrait"
	rival_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rival_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rival_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rival_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rival_row.add_child(rival_portrait)
	rival_text = _text(rival_row, "RivalText", UiTheme.IVORY)
	# The Charms: a heading with the slot count, then the identities, which wrap to
	# the room they have (rows in landscape's panel, one column in portrait's rail).
	charms = _panel("CharmsRow", "panel")
	_charm_frame = charms.get_theme_stylebox("panel")
	_charm_plate = StyleBoxFlat.new()
	_charm_plate.bg_color = Color(0.06, 0.09, 0.12, 0.6)
	_charm_plate.set_corner_radius_all(8)
	_charm_plate.set_content_margin_all(4)
	var charm_col := VBoxContainer.new()
	charm_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	charm_col.add_theme_constant_override("separation", 6)
	charms.add_child(charm_col)
	charm_head = BoxContainer.new()
	charm_head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	charm_head.add_theme_constant_override("separation", 2)
	charm_col.add_child(charm_head)
	var heading := Label.new()
	charm_heading = heading
	heading.text = "CHARMS"
	heading.add_theme_color_override("font_color", UiTheme.BRASS)
	heading.add_theme_font_size_override("font_size", 18)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	charm_head.add_child(heading)
	charm_count = Label.new()
	charm_count.name = "CharmCount"
	charm_count.add_theme_font_size_override("font_size", 18)
	charm_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	charm_head.add_child(charm_count)
	# UI-47: a tap on the rail opens a Charm's quick view (ThrowLab resolves which).
	charms.mouse_filter = Control.MOUSE_FILTER_STOP
	charms.gui_input.connect(_on_charms_input)
	charm_icons = HFlowContainer.new()
	charm_icons.name = "CharmIcons"
	charm_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	charm_icons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	charm_icons.add_theme_constant_override("h_separation", 8)
	charm_icons.add_theme_constant_override("v_separation", 6)
	charm_col.add_child(charm_icons)
	fold_bar = _panel("FoldBar", "hud")
	fold_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	var fold_row := HBoxContainer.new()
	fold_bar.add_child(fold_row)
	hand_toggle = Button.new()
	hand_toggle.name = "HandToggle"
	hand_toggle.custom_minimum_size = Vector2(180, 48)
	hand_toggle.pressed.connect(func():
		show_hand = not show_hand
		show_details = false
		fold_changed.emit())
	fold_row.add_child(hand_toggle)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fold_row.add_child(spacer)
	details_toggle = Button.new()
	details_toggle.name = "DetailsToggle"
	details_toggle.text = "Slip · Rival · Charms"
	details_toggle.custom_minimum_size = Vector2(300, 48)
	details_toggle.pressed.connect(func():
		show_details = not show_details
		show_hand = false
		fold_changed.emit())
	fold_row.add_child(details_toggle)

func _panel(node_name: String, kind: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiTheme.frame(kind, 14.0, 6.0))
	add_child(panel)
	return panel

func _text(parent: Control, node_name: String, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_FILL # Labels default to shrink-center
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

## The screen regions for a lab of `screen` size. Portrait: a two-row top bar, the
## slip and rival chips, the Charms row, the lane, and the hand at the thumbs.
## Landscape: a one-row top bar, the hand flank and the details flank (mirrored for
## left-handed play), folding into a second bar row when the screen is narrow.
## `compact` is the roll view (UI-3): while the ball rolls and the frame scores, the
## hand and details leave and the top bar shrinks to one slim line.
## Where the shell puts the session menu button (UI-5); the top bar stops short of it.
static func menu_rect(screen: Vector2) -> Rect2:
	if screen.y >= screen.x:
		return Rect2(screen.x - PORTRAIT_MARGIN - MENU_INSET.x - MENU_PORTRAIT.x, PORTRAIT_MARGIN + MENU_INSET.y, MENU_PORTRAIT.x, MENU_PORTRAIT.y)
	return Rect2(screen.x - MARGIN - MENU_INSET.x - MENU_LANDSCAPE.x, LANDSCAPE_TOP + MENU_INSET.y + 2.0, MENU_LANDSCAPE.x, MENU_LANDSCAPE.y)

## Width the bar's top row keeps clear at its right end for the button.
static func menu_room(screen: Vector2) -> float:
	return (MENU_PORTRAIT.x if screen.y >= screen.x else MENU_LANDSCAPE.x) + MENU_GAP

## `bar_extra`: added height for portrait's top bar when its rule badge takes two
## lines (a champion's two rules); everything below moves down with it.
static func compute(screen: Vector2, left_handed: bool, hand_height: float, compact: bool = false, bar_extra: float = 0.0) -> Dictionary:
	var w := screen.x
	var h := screen.y
	var r := {"portrait": h >= w, "fold": false, "left_handed": left_handed, "compact": compact}
	if r.portrait:
		# UI-3 (owner phone trial, 2026-11-08): narrow margins, a two-row bar, one
		# info row (slip, rival, Charms), the lane, and the fanned hand at the thumbs.
		# The prompt sits above the hand, out of the pins' way.
		var m := PORTRAIT_MARGIN
		# UI-5: the bar starts at the top (the session buttons are one menu button
		# at its right), so the lane gains the row they took.
		var bar_w := w - 2 * m # the menu button is inside the bar (UI-8)
		r.top_bar = Rect2(m, m, bar_w, 100 + bar_extra)
		var row_y := m + 108.0 + bar_extra
		# The row is the slip and the rival; the Charms are a rail down the lane's
		# right flank, where six of them fit (in the row, three ran off the screen).
		var slip_w := floorf((w - 2 * m - 8) * 0.52)
		r.slip = Rect2(m, row_y, slip_w, 56)
		r.rival = Rect2(m + slip_w + 8, row_y, w - 2 * m - 8 - slip_w, 56)
		r.charms = Rect2(w - m - RAIL_WIDTH, row_y + 64, RAIL_WIDTH, 0) # as tall as its Charms
		r.hand = Rect2(m, h - m - hand_height, w - 2 * m, hand_height)
		r.lane = Rect2(m, row_y + 64, w - 2 * m, r.hand.position.y - 8 - row_y - 64)
		r.prompt = Rect2(m, r.hand.position.y - 8, w - 2 * m, 0) # bottom edge
		r.kit = Rect2(m, row_y + 68, 64, 0)
		r.bubble = Rect2(m, row_y, w - 2 * m, 0)
		r.corridor = Rect2(w * 0.3, r.lane.position.y, w * 0.4, r.lane.size.y)
		if compact:
			r.top_bar = Rect2(m, m, bar_w, 60) # tall enough for the menu button inside it
			r.prompt = Rect2(m, h - 16, w - 2 * m, 0)
	else:
		var side := floorf(w * FLANK)
		r.fold = w / h < FOLD_ASPECT or side < FLANK_MIN
		r.top_bar = Rect2(MARGIN, LANDSCAPE_TOP, w - 2 * MARGIN, 68)
		var top := LANDSCAPE_TOP + 84.0
		if r.fold:
			r.fold_bar = Rect2(MARGIN, LANDSCAPE_TOP + 72.0, w - 2 * MARGIN, 68)
			top = LANDSCAPE_TOP + 156.0
			side = maxf(side, floorf(w * 0.27))
		var hand_x := w - MARGIN - side if left_handed else MARGIN
		var detail_x := MARGIN if left_handed else w - MARGIN - side
		r.hand = Rect2(hand_x, top, side, h - top - MARGIN)
		r.slip = Rect2(detail_x, top, side, 148)
		r.rival = Rect2(detail_x, top + 164, side, 142)
		r.charms = Rect2(detail_x, top + 322, side, 136)
		r.details = Rect2(detail_x, top, side, h - top - MARGIN)
		r.lane = Rect2(MARGIN, top, w - 2 * MARGIN, h - top - MARGIN)
		r.corridor = Rect2(w * 0.32, top, w * 0.36, h - top - MARGIN)
		var inner := MARGIN + side + 16
		r.prompt = Rect2(inner, h - MARGIN, w - 2 * inner, 0) # bottom edge, between the flanks
		r.kit = Rect2(inner, top, 64, 0)
		r.bubble = Rect2(detail_x, r.rival.position.y, side, 0)
	# Portrait puts the ball lower (UI-3) so the pins clear the info row on short screens.
	r.ball_y = r.lane.position.y + r.lane.size.y * (BALL_AT_PORTRAIT if r.portrait else BALL_AT)
	return r

## Places the panels for `layout` (compute()); `playing` hides them outside a match.
func apply(layout: Dictionary, playing: bool) -> void:
	regions = layout
	var fold: bool = layout.fold
	fold_bar.visible = playing and fold and not practice # UI-39: no hand or details to fold
	if fold:
		_place(fold_bar, layout.fold_bar)
	var details_shown: bool = playing and (not fold or show_details) and not layout.get("compact", false)
	var portrait: bool = layout.portrait
	charms.add_theme_stylebox_override("panel", _charm_plate if portrait else _charm_frame)
	charm_head.vertical = portrait
	charm_heading.text = "Charms" if portrait else "CHARMS"
	charm_heading.add_theme_font_size_override("font_size", 13 if portrait else 18)
	charm_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
	charm_count.add_theme_font_size_override("font_size", 16 if portrait else 18)
	charm_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_RIGHT
	for pair in [[slip, "slip"], [rival, "rival"], [charms, "charms"]]:
		pair[0].visible = details_shown
		_place(pair[0], layout[pair[1]])
	if portrait:
		charms.visible = details_shown and not rail_hidden
	if practice: # UI-39: the practice lane has no rival and no Charms
		rival.visible = false
		charms.visible = false
	if _strip is FlowContainer:
		_strip.alignment = FlowContainer.ALIGNMENT_CENTER if portrait else FlowContainer.ALIGNMENT_BEGIN
	rival_portrait.custom_minimum_size = Vector2(34, 34) if portrait else Vector2(64, 64)
	slip_text.add_theme_font_size_override("font_size", 18 if portrait else 20)
	rival_text.add_theme_font_size_override("font_size", 15 if portrait else 18)
	slip_text.max_lines_visible = 2 if portrait else 4
	rival_text.max_lines_visible = 2 if portrait else 4
	slip_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT

func _place(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
	control.custom_minimum_size = rect.size

## The last banked frame, or a note that none is banked yet.
func show_slip(result: Dictionary, total: int) -> void:
	if result.is_empty():
		slip_text.text = "No frame yet" if regions.get("portrait", true) else "LAST FRAME\nNone banked yet"
		return
	# A restored frame keeps only its banked score and category, not the chain.
	var chain := "%s × %s = %s" % [_n(result.pin_value), _n(result.mult), _n(result.score)] if result.has("pin_value") and result.has("mult") else "Banked %s" % _n(result.get("score", 0))
	if regions.get("portrait", true):
		slip_text.text = chain
	else:
		slip_text.text = "LAST FRAME · %s\n%s\nTotal %s" % [String(result.get("category", "")).to_upper(), chain, _n(total)]

## The match's rival and rule; practice and early matches name the boss to come.
## The rival's latest line (show_quote) follows in landscape.
func show_rival(rival_entry: Dictionary, rule_line: String, boss_now: bool) -> void:
	if rival_entry.is_empty():
		rival_text.text = "Practice · no rival"
		rival_portrait.texture = null
		rival_portrait.visible = false
		return
	rival_portrait.texture = RivalArt.portrait(rival_entry.get("id", ""), "entrance")
	rival_portrait.visible = rival_portrait.texture != null
	var name_line: String = rival_entry.get("name", "")
	if regions.get("portrait", true):
		rival_text.text = "%s\n%s" % [name_line, rule_line] if boss_now else "Next boss\n%s" % name_line
	else:
		rival_text.text = "%s\n%s" % [name_line, rule_line] if boss_now else "BOSS AHEAD\n%s\n%s" % [name_line, rule_line]
		if not quote.is_empty() and boss_now:
			rival_text.text += "\n“%s”" % quote

var quote := ""
## The rival's latest spoken line (E12 reactions).
func show_quote(line: String) -> void:
	quote = line

## The equipped Charms in slot order (left to right), with the slot count.
func show_charms(item_ids: Array, slots: int, names: Dictionary) -> void:
	if charm_icons.get_meta("ids", []) != item_ids:
		charm_icons.set_meta("ids", item_ids.duplicate())
		for child in charm_icons.get_children():
			charm_icons.remove_child(child)
			child.queue_free()
		for id in item_ids:
			var art := ItemAssets.slot(id, "icon") as Texture2D
			if art == null:
				# No identity art (lab fixtures): the Charm's name stands in.
				var tag := Label.new()
				tag.name = "Charm_" + String(id).replace(".", "_")
				tag.text = names.get(id, id)
				tag.add_theme_font_size_override("font_size", 14)
				tag.clip_text = true # portrait's rail is narrow; a fixture's name is cut, not the rail widened
				tag.custom_minimum_size = Vector2(RAIL_WIDTH - 8.0, 0)
				tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
				charm_icons.add_child(tag)
				continue
			var icon := TextureRect.new()
			icon.name = "Charm_" + String(id).replace(".", "_")
			icon.texture = art
			icon.tooltip_text = names.get(id, id)
			icon.custom_minimum_size = Vector2(32, 32)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			charm_icons.add_child(icon)
	charm_count.text = "%d/%d" % [item_ids.size(), slots]

## Seats Codex's equipment art strip (kit and Charm identities) in the Charms row;
## this row's own name tags then stand in only for Charms without identity art.
func host_equipment_strip(strip: Control) -> void:
	strip.get_parent().remove_child(strip)
	charm_icons.get_parent().set_meta("hosts_equipment_strip", true)
	charm_icons.get_parent().add_child(strip)
	charm_icons.get_parent().move_child(strip, charm_icons.get_index())
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_strip = strip

var _strip: Control

func _process(_delta: float) -> void:
	if _strip != null:
		charm_icons.visible = _strip.get_child_count() == 0
	if regions.get("portrait", false) and charms.visible:
		# The rail is as tall as its Charms and hangs from the row's right end.
		charms.reset_size()
		charms.position.x = regions.charms.end.x - charms.size.x

## Controls that take touches (the lab never starts a throw over them).
func blocking_controls() -> Array:
	return [fold_bar, charms]

## UI-47 (owner, 2026-11-24): a tap (not a drag) on the Charm rail, in global
## coordinates; ThrowLab finds the Charm under it and opens its quick view.
signal charms_tapped(at: Vector2)
var _press_at := Vector2.INF
func _on_charms_input(event: InputEvent) -> void:
	var pressed: bool
	if event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION: return # the touch itself counts
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT: pressed = event.pressed
	elif event is InputEventScreenTouch: pressed = event.pressed
	else: return
	var at: Vector2 = charms.get_global_transform() * event.position
	if pressed:
		_press_at = at
	elif _press_at != Vector2.INF and _press_at.distance_to(at) < 16.0:
		_press_at = Vector2.INF
		charms_tapped.emit(at)
	charms.accept_event()

## The rail's pieces under a global point: [node, its global rect], or [] (the art
## strip's tiles, else this row's own icons and name tags).
func charm_piece_at(at: Vector2) -> Array:
	var holders: Array = []
	if _strip != null and _strip.visible: holders.append(_strip)
	holders.append(charm_icons)
	for holder in holders:
		for piece in holder.get_children():
			if piece is Control and piece.visible and piece.get_global_rect().has_point(at):
				return [piece, piece.get_global_rect()]
	return []

static func _n(number: Variant) -> String:
	return preload("res://src/rules/score_log.gd")._n(number)
