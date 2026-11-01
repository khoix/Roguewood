extends Control
## Read-only tactical presentation; saved actions restore labels, never audio.
const Assets = preload("res://src/presentation/item_assets.gd")
var lab: Control
var marker: Label
var glyph: Control
var played: Array = []
var waived := false
var audio_events: Array = []
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	marker = Label.new()
	marker.add_theme_font_size_override("font_size", 19)
	marker.add_theme_color_override("font_color", Color("f2d6a0"))
	marker.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	marker.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(marker)
	glyph = preload("res://src/presentation/ability_glyph.gd").new()
	glyph.size = Vector2(48,48)
	add_child(glyph)
	lab.tactic_played.connect(_played)
	lab.hud.badge.draw.connect(_badge)
func _played(action: Dictionary) -> void:
	var id: String = action.item_id
	played.append(id)
	glyph.show_cue(Assets.slot(id,"activation"), lab.settings.reduced_motion or lab.settings.reduced_flash, Assets.slot(id,"icon"))
	var before: int = lab.motion.sound.played
	lab.motion.sound.cue(id, Assets.slot(id,"sound"), 2)
	audio_events.append(lab.motion.sound.played > before)
func _process(_delta: float) -> void:
	var lines: Array[String] = []
	waived = false
	for action in lab.frame_actions:
		match action.kind:
			"reserve_swap":
				if not action.get("restored", false): lines.append("Reserve Call · pin %d · THIS FRAME ONLY" % action.position)
			"relocate_pin": lines.append("Nudge · pin %d → spot %d" % [action.position, action.to])
			"waive_rule":
				waived = true
				lines.append("Rule Waiver · THIS FRAME ONLY")
	marker.text = "\n".join(lines)
	position = lab.card_hand.position + Vector2(0,-76)
	marker.position = Vector2(56,0)
	marker.size = Vector2(maxf(100, lab.card_hand.size.x-56),72)
	visible = lab.state in ["aim", "holding", "rolling", "result", "tactic"] and not lab.settings_panel.visible
	glyph.enabled = lab.motion.sound.enabled
	lab.hud.badge.queue_redraw()
func _badge() -> void:
	if not waived: return
	var button: Button = lab.hud.badge
	button.draw_rect(Rect2(Vector2.ZERO,button.size), Color("f2d6a0"),false,2)
	button.draw_line(Vector2(5,3), Vector2(17,15), Color("f2d6a0"),2)
	button.draw_line(Vector2(17,3), Vector2(5,15), Color("f2d6a0"),2)
