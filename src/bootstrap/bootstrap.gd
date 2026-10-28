extends Control
## Functional shell; visual treatment remains E11/E12 work.
const ThrowLab = preload("res://src/presentation/throw_lab.gd")
const SaveStore = preload("res://src/persistence/save_store.gd")
const Snapshot = preload("res://src/persistence/attempt_snapshot.gd")
const CareerProfile = preload("res://src/persistence/career_profile.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const FrameBuilder = preload("res://src/rules/frame_builder.gd")
const ContentSet = preload("res://src/rules/content_set.gd")
const UnlockGraph = preload("res://src/career/unlock_graph.gd")
const Clubhouse = preload("res://src/clubhouse/clubhouse.gd")
var session: Dictionary = {}
var screen := "menu"
var heading: Label
var details: Label
var enter: Button
var reset: Button
var back: Button
var league: OptionButton
var kit: OptionButton
var panel: VBoxContainer
var session_bar: HBoxContainer
var options: Button
var lab: ThrowLab
## Throw settings shared by every session this run (persistence is E25).
var throw_settings: Dictionary = {}
## Career record (E09), saved apart from attempts since E10 (career.json); E15
## (ADR 010) adds the validated unlock graph, records and mastery. Restart and
## retry keep it.
var career: Dictionary = {}
var career_graph: Dictionary = {}
var career_line: Label
var league_sets: Array = [] # content set behind each League choice
## The Clubhouse (E16): the home screen; its League Board holds the panel below.
var clubhouse: Clubhouse
## E10 saves: user://saves, or --save-dir=<path> for tests.
var store: RefCounted
var continue_button: Button
var notice: Label
var save_notice := ""
## The content set every attempt this run plays (E13): the slice, or --content=lab.
var content: Dictionary = {}

func _ready() -> void:
	get_window().size_changed.connect(_viewport_layout)
	_viewport_layout()
	clubhouse = Clubhouse.new()
	add_child(clubhouse)
	panel = VBoxContainer.new()
	panel.name = "LeaguePanel"
	panel.custom_minimum_size = Vector2(460, 0)
	panel.add_theme_constant_override("separation", 20)
	clubhouse.adopt_board(panel)
	heading = Label.new()
	heading.text = "Roguewood"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 48)
	panel.add_child(heading)
	details = Label.new()
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.text = "The lanes are waiting."
	panel.add_child(details)
	content = ContentSet.load_set(ContentSet.requested())
	if not content.errors.is_empty():
		push_error("Content set %s invalid: %s" % [content.id, str(content.errors)])
	career_graph = ContentSet.career_graph(content.unlocks)
	if not career_graph.errors.is_empty():
		push_error("Unlock graph invalid: %s" % str(career_graph.errors))
	career_line = Label.new()
	career_line.name = "CareerSummary"
	career_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	career_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	career_line.custom_minimum_size = Vector2(460, 0)
	panel.add_child(career_line)
	league = OptionButton.new()
	league.name = "LeagueChoice"
	league.add_item(content.get("name", "House League"))
	league_sets = [content.id]
	if content.id == "slice":
		league.add_item("House Campaign · 8 Divisions (provisional)")
		league_sets.append("campaign")
		league.item_selected.connect(func(index):
			content = ContentSet.load_set("campaign" if index == 1 else "slice")
			_show_menu())
	panel.add_child(league)
	kit = OptionButton.new()
	kit.name = "KitChoice"
	kit.add_item(content.kit.get("name", "House Kit"))
	panel.add_child(kit)
	continue_button = _button(panel, "Continue Attempt", "ContinueAttempt", 460)
	continue_button.pressed.connect(_continue_attempt)
	enter = _button(panel, "Enter League", "EnterLeague", 460)
	notice = Label.new()
	notice.name = "SaveNotice"
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.custom_minimum_size = Vector2(460, 0)
	notice.add_theme_color_override("font_color", Color(1.0, 0.75, 0.5))
	panel.add_child(notice)
	var save_dir := "user://saves"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): save_dir = arg.trim_prefix("--save-dir=")
	store = SaveStore.create(save_dir)
	_load_career()
	clubhouse.graph = career_graph
	clubhouse.career_changed.connect(_save_career)
	session_bar = HBoxContainer.new()
	session_bar.name = "SessionBar"
	session_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	session_bar.offset_top = 16
	session_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	session_bar.add_theme_constant_override("separation", 16)
	add_child(session_bar)
	reset = _button(session_bar, "Restart Session", "ResetSession", 220)
	back = _button(session_bar, "Clubhouse", "BackToMenu", 220)
	options = _button(session_bar, "Options", "ThrowOptions", 220)
	options.pressed.connect(func(): if lab: lab.toggle_settings())
	enter.pressed.connect(_start_session)
	reset.pressed.connect(_start_session)
	back.pressed.connect(_show_menu)
	_show_menu()
	if "--bootstrap-smoke" in OS.get_cmdline_user_args():
		print("ROGUEWOOD_BOOT_OK")
		get_tree().quit(0)

func _button(parent: Node, label: String, node_name: String, width: float) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(width, 64)
	parent.add_child(button)
	return button

func _start_session() -> void:
	_begin_attempt(1)

## The board's Career summary and followed goals.
func _refresh_career_line() -> void:
	career_line.text = CareerProfile.summary(career, career_graph.get("objectives", []))
	var goals: Array = CareerProfile.goals(career, career_graph.get("objectives", []), 0) # attempt-scoped goals start over
	if not goals.is_empty():
		career_line.text += "\nGoals: " + " · ".join(goals.map(func(g): return "%s %d/%d" % [g.name, mini(g.progress, g.threshold), g.threshold]))

## Saves the Career after a Clubhouse change (tracked goals).
func _save_career() -> void:
	_refresh_career_line()
	var errors: Array[String] = store.write("career", CareerProfile.normalized(career))
	if not errors.is_empty():
		push_warning("Career not saved: " + str(errors))

func _load_career() -> void:
	var read: Dictionary = store.read("career")
	career = CareerProfile.normalized(read.payload) if read.ok else CareerProfile.fresh()
	if not read.notice.is_empty():
		save_notice = read.notice
	var unknown: Array = CareerProfile.unknown_ids(career, career_graph)
	if not unknown.is_empty():
		save_notice = ("%s\n" % save_notice if not save_notice.is_empty() else "") + "Your Career holds %d unlock(s) this version does not use; they are kept." % unknown.size()

## The saved attempt, if it can be resumed: {ok, payload, notice}.
func _saved_attempt() -> Dictionary:
	var read: Dictionary = store.read("attempt")
	if not read.ok:
		return read
	var problems := Snapshot.validate(read.payload, content.catalogue, content.id)
	if not problems.is_empty():
		return {"ok": false, "notice": "The saved attempt no longer fits this version's content (%s); start a new attempt." % problems[0]}
	if read.payload.phase == "division_over" and not (content.id == "campaign" and read.payload.division.current.outcome == "won"):
		return {"ok": false, "notice": read.notice}
	return read

func _continue_attempt() -> void:
	var saved := _saved_attempt()
	if saved.ok:
		_begin_attempt(int(saved.payload.attempt), saved.payload)
## Attempt n of the content set's League (seed n). Restart Session begins
## attempt 1 again; Retry and New Attempt begin the next one.
## A saved payload resumes that attempt instead of starting fresh.
func _begin_attempt(attempt: int, saved: Dictionary = {}) -> void:
	if content.id == "campaign": content = ContentSet.load_set("campaign", int(saved.get("seed", attempt)))
	session = {"schema_version": 1, "seed": attempt, "attempt": attempt, "league_id": "league.house", "kit_id": content.kit.get("id", "kit.house"),
		"content": content.id, "division": 1, "match": 1, "frame": 1, "score": 0, "money": int(content.kit.get("money", 6))}
	if not saved.is_empty():
		session.seed = int(saved.seed)
		session.score = int(saved.lab.total_score)
		session.frame = int(saved.lab.frame_number)
		session.match = int(saved.lab.match_number)
		session.money = int(saved.run.money)
	screen = "session"
	details.text = "%s · %d Division%s" % [content.get("name", "House League"), content.divisions.size(), "" if content.divisions.size() == 1 else "s"]
	if content.id == "campaign": details.text += " · Seed %d" % int(session.seed)
	clubhouse.hide()
	_clear_lab()
	# Throw lab (E04–E09); the lane draws beneath the session controls.
	lab = ThrowLab.new()
	lab.name = "ThrowLab"
	lab.settings = throw_settings
	lab.content = content
	lab.equipment_seed = session.seed
	lab.career = career
	lab.career_graph = career_graph
	lab.attempt = attempt
	lab.save_store = store
	lab.restore_from = saved
	lab.attempt_finished.connect(func(outcome): session.outcome = outcome)
	lab.retry_requested.connect(func(): _begin_attempt(int(session.attempt) + 1), CONNECT_DEFERRED)
	lab.menu_requested.connect(_show_menu, CONNECT_DEFERRED)
	lab.frame_scored.connect(_on_frame_scored)
	lab.money_changed.connect(func(money): session.money = money)
	add_child(lab)
	move_child(lab, 0)
	session_bar.show()
	reset.grab_focus()

## The session fixture tracks the lab's banked total and current frame.
func _on_frame_scored(scored: Dictionary) -> void:
	session.score = int(session.score) + int(scored.get("banked", scored.result.score))
	session.frame = int(scored.frame_number) + 1
	session.match = int(scored.get("match_number", session.match))
	if lab != null:
		session.division = lab.division.division_number()

func _show_menu() -> void:
	screen = "menu"
	session = {}
	details.text = "The lanes are waiting."
	_clear_lab()
	_refresh_career_line()
	# League access from the unlock graph: a locked League is shown but cannot be entered.
	enter.disabled = false
	var played := int(career.records.get(career_graph.get("league_of_set", {}).get(league_sets[league.selected], ""), {}).get("attempts", 0)) > 0
	enter.text = "Try Again" if played else "Enter League" # design §16 button words
	for i in league.item_count:
		var reason := UnlockGraph.league_access(career_graph, career, career_graph.get("league_of_set", {}).get(league_sets[i], ""))
		league.set_item_disabled(i, not reason.is_empty())
		if i == league.selected and not reason.is_empty():
			details.text = reason
			enter.disabled = true
	var saved := _saved_attempt()
	continue_button.visible = saved.ok
	if saved.ok:
		continue_button.text = "Continue Attempt %d · match %d" % [int(saved.payload.attempt), int(saved.payload.lab.match_number)]
	var notes: Array = [save_notice, saved.get("notice", "")].filter(func(n): return not n.is_empty())
	notice.text = "\n".join(notes)
	save_notice = ""
	clubhouse.career = career
	clubhouse.show()
	clubhouse.show_tab("board")
	session_bar.hide()
	(continue_button if saved.ok else enter).grab_focus()

func _clear_lab() -> void:
	if lab:
		remove_child(lab)
		lab.free()
		lab = null

## Preserve native reference typography in both orientations.
func _viewport_layout() -> void:
	var window := get_window()
	window.content_scale_size = Vector2i(1280,720) if window.size.x > window.size.y else Vector2i(720,1280)
