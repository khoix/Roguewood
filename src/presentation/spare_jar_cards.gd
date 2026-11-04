extends Node
## Presentation-only observer; never writes inventory or the score panel's state.
const Assets = preload("res://src/presentation/item_assets.gd")
const Rows = preload("res://src/presentation/ability_score_rows.gd")
const Marks = preload("res://src/presentation/spare_jar_marks.gd")
var lab: Control
var state = preload("res://src/presentation/spare_jar_state.gd").new()
var frame_key := ""
var count := 0
var score_card: PanelContainer
var shop_card: PanelContainer
var score_text: Label
var shop_text: Label
var score_marks: Control
var shop_marks: Control
var strip_marks: Control
var strip_text: Label
func _card() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",Assets.slot("charm.spare_jar","rarity_treatment"))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	row.add_child(Marks.new())
	var text := Label.new()
	text.add_theme_font_size_override("font_size",16)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	return panel
func _ready() -> void:
	score_card = _card()
	var box: Node = lab.score_panel.header.get_parent().get_parent()
	box.add_child(score_card)
	box.move_child(score_card,1)
	score_marks = score_card.get_child(0).get_child(0)
	score_text = score_card.get_child(0).get_child(1)
	shop_card = _card()
	lab.shop_panel._main.add_child(shop_card)
	shop_marks = shop_card.get_child(0).get_child(0)
	shop_text = shop_card.get_child(0).get_child(1)
	score_card.hide()
	shop_card.hide()
	lab.score_panel.step_revealed.connect(_step)
func _sync(scored: Dictionary) -> void:
	var key := "%s:%s:%s" % [lab.run.get_instance_id(),lab.frame_number,lab.scored_frames.size()]
	if key == frame_key: return
	frame_key = key
	state.begin(scored.frame)
	score_marks.drop_age = 2.0
func _step(_data: Dictionary, index: int, skipped: bool) -> void:
	if lab.scored_frames.is_empty() or not lab.scored_frames[-1].has("frame"): return
	var scored: Dictionary = lab.scored_frames[-1]
	_sync(scored)
	var row := Rows.at(scored,index)
	if row.has("event") and state.reveal(scored.frame,row.event,int(row.event_index)):
		score_marks.drop_age = 2.0 if skipped else 0.0
	_refresh()
func _process(_delta: float) -> void: _refresh()
func _refresh() -> void:
	if lab.run == null: return
	var entries: Array = lab.run.charms.filter(func(e): return e.item_id == "charm.spare_jar")
	score_card.visible = not entries.is_empty()
	shop_card.visible = not entries.is_empty() and lab.state == "shop"
	var saved := int(entries[0].growth) if not entries.is_empty() else 0
	var explaining: bool = lab.state in ["scoring","frame_done"] and not lab.scored_frames.is_empty() and lab.scored_frames[-1].has("frame")
	if explaining: _sync(lab.scored_frames[-1])
	count = state.count if explaining else saved
	score_text.text = "Spare Jar · %d pins%s" % [count,"\n+%d after bank · next frame" % state.added if explaining and state.added > 0 else ""]
	shop_text.text = "Spare Jar · %d pins" % saved
	score_marks.count = count
	score_marks.reduced = lab.settings.reduced_motion or lab.settings.reduced_flash
	shop_marks.count = saved
	# Attach to the actual read-only inventory card, rebuilt by EquipmentArtStrip.
	var body: Node = lab.motion.equipment_art.get_node_or_null("charm_spare_jar/Body")
	if body != null:
		if not is_instance_valid(strip_marks) or strip_marks.get_parent() != body:
			strip_marks = Marks.new()
			body.add_child(strip_marks)
			strip_text = Label.new()
			strip_text.add_theme_font_size_override("font_size",16)
			strip_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			strip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
			body.add_child(strip_text)
		strip_marks.count = saved
		strip_text.text = "%d pins" % saved
