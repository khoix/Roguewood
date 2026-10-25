extends Control
## Functional E03 shell; visual treatment remains E11/E12 work.
var session: Dictionary = {}
var screen := "menu"
var heading: Label
var details: Label
var enter: Button
var reset: Button
var back: Button

func _ready() -> void:
	var panel := VBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-230, -190)
	panel.custom_minimum_size = Vector2(460, 380)
	panel.add_theme_constant_override("separation", 24)
	add_child(panel)
	heading = Label.new()
	heading.text = "Roguewood"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 48)
	panel.add_child(heading)
	details = Label.new()
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.text = "The lanes are waiting."
	panel.add_child(details)
	enter = _button(panel, "Enter League", "EnterLeague")
	reset = _button(panel, "Restart Session", "ResetSession")
	back = _button(panel, "Clubhouse", "BackToMenu")
	enter.pressed.connect(_start_session)
	reset.pressed.connect(_start_session)
	back.pressed.connect(_show_menu)
	_show_menu()
	if "--bootstrap-smoke" in OS.get_cmdline_user_args():
		print("ROGUEWOOD_BOOT_OK")
		get_tree().quit(0)

func _button(parent: Node, label: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(460, 64)
	parent.add_child(button)
	return button

func _start_session() -> void:
	# Fixed shell fixture, not procedural League progression or a Career save.
	session = {"schema_version": 1, "seed": 1, "league_id": "league.house", "division": 1, "match": 1, "frame": 1, "score": 0}
	screen = "session"
	details.text = "House League · Division 1\nBowling is coming soon."
	enter.hide()
	reset.show()
	back.show()
	reset.grab_focus()

func _show_menu() -> void:
	screen = "menu"
	session = {}
	details.text = "The lanes are waiting."
	enter.show()
	reset.hide()
	back.hide()
	enter.grab_focus()
