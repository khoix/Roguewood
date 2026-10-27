extends PanelContainer
## In-session throw settings: handedness, flick sensitivity, reduced motion, larger
## touch targets, the accessible controls, the E07 equipment model under test and
## E09 practice mode. Values live in the shell's settings
## dictionary so they survive Restart Session; saving them is E25 work.
signal changed
const DEFAULTS := {"handedness": "right", "sensitivity": 1.0, "reduced_motion": false, "large_targets": false, "assist": false, "score_speed": 1,
	"equipment": "deck", "practice": false}

var settings: Dictionary = {}
var handedness: OptionButton
var sensitivity: HSlider
var reduced_motion: CheckButton
var large_targets: CheckButton
var assist: CheckButton
var equipment: OptionButton
var practice: CheckButton
var close: Button
var _sensitivity_label: Label

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
	reduced_motion = _toggle(box, "ReducedMotion", "Reduced motion (steady ring)", "reduced_motion")
	large_targets = _toggle(box, "LargeTargets", "Larger touch targets", "large_targets")
	assist = _toggle(box, "AssistControls", "Assist controls (no gestures)", "assist")
	# E07 experiment: the proposed deck against direct selection (ADR 004).
	equipment = OptionButton.new()
	equipment.name = "EquipmentModel"
	equipment.add_item("Equipment: draw & cycle deck")
	equipment.add_item("Equipment: direct selection")
	equipment.custom_minimum_size = Vector2(320, 56)
	equipment.select(1 if settings.equipment == "direct" else 0)
	equipment.item_selected.connect(func(index): _store("equipment", "direct" if index == 1 else "deck"))
	box.add_child(equipment)
	# E09: practice drops the Division's targets (applies to an attempt not yet thrown).
	practice = _toggle(box, "PracticeMode", "Practice (no targets)", "practice")
	close = Button.new()
	close.name = "CloseSettings"
	close.text = "Done"
	close.custom_minimum_size = Vector2(320, 64)
	close.pressed.connect(hide)
	box.add_child(close)
	_refresh()

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
