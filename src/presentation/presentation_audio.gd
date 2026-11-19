extends Node
## Original local foley, at most four voices. Session preferences only.
const THROW_SOUNDS := {
	"throw.charge": preload("res://assets/audio/throw_charge.wav"),
	"throw.curve_ready": preload("res://assets/audio/throw_curve_ready.wav"),
	"throw.full_charge": preload("res://assets/audio/throw_full_charge.wav"),
}
var lab: Control
var muted := false
var volume := 0.65
var enabled := true
var played := 0
var suppressed := 0
var max_active := 0
var voices: Array[AudioStreamPlayer] = []
var priorities: Array[int] = []
var last_at := {}
var panel: PanelContainer
var mute_button: CheckButton
var effects_button: CheckButton
var volume_slider: HSlider # sound effects
var music_slider: HSlider
var music_volume := 1.0 # of the League music's own level
var back_button: Button
signal back # UI-15: the page's Back, to the menu that opened it
## UI-12 (owner's play notes, 2026-11-16): while the Pro Shop or Options is open the
## music eases to half its level (sound effects keep theirs) and eases back on close.
const MENU_DUCK := 0.5
const DUCK_SECONDS := 0.4
var duck := 1.0
var fade := 1.0 # UI-23: leaving for the Clubhouse fades the League's music out (fade_music)
func _ready() -> void:
	name = "PresentationAudio"
	muted = lab.settings.get("sound_muted", false)
	volume = lab.settings.get("sound_volume", 0.65)
	music_volume = lab.settings.get("music_volume", 1.0)
	enabled = lab.settings.get("ability_effects", true)
	for i in 4:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
		priorities.append(0)
	panel = PanelContainer.new()
	panel.name = "SoundEffectsPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101820")
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel",style)
	lab.add_child(panel)
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = 96
	panel.offset_bottom = -24
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation",16)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Sound & Effects"
	title.add_theme_font_size_override("font_size",28)
	box.add_child(title)
	mute_button = CheckButton.new()
	mute_button.text = "Mute Sound"
	mute_button.button_pressed = muted
	mute_button.custom_minimum_size.y = 48
	mute_button.toggled.connect(func(value): muted = value; lab.settings["sound_muted"] = value; _mix())
	box.add_child(mute_button)
	# UI-11 (owner, 2026-11-16): music and sound effects each have a slider.
	var music_label := Label.new()
	music_label.text = "Music Volume"
	box.add_child(music_label)
	music_slider = HSlider.new()
	music_slider.name = "MusicVolume"
	music_slider.min_value = 0
	music_slider.max_value = 1
	music_slider.step = 0.05
	music_slider.value = music_volume
	music_slider.custom_minimum_size.y = 48
	music_slider.value_changed.connect(func(value): music_volume = value; lab.settings["music_volume"] = value; _mix())
	box.add_child(music_slider)
	var label := Label.new()
	label.text = "Sound Effects Volume"
	box.add_child(label)
	volume_slider = HSlider.new()
	volume_slider.name = "EffectsVolume"
	volume_slider.min_value = 0
	volume_slider.max_value = 1
	volume_slider.step = 0.05
	volume_slider.value = volume
	volume_slider.custom_minimum_size.y = 48
	volume_slider.value_changed.connect(func(value): volume = value; lab.settings["sound_volume"] = value; _mix())
	box.add_child(volume_slider)
	effects_button = CheckButton.new()
	effects_button.text = "Ability Effects"
	effects_button.button_pressed = enabled
	effects_button.custom_minimum_size.y = 48
	effects_button.toggled.connect(func(value): enabled = value; lab.settings["ability_effects"] = value)
	box.add_child(effects_button)
	back_button = Button.new()
	back_button.name = "SoundBack"
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(220, 64)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(go_back)
	box.add_child(back_button)
	panel.hide()
	lab.throw_cue.connect(_throw_cue)

func _throw_cue(id: String, _charge: float) -> void:
	if THROW_SOUNDS.has(id):
		cue(id, THROW_SOUNDS[id], 3 if id == "throw.full_charge" else 2)

func _mix() -> void:
	for voice in voices:
		voice.volume_db = linear_to_db(maxf(0.0001, volume * 0.35))
		if muted or volume == 0: voice.stop()
	_mix_music()

## The League's music: its own level times the music slider; Mute silences it too.
func _mix_music() -> void:
	var theme = lab.get("league_theme") if lab != null else null
	if theme == null or theme.music == null: return
	var level: float = 0.0 if muted else music_volume * duck * fade
	var want: float = float(theme.MUSIC_DB) + linear_to_db(maxf(level, 0.0001))
	if not is_equal_approx(theme.music.volume_db, want):
		theme.music.volume_db = want


## UI-23: fades the League's music to silence over `seconds` (leaving for the Clubhouse).
func fade_music(seconds: float) -> void:
	var t := create_tween()
	t.tween_property(self, "fade", 0.0, seconds)

func cue(id: String, stream: AudioStream, priority: int = 1) -> void:
	var now := Time.get_ticks_msec()
	if muted or volume <= 0 or stream == null or now - int(last_at.get(id,-1000)) < 85:
		suppressed += 1
		return
	var index := -1
	for i in voices.size():
		if not voices[i].playing: index = i; break
	if index < 0:
		for i in voices.size():
			if priorities[i] < priority: index = i; break
	if index < 0: suppressed += 1; return
	last_at[id] = now
	priorities[index] = priority
	voices[index].stream = stream
	_mix()
	voices[index].play()
	played += 1
	max_active = maxi(max_active, voices.filter(func(v): return v.playing).size())

func menu_open() -> bool:
	return lab.settings_panel.visible or panel.visible or (lab.get("shop_panel") != null and lab.shop_panel.visible)

## UI-15 (owner, 2026-11-18): Sound & Effects is its own page, opened from the menu
## beside Throw Settings; Back returns to that menu.
func open() -> void:
	panel.move_to_front() # over the lane's later layers
	panel.show()
	mute_button.grab_focus()

func go_back() -> void:
	panel.hide()
	back.emit()

func _process(delta: float) -> void:
	var target := MENU_DUCK if menu_open() else 1.0
	var ceremony = lab.get("award_ceremony")
	if ceremony != null and ceremony.visible and ceremony.playing:
		target = ceremony.music_duck() # UI-22: the ceremony's own music takes over
	duck = move_toward(duck, target, delta * (1.0 - MENU_DUCK) / DUCK_SECONDS)
	_mix_music() # the music may start after the panel is built

func _exit_tree() -> void:
	# Release active mixer references before SceneTree teardown, including Dummy
	# audio under fixed-fps journeys that can finish before a sound's wall time.
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
	if AudioServer.get_driver_name() == "Dummy":
		# Godot 4.5 retires stopped WAV playbacks on the next mixer pass.
		# Dummy uses 4096 frames (~93 ms at 44.1 kHz), independently of
		# fixed-fps simulation. Wait for an actual pass, not a fixed delay.
		# The clock query takes the driver's lock, so that pass is complete
		# when it returns. Bound the wait if the driver has already stopped.
		var stopped_at := Time.get_ticks_usec()
		while Time.get_ticks_usec() - stopped_at < 1000000:
			var sampled_at := Time.get_ticks_usec()
			var since_mix := int(AudioServer.get_time_since_last_mix() * 1000000.0)
			if sampled_at - since_mix > stopped_at: break
			OS.delay_msec(1)
