extends Control
## UI-20's placeholder celebration: plain pixel lettering on the alley screen's
## 252 x 90 canvas. It shows the scene contract Codex's UI-A9 scenes follow:
## play(context), signal finished, duration(), skip(). It plays only where a test
## asks for it: the real game shows celebrations only once a League's theme lists
## Codex's scenes (owner, 2026-11-19).
signal finished

const CANVAS := Vector2(252, 90)
const FONT = preload("res://assets/ui/fonts/PixelifySans.ttf")
const LENGTHS := {"strike": 1.8, "spare": 1.6, "boss_defeated": 3.0}

var context: Dictionary = {}
var title: Label
var _tween: Tween
var _done := false

func _ready() -> void:
	size = CANVAS
	var back := ColorRect.new()
	back.color = Color("101622")
	back.size = CANVAS
	add_child(back)
	title = Label.new()
	title.name = "Title"
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size = CANVAS
	title.pivot_offset = CANVAS * 0.5
	add_child(title)

func duration() -> float:
	return float(LENGTHS.get(String(context.get("event", "strike")), 1.8))

func play(with: Dictionary) -> void:
	context = with
	_done = false
	var event := String(context.get("event", "strike"))
	title.text = {"strike": "STRIKE!", "spare": "SPARE!"}.get(event, "%s\nDEFEATED!" % String(context.get("rival_name", "Rival")).to_upper())
	title.add_theme_font_size_override("font_size", 26 if event != "boss_defeated" else 18)
	title.add_theme_color_override("font_color", Color(String(context.get("rival_color", "f5cb69"))) if event == "boss_defeated" else Color("f5cb69"))
	if _tween: _tween.kill()
	_tween = create_tween()
	if bool(context.get("reduced_motion", false)):
		title.scale = Vector2.ONE
		_tween.tween_interval(duration())
	else:
		title.scale = Vector2(0.3, 0.3)
		_tween.tween_property(title, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_interval(maxf(0.0, duration() - 0.35))
	_tween.tween_callback(_finish)

func skip() -> void:
	if _tween: _tween.kill()
	title.scale = Vector2.ONE
	_finish()

func _finish() -> void:
	if _done: return
	_done = true
	finished.emit()
