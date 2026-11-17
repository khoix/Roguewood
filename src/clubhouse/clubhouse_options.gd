extends Control
## UI-12 (owner's play notes, 2026-11-16): Options and Sound & effects from the
## Clubhouse's menu. The same panels as in a match (ThrowSettingsPanel and
## PresentationAudio), hosted on the shell's session settings, so a change made here
## is what the next match reads. This host stands in for the lab: PresentationAudio
## reads `settings`, `settings_panel` and (absent here) `league_theme` and `shop_panel`.
const SettingsPanel = preload("res://src/presentation/throw_settings_panel.gd")
const Audio = preload("res://src/presentation/presentation_audio.gd")

var settings: Dictionary = {}
var settings_panel: SettingsPanel
var sound: Node
var league_theme = null # the Clubhouse music is the shell's, not a League theme's
var dim: ColorRect
signal closed
signal throw_cue(id: String, charge: float) # PresentationAudio listens; nothing is thrown here

func _ready() -> void:
	name = "ClubhouseOptions"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	SettingsPanel.with_defaults(settings)
	# The Clubhouse stays under the page, dimmed and out of reach while it is open.
	dim = ColorRect.new()
	dim.name = "OptionsDim"
	dim.color = Color(0.03, 0.05, 0.08, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.hide()
	add_child(dim)
	_build()
	resized.connect(_layout)

## The pages read the settings when built, so each opening builds them afresh: a
## change made in a match shows here, and one made here reaches the next match.
func _build() -> void:
	if settings_panel != null:
		sound.panel.free()
		sound.free()
		settings_panel.free()
	settings_panel = SettingsPanel.new()
	settings_panel.settings = settings
	settings_panel.hide()
	settings_panel.visibility_changed.connect(func():
		dim.visible = settings_panel.visible
		if not settings_panel.visible: closed.emit())
	add_child(settings_panel)
	sound = Audio.new()
	sound.lab = self
	add_child(sound)
	_layout()

## Open on the Options page, or straight on Sound & effects.
func open(page: String = "options") -> void:
	_build()
	settings_panel.show()
	settings_panel.handedness.grab_focus()
	if page == "sound":
		sound.panel.show()
		sound.mute_button.grab_focus()

func close() -> void:
	sound.panel.hide()
	settings_panel.hide()

func is_open() -> bool:
	return settings_panel.visible

## As in a match: the full width in portrait, a centred column in landscape.
func _layout() -> void:
	if settings_panel == null: return
	var portrait := size.y >= size.x
	settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_panel.offset_top = 88.0
	settings_panel.offset_bottom = -12.0
	if portrait:
		settings_panel.anchor_left = 0.0
		settings_panel.anchor_right = 1.0
		settings_panel.offset_left = 12.0
		settings_panel.offset_right = -12.0
	else:
		settings_panel.anchor_left = 0.5
		settings_panel.anchor_right = 0.5
		settings_panel.offset_left = -320.0
		settings_panel.offset_right = 320.0
