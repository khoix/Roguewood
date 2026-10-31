extends PanelContainer
## E18-C06: the chooser an instant tactical card opens before the throw (which pin,
## which spot, or a confirmation). Nothing is spent until a choice is made; Cancel
## closes it with the card still in hand.
signal chosen(index: int)
signal cancelled

var prompt: Label
var choices: VBoxContainer
var cancel: Button
var rack_diagram: Control
var rack_hint: Label

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
	rack_hint = Label.new()
	rack_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(rack_hint)
	rack_diagram = Control.new()
	rack_diagram.custom_minimum_size = Vector2(0, 216)
	column.add_child(rack_diagram)
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
	_show_rack(text, labels)
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
	size = Vector2(minf(560.0, viewport_size.x - 32.0), minf(64.0 * (labels.size() + 2) + 60.0 + (250.0 if rack_diagram.visible else 0.0), viewport_size.y - 160.0))
	position = (viewport_size - size) * 0.5
	(choices.get_child(0) if labels.size() > 0 else cancel).grab_focus()

func button(index: int) -> Button:
	return choices.get_child(index) if index < choices.get_child_count() else null

## Mirrors the existing choices; the original list and index contract stay intact.
func _show_rack(text: String, labels: Array) -> void:
	for child in rack_diagram.get_children():
		rack_diagram.remove_child(child)
		child.queue_free()
	rack_diagram.visible = text.begins_with("Nudge:")
	rack_hint.visible = rack_diagram.visible
	if not rack_diagram.visible: return
	var destinations := text.contains("empty spot")
	rack_hint.text = "Outlined gold spots are legal empty destinations." if destinations else "Gold pins can move. Tap one here or in the list."
	var positions := {}
	for index in labels.size():
		positions[String(labels[index]).get_slice(" ", 1).to_int()] = index
	var number := 1
	for row in 4:
		for column in row + 1:
			var spot := Button.new()
			spot.text = str(number)
			spot.position = Vector2(230 + (column - row * 0.5) * 58, 160 - row * 50)
			spot.size = Vector2(46, 46)
			spot.disabled = not positions.has(number)
			spot.set_meta("rack_position", number)
			if positions.has(number):
				var style := StyleBoxFlat.new()
				style.bg_color = Color("263d42") if destinations else Color("9c6b31")
				style.border_color = Color("f2d6a0")
				style.set_border_width_all(3)
				style.set_corner_radius_all(23)
				spot.add_theme_stylebox_override("normal", style)
				var choice: int = positions[number]
				spot.pressed.connect(func(): chosen.emit(choice), CONNECT_DEFERRED)
			rack_diagram.add_child(spot)
			number += 1
