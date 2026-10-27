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
var options: Button
var lab: ThrowLab
## Throw settings shared by every session this run (persistence is E25).
var throw_settings: Dictionary = {}
## Career record for this run of the app: first clears, unlocked gates and rivals
## met. In memory only; E10/E15 make it durable. Restart and retry keep it.
var career: Dictionary = {}

func _ready() -> void:
	get_window().size_changed.connect(_viewport_layout)
	_viewport_layout()
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
	reset = _button(session_bar, "Restart Session", "ResetSession", 220)
	back = _button(session_bar, "Clubhouse", "BackToMenu", 220)
	options = _button(session_bar, "Options", "ThrowOptions", 220)
	options.pressed.connect(func(): if lab: lab.toggle_settings())
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
	_begin_attempt(1)

## Attempt n of the fixed House League Division (seed n). Restart Session begins
## attempt 1 again; Retry and New Attempt begin the next one.
func _begin_attempt(attempt: int) -> void:
	# Fixed shell fixture, not procedural League progression or a Career save.
	session = {"schema_version": 1, "seed": attempt, "attempt": attempt, "league_id": "league.house", "kit_id": "kit.house", "division": 1, "match": 1, "frame": 1, "score": 0, "money": 6}
	screen = "session"
	details.text = "House League · Division 1"
	panel.hide()
	_clear_lab()
	# Throw lab (E04–E09); the lane draws beneath the session controls.
	lab = ThrowLab.new()
	lab.name = "ThrowLab"
	lab.settings = throw_settings
	lab.equipment_seed = session.seed
	lab.career = career
	lab.attempt = attempt
	lab.attempt_finished.connect(func(outcome): session.outcome = outcome)
	lab.retry_requested.connect(func(): _begin_attempt(int(session.attempt) + 1), CONNECT_DEFERRED)
	lab.menu_requested.connect(_show_menu, CONNECT_DEFERRED)
	lab.frame_scored.connect(_on_frame_scored)
	lab.money_changed.connect(func(money): session.money = money)
	add_child(lab)
	move_child(lab, 0)
	session_bar.show()
	reset.grab_focus()

## The session fixture tracks the lab's banked total and current frame.
func _on_frame_scored(scored: Dictionary) -> void:
	session.score = int(session.score) + int(scored.get("banked", scored.result.score))
	session.frame = int(scored.frame_number) + 1
	session.match = int(scored.get("match_number", session.match))

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

## Preserve native reference typography in both orientations.
func _viewport_layout() -> void:
	var window := get_window()
	window.content_scale_size = Vector2i(1280,720) if window.size.x > window.size.y else Vector2i(720,1280)
