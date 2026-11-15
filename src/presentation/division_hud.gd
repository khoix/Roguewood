extends Control
## Division presentation (E09): a match bar (match, target, score, frames left) with
## an inspectable rule/boss badge, a rival reaction bubble that never takes input,
## a skippable rival introduction, and the attempt result with Retry and Clubhouse.
## A view only: the lab and the pure DivisionRun own every rule and number.
## E21 portraits resolve exact authored rival IDs; lab badges remain developmental.
const RivalArt = preload("res://src/presentation/rival_art.gd")
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
const ItemArt = preload("res://src/presentation/item_assets.gd")
const RivalRules = preload("res://src/rules/rival_rules.gd")
signal intro_done
signal endless_pressed
signal retry_pressed
signal menu_pressed


var bar: PanelContainer
var info: Label
var extra_rule_badges: HBoxContainer
var badge: Button
var rule_panel: PanelContainer
var rule_text: Label
var reaction: PanelContainer
var reaction_portrait: Portrait
var reaction_text: Label
var intro: PanelContainer
var intro_portrait: Portrait
var intro_title: Label
var intro_body: Label
var intro_button: Button
var result: PanelContainer
var result_title: Label
var result_body: Label
var endless_button: Button
var retry_button: Button
var menu_button: Button
var result_portrait: Portrait
var intro_reward: TextureRect
var result_reward: TextureRect
var current_rival: Dictionary = {}
var reduced_motion := false
var side_box: BoxContainer
var money: Label
var title_label: Label
var _titles := ["", ""] # the bar's title, and the short one the slim roll-view bar shows
var _slim := false
var _result_width := 0.0
var score_label: Label
var frames_label: Label
var _top_row: HBoxContainer
var _bottom_row: HBoxContainer

## A developmental rival badge: a coloured disc, initials and a mood mouth.
class Portrait extends Control:
	var color := Color(0.6, 0.8, 1.0)
	var initials := ""
	var mood := "entrance"
	var texture: Texture2D
	var still := false
	var age := 0.0
	func _process(delta: float) -> void:
		age += delta
		if texture != null and visible: queue_redraw()
	func _draw() -> void:
		if texture != null:
			draw_texture_rect(texture, Rect2(Vector2(0, 0 if still else roundf(sin(age * 1.8))), size), false)
			return
		var r: float = minf(size.x, size.y) * 0.5
		var c := size * 0.5
		draw_circle(c, r, color.darkened(0.55))
		draw_circle(c, r * 0.9, color)
		var font := get_theme_default_font()
		var font_size := int(r * 0.6)
		draw_string(font, c + Vector2(-r, -r * 0.05), initials, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, font_size, Color(0.08, 0.06, 0.12))
		var mouth := c + Vector2(0, r * 0.45)
		var w := r * 0.4
		match mood:
			"impressed", "threatened":
				draw_arc(mouth, w * 0.35, 0.0, TAU, 16, Color(0.08, 0.06, 0.12), 3.0)
			"defeated":
				draw_arc(mouth + Vector2(0, w * 0.5), w, PI * 1.15, PI * 1.85, 12, Color(0.08, 0.06, 0.12), 3.0)
			_:
				draw_arc(mouth - Vector2(0, w * 0.6), w, PI * 0.15, PI * 0.85, 12, Color(0.08, 0.06, 0.12), 3.0)

func _ready() -> void:
	name = "DivisionHud"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar = PanelContainer.new()
	bar.name = "MatchBar"
	bar.add_theme_stylebox_override("panel", UiTheme.frame("hud", 18.0, 10.0))
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 12.0
	bar.offset_right = -12.0
	add_child(bar)
	# UI-3: the bar shows the match as a title, a big score against target and the
	# frames left; `info` keeps the full sentence (read by tools and tests) unshown.
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 2)
	bar.add_child(rows)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	rows.add_child(row)
	_top_row = row
	_bottom_row = HBoxContainer.new()
	_bottom_row.add_theme_constant_override("separation", 12)
	rows.add_child(_bottom_row)
	info = Label.new()
	info.name = "MatchInfo"
	info.visible = false
	row.add_child(info)
	title_label = _bar_label(row, "MatchTitle", 20, UiTheme.IVORY)
	# UI-8: room at the top row's right end for the session menu button, which sits
	# inside the bar's corner (its width is set with the layout).
	menu_room = Control.new()
	menu_room.name = "MenuRoom"
	menu_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.clip_text = true
	score_label = _bar_label(_bottom_row, "MatchScore", 28, UiTheme.IVORY)
	frames_label = _bar_label(_bottom_row, "FramesLeft", 18, UiTheme.SEA_GLASS)
	frames_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# UI-2: the rule badge, its extra seals and the money slot; one row in
	# landscape, stacked at the right of portrait's two-row bar.
	side_box = BoxContainer.new()
	side_box.name = "BarSide"
	side_box.alignment = BoxContainer.ALIGNMENT_CENTER
	side_box.add_theme_constant_override("separation", 8)
	row.add_child(side_box)
	var badges := HBoxContainer.new()
	badges.add_theme_constant_override("separation", 6)
	side_box.add_child(badges)
	badge = Button.new()
	badge.name = "RuleBadge"
	badge.custom_minimum_size = Vector2(200, 48)
	badge.add_theme_font_size_override("font_size", 18)
	badge.pressed.connect(func(): rule_panel.visible = not rule_panel.visible)
	badges.add_child(badge)
	extra_rule_badges = HBoxContainer.new()
	extra_rule_badges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badges.add_child(extra_rule_badges)
	var money_slot := PanelContainer.new()
	money_slot.name = "MoneySlot"
	money_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	money_slot.add_theme_stylebox_override("panel", UiTheme.frame("panel", 14.0, 4.0))
	money_slot.custom_minimum_size = Vector2(120, 44)
	side_box.add_child(money_slot)
	money = Label.new()
	money.name = "Money"
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money.add_theme_font_size_override("font_size", 26)
	money.add_theme_color_override("font_color", UiTheme.BRASS)
	money_slot.add_child(money)
	rule_panel = PanelContainer.new()
	rule_panel.name = "RulePanel"
	rule_panel.add_theme_stylebox_override("panel", UiTheme.frame("menu", 18.0, 14.0))
	rule_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	rule_panel.offset_left = 12.0 # the bar's own edges, so it covers the row beneath it cleanly
	rule_panel.offset_right = -12.0
	rule_panel.hide()
	add_child(rule_panel)
	rule_text = _label(rule_panel, "RuleText", 22)
	# Reaction bubble: purely visual, so it can never take a touch or block a throw.
	reaction = PanelContainer.new()
	reaction.name = "Reaction"
	reaction.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reaction.add_theme_stylebox_override("panel", UiTheme.frame("panel", 14.0, 10.0))
	reaction.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	reaction.custom_minimum_size = Vector2(420, 0)
	reaction.hide()
	add_child(reaction)
	var reaction_row := HBoxContainer.new()
	reaction_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reaction_row.add_theme_constant_override("separation", 10)
	reaction.add_child(reaction_row)
	reaction_portrait = Portrait.new()
	reaction_portrait.custom_minimum_size = Vector2(72, 72)
	reaction_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reaction_portrait.texture_filter = TEXTURE_FILTER_NEAREST
	reaction_row.add_child(reaction_portrait)
	reaction_text = Label.new()
	reaction_text.name = "ReactionText"
	reaction_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reaction_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reaction_text.custom_minimum_size = Vector2(320, 0)
	reaction_text.add_theme_font_size_override("font_size", 20)
	reaction_row.add_child(reaction_text)
	_build_intro()
	result = _sheet("AttemptResult")
	var result_box: VBoxContainer = result.get_child(0)
	result_portrait = Portrait.new()
	result_portrait.custom_minimum_size = Vector2(96,96)
	result_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result_portrait.texture_filter = TEXTURE_FILTER_NEAREST
	result_box.add_child(result_portrait)
	result_reward = _reward(result_box)
	result_title = _label(result_box, "ResultTitle", 36)
	var result_scroll := ScrollContainer.new()
	result_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	result_box.add_child(result_scroll)
	# UI-8 (owner's play notes, 2026-11-15: the end screen read as a wall of text):
	# sections under the title (a one-line outcome, stat tiles, each Division's
	# matches as chips, rewards, goals with bars, notes). `result_body` keeps the full
	# text for tools and tests, and shows only for a save older than the sections.
	result_sections = VBoxContainer.new()
	result_sections.name = "ResultSections"
	result_sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_sections.add_theme_constant_override("separation", 14)
	result_scroll.add_child(result_sections)
	result_body = _label(result_sections, "ResultBody", 22)
	result_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_view = VBoxContainer.new()
	result_view.name = "ResultView"
	result_view.add_theme_constant_override("separation", 14)
	result_sections.add_child(result_view)
	endless_button = _button(result_box, "ContinueEndless", "Continue Endless", func(): endless_pressed.emit())
	endless_button.hide()
	retry_button = _button(result_box, "RetryDivision", "Retry Division", func(): retry_pressed.emit())
	menu_button = _button(result_box, "ResultClubhouse", "Clubhouse", func(): menu_pressed.emit())

## UI-2: panels use the House frame kit (the color argument is kept for callers).
func _style(_color: Color) -> StyleBox:
	return UiTheme.frame("panel", 14.0, 12.0)

func _label(parent: Control, node_name: String, font_size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _button(parent: Control, node_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(360, 72)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(action, CONNECT_DEFERRED)
	parent.add_child(button)
	return button

func _sheet(node_name: String) -> PanelContainer:
	var sheet := PanelContainer.new()
	sheet.name = node_name
	sheet.add_theme_stylebox_override("panel", UiTheme.frame("menu", 18.0, 16.0))
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.hide()
	add_child(sheet)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	sheet.add_child(box)
	return sheet

## UI-9 (owner's play notes, 2026-11-15): the introduction reads as parts, not a
## paragraph. Who: a kicker (Boss or Championship, the Division), the rival's name,
## the portrait and their line in a speech bubble. What: one card per rule (its
## seal, its name, what it does), the match's figures (target, frames, lane), the
## first-clear reward, and the rival's story behind "Scouting report". Portrait
## stacks the two; landscape sets them side by side. The full text stays in
## intro_body, hidden, for tools and tests.
var intro_columns: BoxContainer
var intro_kicker: Label
var intro_quote: PanelContainer
var intro_quote_text: Label
var intro_rules: VBoxContainer
var intro_facts: HBoxContainer
var intro_reward_text: Label
var intro_story_button: Button
var intro_story: Label
var intro_scroll: ScrollContainer

func _build_intro() -> void:
	intro = _sheet("RivalIntro")
	var intro_box: VBoxContainer = intro.get_child(0)
	intro_box.add_theme_constant_override("separation", 12)
	intro_scroll = ScrollContainer.new()
	intro_scroll.name = "IntroScroll"
	intro_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	intro_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	intro_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	intro_box.add_child(intro_scroll)
	var centre := VBoxContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	intro_scroll.add_child(centre)
	intro_columns = BoxContainer.new()
	intro_columns.name = "IntroColumns"
	intro_columns.vertical = true
	intro_columns.alignment = BoxContainer.ALIGNMENT_CENTER
	intro_columns.add_theme_constant_override("separation", 14)
	centre.add_child(intro_columns)
	var who := VBoxContainer.new()
	who.name = "IntroWho"
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	who.add_theme_constant_override("separation", 6)
	intro_columns.add_child(who)
	intro_kicker = _label(who, "IntroKicker", 16)
	intro_kicker.add_theme_color_override("font_color", UiTheme.BRASS)
	intro_title = _label(who, "IntroTitle", 34)
	intro_portrait = Portrait.new()
	intro_portrait.custom_minimum_size = Vector2(160, 160)
	intro_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	intro_portrait.texture_filter = TEXTURE_FILTER_NEAREST
	who.add_child(intro_portrait)
	intro_quote = PanelContainer.new()
	intro_quote.name = "IntroQuote"
	intro_quote.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bubble := StyleBoxFlat.new()
	bubble.bg_color = Color("f1e6cc")
	bubble.set_corner_radius_all(14)
	bubble.content_margin_left = 16
	bubble.content_margin_right = 16
	bubble.content_margin_top = 8
	bubble.content_margin_bottom = 8
	intro_quote.add_theme_stylebox_override("panel", bubble)
	who.add_child(intro_quote)
	intro_quote_text = _label(intro_quote, "IntroQuoteText", 19)
	intro_quote_text.add_theme_color_override("font_color", Color("2a2016"))
	var what := VBoxContainer.new()
	what.name = "IntroWhat"
	what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	what.alignment = BoxContainer.ALIGNMENT_CENTER
	what.add_theme_constant_override("separation", 10)
	intro_columns.add_child(what)
	intro_rules = VBoxContainer.new()
	intro_rules.name = "IntroRules"
	intro_rules.add_theme_constant_override("separation", 8)
	what.add_child(intro_rules)
	intro_facts = HBoxContainer.new()
	intro_facts.name = "IntroFacts"
	intro_facts.add_theme_constant_override("separation", 8)
	what.add_child(intro_facts)
	var reward_row := HBoxContainer.new()
	reward_row.name = "IntroRewardRow"
	reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_row.add_theme_constant_override("separation", 10)
	what.add_child(reward_row)
	intro_reward = _reward(reward_row)
	intro_reward_text = _label(reward_row, "IntroReward", 17)
	intro_reward_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro_reward_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	intro_reward_text.add_theme_color_override("font_color", Color("cfe3d6"))
	intro_story_button = Button.new()
	intro_story_button.name = "IntroStoryToggle"
	intro_story_button.flat = true
	intro_story_button.text = "Scouting report +"
	intro_story_button.add_theme_font_size_override("font_size", 18)
	intro_story_button.add_theme_color_override("font_color", UiTheme.BRASS)
	intro_story_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	intro_story_button.pressed.connect(func(): _toggle_story())
	what.add_child(intro_story_button)
	intro_story = _label(what, "IntroStory", 18)
	intro_story.add_theme_color_override("font_color", Color("c9d3cf"))
	intro_story.hide()
	intro_body = _label(intro_box, "IntroBody", 22)
	intro_body.hide() # UI-9: the full text, for tools and tests
	intro_button = _button(intro_box, "IntroBegin", "Begin", func(): _finish_intro())

func _toggle_story() -> void:
	intro_story.visible = not intro_story.visible
	intro_story_button.text = "Scouting report −" if intro_story.visible else "Scouting report +"

## One rule as a card: its seal, its name and what it does.
func _rule_card(rule: String) -> Control:
	var card := PanelContainer.new()
	card.name = "Rule_" + rule.trim_prefix("boss_rule.")
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0d181d")
	style.border_color = UiTheme.BRASS
	style.border_width_left = 4
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var seal := TextureRect.new()
	seal.name = "Seal"
	seal.texture = RivalArt.rule_badge(rule)
	seal.custom_minimum_size = Vector2(44, 44)
	seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	seal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	seal.visible = seal.texture != null
	row.add_child(seal)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 2)
	row.add_child(text)
	var summary := RivalRules.summary(rule)
	var parts := summary.split(" — ", true, 1)
	var title := _label(text, "RuleName", 21)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.text = parts[0]
	title.add_theme_color_override("font_color", UiTheme.BRASS)
	var effect := _label(text, "RuleEffect", 18)
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	effect.text = parts[1].capitalize().substr(0, 1) + parts[1].substr(1) if parts.size() > 1 else ""
	effect.visible = parts.size() > 1
	return card

## A figure of the match: its value over a small caption.
func _fact(value: String, caption: String) -> Control:
	var chip := PanelContainer.new()
	chip.name = "Fact_" + caption.replace(" ", "")
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("13232a")
	style.border_color = Color("3a5158")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	chip.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	chip.add_child(box)
	var number := _label(box, "Value", 22)
	number.text = value
	number.add_theme_color_override("font_color", Color("f0d99b"))
	number.autowrap_mode = TextServer.AUTOWRAP_OFF
	number.clip_text = true
	var what := _label(box, "Caption", 13)
	what.text = caption.to_upper()
	what.add_theme_color_override("font_color", Color("9aa8a6"))
	return chip

## Places the bar under the session controls; the bubble sits below the status.
func layout(top: float, bubble_top: float) -> void:
	bar.offset_top = top
	bar.offset_bottom = top
	rule_panel.offset_top = top + 64.0
	rule_panel.offset_bottom = top + 64.0
	reaction.position = Vector2(16.0, bubble_top)
	for sheet in [intro, result]:
		sheet.offset_top = top
		sheet.offset_left = 12.0
		sheet.offset_right = -12.0
		sheet.offset_bottom = -12.0

## UI-2: the top bar at `bar_rect` (two rows in portrait) and the reaction bubble
## over the rival's panel at `bubble`.
## `sheet_top` (UI-5): the introduction and result sheets start below the session
## menu button, which stays in reach over them.
func layout_regions(bar_rect: Rect2, bubble: Rect2, portrait: bool, slim: bool = false, sheet_top: float = -1.0, menu_width: float = 0.0) -> void:
	side_box.vertical = false
	# Portrait: title and money on top, score, frames and the rule badge below.
	# Landscape: one row.
	var badges: Control = badge.get_parent()
	var money_slot: Control = money.get_parent()
	for node in [score_label, frames_label, badges, money_slot]:
		node.get_parent().remove_child(node)
	if menu_room.get_parent() != null:
		menu_room.get_parent().remove_child(menu_room)
	if portrait:
		_top_row.add_child(money_slot)
		for node in [score_label, frames_label, badges]: _bottom_row.add_child(node)
	else:
		for node in [score_label, frames_label, badges, money_slot]: _top_row.add_child(node)
	_top_row.add_child(menu_room)
	menu_room.custom_minimum_size = Vector2(menu_width, 0)
	_bottom_row.visible = portrait
	badge.custom_minimum_size = Vector2(0, 40)
	# The roll view's slim bar: the match and its score only.
	badges.visible = not slim
	money_slot.visible = not slim
	frames_label.visible = not slim
	_bar_width = bar_rect.size.x
	_bar_portrait = portrait
	_set_badge()
	_bar_slim = slim
	_fit_bar()
	# A phone's slim bar has no room for the Division or the rival; a wide one has.
	_slim = slim and bar_rect.size.x < 400.0
	title_label.text = _titles[1 if _slim else 0]
	title_label.custom_minimum_size.x = 0
	# Placed after the rows are rearranged, so the bar shrinks to the new content.
	bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bar.custom_minimum_size = bar_rect.size
	bar.position = bar_rect.position
	bar.size = Vector2.ZERO
	bar.size = bar_rect.size
	_fit_bar() # again with the title in place
	bar.size = Vector2.ZERO
	bar.size = bar_rect.size
	rule_panel.offset_top = bar_rect.end.y + 8.0
	rule_panel.offset_bottom = bar_rect.end.y + 8.0
	reaction.position = bubble.position
	reaction.custom_minimum_size = Vector2(bubble.size.x, 0)
	reaction.size = Vector2(bubble.size.x, 0)
	# Portrait: the bubble covers the info row and no more (it used to run over the
	# top of the hand under it), so its portrait and text are sized to that row.
	reaction_portrait.custom_minimum_size = Vector2(56, 56) if not portrait else Vector2(40, 40)
	if portrait != _reaction_portrait:
		_reaction_portrait = portrait
		reaction.add_theme_stylebox_override("panel", UiTheme.frame("panel", 14.0, 8.0 if portrait else 10.0))
	reaction_text.custom_minimum_size.x = maxf(bubble.size.x - 28.0 - reaction_portrait.custom_minimum_size.x - 10.0, 80.0)
	reaction_text.add_theme_font_size_override("font_size", 18 if portrait else 17)
	for sheet in [intro, result]:
		sheet.offset_top = sheet_top if sheet_top >= 0.0 else bar_rect.position.y
		sheet.offset_left = 12.0
		sheet.offset_right = -12.0
		sheet.offset_bottom = -12.0
	if result.visible and not is_equal_approx(result.size.x, _result_width):
		_result_width = result.size.x
		_fit_result()

## The bar never grows past its region (it would run under the session menu
## button): a long score, frame count and two-rule badge step down in size until
## the row fits, and as a last resort the frame count is cut short.
const BAR_STEPS := [[28, 18, 18], [28, 16, 16], [26, 15, 16], [24, 15, 15], [22, 14, 15], [20, 14, 14]] # score, frames, badge
var result_sections: VBoxContainer
var result_view: VBoxContainer
var menu_room: Control
var _bar_width := 0.0
var _bar_slim := false

var _reaction_portrait := false
var _badge_raw := ""
var _bar_portrait := true
## Portrait stacks a champion's two rules; landscape has room for one line.
func _set_badge() -> void:
	badge.text = _badge_raw.replace(" + ", " +\n") if _bar_portrait else _badge_raw

## Lines the rule badge takes on a portrait bar: two for a champion's two rules.
func badge_lines() -> int:
	return _badge_raw.count(" + ") + 1

## How much taller than its usual two rows portrait's bar must be for the badge as
## it really measures: a stacked two-rule badge, or one whose ⓘ falls back to a
## taller system font on another machine. The lab reserves this much more.
const BAR_USUAL := 106.0 # frame, the money row, the gap and a 40 px badge row
func bar_extra() -> float:
	if _badge_raw.is_empty():
		return 0.0
	var rows: float = bar.get_theme_stylebox("panel").get_minimum_size().y + money.get_parent().custom_minimum_size.y + 2.0
	return maxf(0.0, ceilf(rows + badge.get_parent().get_combined_minimum_size().y - BAR_USUAL))

func _fit_bar() -> void:
	if _bar_width <= 0.0:
		return
	var row: Control = score_label.get_parent()
	var room: float = _bar_width - bar.get_theme_stylebox("panel").get_minimum_size().x
	frames_label.clip_text = false
	frames_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	for step in BAR_STEPS.slice(4 if _bar_slim else 0):
		score_label.add_theme_font_size_override("font_size", step[0])
		frames_label.add_theme_font_size_override("font_size", step[1])
		# A stacked two-rule badge is 16 at most, so the bar's extra height is fixed.
		badge.add_theme_font_size_override("font_size", mini(step[2], 16) if badge.text.contains("\n") else step[2])
		# Measured here: a Label's own minimum size lags a font change by a frame.
		var need := 0.0
		for child in row.get_children():
			if not child.visible: continue
			if need > 0.0: need += row.get_theme_constant("separation")
			if child is Label and not child.clip_text:
				need += child.get_theme_font("font").get_string_size(child.text, HORIZONTAL_ALIGNMENT_LEFT, -1, child.get_theme_font_size("font_size")).x
			else:
				need += child.get_combined_minimum_size().x
		if need <= room:
			return
	frames_label.clip_text = true
	frames_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func _bar_label(parent: Control, node_name: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

## The money slot (UI-A1-C keeps $ in its own place on the bar).
func show_money(amount: int) -> void:
	money.text = "$%d" % amount

## view: {text, badge ("" hides it), rule_text}
func show_match(view: Dictionary) -> void:
	info.text = view.text
	_titles = [view.get("title", view.text), view.get("short_title", view.get("title", view.text))]
	title_label.text = _titles[1 if _slim else 0]
	score_label.text = view.get("score", "")
	frames_label.text = view.get("frames", "")
	_badge_raw = view.badge
	_set_badge()
	badge.visible = not view.badge.is_empty()
	_fit_bar()
	rule_text.text = view.rule_text
	if badge.visible == false:
		rule_panel.hide()

func show_reaction(rival: Dictionary, key: String) -> void:
	if key.is_empty():
		reaction.hide()
		return
	_portrait(reaction_portrait, rival, key)
	reaction_text.text = "%s: “%s”" % [rival.name, rival.reactions.get(key, "")]
	reaction.show()

func hide_reaction() -> void:
	reaction.hide()

func _portrait(portrait: Portrait, rival: Dictionary, mood: String) -> void:
	current_rival = rival
	portrait.texture = RivalArt.portrait(rival.get("id", ""), mood)
	portrait.color = Color.from_string(rival.get("color", "#9fd8ff"), Color(0.6, 0.8, 1.0))
	portrait.initials = rival.get("initials", "")
	portrait.mood = mood
	portrait.still = reduced_motion
	portrait.age = 0
	portrait.queue_redraw()

## The rival's entrance. It stays until the player presses its button (UI-8, owner's
## play notes, 2026-11-15: it used to advance on its own after a few seconds); a rival
## already met gets the short version. Reduced motion: no fade.
## `match_info` (UI-9): {rules (ids), frames, lane (its name, "" for House Oil), kicker}.
func show_intro(rival: Dictionary, target: int, rule_summary: String, reward: String, seen_before: bool, match_info: Dictionary = {}) -> void:
	_portrait(intro_portrait, rival, "entrance")
	intro_reward.texture = ItemArt.slot(RivalArt.entry(rival.get("id", "")).get("reward", ""), "icon")
	intro_reward.visible = intro_reward.texture != null
	intro_button.icon = RivalArt.rule_badge(rival.get("rule", ""))
	intro_button.expand_icon = true
	intro_button.add_theme_constant_override("icon_max_width",32)
	intro_title.text = String(rival.name)
	var frames := int(match_info.get("frames", 2))
	var frames_words := {1: "one frame", 2: "two frames", 3: "three frames"}
	var body := "Posted target %d in %s.\n%s\nFirst clear: %s" % [target, frames_words.get(frames, "%d frames" % frames), rule_summary, reward]
	if not seen_before:
		body = rival.intro + "\n\n" + body + "\n\n“%s”" % rival.reactions.get("entrance", "")
	intro_body.text = body
	intro_kicker.text = String(match_info.get("kicker", "Boss match")).to_upper()
	intro_quote_text.text = "“%s”" % rival.reactions.get("entrance", "")
	intro_quote.visible = not String(rival.reactions.get("entrance", "")).is_empty()
	for child in intro_rules.get_children():
		intro_rules.remove_child(child)
		child.queue_free()
	var rules: Array = match_info.get("rules", [rival.get("rule", "")] + rival.get("extra_rules", []))
	for rule in rules:
		if not String(rule).is_empty(): intro_rules.add_child(_rule_card(rule))
	for child in intro_facts.get_children():
		intro_facts.remove_child(child)
		child.queue_free()
	intro_facts.add_child(_fact(str(target), "Target"))
	intro_facts.add_child(_fact(str(frames), "Frames"))
	if not String(match_info.get("lane", "")).is_empty():
		intro_facts.add_child(_fact(String(match_info.lane), "Lane"))
	intro_reward_text.text = "First clear: " + reward
	intro_story.text = String(rival.get("intro", ""))
	intro_story.visible = false
	intro_story_button.text = "Scouting report +"
	intro_story_button.visible = not intro_story.text.is_empty()
	intro_scroll.scroll_vertical = 0
	intro.show()
	intro.modulate.a = 1.0
	if not reduced_motion:
		intro.modulate.a = 0.0
		create_tween().tween_property(intro, "modulate:a", 1.0, 0.3)
	intro_button.grab_focus()

func _process(delta: float) -> void:
	var compact := size.x > size.y
	# UI-9: landscape sets who and what side by side; portrait stacks them.
	intro_columns.vertical = not compact
	intro_portrait.custom_minimum_size = Vector2(120,120) if compact else Vector2(160,160)
	intro_button.custom_minimum_size.y = 52 if compact else 72
	intro.get_child(0).add_theme_constant_override("separation", 6 if compact else 12)
	intro_title.add_theme_font_size_override("font_size", 28 if compact else 34)
	intro_quote_text.custom_minimum_size.x = minf(maxf(intro.size.x * (0.4 if compact else 0.8) - 40.0, 160.0), 460.0)
	result_portrait.custom_minimum_size = Vector2(48,48) if compact else Vector2(96,96)
	result.get_child(0).add_theme_constant_override("separation",4 if compact else 12)
	for portrait in [intro_portrait, reaction_portrait, result_portrait]: portrait.still = reduced_motion

func _finish_intro() -> void:
	if not intro.visible:
		return
	intro.hide()
	intro_done.emit()

func show_result(title: String, body: String, won: bool, retry_label: String = "Retry Division", sections: Dictionary = {}) -> void:
	_portrait(result_portrait, current_rival, "defeated" if won else "victorious")
	result_portrait.visible = result_portrait.texture != null
	result_reward.texture = ItemArt.slot(RivalArt.entry(current_rival.get("id", "")).get("reward", ""), "icon")
	result_reward.visible = won and result_reward.texture != null
	result_title.text = title
	result_body.text = body
	result_body.visible = sections.is_empty()
	result_title.visible = sections.is_empty() # the sections carry a shorter headline
	_build_sections(sections, won)
	_fit_result()
	retry_button.text = "New Attempt" if won else retry_label
	endless_button.hide()
	result.show()
	retry_button.grab_focus()

## The result reads as one centred block: the body takes the height its text needs
## (scrolling only when the sheet cannot hold it), not all the height there is.
func _fit_result() -> void:
	var scroll: ScrollContainer = result_sections.get_parent()
	var box: VBoxContainer = scroll.get_parent()
	scroll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in 2:
		await get_tree().process_frame
		if not is_inside_tree() or not result.visible: return
		var others := 0.0
		for child in box.get_children():
			if child != scroll and (child as Control).visible:
				others += (child as Control).get_combined_minimum_size().y + box.get_theme_constant("separation")
		var room := maxf(result.size.y - 32.0 - others, 80.0)
		scroll.custom_minimum_size.y = minf(result_sections.get_combined_minimum_size().y, room)

const WON := Color("95d9cb")
const LOST := Color("e08a7a")
const NOTE := Color("9aa8a6")

## sections: {subtitle, stats: [[value, caption]], matches: [{division, kind, score,
## target, won}], highlights: [text], goals: [{name, progress, threshold}], notes: [text]}.
func _build_sections(sections: Dictionary, won: bool) -> void:
	for child in result_view.get_children():
		result_view.remove_child(child)
		child.queue_free()
	result_view.visible = not sections.is_empty()
	if sections.is_empty(): return
	var headline := _label(result_view, "ResultHeadline", 34)
	headline.text = String(sections.get("headline", ""))
	var subtitle := _label(result_view, "ResultSubtitle", 22)
	subtitle.text = String(sections.get("subtitle", ""))
	subtitle.add_theme_color_override("font_color", WON if won else LOST)
	var tiles := HBoxContainer.new()
	tiles.name = "ResultStats"
	tiles.add_theme_constant_override("separation", 8)
	result_view.add_child(tiles)
	for stat in sections.get("stats", []):
		tiles.add_child(_tile(String(stat[0]), String(stat[1])))
	var highlights: Array = sections.get("highlights", [])
	if not highlights.is_empty():
		_section_heading("Rewards" if won else "Kept")
		for text in highlights:
			var line := _label(result_view, "ResultHighlight", 19)
			line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			line.text = "◆  " + String(text)
			line.add_theme_color_override("font_color", UiTheme.BRASS)
	var goals: Array = sections.get("goals", [])
	if not goals.is_empty():
		_section_heading("Goals")
		for goal in goals:
			result_view.add_child(_goal_row(goal))
	var matches: Array = sections.get("matches", [])
	if not matches.is_empty():
		_section_heading("Matches")
		var grid := VBoxContainer.new()
		grid.name = "ResultMatches"
		grid.add_theme_constant_override("separation", 6)
		result_view.add_child(grid)
		# One header row names the match kinds; each Division's chips follow it.
		var kinds: Array = []
		for m in matches:
			if String(m.get("kind", "")) not in kinds: kinds.append(String(m.get("kind", "")))
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 6)
		grid.add_child(head)
		var corner := Control.new()
		corner.custom_minimum_size.x = 44
		head.add_child(corner)
		for kind in kinds:
			var label := Label.new()
			label.text = kind.capitalize()
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 16)
			label.add_theme_color_override("font_color", NOTE)
			head.add_child(label)
		var rows := {}
		for m in matches:
			var key := int(m.get("division", 1))
			if not rows.has(key):
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 6)
				grid.add_child(row)
				var label := Label.new()
				label.text = "D%d" % key
				label.custom_minimum_size.x = 44
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				label.add_theme_font_size_override("font_size", 18)
				label.add_theme_color_override("font_color", NOTE)
				row.add_child(label)
				rows[key] = row
			rows[key].add_child(_match_chip(m))
	for text in sections.get("notes", []):
		var note := _label(result_view, "ResultNote", 16)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		note.text = String(text)
		note.add_theme_color_override("font_color", NOTE)

func _section_heading(text: String) -> void:
	var heading := _label(result_view, "ResultHeading", 20)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	heading.text = text.to_upper()
	heading.add_theme_color_override("font_color", UiTheme.SEA_GLASS)

static func _flat(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	return style

func _tile(value: String, caption: String) -> Control:
	var tile := PanelContainer.new()
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_stylebox_override("panel", _flat(Color("16242b"), Color("2f474f")))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	tile.add_child(box)
	var number := Label.new()
	number.text = value
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.add_theme_font_size_override("font_size", 26)
	number.add_theme_color_override("font_color", UiTheme.IVORY)
	box.add_child(number)
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", NOTE)
	box.add_child(label)
	return tile

func _match_chip(m: Dictionary) -> Control:
	var won: bool = bool(m.get("won", false))
	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.add_theme_stylebox_override("panel", _flat(Color("1b3330") if won else Color("3a2224"), WON if won else LOST))
	var label := Label.new()
	label.text = "%s  %d / %d" % ["✓" if won else "✗", int(m.get("score", 0)), int(m.get("target", 0))]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", UiTheme.IVORY)
	chip.add_child(label)
	return chip

func _goal_row(goal: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name_label := Label.new()
	name_label.text = String(goal.get("name", ""))
	name_label.custom_minimum_size.x = 170
	name_label.add_theme_font_size_override("font_size", 18)
	row.add_child(name_label)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = maxi(int(goal.get("threshold", 1)), 1)
	bar.value = mini(int(goal.get("progress", 0)), int(bar.max_value))
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size.y = 14
	bar.add_theme_stylebox_override("background", _flat(Color("0d161b"), Color("2f474f")))
	var fill := _flat(UiTheme.BRASS, UiTheme.BRASS)
	fill.set_content_margin_all(0)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	var count := Label.new()
	count.text = "%d/%d" % [mini(int(goal.get("progress", 0)), int(goal.get("threshold", 1))), int(goal.get("threshold", 1))]
	count.add_theme_font_size_override("font_size", 18)
	row.add_child(count)
	return row

func hide_result() -> void:
	result.hide()

## Controls that take touches (the lab ignores throws over them).
func blocking_controls() -> Array:
	return [bar, rule_panel, intro, result]

func _reward(parent: Node) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "RewardIdentity"
	icon.custom_minimum_size = Vector2(40,40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = TEXTURE_FILTER_NEAREST
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon

## Adjacent, stable rule seals; inspectable text remains on the existing button.
func show_extra_rule_badges(rules: Array) -> void:
	extra_rule_badges.visible = badge.visible and rules.any(func(r): return RivalArt.rule_badge(r) != null)
	if extra_rule_badges.get_meta("rules", []) == rules: return
	extra_rule_badges.set_meta("rules", rules.duplicate())
	for child in extra_rule_badges.get_children():
		extra_rule_badges.remove_child(child)
		child.queue_free()
	for rule in rules:
		if RivalArt.rule_badge(rule) == null: continue # no seal art yet: no empty slot on the bar
		var seal := TextureRect.new()
		seal.texture = RivalArt.rule_badge(rule)
		seal.custom_minimum_size = Vector2(32, 32)
		seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		seal.texture_filter = TEXTURE_FILTER_NEAREST
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seal.set_meta("rule", rule)
		extra_rule_badges.add_child(seal)
