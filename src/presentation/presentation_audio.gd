extends Node
## Original local foley, at most four voices. Session preferences only.
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
var volume_slider: HSlider
func _ready() -> void:
	name = "PresentationAudio"
	muted = lab.settings.get("sound_muted", false)
	volume = lab.settings.get("sound_volume", 0.65)
	enabled = lab.settings.get("ability_effects", true)
	for i in 4:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
		priorities.append(0)
	var button := Button.new()
	button.name = "SoundAndEffects"
	button.text = "Sound & effects"
	button.custom_minimum_size.y = 48
	var options: VBoxContainer = lab.settings_panel.get_child(0)
	var row := HBoxContainer.new()
	options.remove_child(lab.settings_panel.close)
	options.add_child(row)
	lab.settings_panel.close.custom_minimum_size.x = 160
	row.add_child(lab.settings_panel.close)
	button.custom_minimum_size.x = 160
	row.add_child(button)
	button.pressed.connect(func(): panel.show(); mute_button.grab_focus())
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
	title.text = "Sound & effects"
	title.add_theme_font_size_override("font_size",28)
	box.add_child(title)
	mute_button = CheckButton.new()
	mute_button.text = "Mute sound"
	mute_button.button_pressed = muted
	mute_button.custom_minimum_size.y = 48
	mute_button.toggled.connect(func(value): muted = value; lab.settings["sound_muted"] = value; _mix())
	box.add_child(mute_button)
	var label := Label.new()
	label.text = "Sound volume"
	box.add_child(label)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 1
	volume_slider.step = 0.05
	volume_slider.value = volume
	volume_slider.custom_minimum_size.y = 48
	volume_slider.value_changed.connect(func(value): volume = value; lab.settings["sound_volume"] = value; _mix())
	box.add_child(volume_slider)
	effects_button = CheckButton.new()
	effects_button.text = "Ability effects"
	effects_button.button_pressed = enabled
	effects_button.custom_minimum_size.y = 48
	effects_button.toggled.connect(func(value): enabled = value; lab.settings["ability_effects"] = value)
	box.add_child(effects_button)
	var close := Button.new()
	close.text = "Back to options"
	close.custom_minimum_size.y = 48
	close.pressed.connect(func(): panel.hide(); button.grab_focus())
	box.add_child(close)
	panel.hide()
func _mix() -> void:
	for voice in voices:
		voice.volume_db = linear_to_db(maxf(0.0001, volume * 0.35))
		if muted or volume == 0: voice.stop()
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

func _process(_delta: float) -> void:
	if not lab.settings_panel.visible: panel.hide()

func _exit_tree() -> void:
	# Release active mixer references before SceneTree teardown, including Dummy
	# audio under fixed-fps journeys that can finish before a sound's wall time.
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
	if DisplayServer.get_name() == "headless":
		# Godot 4.5's Dummy mixer retires stopped WAV playbacks on its next
		# wall-clock mix. Fixed-fps tests can otherwise tear down first.
		OS.delay_msec(50)
