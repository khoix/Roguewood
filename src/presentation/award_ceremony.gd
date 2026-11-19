extends Control
## UI-22 (owner, 2026-11-19): the award ceremony when a run ends. Over the result
## sheet, it presents what the run earned (RunAwards): each new trophy with its own
## Clubhouse art, and every goal it moved, its bar filling from where it stood to
## where it stands, with a stamp and a burst when one completes. Fireworks, bottle
## rockets and confetti, each with its sound; its own music (Soundtrack "awards",
## the owner's Suno track once added). A tap hurries the current moment, Skip jumps
## to the summary, and Continue (or Escape at the end) reveals the result sheet.
## Presentation only: every award was banked before it starts.
## Art direction (Claude, as Codex is away): "Trophy Night". A velvet-dark stage, a
## slow gold sunburst behind each trophy, a spotlight, chunky gold lettering, and
## confetti in the club's colours (plus the League's own accents).
signal finished

const Soundtrack = preload("res://src/presentation/soundtrack.gd")
const Art = preload("res://src/clubhouse/clubhouse_art.gd")
const AwardFx = preload("res://src/presentation/award_fx.gd")
const GOLD := Color("f5cb69")
const IVORY := Color("f4ecd8")
const CORAL := Color("ff7a59")
const TEAL := Color("64dacb")
const SOUNDS := {
	"whoosh": "res://assets/audio/awards/award_whoosh.wav", "drumroll": "res://assets/audio/awards/award_drumroll.wav",
	"reveal": "res://assets/audio/awards/award_reveal.wav", "launch": "res://assets/audio/awards/firework_launch.wav",
	"burst": "res://assets/audio/awards/firework_burst.wav", "rocket": "res://assets/audio/awards/bottle_rocket.wav",
	"confetti": "res://assets/audio/awards/confetti_pop.wav", "tick": "res://assets/audio/awards/goal_tick.wav",
	"complete": "res://assets/audio/awards/goal_complete.wav"}
const VOICES := 8
const MAX_TICKS := 16

var lab: Control
var awards: Dictionary = {}
var context: Dictionary = {} # {league_id, run, title}
var playing := false
var step := "" # intro, trophy, goals, finale, done
var reduced_motion := false
var reduced_flash := false
var cues: Array = [] # every sound asked for, in order (tests read it)
var shown_trophies: Array = [] # ids presented
var goal_rows: Dictionary = {} # goal id -> {bar, count, stamp, ...}
var music: AudioStreamPlayer

var backdrop: TextureRect
var fx: Control
var stage: VBoxContainer # one trophy at a time
var stage_kicker: Label
var stage_art: TextureRect
var stage_name: Label
var stage_detail: Label
var spotlight: TextureRect
var summary: VBoxContainer
var title: Label
var subtitle: Label
var shelf: HFlowContainer
var goals_box: VBoxContainer
var goals_scroll: ScrollContainer
var continue_button: Button
var skip_button: Button
var _voices: Array = []
var _hurry := false
var _skipping := false
var _tweens: Array = []

func _ready() -> void:
	name = "AwardCeremony"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop = TextureRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var velvet := GradientTexture2D.new()
	velvet.fill = GradientTexture2D.FILL_RADIAL
	velvet.fill_from = Vector2(0.5, 0.42)
	velvet.fill_to = Vector2(1.1, 1.1)
	var shades := Gradient.new()
	shades.set_color(0, Color("3a2763"))
	shades.set_color(1, Color("070a16"))
	velvet.gradient = shades
	backdrop.texture = velvet
	add_child(backdrop)
	fx = AwardFx.new()
	fx.name = "AwardFx"
	add_child(fx)
	spotlight = TextureRect.new()
	spotlight.name = "Spotlight"
	spotlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spotlight.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var glow := GradientTexture2D.new()
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1.0, 0.5)
	var light := Gradient.new()
	light.set_color(0, Color(1, 0.93, 0.7, 0.42))
	light.set_color(1, Color(1, 0.93, 0.7, 0.0))
	glow.gradient = light
	spotlight.texture = glow
	spotlight.modulate.a = 0.0
	add_child(spotlight)
	_build_summary()
	_build_stage()
	skip_button = Button.new()
	skip_button.name = "SkipAwards"
	skip_button.text = "Skip"
	skip_button.custom_minimum_size = Vector2(110, 52)
	skip_button.pressed.connect(skip_all)
	add_child(skip_button)
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	music = AudioStreamPlayer.new()
	music.name = "AwardMusic"
	add_child(music)
	hide()

func _label(parent: Node, node_name: String, font_size: int, color: Color, outline: int = 0) -> Label:
	var l := Label.new()
	l.name = node_name
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color("1a1030"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _build_summary() -> void:
	summary = VBoxContainer.new()
	summary.name = "Summary"
	summary.add_theme_constant_override("separation", 12)
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(summary)
	title = _label(summary, "AwardTitle", 46, GOLD, 10)
	title.pivot_offset = Vector2(200, 30)
	subtitle = _label(summary, "AwardSubtitle", 20, IVORY)
	shelf = HFlowContainer.new()
	shelf.name = "TrophyShelf"
	shelf.alignment = FlowContainer.ALIGNMENT_CENTER
	shelf.add_theme_constant_override("h_separation", 14)
	shelf.add_theme_constant_override("v_separation", 10)
	shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary.add_child(shelf)
	goals_scroll = ScrollContainer.new()
	goals_scroll.name = "GoalsScroll"
	goals_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	goals_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	summary.add_child(goals_scroll)
	goals_box = VBoxContainer.new()
	goals_box.name = "Goals"
	goals_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_box.add_theme_constant_override("separation", 10)
	goals_scroll.add_child(goals_box)
	continue_button = Button.new()
	continue_button.name = "ContinueAwards"
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(240, 64)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_button.pressed.connect(close)
	continue_button.modulate.a = 0.0
	continue_button.disabled = true
	summary.add_child(continue_button)

func _build_stage() -> void:
	stage = VBoxContainer.new()
	stage.name = "TrophyStage"
	stage.alignment = BoxContainer.ALIGNMENT_CENTER
	stage.add_theme_constant_override("separation", 8)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	stage_kicker = _label(stage, "Kicker", 30, CORAL, 8)
	stage_art = TextureRect.new()
	stage_art.name = "TrophyArt"
	stage_art.custom_minimum_size = Vector2(220, 220)
	stage_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stage_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage_art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stage_art.pivot_offset = Vector2(110, 110)
	stage_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sweep := ShaderMaterial.new()
	sweep.shader = Shader.new()
	sweep.shader.code = """shader_type canvas_item;
uniform float sweep = -1.0; // the shine's position across the art, -1 (off) to 2
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float band = 1.0 - smoothstep(0.0, 0.12, abs((UV.x + UV.y * 0.6) - sweep));
	COLOR = vec4(c.rgb + band * 0.55 * c.a, c.a);
}"""
	stage_art.material = sweep
	stage.add_child(stage_art)
	stage_name = _label(stage, "TrophyName", 30, GOLD, 8)
	stage_detail = _label(stage, "TrophyDetail", 20, IVORY)
	stage.modulate.a = 0.0

func _layout() -> void:
	var margin := 16.0
	var width := minf(size.x - margin * 2.0, 620.0)
	summary.position = Vector2((size.x - width) * 0.5, margin + 8.0)
	summary.size = Vector2(width, size.y - margin * 2.0 - 8.0)
	stage.size = Vector2(width, 0)
	stage.position = Vector2((size.x - width) * 0.5, maxf(margin, size.y * 0.5 - stage.get_combined_minimum_size().y * 0.5))
	var art_center := stage.position + stage_art.position + stage_art.size * 0.5
	fx.rays_center = art_center
	var spot := minf(size.x, size.y) * 0.9
	spotlight.size = Vector2(spot, spot)
	spotlight.position = art_center - spotlight.size * 0.5
	skip_button.position = Vector2((size.x - skip_button.size.x) * 0.5, size.y - skip_button.size.y - margin) # where Continue appears

func _process(_delta: float) -> void:
	if visible: _layout()

## Starts the ceremony for `data` (RunAwards.for_run). ctx: {league_id, run, won}.
func present(data: Dictionary, ctx: Dictionary = {}) -> void:
	awards = data
	context = ctx
	reduced_motion = bool(lab.settings.get("reduced_motion", false)) if lab != null else false
	reduced_flash = bool(lab.settings.get("reduced_flash", false)) if lab != null else false
	fx.reduced_motion = reduced_motion
	fx.reduced_flash = reduced_flash
	if String(ctx.get("league_id", "")) == "league.neon":
		fx.palette = [GOLD, Color("ff4fd8"), Color("3ff2ff"), Color("b48cff"), IVORY]
	cues.clear()
	shown_trophies.clear()
	goal_rows.clear()
	for child in shelf.get_children(): child.queue_free()
	for child in goals_box.get_children(): child.queue_free()
	_hurry = false
	_skipping = false
	playing = true
	modulate.a = 1.0
	show()
	move_to_front()
	_layout()
	skip_button.show()
	skip_button.grab_focus()
	_start_music()
	_run()

func has_music() -> bool:
	return music != null and music.playing

## How far the League's music should sit while the ceremony shows (PresentationAudio):
## out of the way of the ceremony's own track, or halved without one.
func music_duck() -> float:
	return 0.0 if has_music() else 0.4

func _start_music() -> void:
	if not Soundtrack.has("awards"): return
	music.stream = Soundtrack.stream("awards")
	var target := Soundtrack.level_db(lab.settings if lab != null else {})
	music.volume_db = -60.0
	music.play()
	var fade := create_tween()
	fade.tween_property(music, "volume_db", target, 0.6)

func _stop_music(seconds: float = 0.4) -> void:
	if not music.playing: return
	var fade := create_tween()
	fade.tween_property(music, "volume_db", -60.0, seconds)
	fade.tween_callback(music.stop)

## UI-23: leaving for the Clubhouse fades the ceremony's music out with the screen.
func fade_music(seconds: float) -> void:
	_stop_music(seconds)

func _earned_something() -> bool:
	return not awards.get("trophies", []).is_empty() or awards.get("goals", []).any(func(g): return g.completed)

## Still playing the sequence (not closed, not skipped to the summary).
func _alive() -> bool:
	return playing and not _skipping

func _run() -> void:
	await _intro()
	for trophy in awards.get("trophies", []):
		if not _alive(): return
		await _trophy(trophy)
	if not awards.get("goals", []).is_empty() and _alive():
		await _goals()
	if _alive():
		await _finale()

func _intro() -> void:
	step = "intro"
	var big := _earned_something()
	title.text = "AWARDS" if big else "PROGRESS"
	subtitle.text = String(context.get("title", "Run complete"))
	cue("whoosh")
	if reduced_motion:
		title.scale = Vector2.ONE
	else:
		title.scale = Vector2(2.6, 2.6)
		title.modulate.a = 0.0
		_tween(title, "scale", Vector2.ONE, 0.45, Tween.TRANS_BACK)
		_tween(title, "modulate:a", 1.0, 0.25)
	title.modulate.a = 1.0 if reduced_motion else title.modulate.a
	if big and not reduced_motion:
		for i in 3:
			_rocket(size.x * (0.2 + 0.3 * i), Vector2(size.x * randf_range(0.15, 0.85), size.y * randf_range(0.12, 0.3)))
			await _pause(0.16)
			if not _alive(): return
	await _pause(0.7)

func _trophy(trophy: Dictionary) -> void:
	step = "trophy"
	shown_trophies.append(String(trophy.id))
	summary.modulate.a = 0.25
	stage_kicker.text = String(trophy.get("headline", "New Trophy!")).to_upper()
	stage_name.text = String(trophy.name)
	stage_detail.text = String(trophy.get("detail", ""))
	stage_art.texture = load(Art.path_for(trophy.asset)) if Art.has_art(trophy.asset) else null
	stage_art.scale = Vector2.ZERO if not reduced_motion else Vector2.ONE
	stage.modulate.a = 1.0
	stage_kicker.modulate.a = 0.0
	stage_name.modulate.a = 0.0
	stage_detail.modulate.a = 0.0
	_layout()
	# A League title gets the full show; a plaque or a decoration a quicker one.
	var major := String(trophy.kind) == "trophy"
	# The build-up: the sunburst gathers and spins faster, a drumroll.
	cue("drumroll" if major else "whoosh")
	fx.rays_alpha = 1.0
	fx.rays_speed = 1.6 if not reduced_motion else 0.0
	_tween(spotlight, "modulate:a", 1.0, 0.5)
	await _pause(0.95 if major else 0.4)
	if not _alive(): return
	# The reveal.
	cue("reveal")
	fx.flash_now()
	fx.rays_speed = 0.35
	if reduced_motion:
		stage_art.scale = Vector2.ONE
	else:
		_tween(stage_art, "scale", Vector2.ONE, 0.55, Tween.TRANS_BACK)
		_shine()
	_tween(stage_kicker, "modulate:a", 1.0, 0.2)
	_tween(stage_name, "modulate:a", 1.0, 0.3)
	_tween(stage_detail, "modulate:a", 1.0, 0.4)
	if not reduced_motion:
		cue("confetti")
		fx.confetti_cannons()
		await _pause(0.25)
		if not _alive(): return
		_firework(Vector2(size.x * 0.22, size.y * 0.22))
		if major:
			await _pause(0.3)
			if not _alive(): return
			_firework(Vector2(size.x * 0.78, size.y * 0.18))
	await _pause(1.9 if major else 1.1)
	if not _alive(): return
	# Onto the shelf.
	_add_to_shelf(trophy)
	_tween(stage, "modulate:a", 0.0, 0.25)
	_tween(spotlight, "modulate:a", 0.0, 0.25)
	fx.rays_alpha = 0.0
	summary.modulate.a = 1.0
	await _pause(0.3)

func _shine() -> void:
	if reduced_flash: return
	var mat := stage_art.material as ShaderMaterial
	mat.set_shader_parameter("sweep", -0.6)
	var t := create_tween()
	t.tween_interval(0.35)
	t.tween_method(func(v): mat.set_shader_parameter("sweep", v), -0.6, 2.0, 0.7)
	_tweens.append(t)

func _add_to_shelf(trophy: Dictionary) -> void:
	if shelf.get_node_or_null("Shelf_" + String(trophy.id).replace(".", "_")) != null: return
	var cell := VBoxContainer.new()
	cell.name = "Shelf_" + String(trophy.id).replace(".", "_")
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := Art.slot(trophy.asset, 92, true)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.add_child(art)
	var name_label := _label(cell, "Name", 16, GOLD)
	name_label.text = String(trophy.name)
	name_label.custom_minimum_size.x = 130
	shelf.add_child(cell)
	if not reduced_motion:
		cell.modulate.a = 0.0
		_tween(cell, "modulate:a", 1.0, 0.3)

func _goals() -> void:
	step = "goals"
	var header := _label(goals_box, "GoalsHeader", 26, TEAL, 6)
	header.text = "GOALS"
	for goal in awards.goals:
		if not _alive(): return
		await _goal(goal)

func _goal(goal: Dictionary) -> void:
	var row := PanelContainer.new()
	row.name = "Goal_" + String(goal.id).replace(".", "_")
	var style := StyleBoxFlat.new()
	style.bg_color = Color("16132a")
	style.border_color = Color("6c5a9c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	row.add_theme_stylebox_override("panel", style)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goals_box.add_child(row)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	row.add_child(line)
	var ribbon := Art.slot(goal.asset, 56, goal.completed)
	ribbon.name = "Ribbon"
	line.add_child(ribbon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 4)
	line.add_child(text)
	var name_label := _label(text, "Name", 20, IVORY)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.text = String(goal.name)
	var bar := GoalBar.new()
	bar.name = "Bar"
	bar.threshold = int(goal.threshold)
	bar.value = float(goal.before)
	bar.custom_minimum_size = Vector2(0, 18)
	text.add_child(bar)
	var count := _label(text, "Count", 16, Color("c9d3cf"))
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var stamp := _label(row, "Stamp", 30, CORAL, 8)
	stamp.text = "COMPLETE!"
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stamp.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	stamp.rotation_degrees = -7.0
	stamp.visible = false
	goal_rows[goal.id] = {"row": row, "bar": bar, "count": count, "stamp": stamp, "ribbon": ribbon}
	_count_text(goal, goal.before)
	if not reduced_motion:
		row.modulate.a = 0.0
		_tween(row, "modulate:a", 1.0, 0.2)
	await _pause(0.2)
	if not _alive(): return
	goals_scroll.ensure_control_visible(row)
	# The bar fills, a tick for each step (at most MAX_TICKS), rising in pitch.
	var steps := int(goal.after) - int(goal.before)
	var ticks := mini(steps, MAX_TICKS)
	if reduced_motion or _hurry:
		bar.value = float(goal.after)
		if steps > 0: cue("tick")
	else:
		for i in ticks:
			var v := float(goal.before) + float(steps) * float(i + 1) / ticks
			bar.value = v
			_count_text(goal, int(round(v)))
			cue("tick", 1.0 + 0.06 * i)
			await _pause(0.09)
			if not _alive(): return
	bar.value = float(goal.after)
	_count_text(goal, int(goal.after))
	if goal.completed:
		bar.complete = true
		stamp.visible = true
		cue("complete")
		if reduced_motion:
			stamp.scale = Vector2.ONE
		else:
			stamp.pivot_offset = stamp.size * 0.5
			stamp.scale = Vector2(2.4, 2.4)
			_tween(stamp, "scale", Vector2.ONE, 0.3, Tween.TRANS_BACK)
			var at := row.get_global_rect().get_center() - get_global_rect().position
			cue("confetti")
			fx.confetti_burst(at, 60)
			_rocket(at.x, Vector2(at.x + randf_range(-60, 60), maxf(40.0, at.y - 260.0)))
		await _pause(0.7)
	else:
		await _pause(0.35)

func _count_text(goal: Dictionary, value: int) -> void:
	var row: Dictionary = goal_rows.get(goal.id, {})
	if row.is_empty(): return
	var label: Label = row.count
	var reward := String(goal.get("reward", ""))
	if goal.completed and value >= int(goal.threshold):
		label.text = "%d / %d · Goal complete%s" % [value, goal.threshold, (": " + reward) if not reward.is_empty() else ""]
	elif goal.scope != "career":
		label.text = "This run: %d / %d · starts over next run" % [value, goal.threshold]
	else:
		label.text = "%d → %d / %d" % [int(goal.before), value, goal.threshold]

func _finale() -> void:
	step = "finale"
	if _earned_something() and not reduced_motion and not _skipping:
		cue("confetti")
		fx.confetti_rain()
		for i in 3:
			_firework(Vector2(size.x * randf_range(0.15, 0.85), size.y * randf_range(0.12, 0.35)))
			await _pause(0.35)
			if not _alive(): return
	elif not reduced_motion and not _skipping:
		cue("confetti")
		fx.confetti_burst(Vector2(size.x * 0.5, size.y), 50)
	_end_state()

## Everything in its final place: the shelf, every goal filled, Continue ready.
func _end_state() -> void:
	step = "done"
	_finish_tweens()
	stage.modulate.a = 0.0
	spotlight.modulate.a = 0.0
	fx.rays_alpha = 0.0
	summary.modulate.a = 1.0
	title.scale = Vector2.ONE
	title.modulate.a = 1.0
	for trophy in awards.get("trophies", []):
		if String(trophy.id) not in shown_trophies:
			shown_trophies.append(String(trophy.id))
		_add_to_shelf(trophy)
	for goal in awards.get("goals", []):
		if not goal_rows.has(goal.id):
			if goals_box.get_node_or_null("GoalsHeader") == null:
				_label(goals_box, "GoalsHeader", 26, TEAL, 6).text = "GOALS"
			_skipping = true
			_hurry = true
			_goal(goal) # builds the row in its final state (no waits while hurrying)
		var row: Dictionary = goal_rows.get(goal.id, {})
		if not row.is_empty():
			row.bar.value = float(goal.after)
			row.bar.complete = goal.completed
			row.stamp.visible = goal.completed
			row.stamp.scale = Vector2.ONE
			row.row.modulate.a = 1.0
			_count_text(goal, int(goal.after))
	skip_button.hide()
	continue_button.disabled = false
	continue_button.modulate.a = 1.0
	continue_button.grab_focus()

## Plays a sound (and logs it): silent under Mute or with the effects level at 0.
func cue(id: String, pitch: float = 1.0) -> void:
	cues.append(id)
	if _skipping: return
	var muted := bool(lab.settings.get("sound_muted", false)) if lab != null else false
	var volume := float(lab.settings.get("sound_volume", 0.65)) if lab != null else 0.65
	if muted or volume <= 0.0 or not SOUNDS.has(id) or not ResourceLoader.exists(SOUNDS[id]): return
	var voice: AudioStreamPlayer = null
	for v in _voices:
		if not v.playing: voice = v; break
	if voice == null: voice = _voices[cues.size() % _voices.size()]
	voice.stream = load(SOUNDS[id])
	voice.pitch_scale = pitch
	voice.volume_db = linear_to_db(maxf(volume * 0.5, 0.0001))
	voice.play()

func _firework(at: Vector2) -> void:
	if reduced_motion or _skipping: return
	if reduced_flash:
		cue("confetti")
		fx.confetti_burst(Vector2(at.x, size.y), 40)
		return
	cue("launch")
	var flight: float = fx.launch_firework(at)
	get_tree().create_timer(flight).timeout.connect(func(): if playing: cue("burst"))

func _rocket(from_x: float, to: Vector2) -> void:
	if reduced_motion or _skipping: return
	cue("rocket")
	fx.bottle_rocket(from_x, to)

func _tween(target: Object, property: String, value: Variant, seconds: float, trans: int = Tween.TRANS_CUBIC) -> void:
	if _hurry or reduced_motion:
		target.set_indexed(property, value)
		return
	var t := create_tween()
	t.tween_property(target, property, value, seconds).set_trans(trans).set_ease(Tween.EASE_OUT)
	_tweens.append(t)

func _finish_tweens() -> void:
	for t in _tweens:
		if is_instance_valid(t) and t.is_running():
			t.custom_step(60.0)
	_tweens.clear()

## Waits, unless a tap is hurrying this moment along.
func _pause(seconds: float) -> void:
	var waited := 0.0
	while waited < seconds and not _hurry and playing:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if _hurry and not _skipping:
		_hurry = false # hurries one moment at a time
		_finish_tweens()

## A tap: hurries the current moment. Skip: straight to the summary.
func hurry() -> void:
	_hurry = true

func skip_all() -> void:
	if step == "done": return
	_skipping = true
	_hurry = true
	_end_state()

func close() -> void:
	if not playing: return
	playing = false
	_stop_music()
	_finish_tweens()
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.2 if not reduced_motion else 0.0)
	fade.tween_callback(hide)
	finished.emit()

## Releases the mixer's references before teardown (as PresentationAudio does): a
## sound or the music may still be playing when the lab is freed after a result.
func _exit_tree() -> void:
	var any := false
	for voice in _voices + [music]:
		if is_instance_valid(voice):
			any = any or voice.playing
			voice.stop()
			voice.stream = null
	if any and AudioServer.get_driver_name() == "Dummy":
		# Godot 4.5 retires stopped playbacks on the next mixer pass; wait for one.
		var stopped_at := Time.get_ticks_usec()
		while Time.get_ticks_usec() - stopped_at < 1000000:
			var sampled_at := Time.get_ticks_usec()
			var since_mix := int(AudioServer.get_time_since_last_mix() * 1000000.0)
			if sampled_at - since_mix > stopped_at: break
			OS.delay_msec(1)

func _gui_input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if tapped and step != "done":
		hurry()
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not playing: return
	if event.is_action_pressed("ui_cancel"):
		if step == "done": close()
		else: skip_all()
		get_viewport().set_input_as_handled()

## A goal's bar: segments for small thresholds, gold when complete.
class GoalBar extends Control:
	var threshold := 1
	var value := 0.0:
		set(v):
			value = v
			queue_redraw()
	var complete := false:
		set(v):
			complete = v
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color("0b0a18"))
		var share := clampf(value / maxf(1.0, threshold), 0.0, 1.0)
		draw_rect(Rect2(r.position, Vector2(r.size.x * share, r.size.y)), Color("f5cb69") if complete else Color("64dacb"))
		if threshold <= 20:
			for i in range(1, threshold):
				var x := r.size.x * i / threshold
				draw_line(Vector2(x, 0), Vector2(x, r.size.y), Color(0, 0, 0, 0.45), 2.0)
		draw_rect(r, Color("6c5a9c"), false, 2.0)
