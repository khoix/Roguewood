extends Control
## The Clubhouse (E16, design §16): the home screen between attempts. Four tabs:
## - League Board: the shell's League, kit, Continue and Enter controls (handed in
##   by the shell), each League's record and titles, and the latest unlocks;
## - Binder: every collectible as Locked, Available, Discovered or Mastered, with
##   what unlocks it and its history (inspect a card for detail);
## - Trophies: League titles, mastery ribbons, rival plaques and club decorations;
## - Goals: every mastery objective with progress; follow up to three.
## It only reads the Career (ClubhouseModel), except for tracked goals, which it
## changes and announces with career_changed so the shell saves them. Art comes by
## asset ID through ClubhouseArt. E16-ART supplies final identities. No new currency.
signal career_changed
const Model = preload("res://src/clubhouse/clubhouse_model.gd")
const Art = preload("res://src/clubhouse/clubhouse_art.gd")
const CardView = preload("res://src/presentation/card_view.gd")
const Career = preload("res://src/persistence/career_profile.gd")
const TABS := ["board", "binder", "trophies", "goals"]
const TAB_NAMES := {"board": "League Board", "binder": "Binder", "trophies": "Trophies", "goals": "Goals"}
const FONT_SIZE := 22 # readable at phone size on the 720-wide portrait canvas
## Below this width (a phone held upright lays out 540 wide) the pages use their
## narrow layouts: four tabs on one row, stat tiles, trophy rows.
const NARROW := 700.0
const STATE_ORDER := ["locked", "available", "discovered", "mastered"]

var career: Dictionary = {}
var graph: Dictionary = {}
var current_tab := "board"
var category := ""
var selected_item := ""
var tab_buttons: Dictionary = {}
var pages: Dictionary = {}
var records_label: Label
var latest_label: Label
var binder_counts: Label # the full sentence (read by tools and tests); the tiles show it
var binder_stats: HBoxContainer
var _narrow := false
var _fit_width := 0.0
var binder_filters: HFlowContainer
var binder_grid: HFlowContainer
var binder_detail: Label
var binder_art: CenterContainer
var trophy_grid: HFlowContainer
var goals_list: VBoxContainer
var goals_message: Label

func _init() -> void:
	name = "Clubhouse"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var theme_override := Theme.new()
	theme_override.default_font_size = FONT_SIZE
	theme_override.set_color("font_color", "Label", Color("f4e9cf"))
	theme = theme_override
	var background := ColorRect.new()
	background.name = "ClubhouseBackdrop"
	background.color = Color("101d25")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var masthead := HBoxContainer.new()
	masthead.alignment = BoxContainer.ALIGNMENT_CENTER
	masthead.add_theme_constant_override("separation", 16)
	column.add_child(masthead)
	masthead.add_child(Art.slot("deco.club_sign", 56))
	var club_title := Label.new()
	club_title.text = "THE CLUBHOUSE"
	club_title.add_theme_font_size_override("font_size", 28)
	masthead.add_child(club_title)
	# One row of four equal tabs in both orientations (a phone shortens "League Board").
	var bar := HBoxContainer.new()
	bar.name = "ClubhouseTabs"
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 8)
	column.add_child(bar)
	for tab in TABS:
		var button := Button.new()
		button.name = "Tab" + tab.capitalize()
		button.text = TAB_NAMES[tab]
		button.toggle_mode = true
		Art.button_style(button)
		button.custom_minimum_size = Vector2(0, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): show_tab(tab))
		bar.add_child(button)
		tab_buttons[tab] = button
	for tab in TABS:
		var scroll := ScrollContainer.new()
		scroll.name = "Page" + tab.capitalize()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		column.add_child(scroll)
		var body := VBoxContainer.new()
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_theme_constant_override("separation", 16)
		scroll.add_child(body)
		pages[tab] = body
	_build_board()
	_build_binder()
	_build_trophies()
	_build_goals()
	resized.connect(_fit)
	_fit()
	show_tab("board")

## Narrow (phone) or wide: the tab words, then the visible page is laid out again.
func _fit() -> void:
	var narrow := size.x > 0.0 and size.x < NARROW
	for tab in TABS:
		tab_buttons[tab].text = TAB_NAMES[tab].get_slice(" ", TAB_NAMES[tab].get_slice_count(" ") - 1) if narrow else TAB_NAMES[tab]
		tab_buttons[tab].add_theme_font_size_override("font_size", 20 if narrow else FONT_SIZE)
	# A phone's pages size their cards and rows from the width.
	if narrow != _narrow or (narrow and not is_equal_approx(size.x, _fit_width)):
		_narrow = narrow
		_fit_width = size.x
		refresh()

## A number over its caption: the Career and binder summaries read at a glance.
static func stat_tile(value: String, caption: String) -> Control:
	var tile := PanelContainer.new()
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := Art.panel_style(Color("182b32"), Color("4d5f61"))
	style.set_content_margin_all(6)
	tile.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	tile.add_child(box)
	for row in [[value, 26, Color("f0d99b")], [caption, 16, Color("c9d3cf")]]:
		var label := Label.new()
		label.text = row[0]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", row[1])
		label.add_theme_color_override("font_color", row[2])
		box.add_child(label)
	return tile

## A goal's progress: a bar with its count.
static func progress_row(progress: int, threshold: int, note: String = "") -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.max_value = maxi(threshold, 1)
	bar.value = clampi(progress, 0, threshold)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(120, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var back := Art.panel_style(Color("0c151a"), Color("4d5f61"))
	back.set_content_margin_all(0)
	bar.add_theme_stylebox_override("background", back)
	var fill := Art.panel_style(Color("d8b873"), Color("d8b873"))
	fill.set_content_margin_all(0)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	var count := Label.new()
	count.name = "Count"
	count.text = "%d/%d%s" % [mini(progress, threshold), threshold, "" if note.is_empty() else " · " + note]
	count.add_theme_font_size_override("font_size", 18)
	row.add_child(count)
	return row

func _label(parent: Node, node_name: String, size: int = FONT_SIZE) -> Label:
	var label := Label.new()
	label.name = node_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(240, 0)
	if size != FONT_SIZE:
		label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label

func _heading(parent: Node, text: String) -> void:
	var label := _label(parent, "Heading", 30)
	label.text = text

## The shell's League controls go at the top of the board.
func adopt_board(panel: Control) -> void:
	var holder: CenterContainer = pages.board.get_node("BoardHolder")
	holder.add_child(panel)

func _build_board() -> void:
	var holder := CenterContainer.new()
	holder.name = "BoardHolder"
	pages.board.add_child(holder)
	var notes := VBoxContainer.new()
	notes.add_theme_constant_override("separation", 12)
	pages.board.add_child(notes)
	_heading(notes, "League records")
	records_label = _label(notes, "LeagueRecords")
	_heading(notes, "Latest unlocks")
	latest_label = _label(notes, "LatestUnlocks")

func _build_binder() -> void:
	_heading(pages.binder, "Collection binder")
	binder_counts = _label(pages.binder, "BinderCounts")
	binder_counts.hide()
	binder_stats = HBoxContainer.new()
	binder_stats.name = "BinderStats"
	binder_stats.add_theme_constant_override("separation", 8)
	pages.binder.add_child(binder_stats)
	binder_filters = HFlowContainer.new()
	binder_filters.name = "BinderFilters"
	binder_filters.add_theme_constant_override("h_separation", 8)
	binder_filters.add_theme_constant_override("v_separation", 8)
	pages.binder.add_child(binder_filters)
	var detail := HBoxContainer.new()
	detail.name = "BinderDetail"
	detail.add_theme_constant_override("separation", 16)
	pages.binder.add_child(detail)
	binder_art = CenterContainer.new()
	binder_art.name = "BinderArt"
	detail.add_child(binder_art)
	binder_detail = _label(detail, "BinderText")
	binder_grid = HFlowContainer.new()
	binder_grid.name = "BinderGrid"
	binder_grid.add_theme_constant_override("h_separation", 8)
	binder_grid.add_theme_constant_override("v_separation", 8)
	pages.binder.add_child(binder_grid)
	var note := _label(pages.binder, "BinderNote", 18)
	note.text = "The binder keeps each item's history. A new attempt never starts with an item."
	note.add_theme_color_override("font_color", Color("9aa8a6"))

func _build_trophies() -> void:
	_heading(pages.trophies, "Trophy shelf")
	trophy_grid = HFlowContainer.new()
	trophy_grid.name = "TrophyGrid"
	trophy_grid.alignment = FlowContainer.ALIGNMENT_CENTER
	trophy_grid.add_theme_constant_override("h_separation", 16)
	trophy_grid.add_theme_constant_override("v_separation", 16)
	pages.trophies.add_child(trophy_grid)

func _build_goals() -> void:
	_heading(pages.goals, "Mastery goals")
	var hint := _label(pages.goals, "GoalsHint")
	hint.text = "Follow up to three. They show on the League Board and after every attempt; practice does not count."
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("c9d3cf"))
	goals_message = _label(pages.goals, "GoalsMessage")
	goals_message.add_theme_color_override("font_color", Color(1.0, 0.75, 0.5))
	goals_message.hide()
	goals_list = VBoxContainer.new()
	goals_list.name = "GoalsList"
	goals_list.add_theme_constant_override("separation", 12)
	pages.goals.add_child(goals_list)

func show_tab(tab: String) -> void:
	current_tab = tab
	for name_key in TABS:
		pages[name_key].get_parent().visible = name_key == tab
		tab_buttons[name_key].set_pressed_no_signal(name_key == tab)
	refresh()

## Rebuilds the visible page from the Career and graph.
func refresh() -> void:
	if career.is_empty() or graph.is_empty():
		return
	match current_tab:
		"board": _refresh_board()
		"binder": _refresh_binder()
		"trophies": _refresh_trophies()
		"goals": _refresh_goals()

func _refresh_board() -> void:
	records_label.text = "\n".join(Model.board(career, graph).map(func(row): return Model.record_line(row) + ("" if row.access.is_empty() else " · " + row.access)))
	var latest: Array = Model.latest(career, graph)
	latest_label.text = "\n".join(latest.map(func(l): return l.text)) if not latest.is_empty() else "No unlocks yet. Beat a rival for the first time to add an item to the pool."

func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _refresh_binder() -> void:
	var catalogue: Dictionary = graph.get("catalogue", {})
	var all: Array = Model.binder(career, graph, catalogue)
	var counts := Model.binder_counts(all)
	binder_counts.text = "%d Locked · %d Available · %d Discovered · %d Mastered" % [counts.locked, counts.available, counts.discovered, counts.mastered]
	_clear(binder_stats)
	for state in STATE_ORDER:
		binder_stats.add_child(stat_tile(str(counts[state]), Model.STATE_NAMES[state]))
	_clear(binder_filters)
	var categories: Array = [""]
	for entry in all:
		if entry.category not in categories:
			categories.append(entry.category)
	for key in categories:
		var filter := Button.new()
		filter.name = "Filter" + (key.capitalize().replace(" ", "") if not key.is_empty() else "All")
		filter.text = Model.CATEGORY_NAMES.get(key, "All")
		filter.toggle_mode = true
		filter.button_pressed = key == category
		Art.button_style(filter)
		filter.custom_minimum_size = Vector2(0, 52)
		filter.pressed.connect(func(): _filter(key))
		binder_filters.add_child(filter)
	_clear(binder_grid)
	var shown: Array = all.filter(func(e): return category.is_empty() or e.category == category)
	if selected_item.is_empty() or shown.filter(func(e): return e.id == selected_item).is_empty():
		selected_item = shown[0].id if not shown.is_empty() else ""
	# A phone fits three cards across the page exactly; wider screens keep 150 px cards.
	var card_size := Vector2(150, 214)
	if _narrow:
		var room := size.x - 32.0 - 12.0 # the page margins and the scroll bar
		var width := floorf((room - 16.0) / 3.0)
		card_size = Vector2(width, floorf(width * 214.0 / 150.0))
	for entry in shown:
		# UI-1: binder entries are the playing cards themselves, with their Career state.
		var card := CardView.new()
		card.name = "Binder_" + entry.id.replace(".", "_")
		card.set_item(entry.id)
		var state_word: String = Model.STATE_NAMES[entry.state]
		card.set_state("locked" if entry.state == "locked" else "", "" if entry.state in ["locked", "available"] else ("%s %s" % [Art.STATE_MARKS[entry.state], state_word]).to_upper(), "",
			"%s\n%s  %s" % [entry.name, Art.STATE_MARKS[entry.state], state_word])
		if Art.has_art(entry.asset):
			card.icon = load(Art.path_for(entry.asset)) # the binder's identity art (art journeys check it)
		card.toggle_mode = true
		card.button_pressed = entry.id == selected_item
		card.custom_minimum_size = card_size
		card.pressed.connect(func(): _select(entry.id))
		binder_grid.add_child(card)
	_clear(binder_art)
	binder_detail.text = ""
	for entry in shown:
		if entry.id == selected_item:
			var picture := Art.slot(entry.asset, 120 if _narrow else 150, entry.state != "locked")
			if entry.state == "mastered": Art.mastered_finish(picture)
			binder_art.add_child(picture)
			binder_detail.text = Model.inspect(entry, catalogue)

## The grid is rebuilt on every choice; keyboard focus follows the chosen control.
func _select(item_id: String) -> void:
	selected_item = item_id
	_refresh_binder()
	entry_button(item_id).grab_focus()

func _filter(key: String) -> void:
	category = key
	_refresh_binder()
	filter_button(key).grab_focus()

func entry_button(item_id: String) -> Button:
	return binder_grid.get_node_or_null("Binder_" + item_id.replace(".", "_"))

func filter_button(key: String) -> Button:
	return binder_filters.get_node_or_null("Filter" + (key.capitalize().replace(" ", "") if not key.is_empty() else "All"))

func _refresh_trophies() -> void:
	_clear(trophy_grid)
	for slot in Model.trophies(career, graph):
		if _narrow:
			trophy_grid.add_child(_trophy_row(slot))
			continue
		var box := VBoxContainer.new()
		box.name = "Trophy_" + slot.id.replace(".", "_")
		box.custom_minimum_size = Vector2(316, 0)
		box.add_theme_constant_override("separation", 6)
		var shelf_style := Art.panel_style(Color("1c2d32"), Color("77684c"), 2)
		box.draw.connect(func(): box.draw_style_box(shelf_style, Rect2(Vector2.ZERO, box.size)))
		box.resized.connect(func(): box.queue_redraw())
		var top_space := Control.new()
		top_space.custom_minimum_size.y = 12
		box.add_child(top_space)
		var art_holder := CenterContainer.new()
		art_holder.add_child(Art.slot(slot.asset, 120, slot.earned))
		box.add_child(art_holder)
		var title := _label(box, "Name")
		title.text = slot.name + ("" if slot.earned else " (not yet)")
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		title.custom_minimum_size.x = 292
		var detail := _label(box, "Detail", 20)
		detail.text = slot.detail
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		detail.custom_minimum_size.x = 292
		var bottom_space := Control.new()
		bottom_space.custom_minimum_size.y = 12
		box.add_child(bottom_space)
		trophy_grid.add_child(box)

## A phone's shelf: one full-width row per trophy, the art beside its name and detail.
func _trophy_row(slot: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.name = "Trophy_" + slot.id.replace(".", "_")
	row.custom_minimum_size = Vector2(maxf(size.x - 32.0 - 12.0, 240.0), 0)
	row.add_theme_stylebox_override("panel", Art.panel_style(Color("1c2d32"), Color("77684c"), 2))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	row.add_child(line)
	line.add_child(Art.slot(slot.asset, 84, slot.earned))
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 2)
	line.add_child(text)
	var title := _label(text, "Name")
	title.custom_minimum_size.x = 120
	title.text = slot.name + ("" if slot.earned else " (not yet)")
	if not slot.earned: title.add_theme_color_override("font_color", Color("c9d3cf"))
	var detail := _label(text, "Detail", 18)
	detail.custom_minimum_size.x = 120
	detail.text = slot.detail
	detail.add_theme_color_override("font_color", Color("f0d99b") if slot.earned else Color("9aa8a6"))
	return row

## Each goal: its name beside a compact Follow button, what it asks, and a
## progress bar with its count.
func _refresh_goals() -> void:
	_clear(goals_list)
	for goal in Model.goals(career, graph):
		var row := PanelContainer.new()
		row.name = "Goal_" + goal.id.replace(".", "_")
		row.add_theme_stylebox_override("panel", Art.panel_style(Color("16262d"), Color("d8b873") if goal.tracked else Color("4d5f61"), 2 if goal.tracked else 1))
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		row.add_child(box)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 12)
		box.add_child(head)
		var title := _label(head, "Name", 24)
		title.custom_minimum_size.x = 120
		title.text = goal.name
		title.add_theme_color_override("font_color", Color("f0d99b"))
		var text := _label(box, "Text", 20)
		text.custom_minimum_size.x = 120
		text.text = goal.text
		if goal.done:
			var reward := _label(box, "Reward", 18)
			reward.custom_minimum_size.x = 120
			reward.text = "Complete: " + goal.reward
			reward.add_theme_color_override("font_color", Color("a8e0b0"))
		else:
			box.add_child(progress_row(goal.progress, goal.threshold, "in one attempt" if goal.scope == "attempt" else "across your Career"))
		var track := Button.new()
		track.name = "Track"
		track.custom_minimum_size = Vector2(132, 48)
		track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		track.add_theme_font_size_override("font_size", 20)
		Art.button_style(track)
		track.text = "Done" if goal.done else ("Following" if goal.tracked else "Follow")
		track.disabled = goal.done
		track.toggle_mode = true
		track.set_pressed_no_signal(goal.tracked)
		track.pressed.connect(func(): _toggle(goal.id))
		head.add_child(track)
		goals_list.add_child(row)

func track_button(objective_id: String) -> Button:
	var row := goals_list.get_node_or_null("Goal_" + objective_id.replace(".", "_"))
	return row.find_child("Track", true, false) if row != null else null

func _toggle(objective_id: String) -> void:
	var refused := Career.toggle_tracked(career, objective_id, graph.get("objectives", []))
	goals_message.text = refused
	goals_message.visible = not refused.is_empty()
	if refused.is_empty():
		career_changed.emit()
	_refresh_goals()
	track_button(objective_id).grab_focus()
