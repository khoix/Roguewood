extends Control
## Functional shell; visual treatment remains E11/E12 work.
const ThrowLab = preload("res://src/presentation/throw_lab.gd")
var session: Dictionary = {}
var screen := "menu"
var heading: Label
var details: Label
var enter: Button
var reset: Button
var back: Button
var league: OptionButton
var kit: OptionButton
var panel: VBoxContainer
var session_bar: HBoxContainer
var lab: ThrowLab

func _ready() -> void:
	panel = VBoxContainer.new()
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
	league = OptionButton.new()
	league.name = "LeagueChoice"
	league.add_item("House League")
	panel.add_child(league)
	kit = OptionButton.new()
	kit.name = "KitChoice"
	kit.add_item("House Kit")
	panel.add_child(kit)
	enter = _button(panel, "Enter League", "EnterLeague", 460)
	session_bar = HBoxContainer.new()
	session_bar.name = "SessionBar"
	session_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	session_bar.offset_top = 16
	session_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	session_bar.add_theme_constant_override("separation", 16)
	add_child(session_bar)
	reset = _button(session_bar, "Restart Session", "ResetSession", 300)
	back = _button(session_bar, "Clubhouse", "BackToMenu", 300)
	enter.pressed.connect(_start_session)
	reset.pressed.connect(_start_session)
	back.pressed.connect(_show_menu)
	_show_menu()
	if "--bootstrap-smoke" in OS.get_cmdline_user_args():
		print("ROGUEWOOD_BOOT_OK")
		get_tree().quit(0)

func _button(parent: Node, label: String, node_name: String, width: float) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(width, 64)
	parent.add_child(button)
	return button

func _start_session() -> void:
	# Fixed shell fixture, not procedural League progression or a Career save.
	session = {"schema_version": 1, "seed": 1, "league_id": "league.house", "kit_id": "kit.house", "division": 1, "match": 1, "frame": 1, "score": 0}
	screen = "session"
	details.text = "House League · Division 1"
	panel.hide()
	_clear_lab()
	# E04 throw lab; the lane draws beneath the session controls.
	lab = ThrowLab.new()
	lab.name = "ThrowLab"
	add_child(lab)
	move_child(lab, 0)
	session_bar.show()
	reset.grab_focus()

func _show_menu() -> void:
	screen = "menu"
	session = {}
	details.text = "The lanes are waiting."
	_clear_lab()
	panel.show()
	session_bar.hide()
	enter.grab_focus()

func _clear_lab() -> void:
	if lab:
		remove_child(lab)
		lab.free()
		lab = null
