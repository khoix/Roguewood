extends Control
## Division presentation (E09): a match bar (match, target, score, frames left) with
## an inspectable rule/boss badge, a rival reaction bubble that never takes input,
## a skippable rival introduction, and the attempt result with Retry and Clubhouse.
## A view only: the lab and the pure DivisionRun own every rule and number.
## Developmental portrait (a drawn badge); final rival art and animation are E21.
signal intro_done
signal retry_pressed
signal menu_pressed

const INTRO_FIRST_SEC := 6.0
const INTRO_REPEAT_SEC := 2.0

var bar: PanelContainer
var info: Label
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
var retry_button: Button
var menu_button: Button
var reduced_motion := false
var intro_remaining := 0.0

## A developmental rival badge: a coloured disc, initials and a mood mouth.
class Portrait extends Control:
	var color := Color(0.6, 0.8, 1.0)
	var initials := ""
	var mood := "entrance"
	func _draw() -> void:
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
	bar.add_theme_stylebox_override("panel", _style(Color(0.04, 0.03, 0.08, 0.85)))
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 12.0
	bar.offset_right = -12.0
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)
	info = Label.new()
	info.name = "MatchInfo"
	info.add_theme_font_size_override("font_size", 22)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(info)
	badge = Button.new()
	badge.name = "RuleBadge"
	badge.custom_minimum_size = Vector2(200, 52)
	badge.pressed.connect(func(): rule_panel.visible = not rule_panel.visible)
	row.add_child(badge)
	rule_panel = PanelContainer.new()
	rule_panel.name = "RulePanel"
	rule_panel.add_theme_stylebox_override("panel", _style(Color(0.1, 0.08, 0.16, 0.97)))
	rule_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	rule_panel.offset_left = 24.0
	rule_panel.offset_right = -24.0
	rule_panel.hide()
	add_child(rule_panel)
	rule_text = _label(rule_panel, "RuleText", 22)
	# Reaction bubble: purely visual, so it can never take a touch or block a throw.
	reaction = PanelContainer.new()
	reaction.name = "Reaction"
	reaction.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reaction.add_theme_stylebox_override("panel", _style(Color(0.08, 0.06, 0.14, 0.88)))
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
	reaction_row.add_child(reaction_portrait)
	reaction_text = Label.new()
	reaction_text.name = "ReactionText"
	reaction_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reaction_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reaction_text.custom_minimum_size = Vector2(320, 0)
	reaction_text.add_theme_font_size_override("font_size", 20)
	reaction_row.add_child(reaction_text)
	intro = _sheet("RivalIntro")
	var intro_box: VBoxContainer = intro.get_child(0)
	intro_portrait = Portrait.new()
	intro_portrait.custom_minimum_size = Vector2(180, 180)
	intro_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	intro_box.add_child(intro_portrait)
	intro_title = _label(intro_box, "IntroTitle", 34)
	intro_body = _label(intro_box, "IntroBody", 22)
	intro_button = _button(intro_box, "IntroBegin", "Begin", func(): _finish_intro())
	result = _sheet("AttemptResult")
	var result_box: VBoxContainer = result.get_child(0)
	result_title = _label(result_box, "ResultTitle", 36)
	result_body = _label(result_box, "ResultBody", 22)
	retry_button = _button(result_box, "RetryDivision", "Retry Division", func(): retry_pressed.emit())
	menu_button = _button(result_box, "ResultClubhouse", "Clubhouse", func(): menu_pressed.emit())

func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	return style

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
	sheet.add_theme_stylebox_override("panel", _style(Color(0.05, 0.04, 0.1, 0.96)))
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.hide()
	add_child(sheet)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	sheet.add_child(box)
	return sheet

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

## view: {text, badge ("" hides it), rule_text}
func show_match(view: Dictionary) -> void:
	info.text = view.text
	badge.text = view.badge
	badge.visible = not view.badge.is_empty()
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
	portrait.color = Color.from_string(rival.get("color", "#9fd8ff"), Color(0.6, 0.8, 1.0))
	portrait.initials = rival.get("initials", "")
	portrait.mood = mood
	portrait.queue_redraw()

## The rival's entrance. Skippable at once; it advances on its own after a few
## seconds (shorter once the rival has been met). Reduced motion: no fade.
func show_intro(rival: Dictionary, target: int, rule_summary: String, reward: String, seen_before: bool) -> void:
	_portrait(intro_portrait, rival, "entrance")
	intro_title.text = "Boss: %s" % rival.name
	var body := "Posted target %d in two frames.\n%s\nFirst clear: %s" % [target, rule_summary, reward]
	if not seen_before:
		body = rival.intro + "\n\n" + body + "\n\n“%s”" % rival.reactions.get("entrance", "")
	intro_body.text = body
	intro_remaining = INTRO_REPEAT_SEC if seen_before else INTRO_FIRST_SEC
	intro.show()
	intro.modulate.a = 1.0
	if not reduced_motion:
		intro.modulate.a = 0.0
		create_tween().tween_property(intro, "modulate:a", 1.0, 0.3)
	intro_button.grab_focus()

func _process(delta: float) -> void:
	if intro.visible:
		intro_remaining -= delta
		if intro_remaining <= 0.0:
			_finish_intro()

func _finish_intro() -> void:
	if not intro.visible:
		return
	intro.hide()
	intro_done.emit()

func show_result(title: String, body: String, won: bool, retry_label: String = "Retry Division") -> void:
	result_title.text = title
	result_body.text = body
	retry_button.text = "New Attempt" if won else retry_label
	result.show()
	retry_button.grab_focus()

func hide_result() -> void:
	result.hide()

## Controls that take touches (the lab ignores throws over them).
func blocking_controls() -> Array:
	return [bar, rule_panel, intro, result]
