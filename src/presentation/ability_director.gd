extends Node
## Read-only bridge from authoritative presentation steps to authored cues.
const Assets = preload("res://src/presentation/item_assets.gd")
var lab: Control
var glyph: Control
var intro_glyph: Control
var history: Array = []
var _boss := ""
var _projected := {}
var _settlement := -1
var shop_glyph: Control
var growth_label: Label
var growth_row: HBoxContainer
func _ready() -> void:
	name = "AbilityDirector"
	glyph = preload("res://src/presentation/ability_glyph.gd").new()
	lab.score_panel.header.get_parent().add_child(glyph)
	intro_glyph = preload("res://src/presentation/ability_glyph.gd").new()
	intro_glyph.position = Vector2(8,4)
	intro_glyph.size = Vector2(64,64)
	lab.hud.intro_button.add_child(intro_glyph)
	growth_row = HBoxContainer.new()
	growth_row.name = "GrowthPresentation"
	growth_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.shop_panel._main.add_child(growth_row)
	lab.shop_panel._main.move_child(growth_row,2)
	shop_glyph = preload("res://src/presentation/ability_glyph.gd").new()
	growth_row.add_child(shop_glyph)
	growth_label = Label.new()
	growth_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	growth_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	growth_label.add_theme_font_size_override("font_size",20)
	growth_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	growth_row.add_child(growth_label)
	growth_row.hide()
	lab.score_panel.step_revealed.connect(_step)
func _process(_delta: float) -> void:
	glyph.enabled = lab.motion.sound.enabled
	intro_glyph.enabled = lab.motion.sound.enabled
	shop_glyph.enabled = lab.motion.sound.enabled
	if lab.state == "shop" and int(lab.settlement.get("match",-1)) != _settlement:
		_settlement = int(lab.settlement.get("match",-1))
		growth_label.text = ""
		for growth in lab.settlement.get("grown",[]):
			if growth.item_id != "charm.patient_investor": continue
			cue(growth.item_id,"match_growth",false)
			shop_glyph.show_cue(Assets.slot(growth.item_id,"activation"),lab.settings.reduced_motion or lab.settings.reduced_flash,Assets.slot(growth.item_id,"icon"))
			growth_label.text += "Patient Investor · growth +%d after match %d" % [int(growth.amount),_settlement]
		growth_row.visible = not growth_label.text.is_empty()
	if lab.division == null: return
	var rule: String = lab.division.rival_for(lab.division.current()).get("rule", "") if lab.division.is_boss() else ""
	if rule != _boss:
		_boss = rule
		if not rule.is_empty(): cue(rule,"encounter",false)
func cue(id: String, event: String, skipped: bool) -> void:
	var recipe := Assets.slot(id,"activation")
	if recipe == null: return
	history.append({"id":id,"event":event,"skipped":skipped})
	if history.size() > 512: history.pop_front()
	if skipped: return
	glyph.show_cue(recipe,lab.settings.reduced_motion or lab.settings.reduced_flash,Assets.slot(id,"icon"))
	if event == "encounter": intro_glyph.show_cue(recipe,lab.settings.reduced_motion or lab.settings.reduced_flash,Assets.slot(id,"icon"))
	lab.motion.sound.cue(id,Assets.slot(id,"sound"),recipe.priority)
func _step(step: Dictionary, index: int, skipped: bool) -> void:
	if index == 0: _projected.clear()
	if step.phase == "rule" and not _boss.is_empty(): cue(_boss,"bank_rule",skipped)
	if lab.scored_frames.is_empty(): return
	var scored: Dictionary = lab.scored_frames[-1]
	if not scored.has("frame") or index >= scored.result.get("events",[]).size(): return
	var event: Dictionary = scored.result.events[index]
	for activation in preload("res://src/presentation/ability_events.gd").project(scored.frame,event):
		if _projected.has(activation.key): continue
		_projected[activation.key] = true
		cue(activation.id,activation.phase,skipped)
