extends PanelContainer
## E18-C06: the chooser an instant tactical card opens before the throw (which pin,
## which spot, or a confirmation). Nothing is spent until a choice is made; Cancel
## closes it with the card still in hand.
signal chosen(index: int)
signal cancelled

var prompt: Label
var choices: VBoxContainer
var cancel: Button

func _ready() -> void:
	name = "TacticSheet"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.16, 0.99)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(14)
	add_theme_stylebox_override("panel", style)
	top_level = true
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	prompt = Label.new()
	prompt.name = "TacticPrompt"
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(prompt)
	choices = VBoxContainer.new()
	choices.name = "TacticChoices"
	choices.add_theme_constant_override("separation", 6)
	column.add_child(choices)
	cancel = Button.new()
	cancel.name = "TacticCancel"
	cancel.text = "Cancel"
	cancel.custom_minimum_size = Vector2(200, 64)
	cancel.pressed.connect(func(): cancelled.emit())
	column.add_child(cancel)
	hide()

func open(text: String, labels: Array) -> void:
	prompt.text = text
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	for i in labels.size():
		var index := i
		var button := Button.new()
		button.name = "Tactic_%d" % i
		button.text = labels[i]
		button.custom_minimum_size = Vector2(0, 56)
		button.pressed.connect(func(): chosen.emit(index), CONNECT_DEFERRED)
		choices.add_child(button)
	show()
	var viewport_size := get_viewport_rect().size
	size = Vector2(minf(560.0, viewport_size.x - 32.0), minf(64.0 * (labels.size() + 2) + 60.0, viewport_size.y - 160.0))
	position = (viewport_size - size) * 0.5
	(choices.get_child(0) if labels.size() > 0 else cancel).grab_focus()

func button(index: int) -> Button:
	return choices.get_child(index) if index < choices.get_child_count() else null
