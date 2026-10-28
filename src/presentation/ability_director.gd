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
var world_glyphs: Array[Control] = []
var _lane_id := 0
var _fallen := 0
var _hook := false
var _hammer := false
var _rubber := {}
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
	for i in 4:
		var marker: Control = preload("res://src/presentation/ability_glyph.gd").new()
		marker.size = Vector2(64,64)
		lab.motion.add_child(marker)
		world_glyphs.append(marker)
	lab.score_panel.step_revealed.connect(_step)
func _process(_delta: float) -> void:
	_physical()
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

func _physical() -> void:
	for marker in world_glyphs:
		marker.enabled = lab.motion.sound.enabled
		marker.visible = lab.state == "rolling" and not lab.settings_panel.visible
	if lab.lane == null: return
	if lab.lane.get_instance_id() != _lane_id:
		_lane_id = lab.lane.get_instance_id()
		_fallen = 0
		_hook = false
		_hammer = false
		_rubber.clear()
	if lab.state != "rolling": return
	var launch: Dictionary = lab.lane.launch
	var ball_id: String = launch.get("ball_id","")
	if ball_id == "ball.hook" and not _hook and preload("res://src/simulation/lane_spec.gd").is_curved(float(launch.get("spin",0))):
		_hook = true
		_world_cue(ball_id,"committed_curve",lab.screen_point(lab.lane.ball_position()))
	for position in lab.lane.pins:
		var pin: RigidBody3D = lab.lane.pins[position]
		if lab.run.rack[position].item_id == "pin.rubber" and not _rubber.has(position) and pin.linear_velocity.length() > 0.1:
			if pin.get_colliding_bodies().any(func(body): return body is RigidBody3D):
				_rubber[position] = true
				_world_cue("pin.rubber","physical_contact",lab.screen_point(pin.global_position))
	var sequence: Array = lab.lane.tracker.sequence
	for i in range(_fallen,sequence.size()):
		var position: int = sequence[i]
		var id: String = lab.run.rack[position].item_id
		var point: Vector2 = lab.screen_point(lab.lane.pins[position].global_position)
		if ball_id == "ball.hammer" and not _hammer:
			_hammer = true
			_world_cue(ball_id,"physical_impact",point)
		if id in ["pin.wood","pin.ruby"]: _world_cue(id,"physical_knockdown",point)
	_fallen = sequence.size()
func _world_cue(id: String, event: String, point: Vector2) -> void:
	var recipe := Assets.slot(id,"activation")
	if recipe == null: return
	cue(id,event,false)
	var selected: Control
	for marker in world_glyphs:
		if marker.style == null or marker.age > marker.style.duration:
			selected = marker
			break
	if selected == null:
		for marker in world_glyphs:
			if marker.style.priority < recipe.priority: selected = marker; break
	if selected == null: return
	selected.position = (point-Vector2(32,32)).clamp(Vector2.ZERO,lab.size-Vector2(64,64))
	selected.show_cue(recipe,lab.settings.reduced_motion or lab.settings.reduced_flash,Assets.slot(id,"icon"))
