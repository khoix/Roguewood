extends PanelContainer
## Accessible aim, power and spin controls: sliders and a Throw button, all usable by
## keyboard/gamepad focus. No gesture is needed, and the ring timing stays optional.
## Throw emits the same launch record a gesture with these values would.
signal throw_requested(controls: Dictionary)
signal preview_changed(controls: Dictionary)
const Lane = preload("res://src/simulation/lane_spec.gd")
const Mapper = preload("res://src/input/launch_mapper.gd")
const Ring = preload("res://src/input/target_ring.gd")

var position_slider: HSlider
var aim_slider: HSlider
var power_slider: HSlider
var spin_slider: HSlider
var target_slider: HSlider
var throw_button: Button
var _labels: Dictionary = {}
var _initial_target := Lane.DEFAULT_TARGET_X

func _ready() -> void:
	name = "AssistControls"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	position_slider = _slider(box, "AssistPosition", -snappedf(Lane.MAX_START_X, 0.05), snappedf(Lane.MAX_START_X, 0.05), 0.05, 0.0)
	aim_slider = _slider(box, "AssistAim", -Mapper.MAX_LAUNCH_ANGLE_DEG, Mapper.MAX_LAUNCH_ANGLE_DEG, 0.25, 0.0)
	power_slider = _slider(box, "AssistPower", 0.0, 1.0, 0.05, 0.5)
	spin_slider = _slider(box, "AssistSpin", -1.0, 1.0, 0.25, 0.0)
	target_slider = _slider(box, "AssistTarget", -Ring.MAX_TARGET_X, Ring.MAX_TARGET_X, 0.05, _initial_target)
	throw_button = Button.new()
	throw_button.name = "AssistThrow"
	throw_button.text = "Throw"
	throw_button.custom_minimum_size = Vector2(0, 64)
	throw_button.pressed.connect(func(): throw_requested.emit(values()))
	box.add_child(throw_button)
	_refresh()

func set_target(x: float) -> void:
	_initial_target = x
	if target_slider:
		target_slider.set_value_no_signal(x)
		_refresh()

func _slider(box: Container, node_name: String, low: float, high: float, step: float, value: float) -> HSlider:
	var label := Label.new()
	box.add_child(label)
	var slider := HSlider.new()
	slider.name = node_name
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(260, 40)
	slider.value_changed.connect(func(_value): _refresh(); preview_changed.emit(values()))
	box.add_child(slider)
	_labels[node_name] = label
	return slider

## Values in launch units: start_x/target normalized, aim in lane degrees.
func values() -> Dictionary:
	return {"start_x": position_slider.value, "angle_deg": aim_slider.value, "power": power_slider.value,
		"spin": spin_slider.value, "target_x": target_slider.value}

func _refresh() -> void:
	if _labels.is_empty() or target_slider == null:
		return
	var spin := spin_slider.value
	_labels.AssistPosition.text = "Position %+.2f" % position_slider.value
	_labels.AssistAim.text = "Aim %+.2f°" % aim_slider.value
	_labels.AssistPower.text = "Power %d%%" % roundi(power_slider.value * 100.0)
	_labels.AssistSpin.text = "Straight" if spin == 0.0 else "Spin %s %d%%" % ["↻ right" if spin > 0.0 else "↺ left", roundi(absf(spin) * 100.0)]
	_labels.AssistTarget.text = "Target %+.2f" % target_slider.value
