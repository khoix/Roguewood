extends PanelContainer
## In-session throw settings: handedness, flick sensitivity, reduced motion, larger
## touch targets, the accessible controls (the equipment model is the deck, ADR 004) and
## E09 practice mode. Values live in the shell's settings
## dictionary so they survive Restart Session; saving them is E25 work.
signal changed
const DEFAULTS := {"handedness": "right", "sensitivity": 1.0, "reduced_motion": false, "large_targets": false, "assist": false, "score_speed": 1,
	"equipment": "deck", "practice": false, "reduced_flash": false, "haptics": true, "throw_tuning": {}}
## E05-R2: the tethered-swing constants the tuning page adjusts (ADR 011), as
## [key, label, min, max, step, format]. Values live in settings.throw_tuning for the
## session; anything not set uses held_ball.gd's defaults.
const Held = preload("res://src/input/held_ball.gd")
const TUNABLE := [
	["full_charge_speed", "Full-charge swirl (rad/s)", 4.0, 25.0, 0.5, "%.1f"],
	["swirl_half_life", "Swirl wind-down half-life (s)", 0.3, 5.0, 0.1, "%.1f"],
	["spin_up_time", "Swirl catch-up time (s)", 0.03, 0.5, 0.01, "%.2f"],
	["swirl_start_deg", "Turn before a swirl counts (°)", 90.0, 540.0, 10.0, "%.0f"],
	["orbit_nudge", "Orbit nudge on release", 0.0, 1.0, 0.05, "%.2f"],
]

var settings: Dictionary = {}
var handedness: OptionButton
var sensitivity: HSlider
var reduced_motion: CheckButton
var reduced_flash: CheckButton
var large_targets: CheckButton
var assist: CheckButton
var practice: CheckButton
var close: Button
var _sensitivity_label: Label
var haptics: CheckButton
var tuning_button: Button
var tuning_box: VBoxContainer
var _main_box: VBoxContainer
var _tuning_sliders: Dictionary = {}
var _tuning_labels: Dictionary = {}

static func with_defaults(values: Dictionary) -> Dictionary:
	for key in DEFAULTS:
		if not values.has(key):
			values[key] = DEFAULTS[key]
	return values

func _ready() -> void:
	name = "ThrowSettings"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	_main_box = box
	var title := Label.new()
	title.text = "Throw settings"
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	handedness = OptionButton.new()
	handedness.name = "Handedness"
	handedness.add_item("Right-handed")
	handedness.add_item("Left-handed")
	handedness.select(1 if settings.handedness == "left" else 0)
	handedness.item_selected.connect(func(index): _store("handedness", "left" if index == 1 else "right"))
	box.add_child(handedness)
	_sensitivity_label = Label.new()
	box.add_child(_sensitivity_label)
	sensitivity = HSlider.new()
	sensitivity.name = "Sensitivity"
	sensitivity.min_value = 0.5
	sensitivity.max_value = 2.0
	sensitivity.step = 0.25
	sensitivity.value = settings.sensitivity
	sensitivity.custom_minimum_size = Vector2(320, 44)
	sensitivity.value_changed.connect(func(value): _store("sensitivity", value))
	box.add_child(sensitivity)
	reduced_motion = _toggle(box, "ReducedMotion", "Reduced motion (steady camera & foil)", "reduced_motion")
	reduced_flash = _toggle(box, "ReducedFlash", "Reduced flash (no impact accents)", "reduced_flash")
	large_targets = _toggle(box, "LargeTargets", "Larger touch targets", "large_targets")
	assist = _toggle(box, "AssistControls", "Assist controls (no gestures)", "assist")
	haptics = _toggle(box, "Haptics", "Vibration on charge", "haptics")
	tuning_button = Button.new()
	tuning_button.name = "ThrowTuning"
	tuning_button.text = "Throw tuning (test)…"
	tuning_button.custom_minimum_size = Vector2(320, 56)
	tuning_button.pressed.connect(func(): _show_tuning(true))
	box.add_child(tuning_button)
	# ADR 004 decided the draw-and-cycle deck (owner, 2026-11-04): the player's Options
	# no longer offer direct selection. It stays a test fixture (use_equipment).
	# E09: practice drops the Division's targets (applies to an attempt not yet thrown).
	practice = _toggle(box, "PracticeMode", "Practice (no targets; no unlocks)", "practice")
	close = Button.new()
	close.name = "CloseSettings"
	close.text = "Done"
	close.custom_minimum_size = Vector2(320, 64)
	close.pressed.connect(hide)
	box.add_child(close)
	_build_tuning()
	_refresh()

## A second page in the same panel: sliders for the held-ball constants, for
## tuning the throw on a real phone through the web build.
func _build_tuning() -> void:
	tuning_box = VBoxContainer.new()
	tuning_box.name = "TuningPage"
	tuning_box.add_theme_constant_override("separation", 6)
	tuning_box.visible = false
	add_child(tuning_box)
	var title := Label.new()
	title.text = "Throw tuning (test)"
	title.add_theme_font_size_override("font_size", 30)
	tuning_box.add_child(title)
	for row in TUNABLE:
		var label := Label.new()
		tuning_box.add_child(label)
		_tuning_labels[row[0]] = label
		var slider := HSlider.new()
		slider.name = "Tune_" + row[0]
		slider.min_value = row[2]
		slider.max_value = row[3]
		slider.step = row[4]
		slider.custom_minimum_size = Vector2(320, 40)
		slider.value = _tuned(row[0])
		slider.value_changed.connect(func(value): _store_tuning(row[0], value))
		tuning_box.add_child(slider)
		_tuning_sliders[row[0]] = slider
	var reset := Button.new()
	reset.name = "ResetTuning"
	reset.text = "Reset to defaults"
	reset.custom_minimum_size = Vector2(320, 52)
	reset.pressed.connect(func():
		settings.throw_tuning = {}
		for key in _tuning_sliders: _tuning_sliders[key].set_value_no_signal(_tuned(key))
		_refresh()
		changed.emit())
	tuning_box.add_child(reset)
	var back := Button.new()
	back.name = "CloseTuning"
	back.text = "Back"
	back.custom_minimum_size = Vector2(320, 52)
	back.pressed.connect(func(): _show_tuning(false))
	tuning_box.add_child(back)

func _show_tuning(on: bool) -> void:
	_main_box.visible = not on
	tuning_box.visible = on
	(_tuning_sliders[TUNABLE[0][0]] if on else tuning_button).grab_focus()

func _tuned(key: String) -> float:
	return float(settings.get("throw_tuning", {}).get(key, Held.DEFAULTS[key]))

func _store_tuning(key: String, value: float) -> void:
	var tuning: Dictionary = settings.get("throw_tuning", {}).duplicate()
	tuning[key] = value
	settings.throw_tuning = tuning
	_refresh()
	changed.emit()

## Test fixture only: switches the equipment model (direct selection is not a player option).
func use_equipment(model: String) -> void:
	_store("equipment", model)

func _toggle(box: Container, node_name: String, text: String, key: String) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.name = node_name
	toggle.text = text
	toggle.custom_minimum_size = Vector2(320, 56)
	toggle.button_pressed = settings[key]
	toggle.toggled.connect(func(on): _store(key, on))
	box.add_child(toggle)
	return toggle

func _store(key: String, value: Variant) -> void:
	settings[key] = value
	_refresh()
	changed.emit()

func _refresh() -> void:
	_sensitivity_label.text = "Flick sensitivity ×%.2f" % settings.sensitivity
	for row in TUNABLE:
		if _tuning_labels.has(row[0]):
			_tuning_labels[row[0]].text = ("%s: " + row[5]) % [row[1], _tuned(row[0])]
