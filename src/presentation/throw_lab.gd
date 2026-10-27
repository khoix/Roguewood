extends Control
## Throw lab (E04 straight, E05 spin/curve, E06 scoring, E07 equipment, E08 shop,
## E09 Division): elevated
## behind-ball camera, hold / circle / flick gestures, a movable contracting target
## ring, accessible controls and a two-roll frame where survivors are respotted,
## then scored by FrameRules and explained step by step. The equipment row plays
## special balls and tactical cards from the experimental deck or the direct
## selection model (ADR 004); House is thrown when nothing is armed. A Division
## (ADR 006) runs an opener, a feature and a rival boss, each a posted target in two
## frames; won matches are paid and visit the Pro Shop (ADR 005), and what the run
## owns (rack, Charms, deck, modifications) is what scores. Practice drops the
## targets. Every roll
## runs in a fresh World3D so it depends only on its rack state and committed
## launch. Developmental presentation.
signal roll_reported(report: Dictionary)
signal frame_scored(scored: Dictionary)
signal money_changed(money: int)
signal attempt_finished(outcome: String)
signal retry_requested
signal menu_requested
const Lane = preload("res://src/simulation/lane_spec.gd")
const LaneWorld = preload("res://src/simulation/lane_world.gd")
const Dressing = preload("res://src/presentation/lane_dressing.gd")
const AimOverlay = preload("res://src/presentation/aim_overlay.gd")
const SettingsPanel = preload("res://src/presentation/throw_settings_panel.gd")
const AssistPanel = preload("res://src/presentation/assist_panel.gd")
const Flick = preload("res://src/input/flick_gesture.gd")
const Mapper = preload("res://src/input/launch_mapper.gd")
const Ring = preload("res://src/input/target_ring.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const FrameBuilder = preload("res://src/rules/frame_builder.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
const ScorePanel = preload("res://src/presentation/score_panel.gd")
const CardHand = preload("res://src/presentation/card_hand.gd")
const Deck = preload("res://src/rules/card_deck.gd")
const Direct = preload("res://src/rules/direct_loadout.gd")
const Economy = preload("res://src/rules/economy.gd")
const RunInventory = preload("res://src/rules/run_inventory.gd")
const Shop = preload("res://src/rules/shop.gd")
const ShopPanel = preload("res://src/presentation/shop_panel.gd")
const Division = preload("res://src/rules/division_run.gd")
const RivalRules = preload("res://src/rules/rival_rules.gd")
const Reactions = preload("res://src/presentation/rival_reactions.gd")
const DivisionHud = preload("res://src/presentation/division_hud.gd")
const DIVISION_SPEC := "res://content/fixtures/lab_division.json"
const NEAR_VICTORY := 0.75 # share of the target that makes a rival nervous
## Lab starting kit (fixture items, not the production kit): ten Wood pins and a deck
## of two copies of three lab ball types plus one tactical card. Direct selection
## shows the first two ball types and the tactical cards of the same collection.
const LAB_DECK := ["ball.lab_value", "ball.lab_value", "ball.lab_mult", "ball.lab_mult", "ball.lab_coin", "ball.lab_coin", "consumable.lab_focus"]
const LAB_RACK := ["pin.wood", "pin.wood", "pin.wood", "pin.wood", "pin.wood", "pin.wood", "pin.wood", "pin.wood", "pin.wood", "pin.wood"]
const LAB_DIVISION := 1
const HOUSE := "ball.house"
const LANDSCAPE_HAND_WIDTH := 440.0
const RESULT_HOLD_SEC := 1.2
const AIM_BACK := 2.0
const AIM_HEIGHT := 1.05
const DECK_VIEW_F := Lane.HEAD_PIN_F - 4.0
const TOP_UI_HEIGHT := 96.0 # session bar band; touches there are never throws
const RING_COLORS := {"clean": Color(1.0, 1.0, 1.0), "sweet": Color(0.3, 0.95, 0.85), "perfect": Color(1.0, 0.8, 0.2)}

var state := "aim"
var frame_number := 1
var roll_index := 1
var rack: Dictionary = Lane.fresh_rack()
var start_x := 0.0
var target_x := Lane.DEFAULT_TARGET_X
var ring_radius := Ring.RING_MAX
var frame_reports: Array = []
var history: Array = []
var trials: Array = []
var cancels := 0
var last_cancel := ""
var last_source := ""
var settings: Dictionary = {}
var trial_log_path := "user://throw_trials.jsonl"
var lane: LaneWorld
var status: Label
var next_rack: Button
var settings_panel: SettingsPanel
var assist_panel: AssistPanel
var score_panel: ScorePanel
var total_score := 0
var scored_frames: Array = []
var _catalogue: Dictionary = {}
var _names: Dictionary = {}
var _viewport: SubViewport
var _camera: Camera3D
var _marker: MeshInstance3D
var _dressing := Dressing.new()
var _flick := Flick.new()
var _touch := -1
var _target_touch := -1
var _hold_source := "touch"
var _hold_start_x := 0.0
var _clock_usec := 0
var _ring_start_usec := 0
var _result_timer := 0.0
var _launch_serial := 0
var _last_input: Dictionary = {}
var _handedness := ""
var equipment: RefCounted # CardDeck or DirectLoadout
var equipment_seed := 1
var card_hand: CardHand
var armed_ball := "" # card uid (deck) or item id (direct); empty throws House
var armed_tactical := ""
var keep_card := ""
var cycling := false
var frame_tactics: Dictionary = {} # roll index -> tactical item ids
var match_number := 1
var match_frame := 1
var _equipment_model := ""
var _kept_last_frame := ""
var frame_mods: Dictionary = {} # roll index -> ball modification of the thrown card
var run: RunInventory
var shop: Shop
var shop_panel: ShopPanel
var settlement: Dictionary = {}
var shop_message := ""
var _choice: Dictionary = {} # pending shop choice: {kind, index, targets}
var division: Division
var division_spec: Dictionary = {}
var hud: DivisionHud
var reactions := Reactions.new()
## Career record shared by the shell across attempts this run (in memory until
## E10/E15 persist it): first_clears (rival id -> true), unlocked gates, intros_seen.
var career: Dictionary = {}
var attempt := 1

func _ready() -> void:
	SettingsPanel.with_defaults(settings)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var container := SubViewportContainer.new()
	container.name = "LaneView"
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(container)
	_viewport = SubViewport.new()
	container.add_child(_viewport)
	_camera = Camera3D.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.04, 0.1)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.52, 0.65)
	environment.ambient_light_energy = 0.7
	_camera.environment = environment
	_viewport.add_child(_camera)
	_camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, 25.0, 0.0)
	light.light_energy = 1.1
	_viewport.add_child(light)
	_build_ring()
	var overlay := AimOverlay.new()
	overlay.name = "AimOverlay"
	overlay.lab = self
	add_child(overlay)
	status = Label.new()
	status.name = "ThrowStatus"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 26)
	status.add_theme_color_override("font_outline_color", Color.BLACK)
	status.add_theme_constant_override("outline_size", 6)
	status.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	status.offset_top = TOP_UI_HEIGHT + 100.0 # below the Division match bar
	status.offset_left = 24
	status.offset_right = -24
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status)
	next_rack = Button.new()
	next_rack.name = "NextRack"
	next_rack.text = "Next Rack"
	next_rack.custom_minimum_size = Vector2(320, 72)
	next_rack.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	next_rack.position = Vector2(-160, -36)
	next_rack.pressed.connect(_next_rack)
	next_rack.hide()
	add_child(next_rack)
	_catalogue = Contracts.read_json(FrameBuilder.LAB_CATALOGUE)
	for entry in _catalogue.items:
		_names[entry.id] = entry.name
	run = RunInventory.create(_catalogue, LAB_RACK, LAB_DECK)
	shop = Shop.create(_catalogue, hash([equipment_seed, "shop"])) # its own stream, never the deck's
	for key in ["first_clears", "unlocked", "intros_seen"]:
		if not career.has(key):
			career[key] = {} if key != "unlocked" else []
	shop.unlocked = career.unlocked
	division_spec = Contracts.read_json(DIVISION_SPEC)
	var spec_errors := Division.validate_spec(division_spec, _catalogue)
	if not spec_errors.is_empty():
		push_error("Division spec invalid: " + str(spec_errors))
	division = Division.create(division_spec, settings.get("practice", false))
	score_panel = ScorePanel.new()
	score_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	score_panel.offset_top = -540.0
	score_panel.offset_left = 16.0
	score_panel.offset_right = -16.0
	score_panel.offset_bottom = -16.0
	score_panel.finished.connect(_on_scored)
	score_panel.speed_changed.connect(func(speed): settings.score_speed = speed)
	score_panel.hide()
	add_child(score_panel)
	card_hand = CardHand.new()
	card_hand.card_pressed.connect(_on_card)
	card_hand.cycle_pressed.connect(_on_cycle)
	add_child(card_hand)
	assist_panel = AssistPanel.new()
	assist_panel.throw_requested.connect(_assist_throw)
	assist_panel.preview_changed.connect(_assist_preview)
	add_child(assist_panel)
	shop_panel = ShopPanel.new()
	shop_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_panel.offset_top = TOP_UI_HEIGHT + 84.0 # below the Division match bar
	shop_panel.offset_left = 12.0
	shop_panel.offset_right = -12.0
	shop_panel.offset_bottom = -12.0
	shop_panel.offer_pressed.connect(_on_offer)
	shop_panel.reroll_pressed.connect(_on_reroll)
	shop_panel.remove_pressed.connect(_on_remove)
	shop_panel.sell_pressed.connect(_on_sell)
	shop_panel.continue_pressed.connect(_start_next_match)
	shop_panel.choice_made.connect(_on_choice)
	shop_panel.choice_cancelled.connect(_on_choice_cancelled)
	shop_panel.hide()
	add_child(shop_panel)
	hud = DivisionHud.new()
	add_child(hud)
	hud.layout(TOP_UI_HEIGHT, TOP_UI_HEIGHT + 300.0)
	hud.intro_done.connect(_on_intro_done)
	hud.retry_pressed.connect(func(): retry_requested.emit())
	hud.menu_pressed.connect(func(): menu_requested.emit())
	settings_panel = SettingsPanel.new()
	settings_panel.settings = settings
	settings_panel.changed.connect(_apply_settings)
	settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	settings_panel.hide()
	add_child(settings_panel)
	_apply_settings()
	_new_roll()

## The selected model over the run's card collection; the deck shuffles from the
## session seed. Direct selection is rebuilt every match (its uses are per match).
func _build_equipment() -> void:
	_equipment_model = settings.equipment
	if _equipment_model == "direct":
		var balls: Array = []
		var tacticals: Array = []
		var tactical_uids: Array = []
		for owned in run.entries():
			if not owned.ref.begins_with("card:"):
				continue
			var id: String = owned.entry.item_id
			if Deck.kind(id) == "ball" and id not in balls:
				balls.append(id)
			elif Deck.kind(id) == "tactical":
				tacticals.append(id)
				tactical_uids.append(owned.ref.trim_prefix("card:"))
		equipment = Direct.create(balls, tacticals, tactical_uids)
	else:
		equipment = Deck.create_with(run.deck_cards(), equipment_seed)
	equipment.start_frame()
	_clear_choices()

func _clear_choices() -> void:
	armed_ball = ""
	armed_tactical = ""
	keep_card = ""
	cycling = false

func _item_of(uid: String) -> String:
	return equipment.cards.get(uid, "") if equipment.MODEL == "deck" else equipment.tacticals.get(uid, uid)

func armed_ball_id() -> String:
	return HOUSE if armed_ball.is_empty() else _item_of(armed_ball)

func _on_card(uid: String) -> void:
	if state == "frame_done":
		if equipment.can_retain() and not division.match_over():
			keep_card = "" if keep_card == uid else uid
		_refresh_hand()
		return
	if state != "aim":
		return
	if cycling:
		var errors: Array[String] = equipment.cycle(uid)
		if errors.is_empty():
			if armed_ball == uid: armed_ball = ""
			if armed_tactical == uid: armed_tactical = ""
		cycling = false
	elif Deck.kind(_item_of(uid)) == "ball":
		armed_ball = "" if armed_ball == uid else uid
	else:
		armed_tactical = "" if armed_tactical == uid else uid
	_update_status()

## Cycle arms a one-card swap: the next card pressed is discarded and replaced.
func _on_cycle() -> void:
	if state == "aim" and equipment.can_cycle():
		cycling = not cycling
		_update_status()

func _refresh_hand() -> void:
	if card_hand == null or equipment == null:
		return
	var cards: Array = []
	for option in equipment.options():
		var item := FrameBuilder.item(_catalogue, option.item_id)
		var detail := _effect_text(item)
		if equipment.MODEL == "direct" and option.kind == "ball":
			detail += "\n%d left" % option.uses
		elif equipment.MODEL == "deck" and not run.card_mod(option.uid).is_empty():
			detail += "\n+ " + _names.get(run.card_mod(option.uid), "")
		cards.append({"uid": option.uid, "title": item.get("name", option.item_id), "detail": detail, "kind": option.kind})
	var marks := {}
	if not armed_ball.is_empty(): marks[armed_ball] = "ball"
	if not armed_tactical.is_empty(): marks[armed_tactical] = "tactical"
	if not keep_card.is_empty(): marks[keep_card] = "keep"
	var counts: Dictionary = equipment.counts()
	var header: String
	if equipment.MODEL == "deck":
		header = "Deck · draw %d · discard %d · used %d · House always ready" % [counts.draw, counts.discard, counts.exhausted]
		if state == "frame_done":
			header = "Tap one card to keep for next frame (optional)" if not division.match_over() else "Match over — the deck recombines and reshuffles"
		elif cycling:
			header = "Cycle: tap a card to discard it and draw one"
	else:
		header = "Bag · House always ready · specials %d uses left this match" % counts.special_uses
	var choosing: bool = state == "aim" or (state == "frame_done" and equipment.can_retain() and not division.match_over())
	card_hand.show_cards(cards, marks, header, equipment.MODEL == "deck", state == "aim" and equipment.can_cycle(), choosing)
	card_hand.cycle_button.text = "Cancel" if cycling else "Cycle"
	card_hand.visible = state not in ["scoring", "shop", "intro", "division_over"]
	# Bottom for thumbs while aiming; under the status line once the score panel is up.
	# Landscape keeps the ball clear: a narrow two-row panel away from the assist side.
	card_hand.set_anchors_preset(Control.PRESET_TOP_WIDE if state == "frame_done" else Control.PRESET_BOTTOM_WIDE)
	card_hand.offset_left = 16.0
	card_hand.offset_right = -16.0
	if size.x > size.y:
		var left: bool = settings.handedness != "left"
		card_hand.anchor_left = 0.0 if left else 1.0
		card_hand.anchor_right = card_hand.anchor_left
		card_hand.offset_left = 16.0 if left else -16.0 - LANDSCAPE_HAND_WIDTH
		card_hand.offset_right = card_hand.offset_left + LANDSCAPE_HAND_WIDTH
	if state == "frame_done":
		card_hand.grow_vertical = Control.GROW_DIRECTION_END
		card_hand.offset_top = TOP_UI_HEIGHT + 170.0
		card_hand.offset_bottom = TOP_UI_HEIGHT + 170.0
	else:
		card_hand.grow_vertical = Control.GROW_DIRECTION_BEGIN
		card_hand.offset_top = -16.0
		card_hand.offset_bottom = -16.0

static func _effect_text(item: Dictionary) -> String:
	var parts: Array = []
	for effect in item.get("effects", []):
		match effect.op:
			"add_value": parts.append("+%s Value" % ScoreLog._n(effect.amount))
			"add_mult": parts.append("+%s Mult" % ScoreLog._n(effect.amount))
			"multiply_mult": parts.append("×%s Mult" % ScoreLog._n(effect.amount))
			"payout": parts.append("+$%s" % ScoreLog._n(effect.amount))
	if item.get("category", "") == "consumable":
		parts.append("once")
	return " ".join(parts) if not parts.is_empty() else "—"

## In-world target marker; the readable ring itself is drawn by the aim overlay.
func _build_ring() -> void:
	var arrow := PrismMesh.new()
	arrow.size = Vector3(0.12, 0.14, 0.03)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = true
	_marker = MeshInstance3D.new()
	_marker.name = "TargetMarker"
	_marker.mesh = arrow
	_marker.material_override = material
	_marker.rotation_degrees = Vector3(0.0, 0.0, 180.0)
	_viewport.add_child(_marker)

func _new_roll() -> void:
	if lane:
		_viewport.remove_child(lane)
		lane.free()
	# Keep the old world alive until the viewport has detached from its scenario.
	var retired := _viewport.world_3d
	_viewport.world_3d = World3D.new()
	retired = null
	lane = LaneWorld.new()
	lane.name = "Lane"
	_viewport.add_child(lane)
	lane.setup(rack, _dressing)
	lane.roll_finished.connect(_on_roll_finished)
	start_x = assist_panel.values().start_x if settings.assist else 0.0
	lane.place_ball(start_x)
	state = "aim"
	_ring_start_usec = _clock_usec
	_camera.position = Lane.world(0.0, Lane.BALL_START_F - AIM_BACK, AIM_HEIGHT)
	_camera.look_at(Lane.world(0.0, 11.0, 0.0))
	_update_status()

func _apply_settings() -> void:
	if settings.handedness != _handedness:
		_handedness = settings.handedness
		target_x = Ring.default_target(_handedness)
		assist_panel.set_target(target_x)
	_flick.sensitivity = settings.sensitivity
	assist_panel.visible = settings.assist
	var left: bool = settings.handedness == "left"
	assist_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT if left else Control.PRESET_CENTER_RIGHT)
	assist_panel.offset_left = 12.0 if left else -312.0
	assist_panel.offset_right = 312.0 if left else -12.0
	assist_panel.offset_top = -40.0
	assist_panel.offset_bottom = 330.0
	if settings.assist and state == "aim" and lane:
		_assist_preview(assist_panel.values())
	# Practice applies to an attempt that has not thrown yet, otherwise to the next attempt.
	if division != null and settings.get("practice", false) != division.practice and history.is_empty():
		division = Division.create(division_spec, settings.practice)
	if hud != null:
		hud.reduced_motion = settings.reduced_motion
	# A model switch applies now at the very start of a match, otherwise at the next match.
	if settings.equipment != _equipment_model and (equipment == null or (state == "aim" and roll_index == 1 and match_frame == 1)):
		_build_equipment()
	_update_status()

func toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	if settings_panel.visible:
		settings_panel.handedness.grab_focus()

func _process(delta: float) -> void:
	_clock_usec += int(round(delta * 1000000.0))
	_camera.keep_aspect = Camera3D.KEEP_WIDTH if size.y > size.x else Camera3D.KEEP_HEIGHT
	_camera.fov = 44.0 if size.y > size.x else 50.0
	if state in ["rolling", "result", "frame_done"]:
		var ball_f: float = -lane.ball_position().z
		var cam_f := clampf(ball_f - 2.6, Lane.BALL_START_F - AIM_BACK, DECK_VIEW_F)
		var target := Lane.world(0.0, cam_f, lerpf(AIM_HEIGHT, 1.25, inverse_lerp(0.0, DECK_VIEW_F, cam_f)))
		_camera.position = _camera.position.lerp(target, 1.0 - exp(-8.0 * delta))
		_camera.look_at(Lane.world(0.0, minf(_camera.position.z * -1.0 + 6.0, Lane.HEAD_PIN_F + 0.35), 0.12))
	if hud != null and hud.reaction.visible and reactions.visible_at(_clock_usec).is_empty():
		hud.hide_reaction()
	var ringing: bool = state == "holding" or (state == "aim" and settings.assist)
	ring_radius = Ring.radius(_clock_usec - _ring_start_usec, settings.reduced_motion) if ringing else Ring.RING_MAX
	_update_ring()
	assist_panel.visible = settings.assist and state == "aim"
	if state == "holding" and not settings.reduced_motion and lane.state == "ready":
		lane.aim_ball.rotate(Vector3.FORWARD, _flick.charge() * 12.0 * delta)
	if state == "result":
		_result_timer += delta
		if _result_timer >= RESULT_HOLD_SEC:
			_advance()

func _update_ring() -> void:
	_marker.visible = state in ["aim", "holding"]
	if _marker.visible:
		_marker.position = Lane.world(target_x * Lane.LANE_HALF_WIDTH, Lane.TARGET_PLANE_F, 0.55)
		(_marker.material_override as StandardMaterial3D).albedo_color = ring_color()

func ring_color() -> Color:
	return RING_COLORS[Ring.grade(ring_radius)]

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and state == "aim" and _touch == -1 and _target_touch == -1 and not _over_ui(event.position):
			if _on_ball(event.position) and not settings.assist:
				_touch = event.index
				_hold_source = "mouse" if event.device == InputEvent.DEVICE_ID_EMULATION else "touch"
				_hold_start_x = start_x
				_ring_start_usec = _clock_usec
				_flick.begin(_normalized(event.position), _clock_usec)
				state = "holding"
				_update_status()
			elif _in_target_zone(event.position):
				_target_touch = event.index
				_set_target_from(event.position)
			else:
				return
		elif not event.pressed and state == "holding" and event.index == _touch:
			if event.canceled:
				_cancel("touch_canceled")
			else:
				_release(event.position)
		elif not event.pressed and event.index == _target_touch:
			_target_touch = -1
		else:
			return
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if state == "holding" and event.index == _touch:
			_flick.move(_normalized(event.position), _clock_usec)
			lane.place_ball(_placed_x(_flick.placement(), _flick.origin))
		elif state == "aim" and event.index == _target_touch:
			_set_target_from(event.position)
		else:
			return
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_refresh_hand()
	if state == "holding" and what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		_cancel("interrupted")

func _release(position: Vector2) -> void:
	var origin := _flick.origin
	var frozen := Ring.radius(_clock_usec - _ring_start_usec, settings.reduced_motion)
	var flick := _flick.release(_normalized(position), _clock_usec)
	if not flick.committed:
		_cancel(flick.reason)
		return
	var x := _placed_x(flick.placement, origin)
	var launch := Mapper.to_launch(flick, x, "lab-%d" % (_launch_serial + 1), roll_index, target_x, frozen, armed_ball_id())
	_last_input = {"source": _hold_source, "speed": flick.speed, "screen_angle_deg": flick.angle_deg, "turn_deg": flick.turn_deg,
		"spin": flick.spin, "power": flick.power}
	_commit(launch, _hold_source)

func _assist_throw(controls: Dictionary) -> void:
	if state != "aim" or not settings.assist:
		return
	target_x = controls.target_x
	var frozen := Ring.radius(_clock_usec - _ring_start_usec, settings.reduced_motion)
	var launch := Mapper.from_controls(controls, "lab-%d" % (_launch_serial + 1), roll_index, target_x, frozen, armed_ball_id())
	_last_input = {"source": "assist", "controls": controls.duplicate()}
	_commit(launch, "assist")

func _assist_preview(controls: Dictionary) -> void:
	if state != "aim":
		return
	start_x = controls.start_x
	target_x = controls.target_x
	lane.place_ball(start_x)

func _commit(launch: Dictionary, source: String) -> void:
	var errors := lane.commit(launch)
	if not errors.is_empty():
		push_error("Rejected lab launch: " + str(errors))
		_cancel("rejected")
		return
	_launch_serial += 1
	start_x = launch.start_x
	_play_armed()
	_touch = -1
	last_cancel = ""
	last_source = source
	state = "rolling"
	_update_status()

## Committed cards are spent exactly once; a cancelled or rejected throw spends none.
func _play_armed() -> void:
	_last_input.equipment = {"model": equipment.MODEL, "ball_id": armed_ball_id(), "card": armed_ball, "tactical": null,
		"hand": equipment.options().map(func(o): return o.item_id), "cycled": equipment.MODEL == "deck" and equipment.cycled,
		"kept": _kept_last_frame, "counts": equipment.counts()}
	if not armed_ball.is_empty():
		var errors: Array[String] = equipment.play(armed_ball, roll_index)
		if not errors.is_empty():
			push_error("Ball card not played: " + str(errors))
		elif equipment.MODEL == "deck" and not run.card_mod(armed_ball).is_empty():
			frame_mods[roll_index] = run.card_mod(armed_ball)
			_last_input.equipment.mod = frame_mods[roll_index]
	if not armed_tactical.is_empty():
		var tactical_id := _item_of(armed_tactical)
		var errors: Array[String] = equipment.play(armed_tactical, roll_index)
		if errors.is_empty():
			frame_tactics[roll_index] = [tactical_id]
			_last_input.equipment.tactical = tactical_id
		else:
			push_error("Tactical card not played: " + str(errors))
	armed_ball = ""
	armed_tactical = ""
	cycling = false

## Cancelling restores the pre-gesture ball and consumes no roll or launch.
func _cancel(reason: String) -> void:
	_flick.cancel()
	_touch = -1
	start_x = _hold_start_x
	lane.place_ball(start_x)
	lane.aim_ball.rotation = Vector3.ZERO
	cancels += 1
	last_cancel = reason
	state = "aim"
	_update_status()

func _on_roll_finished(report: Dictionary) -> void:
	frame_reports.append(report)
	history.append(report)
	_log_trial(report)
	if report.knockdown_log.gutter:
		_react("gutter")
	elif report.roll_result.roll_index == 1 and report.roll_result.fallen_positions.size() == 10:
		_react("strike")
	state = "result"
	_result_timer = 0.0
	_update_status()
	roll_reported.emit(report)

## One JSON line per committed roll: what the player did and what happened. Device
## trials (docs/playtests) read this file; nothing here affects play.
func _log_trial(report: Dictionary) -> void:
	var hook := Lane.hook_at_target(report.launch, report.knockdown_log)
	var entry := {"schema_version": 1, "clock_usec": _clock_usec, "frame": frame_number, "roll": roll_index, "input": _last_input,
		"launch": report.launch, "curved": Lane.is_curved(report.launch.spin), "hook_m": null if is_nan(hook) else hook,
		"fallen": report.roll_result.fallen_positions, "standing": report.knockdown_log.standing, "gutter": report.knockdown_log.gutter,
		"accuracy": report.roll_result.accuracy, "settings": settings.duplicate(), "viewport": [size.x, size.y]}
	trials.append(entry)
	if trial_log_path.is_empty():
		return
	var file := FileAccess.open(trial_log_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(trial_log_path, FileAccess.WRITE)
	if file == null:
		push_warning("Trial log unavailable: " + trial_log_path)
		return
	file.seek_end()
	file.store_line(JSON.stringify(entry, "", true, true))

func _advance() -> void:
	var report: Dictionary = frame_reports[-1]
	if roll_index == 1 and not report.knockdown_log.standing.is_empty():
		roll_index = 2
		rack = report.rack_after
		_new_roll()
	else:
		_score_frame()

## Scores the completed frame from its roll reports and plays the explanation.
func _score_frame() -> void:
	var extras := {}
	for roll in [1, 2]:
		var played: Array = ([frame_mods[roll]] if frame_mods.has(roll) else []) + frame_tactics.get(roll, [])
		if not played.is_empty():
			extras[roll] = played
	var built := FrameBuilder.build(run.loadout(), _catalogue, frame_reports, extras)
	var result := Rules.resolve(built.frame) if built.ok else {"ok": false, "errors": built.errors}
	if not result.ok:
		push_error("Frame could not be scored: " + str(result.errors))
		_frame_done()
		return
	var steps := ScoreLog.steps(result, built.frame, _names, built.owners)
	# A rival's rule decides what the match banks; the calculation above stays as resolved.
	var banked: Dictionary = RivalRules.bank(division.rules(), result)
	for note in banked.notes:
		steps.append({"phase": "rule", "symbol": "✕", "pin": 0, "text": note, "pin_value": steps[-1].pin_value, "mult": steps[-1].mult, "score": banked.score})
	var income := run.credit_frame(result, built.frame)
	var outcome: Dictionary = division.record_frame(banked.score)
	scored_frames.append({"frame_number": frame_number, "match_number": match_number, "frame": built.frame, "result": result, "steps": steps,
		"income": income, "money": run.money, "banked": banked.score, "match_score": division.match_score, "match_over": outcome.over, "match_won": outcome.won})
	money_changed.emit(run.money)
	state = "scoring"
	_update_status()
	score_panel.play(steps, frame_reports, "Frame %d — %s" % [frame_number, String(result.category).capitalize()], int(settings.score_speed))

func _on_scored() -> void:
	var scored: Dictionary = scored_frames[-1]
	total_score += int(scored.banked)
	if scored.match_over:
		_react("victory" if scored.match_won else "defeat")
	elif not division.practice and division.match_score >= NEAR_VICTORY * division.target():
		_react("near_victory")
	elif scored.result.category == "open":
		_react("open")
	_frame_done()
	frame_scored.emit(scored.duplicate(true))

func _frame_done() -> void:
	state = "frame_done"
	next_rack.text = "Next Rack"
	if division.match_over():
		if division.outcome == "lost":
			next_rack.text = "See Result"
		elif division.outcome == "won":
			next_rack.text = "Division Result"
		else:
			next_rack.text = "Collect & Shop"
	next_rack.show()
	next_rack.grab_focus()
	_update_status()

func _next_rack() -> void:
	if state != "frame_done":
		return
	if division.match_over():
		if division.is_finished():
			_show_result()
		else:
			_open_shop()
		return
	_kept_last_frame = _item_of(keep_card) if not keep_card.is_empty() else ""
	_advance_frame()
	match_frame += 1
	var errors: Array[String] = equipment.start_frame(keep_card)
	if not errors.is_empty():
		push_error("Frame start: " + str(errors))
	_clear_choices()
	_new_roll()

func _advance_frame() -> void:
	frame_number += 1
	roll_index = 1
	frame_reports = []
	frame_tactics = {}
	frame_mods = {}
	rack = Lane.fresh_rack()
	next_rack.hide()
	score_panel.hide()

## A won match: used tactical cards leave the run, interest and the payout (with
## its unused-frame bonus) are paid, and the Pro Shop opens with the next match,
## and the rival's rule, on show before anything is bought.
func _open_shop() -> void:
	run.drop_consumed(equipment.exhausted.duplicate())
	settlement = run.settle_match(int(division.results[-1].frames))
	shop.open_visit(run, int(division_spec.get("division", LAB_DIVISION)))
	shop_message = ""
	state = "shop"
	next_rack.hide()
	score_panel.hide()
	shop_panel.show()
	_refresh_shop()
	shop_panel.continue_button.grab_focus()
	_update_status()
	money_changed.emit(run.money)

func _start_next_match() -> void:
	if state != "shop" or not _choice.is_empty():
		return
	shop_panel.hide()
	_kept_last_frame = ""
	_advance_frame()
	match_number += 1
	match_frame = 1
	division.next_match()
	if settings.equipment != _equipment_model or _equipment_model == "direct":
		_build_equipment()
	else:
		equipment.sync(run.deck_cards())
		equipment.start_match()
		equipment.start_frame()
	_clear_choices()
	_new_roll()
	if division.is_boss():
		_show_intro()

## The rival's entrance before the boss match: skippable, shorter once seen.
func _show_intro() -> void:
	var rival: Dictionary = division.rival()
	var seen: bool = career.intros_seen.has(rival.id)
	career.intros_seen[rival.id] = true
	state = "intro"
	hud.show_intro(rival, division.target(), RivalRules.summary(rival.rule), rival.first_clear.text, seen)
	_update_status()

func _on_intro_done() -> void:
	if state != "intro":
		return
	state = "aim"
	_ring_start_usec = _clock_usec
	_react("entrance")
	_update_status()

## Rival reactions during the boss match only; they never pause or block input.
func _react(event: String) -> void:
	if division == null or not division.is_boss():
		return
	var key: String = reactions.react(event, _clock_usec)
	if not key.is_empty():
		hud.show_reaction(division.rival(), key)

## Attempt over: the boss defeated (first clear banks its Career reward at once) or
## a target missed (the unmet score and the active rule are shown).
func _show_result() -> void:
	state = "division_over"
	next_rack.hide()
	score_panel.hide()
	var last: Dictionary = division.results[-1]
	var lines: Array = []
	for r in division.results:
		lines.append("%s: %d / %d %s" % [String(r.kind).capitalize(), r.score, r.target, "✓" if r.won else "✗"])
	var title: String
	if division.outcome == "won":
		var rival: Dictionary = division.rival()
		title = "%s defeated — Division cleared!" % rival.name
		if not career.first_clears.has(rival.id):
			career.first_clears[rival.id] = true
			for gate in rival.first_clear.unlocks:
				if gate not in career.unlocked:
					career.unlocked.append(gate)
			lines.append("First clear: " + rival.first_clear.text)
		else:
			lines.append("Already cleared before; no new reward.")
	else:
		title = "Attempt over — %s lost" % String(last.kind).capitalize()
		lines.append("Scored %d of the %d target." % [last.score, last.target])
		for rule in division.rules():
			lines.append("Rule in force: " + RivalRules.summary(rule))
		if not career.first_clears.is_empty():
			lines.append("Career progress kept: %d rival(s) cleared." % career.first_clears.size())
	lines.append("Attempt %d · total %d · $%d left" % [attempt, total_score, run.money])
	hud.show_result(title, "\n".join(lines), division.outcome == "won")
	_update_status()
	attempt_finished.emit(division.outcome)

func _on_offer(index: int) -> void:
	if state != "shop" or not _choice.is_empty():
		return
	var plan: Dictionary = shop.plan(index, run)
	if not plan.ok:
		shop_message = "Can't buy that: %s." % plan.reason
		_refresh_shop()
		return
	var options: Array = plan.placements
	var simple: bool = options.size() == 1 and options[0].replaces.is_empty() and options[0].moves_to.is_empty() and options[0].target.ends_with(":new")
	if simple:
		_finish_buy(index, options[0].target)
		return
	var item_name: String = _names.get(plan.item_id, plan.item_id)
	var full: bool = options.all(func(o): return not o.replaces.is_empty())
	var prompt := "Place %s ($%d)" % [item_name, plan.price]
	if full:
		prompt = "No free slot for %s ($%d): replace one (it is sold) or Cancel." % [item_name, plan.price]
	elif RunInventory.slot_kind(run.item(plan.item_id).category) == "mod":
		prompt = "Attach %s ($%d) to:" % [item_name, plan.price]
	_choice = {"kind": "buy", "index": index, "targets": options.map(func(o): return o.target)}
	shop_panel.show_choices(prompt, options.map(_placement_label))
	_refresh_shop()

func _finish_buy(index: int, target: String) -> void:
	var item_id: String = shop.offers[index].item_id
	var errors: Array[String] = shop.buy(index, target, run)
	shop_message = ("Bought %s." % _names.get(item_id, item_id)) if errors.is_empty() else "Can't buy that: %s." % ", ".join(errors)
	_refresh_shop()

func _on_choice(index: int) -> void:
	var choice := _choice
	_choice = {}
	shop_panel.hide_choices()
	match choice.get("kind", ""):
		"buy":
			_finish_buy(choice.index, choice.targets[index])
		"remove":
			var uid: String = choice.targets[index]
			var removed: String = _names.get(run.cards[uid].item_id, "")
			var errors: Array[String] = shop.remove_card(uid, run)
			shop_message = ("Removed %s from the deck." % removed) if errors.is_empty() else "Can't remove: %s." % ", ".join(errors)
			_refresh_shop()

func _on_choice_cancelled() -> void:
	_choice = {}
	shop_panel.hide_choices()
	shop_message = "Cancelled — nothing changed."
	_refresh_shop()
	shop_panel.continue_button.grab_focus()

func _on_reroll() -> void:
	if state != "shop" or not _choice.is_empty():
		return
	var errors: Array[String] = shop.reroll(run)
	shop_message = "New offers." if errors.is_empty() else "Can't reroll: %s." % ", ".join(errors)
	_refresh_shop()

func _on_remove() -> void:
	if state != "shop" or not _choice.is_empty():
		return
	if run.money < Economy.REMOVAL_PRICE:
		shop_message = "Can't remove: insufficient funds."
		_refresh_shop()
		return
	var targets: Array = []
	for owned in run.entries():
		if owned.ref.begins_with("card:"):
			targets.append(owned.ref.trim_prefix("card:"))
	_choice = {"kind": "remove", "targets": targets}
	shop_panel.show_choices("Remove which card from the run for $%d? (No refund.)" % Economy.REMOVAL_PRICE,
		targets.map(func(uid): return _ref_label("card:" + uid)))
	_refresh_shop()

func _on_sell(ref: String) -> void:
	if state != "shop" or not _choice.is_empty():
		return
	var label := _ref_label(ref)
	var value: int = run.sale_value(ref)
	var errors: Array[String] = run.sell(ref)
	shop_message = ("Sold %s for $%d." % [label, value]) if errors.is_empty() else "Can't sell: %s." % ", ".join(errors)
	_refresh_shop()

## What comes next, shown before any purchase: the target and, for the boss, the
## rival, its rule and the first-clear reward.
func _next_match_preview() -> String:
	if division.practice:
		return "Next: another practice match (no target)."
	var next: Dictionary = division.spec.matches[division.match_index + 1]
	var text := "Next: %s — target %d in two frames." % [next.name, int(next.target)]
	var rival: Dictionary = division.rival_for(next)
	if not rival.is_empty():
		text += "\n%s: %s\nFirst clear: %s" % [rival.name, RivalRules.summary(rival.rule),
			rival.first_clear.text if not career.first_clears.has(rival.id) else "already cleared"]
	else:
		var boss: Dictionary = division.boss()
		text += "\nBoss later: %s (%s)." % [division.rival_for(boss).name, RivalRules.summary(division.rival_for(boss).rule).trim_suffix(".")]
	return text

## A readable name for an owned place, with its modification.
func _ref_label(ref: String) -> String:
	var entry = run.entry_at(ref)
	if entry == null:
		return ref
	var text: String = _names.get(entry.item_id, entry.item_id)
	if not String(entry.mod).is_empty():
		text += " + " + _names.get(entry.mod, entry.mod)
	var parts := ref.split(":")
	match parts[0]:
		"rack": return "Rack %s %s" % [parts[1], text]
		"reserve": return "Reserve %s %s" % [parts[1], text]
		"charm": return "Charm %s %s" % [parts[1], text]
	return "Card " + text

func _placement_label(option: Dictionary) -> String:
	var target: String = option.target
	if target == "card:new":
		return "Add to the deck"
	if target == "charm:new":
		return "Add to Charm slot %d" % (run.charms.size() + 1)
	var parts := target.split(":")
	var place := ("Rack %s" % parts[1]) if parts[0] == "rack" else ("Reserve %s" % parts[1]) if parts[0] == "reserve" else ""
	if not option.moves_to.is_empty():
		return "%s — %s moves to %s" % [place, _names.get(run.entry_at(target).item_id, ""), option.moves_to.replace("reserve:", "Reserve ")]
	if not option.replaces.is_empty():
		return "Replace %s (sell +$%d)" % [_ref_label(option.replaces), option.sale]
	if run.entry_at(target) != null:
		return "Modify " + _ref_label(target)
	return place

func _refresh_shop() -> void:
	if shop_panel == null or state != "shop":
		return
	var offers: Array = []
	for offer in shop.offers:
		var slot_name: String = Shop.SLOT_NAMES[offer.slot]
		if offer.item_id.is_empty():
			offers.append({"text": "%s\nNothing available" % slot_name, "state": "empty"})
			continue
		var item: Dictionary = run.item(offer.item_id)
		var text := "%s · %s\n%s\n%s\n$%d" % [slot_name, item.rarity, item.name, _effect_text(item), offer.price]
		var offer_state := "buy"
		if offer.sold:
			offer_state = "sold"
			text += "  SOLD"
		else:
			var plan: Dictionary = shop.plan(offer.slot, run)
			if not plan.ok:
				offer_state = "poor" if plan.reason == "insufficient funds" else "blocked"
				var short := {"insufficient funds": "can't afford", "owned limit": "owned max", "incompatible with owned items": "incompatible",
					"nothing to modify": "no target", "no place for it": "no slot"}
				text += "  (%s)" % short.get(plan.reason, plan.reason)
		offers.append({"text": text, "state": offer_state})
	var pins: Array = []
	for position in range(1, 11):
		var pin: Dictionary = run.rack[position]
		pins.append("%d %s%s" % [position, _names.get(pin.item_id, ""), "+" + _names.get(pin.mod, "") if not String(pin.mod).is_empty() else ""])
	var rack_text := "Rack: " + ", ".join(pins)
	var reserves: Array = run.reserves.map(func(e): return "empty" if e == null else _names.get(e.item_id, ""))
	rack_text += "\nReserves: " + ", ".join(reserves) + " · Charms %d/%d · Deck %d/%d" % [run.charms.size(), RunInventory.CHARM_SLOTS, run.cards.size(), RunInventory.DECK_CAP]
	var sellables: Array = []
	for owned in run.entries():
		if run.can_sell(owned.ref):
			sellables.append({"ref": owned.ref, "label": "Sell %s +$%d" % [_ref_label(owned.ref), run.sale_value(owned.ref)]})
	var summary := "Match %d paid: payout $%d · interest $%d (on $%d held) · item income $%d" % [settlement.match, settlement.payout,
		settlement.interest, settlement.balance_before, settlement.item_income]
	shop_panel.show_view({"title": "Pro Shop", "summary": summary, "preview": _next_match_preview(), "money": run.money, "offers": offers,
		"reroll_cost": shop.reroll_cost(), "can_reroll": run.money >= shop.reroll_cost(),
		"removal_price": Economy.REMOVAL_PRICE, "can_remove": run.money >= Economy.REMOVAL_PRICE and not run.cards.is_empty(),
		"rack": rack_text, "sellables": sellables, "message": shop_message, "columns": 5 if size.x > size.y else 3})
	money_changed.emit(run.money)

func _normalized(position: Vector2) -> Vector2:
	return position / minf(size.x, size.y)

## Ball lane x for a finger position: the ball follows sideways finger travel at
## the ball's own depth, so the lane under the finger stays under the finger.
func _placed_x(finger: Vector2, origin: Vector2) -> float:
	var left := _screen(Lane.world(-Lane.LANE_HALF_WIDTH, Lane.BALL_START_F, Lane.BALL_RADIUS))
	var right := _screen(Lane.world(Lane.LANE_HALF_WIDTH, Lane.BALL_START_F, Lane.BALL_RADIUS))
	var lane_units_per_norm := 2.0 * minf(size.x, size.y) / maxf(right.x - left.x, 1.0)
	return clampf(_hold_start_x + (finger.x - origin.x) * lane_units_per_norm, -Lane.MAX_START_X, Lane.MAX_START_X)

func _screen(point: Vector3) -> Vector2:
	return _camera.unproject_position(point) * size / Vector2(_viewport.size)

## Lab-local screen position of a lane point (overlay drawing, automated input).
func screen_point(point: Vector3) -> Vector2:
	return _screen(point)

## Moves the target to the lane x under the finger on the ring's plane.
func _set_target_from(position: Vector2) -> void:
	var local := position * Vector2(_viewport.size) / size
	var origin := _camera.project_ray_origin(local)
	var direction := _camera.project_ray_normal(local)
	if absf(direction.z) < 1e-6:
		return
	var t := (-Lane.TARGET_PLANE_F - origin.z) / direction.z
	if t <= 0.0:
		return
	target_x = Ring.clamp_target((origin.x + direction.x * t) / Lane.LANE_HALF_WIDTH)
	assist_panel.set_target(target_x)
	_update_status()

func _in_target_zone(position: Vector2) -> bool:
	return position.y < _screen(lane.ball_position()).y - ball_touch_radius() * 1.2

func _over_ui(position: Vector2) -> bool:
	if position.y < TOP_UI_HEIGHT:
		return true
	var global := get_global_transform() * position
	for control in [settings_panel, assist_panel, next_rack, card_hand, shop_panel] + (hud.blocking_controls() if hud else []):
		if control.visible and control.get_global_rect().has_point(global):
			return true
	return false

## Canvas position of the ball, for touch hit-testing and automated input.
func ball_screen_position() -> Vector2:
	return get_global_transform() * _screen(lane.ball_position())

func ball_touch_radius() -> float:
	var center := _screen(lane.ball_position())
	var edge := _screen(lane.ball_position() + _camera.global_transform.basis.x * Lane.BALL_RADIUS)
	var factor := 2.6 if settings.large_targets else 1.8
	var minimum := 0.1 if settings.large_targets else 0.07
	return maxf(center.distance_to(edge) * factor, minimum * minf(size.x, size.y))

func _on_ball(position: Vector2) -> bool:
	return lane != null and position.distance_to(_screen(lane.ball_position())) <= ball_touch_radius()

## Spin shown by the meter and guide: live gesture charge or the assist setting.
func charged_spin() -> float:
	if state == "holding":
		return _flick.charge()
	return assist_panel.values().spin if settings.assist and state == "aim" else 0.0

func _update_status() -> void:
	if status == null:
		return
	_refresh_hand()
	_refresh_hud()
	if state in ["shop", "intro", "division_over"]:
		status.text = ""
		return
	var lead := "Match %d · Frame %d · Roll %d · $%d · Target %+.2f" % [match_number, frame_number, roll_index, run.money, target_x]
	if equipment != null and state in ["aim", "holding", "rolling"]:
		var ball_id: String = lane.launch.get("ball_id", HOUSE) if state == "rolling" else armed_ball_id()
		lead += "\nBall: %s" % _names.get(ball_id, ball_id)
		var tactical: Array = frame_tactics.get(roll_index, []) if state == "rolling" else ([_item_of(armed_tactical)] if not armed_tactical.is_empty() else [])
		if not tactical.is_empty():
			lead += " · Tactic: %s" % _names.get(tactical[0], tactical[0])
	match state:
		"aim":
			if settings.assist:
				status.text = lead + "\nSet position, aim, power and spin, then Throw."
			else:
				status.text = lead + "\nHold the ball · circle to spin · flick up. Tap the lane to move the target."
			if not last_cancel.is_empty():
				status.text += "\nNo throw (%s) — nothing used." % last_cancel.replace("_", " ")
		"holding":
			status.text = lead + "\nCircle to spin, flick up to release. Let go without a flick to cancel."
		"rolling":
			var spin: float = lane.launch.get("spin", 0.0)
			status.text = lead + "\nRolling… " + ("curved %s" % ("right" if spin > 0.0 else "left") if Lane.is_curved(spin) else "straight")
		"result":
			status.text = lead + "\n" + _describe(frame_reports[-1])
		"scoring":
			status.text = lead + "\nScoring…"
		"frame_done":
			var parts: Array = frame_reports.map(func(r): return str(r.roll_result.fallen_positions.size()))
			status.text = "Frame %d complete · %s" % [frame_number, " / ".join(parts)]
			if not scored_frames.is_empty() and scored_frames[-1].frame_number == frame_number:
				var result: Dictionary = scored_frames[-1].result
				status.text += " · %s %s · Total %s" % [String(result.category).capitalize(), ScoreLog._n(result.score), ScoreLog._n(total_score)]

## The match bar: which match, its target, the banked score and frames left; the
## badge inspects the rival's rule (boss) or previews the boss (earlier matches).
func _refresh_hud() -> void:
	if hud == null or division == null:
		return
	var m: Dictionary = division.current()
	var left: int = division.frames_left()
	var frames := "%d frame%s left" % [left, "" if left == 1 else "s"]
	var view := {"text": "", "badge": "", "rule_text": ""}
	if division.practice:
		view.text = "Practice · no target · score %d · %s" % [division.match_score, frames]
	else:
		var index: int = division.spec.matches.find(m) + 1
		view.text = "%s %d/3 · Target %d · Score %d · %s" % [m.name, index, division.target(), division.match_score, frames]
		var boss: Dictionary = division.boss()
		var rival: Dictionary = division.rival_for(boss)
		var reward: String = rival.first_clear.text if not career.first_clears.has(rival.id) else "already cleared"
		if division.is_boss():
			view.text = "%s · %s" % [rival.name, view.text]
			view.badge = "Rule: %s ⓘ" % _names.get(rival.rule, rival.rule)
		else:
			view.badge = "Boss: %s ⓘ" % rival.name
		view.rule_text = "%s — target %d in two frames.\n%s\nFirst clear: %s" % [rival.name, int(boss.target), RivalRules.summary(rival.rule), reward]
	hud.show_match(view)
	if not division.is_boss() or reactions.visible_at(_clock_usec).is_empty():
		hud.hide_reaction()

func _describe(report: Dictionary) -> String:
	var knockdowns: Dictionary = report.knockdown_log
	if knockdowns.gutter:
		return "Gutter — pinfall doesn't count; rack respotted."
	var fallen: Array = report.roll_result.fallen_positions
	var text := "%d down %s · %s" % [fallen.size(), str(fallen), report.roll_result.accuracy]
	if not knockdowns.standing.is_empty():
		text += " · standing %s" % str(knockdowns.standing)
	return text
