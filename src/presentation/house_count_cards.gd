extends Node
## Read-only cards. Frame snapshots prevent post-bank state leaking into scoring.
const Assets = preload("res://src/presentation/item_assets.gd")
const Rows = preload("res://src/presentation/ability_score_rows.gd")
const Events = preload("res://src/presentation/ability_events.gd")
var lab: Control
var trophy_count := 0
var rally_lit := false
var rally_score := 0
var rally_target := 0
var frame_trophies := 0
var landed := false
var explanation_frame := -1
var cards: HBoxContainer
var trophy: PanelContainer
var rally: PanelContainer
var trophy_text: Label
var rally_text: Label
var trophy_icons: Control
var rally_icon: TextureRect
var shop_card: PanelContainer
var shop_text: Label
func _card(id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",Assets.slot(id,"rarity_treatment"))
	var row := HBoxContainer.new()
	panel.add_child(row)
	var icon := TextureRect.new()
	icon.texture = Assets.slot(id,"icon")
	icon.custom_minimum_size = Vector2(36,36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)
	var text := Label.new()
	text.add_theme_font_size_override("font_size",15)
	row.add_child(text)
	return panel
func _ready() -> void:
	cards = HBoxContainer.new()
	var box: Node = lab.score_panel.header.get_parent().get_parent()
	box.add_child(cards)
	box.move_child(cards,1)
	trophy = _card("charm.trophy_case")
	rally = _card("charm.late_rally")
	cards.add_child(trophy)
	cards.add_child(rally)
	trophy_text = trophy.get_child(0).get_child(1)
	rally_text = rally.get_child(0).get_child(1)
	rally_icon = rally.get_child(0).get_child(0)
	trophy_icons = preload("res://src/presentation/trophy_marks.gd").new()
	trophy.get_child(0).add_child(trophy_icons)
	shop_card = _card("charm.trophy_case")
	shop_text = shop_card.get_child(0).get_child(1)
	lab.shop_panel._main.add_child(shop_card)
	cards.hide()
	shop_card.hide()
	lab.score_panel.step_revealed.connect(_step)
func _step(_step_data: Dictionary, index: int, _skipped: bool) -> void:
	if lab.scored_frames.is_empty(): return
	var scored: Dictionary = lab.scored_frames[-1]
	if not scored.has("frame"): return
	if index == 0:
		explanation_frame = lab.frame_number
		frame_trophies = 0
		landed = false
		for entry in scored.frame.get("charms",[]):
			if entry.item_id == "charm.trophy_case": frame_trophies = int(entry.get("growth",0))
	var row := Rows.at(scored,index)
	if row.has("event"):
		var event: Dictionary = row.event
		if event.get("phase","") == "after_bank" and event.get("op","") == "grow_value" and Events.owner(scored.frame,event.get("source","")) == "charm.trophy_case":
			frame_trophies += int(event.get("amount",0))
			landed = true
	_refresh()
func _process(_delta: float) -> void: _refresh()
func _refresh() -> void:
	if lab.run == null or lab.division == null: return
	var entries: Array = lab.run.charms.filter(func(e): return e.item_id == "charm.trophy_case")
	trophy.visible = not entries.is_empty()
	rally.visible = lab.run.charms.any(func(e): return e.item_id == "charm.late_rally")
	cards.visible = trophy.visible or rally.visible
	shop_card.visible = trophy.visible and lab.state == "shop"
	var saved := int(entries[0].growth) if not entries.is_empty() else 0
	var context: Dictionary = lab.frame_context()
	var explaining: bool = lab.state in ["scoring","frame_done","result"] and not lab.scored_frames.is_empty() and lab.scored_frames[-1].has("frame")
	if explaining: context = lab.scored_frames[-1].frame.get("context",{})
	trophy_count = frame_trophies if explaining and explanation_frame == lab.frame_number else saved
	trophy_text.text = "Trophies: %d%s" % [trophy_count,"\n+1 after bank" if explaining and landed else ""]
	trophy_icons.count = trophy_count
	trophy_icons.queue_redraw()
	shop_text.text = "Trophy Case · %d trophies" % saved
	rally_score = int(context.get("match_score",0))
	rally_target = int(context.get("match_target",0))
	rally_lit = eligible(context)
	rally_text.text = "Late Rally %s\n%d / %s half target" % ["ON" if rally_lit else "off",rally_score,str(rally_target/2.0).trim_suffix(".0")]
	rally.tooltip_text = "Pre-bank score / half the match target"
	rally_icon.modulate = Color.WHITE if rally_lit else Color(0.3,0.3,0.3,1)

static func eligible(context: Dictionary) -> bool:
	return int(context.get("match_frame",0)) == 2 and int(context.get("match_target",0)) > 0 and int(context.get("match_score",0))*2 < int(context.get("match_target",0))
