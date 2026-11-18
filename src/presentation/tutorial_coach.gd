extends CanvasLayer
## UI-13 (owner, 2026-11-17): "Learn to Bowl", a visual tutorial played on the fixed
## practice lane (content set "tutorial"). Each step dims the screen except what it
## teaches, shows the gesture with an animated pixel hand and one short line, then
## waits for the player to do it in the real game (or for Next on a step that only
## explains). Skippable at every step. Reduced motion keeps every step and shows the
## hand still, with the gesture's path drawn in full.
## The coach only reads the lab and pauses its lane input on explain-only steps; the
## lab plays the practice match exactly as any other.
signal finished(choice: String) # "run", "clubhouse", "practice", "skip", "retry"

const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const Clubhouse = preload("res://src/clubhouse/clubhouse.gd")
const LAYER := 20
const PAD := 10.0 # room around a spotlit control
const PERIOD := 1.8 # one gesture loop, in seconds
## The pointing hand, a small pixel sprite: '#' ink, 'w' glove, 's' shade. Its tip
## is the top of the finger (HAND_TIP), which is what touches the screen.
const HAND := [
	".....##......",
	"....#ww#.....",
	"....#ww#.....",
	"....#ww#.....",
	"....#ww###...",
	"....#ww#ww##.",
	".##.#ww#ww#w#",
	"#ww##wwwwwww#",
	"#wwwwwwwwwww#",
	".#wwwwwwwwww#",
	"..#wwwwwwwww#",
	"..#swwwwwwws#",
	"...#swwwwws#.",
	"....#######..",
]
const HAND_TIP := Vector2(6.0, 0.0)
const HAND_PIXEL := 4.0

var lab: Control
var first_run := false # started from Enter League: the last step offers the run itself
var reduced := false
var step := -1
var steps: Array = []
var root: Control
var dims: Array = []
var art: Control # the spotlight's outline, the hand and its trail
var card: PanelContainer
var title_label: Label
var body: Label
var counter: Label
var next_button: Button
var skip_button: Button
var extra_button: Button # the last card's second choice
var _hole := Rect2()
var _shown := false
var _time := 0.0
var _done := false
var _lost_shown := false
var _start_target := 0.0
var _card_place := Rect2()
var _settle := 0 # frames until a new card's wrapped text has its size; it shows after

func _ready() -> void:
	layer = LAYER
	root = Control.new()
	root.name = "Coach"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# The dimmed screen around the spotlight: four panes, so the spotlit control
	# itself still takes taps (Controls under this layer get what the panes do not).
	for i in 4:
		var pane := ColorRect.new()
		pane.name = "Dim%d" % i
		pane.color = Color(0.02, 0.04, 0.07, 0.74)
		pane.mouse_filter = Control.MOUSE_FILTER_STOP
		root.add_child(pane)
		dims.append(pane)
	art = Control.new()
	art.name = "CoachArt"
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.draw.connect(_draw_art)
	root.add_child(art)
	card = PanelContainer.new()
	card.name = "CoachCard"
	card.add_theme_stylebox_override("panel", UiTheme.frame("menu", 18.0, 14.0))
	root.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	counter = _label(box, "CoachCounter", 15, Color("9aa8a6"))
	title_label = _label(box, "CoachTitle", 26, UiTheme.BRASS)
	body = _label(box, "CoachBody", 20, UiTheme.IVORY)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	skip_button = _button(row, "CoachSkip", "Skip Tutorial", func(): _finish("skip"))
	extra_button = _button(row, "CoachExtra", "Keep Practising", func(): _finish("practice"))
	next_button = _button(row, "CoachNext", "Next", _next)
	Clubhouse.secondary_style(skip_button)
	Clubhouse.secondary_style(extra_button)
	Clubhouse.primary_style(next_button)
	_build_steps()
	step = 0
	_hide_all()

func _label(parent: Control, node_name: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Control, node_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(140, 56)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

## The script: each step is {id, title, text, enter, done, rect, gesture, point,
## next, pause}. enter: when it may show; done: when it is complete (null: Next);
## rect: what is spotlit (empty: the whole screen dims); gesture: the hand's motion
## at point; pause: the lane ignores touches while it shows (explain-only steps).
func _build_steps() -> void:
	var aiming := func(): return lab.state == "aim" and lab.lane != null and lab.lane.state == "ready"
	steps = [
		{"id": "welcome", "title": "Learn to Bowl", "text": "A practice lane: nothing here counts toward your Career. Follow the hand.",
			"enter": aiming, "pause": true},
		{"id": "target", "title": "Win the Match", "text": "Reach the match's target before your frames run out, and the match is won. Here: %d points in %d frames." % [_target(), _frames()],
			"enter": aiming, "rect": func(): return _rect_of(lab.hud.bar), "pause": true},
		{"id": "cards", "title": "Your Cards", "text": "These cards are your balls. Tap one to throw it; press and hold one to read it. You draw again every frame.",
			"enter": aiming, "done": func(): return not String(lab.armed_ball).is_empty(), "next": true,
			"rect": func(): return _rect_of(lab.card_hand), "gesture": "tap", "point": _card_point, "pause": true},
		{"id": "aim", "title": "Aim", "dock": true, "text": "Tap the lane to aim. The ring shows where the ball will head.",
			"enter": aiming, "done": func(): return absf(lab.target_x - _start_target) > 0.02,
			"rect": _lane_rect, "gesture": "tap", "point": _aim_point,
			"on_enter": func(): _start_target = lab.target_x},
		{"id": "throw", "title": "Throw", "dock": true, "text": "Hold the ball and swirl it in circles to charge a curve, then flick up to roll it.",
			"enter": aiming, "done": func(): return lab.state == "rolling",
			"rect": _throw_rect, "gesture": "swirl_flick", "point": func(): return lab.ball_screen_position()},
		{"id": "spare", "title": "Roll Again", "dock": true, "text": "Pins still standing? Every frame gives you two rolls. Knock the rest down for a spare.", "dim": false,
			"enter": func(): return aiming.call() and lab.roll_index == 2, "done": func(): return lab.state == "rolling",
			"skip_if": func(): return lab.state in ["scoring", "frame_done"]},
		{"id": "scoring", "title": "Scoring", "text": "Each pin that falls adds Value. Balls and Charms add Mult. Value × Mult is banked as the frame's score.",
			"enter": func(): return lab.state in ["scoring", "frame_done"] and lab.score_panel.visible, "rect": func(): return _rect_of(lab.score_panel), "pause": true},
		{"id": "next_rack", "title": "Next Frame", "text": "Tap Next Rack for your second frame.",
			"enter": func(): return lab.state == "frame_done" and lab.next_rack.visible and not lab.division.match_over(),
			"done": func(): return lab.state != "frame_done", "skip_if": func(): return lab.division.match_over(), "rect": func(): return _rect_of(lab.next_rack), "gesture": "tap",
			"point": func(): return _rect_of(lab.next_rack).get_center()},
		{"id": "throw_again", "title": "Your Turn", "dock": true, "text": "Throw your second frame.", "dim": false,
			"enter": aiming, "done": func(): return lab.state == "rolling", "skip_if": func(): return lab.division.match_over()},
		{"id": "spare_again", "title": "Roll Again", "dock": true, "text": "Throw again for the pins still standing.", "dim": false,
			"enter": func(): return aiming.call() and lab.roll_index == 2, "done": func(): return lab.state == "rolling",
			"skip_if": func(): return lab.state in ["scoring", "frame_done"] or lab.division.match_over()},
		{"id": "collect", "title": "Match Won", "text": "Collect your winnings and visit the Pro Shop.",
			"enter": func(): return lab.state == "frame_done" and lab.next_rack.visible and lab.division.match_over() and lab.division.outcome != "lost",
			"done": func(): return lab.state == "shop", "rect": func(): return _rect_of(lab.next_rack), "gesture": "tap",
			"point": func(): return _rect_of(lab.next_rack).get_center()},
		{"id": "shop", "title": "The Pro Shop", "text": "Between matches you can buy balls, pins, Charms and more. Tap a card to read it.",
			"enter": _shop_idle, "rect": func(): return _rect_of(lab.shop_panel.offers_grid)},
		{"id": "buy", "title": "Buy One", "text": "Try it: tap the %s, a pin modification." % _workshop_name(),
			"enter": _shop_idle, "done": func(): return lab.shop_panel.offer_sheet.visible or lab.shop_panel.choice_sheet.visible,
			"rect": func(): return _rect_of(_workshop_offer()), "gesture": "tap", "point": func(): return _rect_of(_workshop_offer()).get_center()},
		{"id": "confirm_buy", "title": "Buy", "text": "Its full rule and price are here. Tap Buy.",
			"enter": func(): return lab.state == "shop" and lab.shop_panel.offer_sheet.visible,
			"done": func(): return lab.shop_panel.choice_sheet.visible or _workshop_sold(),
			"rect": func(): return _rect_of(lab.shop_panel.buy_button), "gesture": "tap", "point": func(): return _rect_of(lab.shop_panel.buy_button).get_center()},
		{"id": "place", "title": "Place It", "text": "This is your rack. Tap a pin to see what is on it now, then Confirm.", "card": false,
			"enter": func(): return lab.state == "shop" and lab.shop_panel.choice_sheet.visible,
			"done": _workshop_sold, "rect": func(): return _rect_of(lab.shop_panel.choice_sheet), "gesture": "tap", "point": _pin_point},
		{"id": "sell", "title": "Sell", "text": "Short of money? Sell what you no longer need. Open Sell.",
			"enter": _shop_idle, "done": func(): return lab.shop_panel.sell_sheet.visible,
			"rect": func(): return _rect_of(lab.shop_panel.sell_open), "gesture": "tap", "point": func(): return _rect_of(lab.shop_panel.sell_open).get_center()},
		{"id": "sell_sheet", "title": "Your Items", "text": "Tap an item to see what it sells for, then Sell or Back. Tap Done when you are finished.", "card": false,
			"enter": func(): return lab.state == "shop" and lab.shop_panel.sell_sheet.visible, "done": func(): return not lab.shop_panel.sell_sheet.visible,
			"rect": func(): return _rect_of(lab.shop_panel.sell_sheet), "gesture": "tap", "point": func(): return _rect_of(lab.shop_panel.sell_close).get_center()},
		{"id": "rival", "title": "The Boss", "text": "Every Division ends with a boss. Their rule changes the game: The Surveyor allows no curve. Tap the badge any time to read it.",
			"enter": _shop_idle, "rect": func(): return _rect_of(lab.hud.badge), "pause": true},
		{"id": "ready", "title": "You're Ready!", "text": "That is a Roguewood run: throw, score, shop, beat the boss. Win Divisions to climb the League.",
			"enter": _shop_idle, "final": true, "pause": true},
	]

func _target() -> int:
	return int(lab.division.target()) if lab != null and lab.division != null else 0

func _frames() -> int:
	return int(lab.division.frames_per_match()) if lab != null and lab.division != null else 0

func _shop_idle() -> bool:
	var shop = lab.shop_panel
	return lab.state == "shop" and shop.visible and not shop.offer_sheet.visible and not shop.choice_sheet.visible and not shop.sell_sheet.visible

func _workshop_index() -> int:
	for i in lab.shop.offers.size():
		if String(lab.shop.offers[i].item_id).begins_with("pin_mod."): return i
	return 4

func _workshop_offer() -> Control:
	return lab.shop_panel.button_for_offer(_workshop_index())

func _workshop_name() -> String:
	var ids: Array = lab.content.get("tutorial_offers", []) if lab != null else []
	for id in ids:
		if String(id).begins_with("pin_mod."): return lab.run.item(id).get("name", "modification")
	return "modification"

func _workshop_sold() -> bool:
	var i := _workshop_index()
	return i < lab.shop.offers.size() and bool(lab.shop.offers[i].sold) and not lab.shop_panel.choice_sheet.visible

static func _rect_of(control: Control) -> Rect2:
	return control.get_global_rect() if control != null and control.is_visible_in_tree() else Rect2()

func _lane_rect() -> Rect2:
	var top: float = _rect_of(lab.hud.bar).end.y
	var bottom: float = _rect_of(lab.card_hand).position.y if _rect_of(lab.card_hand).has_area() else lab.size.y
	return Rect2(0.0, top, lab.size.x, maxf(bottom - top, 80.0))

func _aim_point() -> Vector2:
	var x := 0.45 if lab.target_x < 0.2 else -0.45
	return lab.get_global_transform() * lab.screen_point(Lane.world(x * Lane.LANE_HALF_WIDTH, Lane.TARGET_PLANE_F, 0.0))

func _throw_rect() -> Rect2:
	var at: Vector2 = lab.ball_screen_position()
	var r: float = maxf(lab._ball_screen_radius(), 24.0)
	return Rect2(at.x - r * 3.0, at.y - r * 7.0, r * 6.0, r * 8.0)

func _card_point() -> Vector2:
	for button in lab.card_hand.buttons.values():
		if button.is_visible_in_tree(): return button.get_global_rect().get_center()
	return _rect_of(lab.card_hand).get_center()

func _pin_point() -> Vector2:
	var shop = lab.shop_panel
	# A pin first (the one focus rests on); once a finger has picked one, Confirm.
	var tile: Control = shop.choice_confirm if shop.choice_touched else shop.choice_button(maxi(shop._choice_selected, 0))
	return _rect_of(tile).get_center()

func _process(delta: float) -> void:
	if _done: return
	if not is_instance_valid(lab) or not lab.is_inside_tree():
		_hide_all()
		return
	_time += delta
	# Losing the practice match ends the run: offer a fresh lane instead of the result.
	# (Once the frame's review has finished: while it counts up, a press on it skips it.)
	if lab.division != null and lab.division.outcome == "lost" and lab.state == "frame_done" and not _lost_shown and step < _index("shop"):
		_lost_shown = true
		_show_lost()
	if _settle > 0:
		_card_place = Rect2()
		_layout(steps[step] if step < steps.size() and not _lost_shown else {})
		_settle -= 1
		if _settle == 0: _settled()
	if _lost_shown: return
	if step >= steps.size(): return
	var s: Dictionary = steps[step]
	if not _shown:
		if s.has("skip_if") and bool(s.skip_if.call()): # e.g. a strike needs no second roll
			_advance()
			return
		if bool(s.enter.call()):
			_show(s)
		else:
			_hide_all()
			return
	if s.has("done") and bool(s.done.call()):
		_advance()
		return
	_layout(s)
	art.queue_redraw()

func _index(id: String) -> int:
	for i in steps.size():
		if steps[i].id == id: return i
	return -1

func current_id() -> String:
	if _lost_shown: return "lost"
	return String(steps[step].id) if step >= 0 and step < steps.size() else ""

func _show(s: Dictionary) -> void:
	_shown = true
	_time = 0.0
	if s.has("on_enter"): s.on_enter.call()
	# Only the main steps are numbered; the ones a throw may skip (a second roll, a
	# second frame) are not, so the count never jumps.
	var main: Array = steps.filter(func(t): return not t.has("skip_if") and not t.get("final", false))
	counter.text = "Step %d of %d" % [main.find(s) + 1, main.size()]
	counter.visible = s in main
	title_label.text = s.title
	body.text = s.text
	var final: bool = s.get("final", false)
	next_button.text = ("Start Your Run" if first_run else "Back to the Clubhouse") if final else "Next"
	next_button.visible = final or not s.has("done") or s.get("next", false)
	extra_button.visible = final
	skip_button.visible = not final
	lab.input_paused = bool(s.get("pause", false)) or (not s.has("done") and not final)
	_reveal(s)

## Steps over a sheet that fills the screen (the rack map, the Sell list) show no
## card: the sheet's own prompt says what to do, and the hand shows where.
func _card_shown(s: Dictionary) -> bool:
	return s.get("card", true)

## A new card is laid out out of sight first: wrapped text only knows its height
## once it has its width, so it would otherwise appear in one place and jump.
func _reveal(s: Dictionary) -> void:
	if not _card_shown(s):
		card.hide()
		_settle = 0
		_layout(s)
		return
	card.show()
	card.modulate.a = 0.0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settle = 2
	_card_place = Rect2()
	_layout(s)

func _settled() -> void:
	card.modulate.a = 1.0
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	if next_button.visible: next_button.grab_focus()

## True once the current step is on screen: its card in place and taking taps, or
## (a card-less step) its spotlight up.
func card_ready() -> bool:
	if _shown and not _lost_shown and step < steps.size() and not _card_shown(steps[step]): return true
	return card.visible and _settle == 0 and card.modulate.a > 0.99

func _hide_all() -> void:
	for pane in dims: pane.hide()
	card.hide()
	_hole = Rect2()
	art.queue_redraw()

func _advance() -> void:
	_shown = false
	step += 1
	if is_instance_valid(lab): lab.input_paused = false
	_hide_all()

func _next() -> void:
	if _lost_shown:
		_finish("retry")
		return
	var s: Dictionary = steps[step] if step < steps.size() else {}
	if s.get("final", false):
		_finish("run" if first_run else "clubhouse")
		return
	_advance()

func _finish(choice: String) -> void:
	if _done: return
	_done = true
	if is_instance_valid(lab): lab.input_paused = false
	root.hide()
	finished.emit(choice)

func _show_lost() -> void:
	_shown = true
	lab.input_paused = true
	counter.visible = false
	title_label.text = "Not This Time"
	body.text = "Miss a match's target and the run is over. The practice lane resets, so you can try again."
	next_button.text = "Try Again"
	next_button.visible = true
	extra_button.visible = false
	skip_button.visible = true
	_reveal({})

## The spotlight and the card: the card sits above or below the spotlit control,
## whichever side has more room, and the whole screen dims when nothing is spotlit.
func _layout(s: Dictionary) -> void:
	var screen: Vector2 = root.get_viewport_rect().size
	# Owner (2026-11-17): while the player holds and swirls the ball, the lane is theirs:
	# no dimming and no hand; the card stays docked out of the way.
	var dim: bool = s.get("dim", true) and not _quiet(s)
	var target: Rect2 = s.rect.call() if s.has("rect") else Rect2()
	_hole = target.grow(PAD) if target.has_area() else Rect2()
	_hole = _hole.intersection(Rect2(Vector2.ZERO, screen)) if _hole.has_area() else Rect2()
	var panes: Array = []
	if dim and _hole.has_area():
		panes = [Rect2(0, 0, screen.x, _hole.position.y), Rect2(0, _hole.end.y, screen.x, screen.y - _hole.end.y),
			Rect2(0, _hole.position.y, _hole.position.x, _hole.size.y), Rect2(_hole.end.x, _hole.position.y, screen.x - _hole.end.x, _hole.size.y)]
	elif dim:
		panes = [Rect2(Vector2.ZERO, screen)]
	for i in dims.size():
		dims[i].visible = i < panes.size()
		if i < panes.size():
			dims[i].position = panes[i].position
			dims[i].size = panes[i].size
	var portrait := screen.y >= screen.x
	var docked: bool = s.get("dock", false)
	var width := minf(screen.x - 32.0, 520.0)
	if docked and not portrait:
		width = clampf(screen.x * 0.26, 260.0, 360.0) # a column at the side, clear of the lane
	# Wrapped text measures its height from its width, so the labels get theirs first.
	for label in [counter, title_label, body]:
		label.custom_minimum_size.x = width - 36.0
	var height: float = card.get_combined_minimum_size().y
	var y: float
	if docked or not dim:
		# Owner (2026-11-17): on the throwing steps the card is pinned out of the way:
		# at the bottom in portrait (over the hand of cards, clear of the pins and the
		# ball, where the flick starts), beside the lane in landscape.
		y = screen.y - height - 12.0 if portrait else _rect_of(lab.hud.bar).end.y + 12.0
	elif not _hole.has_area():
		y = (screen.y - height) * 0.5
	elif _hole.position.y > screen.y - _hole.end.y:
		y = _hole.position.y - height - 18.0 # above the spotlight
	else:
		y = _hole.end.y + 18.0 # below it
	y = clampf(y, 12.0, maxf(12.0, screen.y - height - 12.0))
	# Only when it moves: re-laying the card out every frame could drop a tap.
	var x := floorf((screen.x - width) * 0.5) if portrait or not docked else screen.x - width - 12.0
	var place := Rect2(Vector2(x, floorf(y)), Vector2(width, height))
	if place != _card_place:
		_card_place = place
		card.position = place.position
		card.size = place.size

## True while the player holds the ball on a throwing step.
func _quiet(s: Dictionary) -> bool:
	return s.get("dock", false) and is_instance_valid(lab) and lab.state == "holding"

func _draw_art() -> void:
	if not _shown or _lost_shown or step >= steps.size(): return
	var s: Dictionary = steps[step]
	if _quiet(s): return
	if _hole.has_area() and s.get("dim", true):
		var glow := 0.65 + (0.0 if reduced else 0.35 * sin(_time * 4.0))
		art.draw_rect(_hole, Color(UiTheme.BRASS, glow), false, 3.0)
	var gesture: String = s.get("gesture", "")
	if gesture.is_empty() or not s.has("point"): return
	var at: Vector2 = s.point.call()
	var phase := 0.55 if reduced else fmod(_time, PERIOD) / PERIOD
	match gesture:
		"tap": _draw_tap(at, phase)
		"swirl_flick": _draw_swirl(at, phase)

func _draw_tap(at: Vector2, phase: float) -> void:
	var press := clampf((phase - 0.35) / 0.15, 0.0, 1.0)
	var lift := 1.0 - press if phase < 0.7 else clampf((phase - 0.7) / 0.2, 0.0, 1.0)
	if phase >= 0.5 and phase < 0.9 or reduced:
		var ring := clampf((phase - 0.5) / 0.4, 0.0, 1.0) if not reduced else 0.5
		art.draw_arc(at, 10.0 + 26.0 * ring, 0.0, TAU, 32, Color(UiTheme.IVORY, 0.9 - 0.8 * ring), 3.0)
	_draw_hand(at + Vector2(14.0, 26.0) * lift, 1.0 - 0.08 * press)

func _draw_swirl(ball: Vector2, phase: float) -> void:
	var r: float = maxf(lab._ball_screen_radius() * 1.4, 34.0)
	var centre := ball + Vector2(0.0, -r)
	# The path: a full circle about the ball, then straight up.
	art.draw_arc(centre, r, 0.0, TAU, 48, Color(UiTheme.IVORY, 0.35), 2.0)
	var top := centre + Vector2(0.0, -r * 4.0)
	art.draw_line(ball, top, Color(UiTheme.BRASS, 0.5), 2.0)
	art.draw_colored_polygon(PackedVector2Array([top + Vector2(0, -12), top + Vector2(-10, 6), top + Vector2(10, 6)]), Color(UiTheme.BRASS, 0.8))
	var tip: Vector2
	if phase < 0.12:
		tip = ball
	elif phase < 0.7:
		var turns := (phase - 0.12) / 0.58 * 2.0 # two turns
		var angle := PI * 0.5 + TAU * turns
		tip = centre + Vector2(cos(angle), sin(angle)) * r
	else:
		tip = ball.lerp(top, clampf((phase - 0.7) / 0.18, 0.0, 1.0))
	_draw_hand(tip, 0.92 if phase < 0.88 else 1.0)

## The pixel hand with its fingertip at `tip`.
func _draw_hand(tip: Vector2, scale: float) -> void:
	var px := HAND_PIXEL * scale
	var origin := tip - HAND_TIP * px - Vector2(px * 0.5, 0.0)
	var colours := {"#": Color("1b1410"), "w": Color("f4ead6"), "s": Color("c9b89a")}
	for y in HAND.size():
		var row: String = HAND[y]
		for x in row.length():
			var c := row[x]
			if colours.has(c):
				art.draw_rect(Rect2(origin + Vector2(x, y) * px, Vector2(px, px)), colours[c])
