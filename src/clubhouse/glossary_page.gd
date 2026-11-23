extends Control
## UI-24 (owner, 2026-11-19): "Talk the Talk", a visual guide to the words the game
## uses (bowling's and Roguewood's own), from How to Play in the Clubhouse menu.
## Five tabs (The Run, Frames, Lane & Ball, Scoring, Your Cards), each a list of
## words with a picture and a line or two; Next walks on to the following tab, and
## Back (or Escape) returns to How to Play. Laid out like Throw Settings: the full
## width in portrait, a centred column in landscape. Pictures of a throw follow the
## player's hand from Throw Settings.
const Glossary = preload("res://src/clubhouse/glossary.gd")
const Diagram = preload("res://src/presentation/glossary_diagram.gd")
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
const Club = preload("res://src/clubhouse/clubhouse.gd")
const Art = preload("res://src/clubhouse/clubhouse_art.gd")
const SCROLL_SLOP := 12 # px: a press that scrolled further than this opens nothing

signal closed

const WORD := Color("8a4419")
const MEANING := Color("2a221c")

var dim: ColorRect
var panel: PanelContainer
var title: Label
var tabs: HBoxContainer
var tab_buttons := {} # section id -> Button
var scroll: ScrollContainer
var list: VBoxContainer
var next_button: Button
var back_button: Button
var section := "" # the tab showing
var entries := {} # term id -> its row (the tab showing)
var handedness := "right"
var _sections: Array = []
var _group := ButtonGroup.new()
## UI-27 (owner, 2026-11-19): a tapped word opens large in an overlay.
var overlay: Control
var overlay_picture: Control
var overlay_word: Label
var overlay_meaning: Label
var overlay_close: Button
var shown_term := "" # the word open in the overlay
var _press_scroll := 0

func _ready() -> void:
	name = "TalkTheTalk"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sections = Glossary.sections()
	dim = ColorRect.new()
	dim.name = "GlossaryDim"
	dim.color = UiTheme.SCRIM # UI-35: one scrim behind every overlay
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	panel = PanelContainer.new()
	panel.name = "GlossaryPanel"
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	title = Label.new()
	title.name = "GlossaryTitle"
	title.text = "Talk the Talk"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	var lede := Label.new()
	lede.text = "Bowling words, and what they mean here"
	lede.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lede.add_theme_font_size_override("font_size", 17)
	lede.add_theme_color_override("font_color", Diagram.MUTED)
	box.add_child(lede)
	# UI-27: tabs as the Clubhouse's own: segments in a dark track, the chosen one lit.
	var track := PanelContainer.new()
	track.name = "GlossaryTabTrack"
	var track_style := Art.panel_style(Color("0b1519"), Color("2f474f"), 1)
	track_style.set_corner_radius_all(10)
	track_style.set_content_margin_all(4)
	track.add_theme_stylebox_override("panel", track_style)
	box.add_child(track)
	tabs = HBoxContainer.new()
	tabs.name = "GlossaryTabs"
	tabs.add_theme_constant_override("separation", 2)
	track.add_child(tabs)
	for s in _sections:
		var tab := Button.new()
		tab.name = "Tab_" + String(s.id)
		tab.text = String(s.get("tab", s.name)) # a short label; Next names the tab in full
		tab.toggle_mode = true
		tab.button_group = _group
		Club.segment_style(tab)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.custom_minimum_size = Vector2(0, 52)
		tab.clip_text = true
		tab.add_theme_font_size_override("font_size", 18)
		tab.pressed.connect(show_section.bind(String(s.id)))
		tabs.add_child(tab)
		tab_buttons[String(s.id)] = tab
	scroll = ScrollContainer.new()
	scroll.name = "GlossaryScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER # a finger scrolls, as in the Clubhouse
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	box.add_child(scroll)
	list = VBoxContainer.new()
	list.name = "GlossaryList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	back_button = Button.new()
	back_button.name = "GlossaryBack"
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(220, 64)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(go_back)
	box.add_child(back_button)
	_build_overlay()
	hide()
	resized.connect(_layout)
	_layout()

## UI-27: one word, large: its picture at full width, its name and its meaning.
func _build_overlay() -> void:
	overlay = Control.new()
	overlay.name = "TermOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.hide()
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = UiTheme.SCRIM # UI-35: one scrim behind every overlay
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(event):
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed: close_term())
	overlay.add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(centre)
	var card := PanelContainer.new()
	card.name = "TermCard"
	card.add_theme_stylebox_override("panel", UiTheme.frame("slip", 22.0, 18.0))
	centre.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	overlay_word = Label.new()
	overlay_word.name = "TermWord"
	overlay_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_word.add_theme_font_size_override("font_size", 36)
	overlay_word.add_theme_color_override("font_color", WORD)
	box.add_child(overlay_word)
	overlay_picture = Diagram.new({}, handedness)
	overlay_picture.name = "TermPicture"
	overlay_picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(overlay_picture)
	overlay_meaning = Label.new()
	overlay_meaning.name = "TermMeaning"
	overlay_meaning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_meaning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_meaning.add_theme_font_size_override("font_size", 24)
	overlay_meaning.add_theme_color_override("font_color", MEANING)
	box.add_child(overlay_meaning)
	overlay_close = Button.new()
	overlay_close.name = "TermClose"
	overlay_close.text = "Close"
	overlay_close.custom_minimum_size = Vector2(200, 60)
	overlay_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	overlay_close.pressed.connect(close_term)
	box.add_child(overlay_close)

## Opens one word large over the list.
func show_term(id: String) -> void:
	var term: Dictionary = {}
	for t in Glossary.terms():
		if t.id == id: term = t
	if term.is_empty(): return
	shown_term = id
	overlay_word.text = String(term.term)
	overlay_meaning.text = String(term.text)
	overlay_picture.spec = term.get("diagram", {})
	overlay_picture.set_handedness(handedness)
	var width := minf(size.x - 80.0, 520.0)
	overlay_picture.custom_minimum_size = Vector2(width, width * Diagram.BOX.y / Diagram.BOX.x)
	overlay_meaning.custom_minimum_size.x = width
	overlay_picture.queue_redraw()
	overlay.show()
	overlay_close.grab_focus()

func close_term() -> void:
	if not overlay.visible: return
	overlay.hide()
	var row: Control = entries.get(shown_term)
	shown_term = ""
	if row != null and row.is_inside_tree(): row.grab_focus()

## Opens on the first tab, its pictures in the player's hand.
func open(settings: Dictionary = {}, first: String = "") -> void:
	handedness = String(settings.get("handedness", "right"))
	show()
	show_section(first if not first.is_empty() else String(_sections[0].id))
	tab_buttons[section].grab_focus()

func is_open() -> bool:
	return visible

func go_back() -> void:
	if not visible: return
	if overlay.visible: # Escape closes the open word first
		close_term()
		return
	hide()
	closed.emit()

## Close without returning to How to Play (leaving the Clubhouse).
func close() -> void:
	overlay.hide()
	hide()

func section_ids() -> Array:
	return _sections.map(func(s): return String(s.id))

## Shows one tab's words, from the top.
func show_section(id: String) -> void:
	var data: Dictionary = {}
	for s in _sections:
		if s.id == id: data = s
	if data.is_empty(): return
	section = id
	tab_buttons[id].set_pressed_no_signal(true)
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	entries.clear()
	for term in data.terms:
		var row := _row(term)
		list.add_child(row)
		entries[String(term.id)] = row
	var ids := section_ids()
	var at := ids.find(id)
	next_button = null
	if at < ids.size() - 1:
		var following: Dictionary = _sections[at + 1]
		next_button = Button.new()
		next_button.name = "GlossaryNext"
		next_button.text = "Next: %s" % following.name
		next_button.custom_minimum_size = Vector2(0, 56)
		next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		# Deferred: the list it sits in is rebuilt, so it must not be freed mid-press.
		next_button.pressed.connect(func(): _next.call_deferred(String(following.id)))
		list.add_child(next_button)
	Club.drag_through(list) # UI-27: a drag that starts on Next scrolls too; it still takes a tap
	scroll.scroll_vertical = 0

func _next(id: String) -> void:
	show_section(id)
	tab_buttons[id].grab_focus()

## A term's picture, as drawn in its row (for tests and captures).
func diagram(id: String) -> Control:
	var row: Control = entries.get(id)
	return row.find_child("Picture", true, false) if row != null else null

func _row(term: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.name = "Term_" + String(term.id)
	row.add_theme_stylebox_override("panel", UiTheme.frame("slip", 10.0, 8.0))
	# UI-27: a drag that starts on a row scrolls the list (as the Binder's cards, UI-8);
	# a tap, or Enter on a focused row, opens the word large.
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.focus_mode = Control.FOCUS_ALL
	var id := String(term.id)
	row.gui_input.connect(func(event): _row_input(event, id))
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 12)
	row.add_child(line)
	var picture := Diagram.new(term.get("diagram", {}), handedness)
	picture.name = "Picture"
	picture.custom_minimum_size = Diagram.BOX * 0.95
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(picture)
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	words.add_theme_constant_override("separation", 2)
	line.add_child(words)
	var name_label := Label.new()
	name_label.name = "Word"
	name_label.text = String(term.term)
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", WORD) # dark inks on the cream slip
	words.add_child(name_label)
	var text := Label.new()
	text.name = "Meaning"
	text.text = String(term.text)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 17)
	text.custom_minimum_size.x = 120
	text.add_theme_color_override("font_color", MEANING)
	words.add_child(text)
	return row

func _row_input(event: InputEvent, id: String) -> void:
	var touch: bool = event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)
	if touch and event.pressed:
		_press_scroll = scroll.scroll_vertical
	elif touch and not event.pressed:
		if absi(scroll.scroll_vertical - _press_scroll) <= SCROLL_SLOP and not overlay.visible:
			show_term(id)
	elif event.is_action_pressed("ui_accept"):
		show_term(id)
		accept_event()

## As Throw Settings: the full width in portrait, a centred column in landscape.
func _layout() -> void:
	if panel == null: return
	var portrait := size.y >= size.x
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_top = 88.0 if portrait else 24.0
	panel.offset_bottom = -12.0
	if portrait:
		panel.anchor_left = 0.0
		panel.anchor_right = 1.0
		panel.offset_left = 12.0
		panel.offset_right = -12.0
	else:
		panel.anchor_left = 0.5
		panel.anchor_right = 0.5
		panel.offset_left = -330.0
		panel.offset_right = 330.0
