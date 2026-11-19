extends PanelContainer
## UI-20 (owner, 2026-11-19): the alley screen. The aim magnifier's window over the
## top HUD doubles as the alley's overhead TV: on a strike, a spare or a boss win it
## plays a short celebration on a small CRT, in the League's own style.
## - Variants come from the League theme's manifest (`celebrations`): at least 5
##   strikes and 5 spares, and 2 per boss. One is picked by uniform random from
##   this screen's own generator, never from a run's seeded streams.
## - It plays only when the League lists a variant for the event (the owner: not
##   before Codex's art, UI-A9); tests can supply variants (variants_override).
## - A tap on it skips the celebration; celebrations queue, never overlap, and never
##   change the game. Hidden, it renders nothing.
## Scenes follow the contract in docs/handoffs/UI-20.md: play(context),
## signal finished, duration(), skip(), on a 252 x 90 canvas.
signal finished(event: String)

const AimMagnifier = preload("res://src/presentation/aim_magnifier.gd")
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
const PLACEHOLDER := "res://src/presentation/alley_screen_placeholder.gd"
const CANVAS := Vector2i(252, 90)
const EVENTS := ["strike", "spare", "boss_defeated"]
const POWER_SECONDS := 0.15 # the CRT's power-on and power-off

var lab: Control
var view: SubViewport
var screen: TextureRect
var crt: ShaderMaterial
var rng := RandomNumberGenerator.new()
## Tests only: {event: [paths]}, with boss_defeated as {rival_id or "*": [paths]}.
var variants_override: Dictionary = {}
var current: Node
var current_event := ""
var current_path := ""
var current_context: Dictionary = {}
var played: Array = [] # {event, path, rival_id}, for tests and the review tool
var _queue: Array = []
var _power: Tween

func _ready() -> void:
	name = "AlleyScreen"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	add_theme_stylebox_override("panel", UiTheme.frame("hud", 6.0, 6.0))
	view = SubViewport.new()
	view.name = "AlleyView"
	view.size = CANVAS
	view.transparent_bg = false
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(view)
	screen = TextureRect.new()
	screen.name = "AlleyCRT"
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_SCALE
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	crt = ShaderMaterial.new()
	crt.shader = preload("res://assets/ui/alley_screen/crt.gdshader")
	screen.material = crt
	screen.texture = view.get_texture()
	add_child(screen)
	rng.randomize()
	hide()

## The variants for an event (a boss's are its own two), as resource paths.
func variants(event: String, rival_id: String = "") -> Array:
	var list = []
	if variants_override.has(event):
		list = variants_override[event]
	elif lab != null and lab.league_theme != null and lab.league_theme.has_method("celebrations"):
		return lab.league_theme.celebrations(event, rival_id)
	if list is Dictionary:
		list = list.get(rival_id, list.get("*", []))
	return list if list is Array else []

func has_art(event: String, rival_id: String = "") -> bool:
	return not variants(event, rival_id).is_empty()

## Uniform: every variant is equally likely, repeats allowed.
func pick(list: Array) -> String:
	return String(list[rng.randi_range(0, list.size() - 1)])

func playing() -> bool:
	return current != null

## Queues the event's celebration; false (and nothing shown) when it has no variant.
func celebrate(event: String, context: Dictionary = {}) -> bool:
	var list := variants(event, String(context.get("rival_id", "")))
	if list.is_empty():
		return false
	_queue.append({"event": event, "path": pick(list), "context": context})
	if current == null:
		_next()
	return true

func _next() -> void:
	var item: Dictionary = _queue.pop_front()
	var resource = load(item.path)
	var node: Node = resource.instantiate() if resource is PackedScene else (resource.new() if resource is Script else null)
	if node == null:
		push_warning("Celebration not loadable: " + item.path)
		if not _queue.is_empty(): _next()
		return
	current = node
	current_event = item.event
	current_path = item.path
	var reduced_flash := bool(lab.settings.get("reduced_flash", false)) if lab != null else false
	var reduced_motion := bool(lab.settings.get("reduced_motion", false)) if lab != null else false
	current_context = {"event": item.event, "league_id": String(lab.content.get("league_id", "")) if lab != null else "",
		"division": lab.division.division_number() if lab != null and lab.division != null else 1,
		"championship": false, "rival_name": "", "rival_id": "", "rival_color": "",
		"reduced_motion": reduced_motion, "reduced_flash": reduced_flash}
	current_context.merge(item.context, true)
	view.add_child(node)
	node.finished.connect(_on_finished.bind(node), CONNECT_ONE_SHOT)
	crt.set_shader_parameter("flicker", 0.0 if reduced_flash else 1.0)
	if _power: _power.kill()
	if reduced_motion:
		crt.set_shader_parameter("power", 1.0)
	else:
		crt.set_shader_parameter("power", 0.0)
		_power = create_tween()
		_power.tween_method(func(v): crt.set_shader_parameter("power", v), 0.0, 1.0, POWER_SECONDS)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_place()
	show()
	_sting(item.event)
	played.append({"event": item.event, "path": item.path, "rival_id": String(current_context.rival_id)})
	node.play(current_context)

func _sting(event: String) -> void:
	if lab == null or lab.league_theme == null or not lab.league_theme.has_method("celebration_sound"): return
	var sound = lab.get("motion")
	var stream: AudioStream = lab.league_theme.celebration_sound(event, rng)
	if stream != null and sound != null and sound.get("sound") != null:
		sound.sound.cue("celebration." + event, stream, 3)

func _on_finished(node: Node) -> void:
	if node != current: return
	var event := current_event
	current = null
	current_event = ""
	node.queue_free()
	if not _queue.is_empty():
		_next()
		finished.emit(event)
		return
	hide()
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	finished.emit(event)

## A tap: ends the celebration on screen (the next queued one, if any, follows).
func skip() -> void:
	if current != null and current.has_method("skip"):
		current.skip()

## Clears the queue and ends what is playing (leaving the match for the shop or a result).
func stop_all() -> void:
	_queue.clear()
	skip()

func _process(_delta: float) -> void:
	if not visible or lab == null: return
	if lab.state in ["shop", "intro", "division_over"]:
		stop_all()
		return
	_place()

func _place() -> void:
	if lab == null or lab.hud == null: return
	var rect := AimMagnifier.panel_rect(lab, get_viewport_rect().size)
	position = rect.position
	size = rect.size

func _input(event: InputEvent) -> void:
	if not visible or current == null: return
	var tapped: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if tapped and get_global_rect().has_point(event.position):
		skip()
		get_viewport().set_input_as_handled()
