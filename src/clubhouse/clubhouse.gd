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
## asset ID through ClubhouseArt (placeholders until E16-ART). No new currency.
signal career_changed
const Model = preload("res://src/clubhouse/clubhouse_model.gd")
const Art = preload("res://src/clubhouse/clubhouse_art.gd")
const Career = preload("res://src/persistence/career_profile.gd")
const TABS := ["board", "binder", "trophies", "goals"]
const TAB_NAMES := {"board": "League Board", "binder": "Binder", "trophies": "Trophies", "goals": "Goals"}
const FONT_SIZE := 22 # readable at phone size on the 720-wide portrait canvas

var career: Dictionary = {}
var graph: Dictionary = {}
var current_tab := "board"
var category := ""
var selected_item := ""
var tab_buttons: Dictionary = {}
var pages: Dictionary = {}
var records_label: Label
var latest_label: Label
var binder_counts: Label
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
	theme = theme_override
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
	var bar := HFlowContainer.new()
	bar.name = "ClubhouseTabs"
	bar.alignment = FlowContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("h_separation", 8)
	bar.add_theme_constant_override("v_separation", 8)
	column.add_child(bar)
	for tab in TABS:
		var button := Button.new()
		button.name = "Tab" + tab.capitalize()
		button.text = TAB_NAMES[tab]
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(160, 56)
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
	show_tab("board")

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

func _build_trophies() -> void:
	_heading(pages.trophies, "Trophy shelf")
	trophy_grid = HFlowContainer.new()
	trophy_grid.name = "TrophyGrid"
	trophy_grid.add_theme_constant_override("h_separation", 16)
	trophy_grid.add_theme_constant_override("v_separation", 16)
	pages.trophies.add_child(trophy_grid)

func _build_goals() -> void:
	_heading(pages.goals, "Mastery goals")
	var hint := _label(pages.goals, "GoalsHint")
	hint.text = "Follow up to three goals; they show on the League Board and after every attempt. Practice attempts do not count."
	goals_message = _label(pages.goals, "GoalsMessage")
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
		filter.custom_minimum_size = Vector2(0, 52)
		filter.pressed.connect(func(): _filter(key))
		binder_filters.add_child(filter)
	_clear(binder_grid)
	var shown: Array = all.filter(func(e): return category.is_empty() or e.category == category)
	if selected_item.is_empty() or shown.filter(func(e): return e.id == selected_item).is_empty():
		selected_item = shown[0].id if not shown.is_empty() else ""
	for entry in shown:
		var card := Button.new()
		card.name = "Binder_" + entry.id.replace(".", "_")
		card.text = "%s\n%s" % [entry.name, Model.STATE_NAMES[entry.state]]
		card.toggle_mode = true
		card.button_pressed = entry.id == selected_item
		card.custom_minimum_size = Vector2(210, 84)
		card.modulate = Color(1, 1, 1, 0.6) if entry.state == "locked" else Color.WHITE
		card.pressed.connect(func(): _select(entry.id))
		binder_grid.add_child(card)
	_clear(binder_art)
	binder_detail.text = ""
	for entry in shown:
		if entry.id == selected_item:
			binder_art.add_child(Art.slot(entry.asset, 150, entry.state != "locked"))
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
		var box := VBoxContainer.new()
		box.name = "Trophy_" + slot.id.replace(".", "_")
		box.custom_minimum_size = Vector2(200, 0)
		box.add_theme_constant_override("separation", 6)
		var art_holder := CenterContainer.new()
		art_holder.add_child(Art.slot(slot.asset, 120, slot.earned))
		box.add_child(art_holder)
		var title := _label(box, "Name")
		title.text = slot.name + ("" if slot.earned else " (not yet)")
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var detail := _label(box, "Detail", 18)
		detail.text = slot.detail
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		trophy_grid.add_child(box)

func _refresh_goals() -> void:
	_clear(goals_list)
	for goal in Model.goals(career, graph):
		var row := HBoxContainer.new()
		row.name = "Goal_" + goal.id.replace(".", "_")
		row.add_theme_constant_override("separation", 12)
		var text := _label(row, "Text")
		var where := "in one attempt" if goal.scope == "attempt" else "across your Career"
		text.text = "%s — %s\n%s" % [goal.name, goal.text, "Complete: " + goal.reward if goal.done else "Progress %d/%d (%s)" % [goal.progress, goal.threshold, where]]
		var track := Button.new()
		track.name = "Track"
		track.custom_minimum_size = Vector2(170, 56)
		track.text = "Done" if goal.done else ("Following" if goal.tracked else "Follow")
		track.disabled = goal.done
		track.toggle_mode = true
		track.set_pressed_no_signal(goal.tracked)
		track.pressed.connect(func(): _toggle(goal.id))
		row.add_child(track)
		goals_list.add_child(row)

func track_button(objective_id: String) -> Button:
	var row := goals_list.get_node_or_null("Goal_" + objective_id.replace(".", "_"))
	return row.get_node("Track") if row != null else null

func _toggle(objective_id: String) -> void:
	var refused := Career.toggle_tracked(career, objective_id, graph.get("objectives", []))
	goals_message.text = refused
	if refused.is_empty():
		career_changed.emit()
	_refresh_goals()
	track_button(objective_id).grab_focus()
