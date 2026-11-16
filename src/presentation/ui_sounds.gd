extends Node
## UI-12 (owner's play notes, 2026-11-16): every button in the game gives a short tap
## when pressed. One hook on the SceneTree reaches each button as it is added, so a new
## screen needs no wiring. Close, Done and Back buttons take the back sound; toggles and
## the Clubhouse tabs the select sound; everything else the tap. A button can opt out
## with the meta "ui_sound" set to "", or pick a sound by naming it there.
## The sounds are provisional (tools/author_foley.py, wood); the final set is Codex's.
const SOUNDS := {
	"tap": preload("res://assets/audio/ui_tap.wav"),
	"select": preload("res://assets/audio/ui_select.wav"),
	"back": preload("res://assets/audio/ui_back.wav"),
}
const BACK_WORDS := ["Close", "Done", "Back", "Resume", "Cancel"]
const MIN_GAP_FRAMES := 2 # one press that fires two buttons' signals sounds once
var settings: Dictionary = {}
var played := 0
var last_kind := ""
var _voices: Array[AudioStreamPlayer] = []
var _next := 0
var _last_frame := -100

func _ready() -> void:
	name = "UiSounds"
	for i in 2:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	get_tree().node_added.connect(_on_node_added)
	_hook_all(get_tree().root)

func _hook_all(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_hook_all(child)

func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.pressed.is_connected(_on_pressed):
		node.pressed.connect(_on_pressed.bind(node))

## The sound a button makes: its own choice, else by kind and wording.
static func kind_of(button: BaseButton) -> String:
	if button.has_meta("ui_sound"): return String(button.get_meta("ui_sound"))
	if button.toggle_mode or button is CheckButton or button is CheckBox: return "select"
	var text: String = button.text if button is Button else ""
	for word in BACK_WORDS:
		if text.begins_with(word) or String(button.name).begins_with(word): return "back"
	return "tap"

func _on_pressed(button: BaseButton) -> void:
	if not is_instance_valid(button): return
	play(kind_of(button))

func play(kind: String) -> void:
	if kind.is_empty() or not SOUNDS.has(kind): return
	var level := float(settings.get("sound_volume", 0.65))
	if bool(settings.get("sound_muted", false)) or level <= 0.0: return
	var frame := Engine.get_process_frames()
	if frame - _last_frame < MIN_GAP_FRAMES: return
	_last_frame = frame
	var voice := _voices[_next]
	_next = (_next + 1) % _voices.size()
	voice.stream = SOUNDS[kind]
	# As PresentationAudio's effects level; a tap sits a little under the foley.
	voice.volume_db = linear_to_db(maxf(0.0001, level * 0.35 * 0.8))
	voice.play()
	played += 1
	last_kind = kind

func _exit_tree() -> void:
	for voice in _voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
