extends Node
## E26-W01: browser QA status for the web journey (tests/web/web_journey.mjs).
## Present only in a Web build opened with `?qa=1`; players never get it. Once a
## second, and whenever the screen or lab state changes, it prints one console
## line `ROGUEWOOD_WEB {json}` that the browser test reads: where the ball and
## buttons are in window pixels, the lab's state and history, whether a saved
## attempt exists, and the frame rate. It only reads; it never drives the game.
const PREFIX := "ROGUEWOOD_WEB "

var shell: Node
var _last := ""
var _clock := 0.0

static func requested() -> bool:
	if not OS.has_feature("web"):
		return false
	var search = JavaScriptBridge.eval("window.location.search", true)
	return typeof(search) == TYPE_STRING and "qa=1" in search

func _process(delta: float) -> void:
	_clock += delta
	var status := snapshot()
	var key := "%s|%s|%d" % [status.screen, status.get("state", ""), int(status.get("history", 0))]
	if key != _last or _clock >= 1.0:
		_last = key
		_clock = 0.0
		print(PREFIX + JSON.stringify(status))

## Logs pointer input as the game receives it, so a failed browser gesture can be
## diagnosed (event type, window position, engine time).
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		var kind := "drag" if event is InputEventScreenDrag else ("down" if event.pressed else "up")
		print("ROGUEWOOD_WEB_INPUT %s %.1f,%.1f t=%d" % [kind, event.position.x, event.position.y, Time.get_ticks_usec()])

func snapshot() -> Dictionary:
	var view := get_viewport()
	var to_window := view.get_final_transform()
	var out := {"screen": shell.screen, "fps": Engine.get_frames_per_second(), "window": [view.get_visible_rect().size.x, view.get_visible_rect().size.y],
		"saved": bool(shell._saved_attempt().ok)}
	for pair in [["enter", shell.enter], ["continue", shell.continue_button]]:
		var button: Button = pair[1]
		out[pair[0]] = {"visible": button.is_visible_in_tree(), "at": _point(to_window * button.get_global_rect().get_center())}
	var lab = shell.lab
	if lab != null and is_instance_valid(lab) and lab.lane != null:
		out.state = lab.state
		out.history = lab.history.size()
		out.cancels = int(lab.cancels)
		out.last_cancel = str(lab.last_cancel)
		out.score = int(lab.total_score)
		out.match = int(lab.match_number)
		out.ball = _point(to_window * lab.ball_screen_position())
		out.ball_radius = lab.ball_touch_radius() * to_window.get_scale().x
	return out

static func _point(p: Vector2) -> Array:
	return [snappedf(p.x, 0.1), snappedf(p.y, 0.1)]
