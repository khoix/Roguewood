extends Control
## UI-12 (owner's play notes, 2026-11-16): Options and Sound & effects from the
## Clubhouse's menu. UI-15 (owner, 2026-11-18): Throw Settings and Sound & Effects
## are sibling pages of the menu, each with Back to it, as in a match. The same panels as in a match (ThrowSettingsPanel and
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
var page := "" # the page open: "throw" or "sound"
## UI-15: a page's Back (or Escape) closed it; the Clubhouse menu comes back.
signal closed(page: String)
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
	settings_panel.back.connect(_back)
	add_child(settings_panel)
	sound = Audio.new()
	sound.lab = self
	add_child(sound)
	sound.back.connect(_back)
	_layout()

## Open one page: Throw Settings ("throw") or Sound & Effects ("sound").
func open(which: String = "throw") -> void:
	_build()
	page = which
	dim.show()
	if which == "sound":
		sound.open()
	else:
		settings_panel.show()
		settings_panel.handedness.grab_focus()

## Back from the open page (its Back button, or Escape).
func go_back() -> void:
	if page == "sound": sound.go_back()
	elif page != "": settings_panel.go_back()

func _back() -> void:
	var was := page
	page = ""
	dim.hide()
	closed.emit(was)

## Close without returning to the menu (leaving the Clubhouse).
func close() -> void:
	page = ""
	sound.panel.hide()
	settings_panel.hide()
	dim.hide()

func is_open() -> bool:
	return settings_panel.visible or sound.panel.visible

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
