extends SceneTree
## J07 save and recovery journey (E10). Every stage is a separate engine process
## (tools/qa.py runs stages 1..10 against one save directory), so each "restart" is
## a real one: only what reached the disk survives. Each stage leaves at a chosen
## moment and the next stage checks the resume through the real menu:
##   1 before a throw (after a cycle) → 2 resumes the cycled hand, commits a throw and
##   leaves mid-roll → 3 re-simulates exactly that launch (checked against a clean
##   replay) and leaves while the frame's score plays → 4 shows the banked frame
##   once, then buys in the shop → 5 keeps the purchase once, then rerolls → 6 keeps
##   the rerolled offers and price, then leaves between rolls → 7 resumes roll two on
##   the same standing pins and wins the Division → 8 keeps the first clear once,
##   starts a new attempt and corrupts its save → 9 falls back to the previous
##   checkpoint, then corrupts every copy → 10 reports no usable save and starts fresh.
## Run with --fixed-fps 60.
const LaneWorld = preload("res://src/simulation/lane_world.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const SaveStore = preload("res://src/persistence/save_store.gd")
const Economy = preload("res://src/rules/economy.gd")
const ROLL_FRAMES := 1800
const PORTRAIT := Vector2i(450, 800)
const STRIKE := [0.1, 0.0, 0.7]
const LEAVE := [-0.4, 0.0, 0.6]
const CLEANUP := [0.0, 0.0, 0.6]
var failures: Array[String] = []
var artifact_dir := ""
var save_dir := ""
var stage := 0
var scene: Control
var lab: Control
var memo: Dictionary = {} # expectations handed from one stage to the next

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
		printerr("FAIL: stage %d: %s" % [stage, label])

func _wait_for(predicate: Callable, label: String, frames: int = 240) -> bool:
	for i in frames:
		if predicate.call():
			return true
		await process_frame
	if predicate.call():
		return true
	var where := "" if lab == null else " (lab=%s match=%s score=%d outcome=%s)" % [lab.state, lab.division.current().id, lab.division.match_score, lab.division.outcome]
	_check(false, "Timeout: " + label + where)
	return false

func _capture(label: String) -> void:
	print("J07 stage=%d %s screen=%s lab=%s phase=%s money=%s" % [stage, label, scene.screen, lab.state if lab else "-",
		lab.restored_phase if lab else "-", str(lab.run.money) if lab else "-"])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)

func _action(action: String, times: int = 1) -> void:
	for i in times:
		for pressed in [true, false]:
			var event := InputEventAction.new()
			event.action = action
			event.pressed = pressed
			Input.parse_input_event(event)
			await process_frame

func _focus_accept(control: Control) -> void:
	control.grab_focus()
	await _action("ui_accept")

func _slide(slider: HSlider, value: float) -> void:
	slider.grab_focus()
	var steps := roundi((value - slider.value) / slider.step)
	await _action("ui_right" if steps > 0 else "ui_left", absi(steps))

func _memo_path() -> String:
	return artifact_dir.path_join("j07_expectations.json")

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
		if arg.begins_with("--save-dir="): save_dir = arg.trim_prefix("--save-dir=")
		if arg.begins_with("--stage="): stage = int(arg.trim_prefix("--stage="))
	if stage > 1:
		memo = JSON.parse_string(FileAccess.get_file_as_string(_memo_path()))
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.screen == "menu", "menu")
	match stage:
		1: await _stage1()
		2: await _stage2()
		3: await _stage3()
		4: await _stage4()
		5: await _stage5()
		6: await _stage6()
		7: await _stage7()
		8: await _stage8()
		9: await _stage9()
		10: await _stage10()
		_: _check(false, "unknown stage")
	var file := FileAccess.open(_memo_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify(memo, "", true, true))
	file.close()
	if stage == 10 and "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if not failures.is_empty() and lab != null: await _capture("failure")
	if failures.is_empty():
		print("ROGUEWOOD_J07_OK" if stage == 10 else "ROGUEWOOD_J07_STAGE%d_OK" % stage)
	quit(0 if failures.is_empty() else 1)

## Settings are not saved (E25), so each process sets assist and reduced motion.
func _settings() -> void:
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.close)

func _enter() -> void:
	await _focus_accept(scene.enter)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "a new attempt")
	lab = scene.lab
	lab.trial_log_path = ""
	await _settings()

func _continue(phase: String) -> void:
	_check(scene.continue_button.visible and scene.continue_button.has_focus(), "the menu offers Continue Attempt")
	await _focus_accept(scene.continue_button)
	await _wait_for(func(): return scene.lab != null, "the attempt resumes")
	lab = scene.lab
	lab.trial_log_path = ""
	_check(lab.restored_phase == phase, "resumed from the %s phase (got %s)" % [phase, lab.restored_phase])
	await _settings()

func _aim() -> void:
	await _wait_for(func(): return lab.state == "aim" and lab.lane.state == "ready", "aim", ROLL_FRAMES)

func _throw_start(shot: Array) -> void:
	await _aim()
	var panel: Control = lab.assist_panel
	await _slide(panel.position_slider, shot[0])
	await _slide(panel.aim_slider, shot[1])
	await _slide(panel.power_slider, shot[2])
	await _slide(panel.spin_slider, 0.0)
	await _focus_accept(panel.throw_button)
	_check(lab.state == "rolling", "Throw commits")

func _throw(shot: Array) -> Dictionary:
	var count: int = lab.history.size()
	await _throw_start(shot)
	await _wait_for(func(): return lab.history.size() == count + 1, "roll settles", ROLL_FRAMES)
	return lab.history[-1]

func _scored() -> void:
	await _wait_for(func(): return lab.state == "scoring", "scoring", ROLL_FRAMES)
	await _focus_accept(lab.score_panel.skip_button)
	await _wait_for(func(): return lab.state == "frame_done", "frame done", ROLL_FRAMES)

func _saved() -> Dictionary:
	var store = SaveStore.create(save_dir)
	return store.read("attempt")

# --- Stages ------------------------------------------------------------------

## 1: a new attempt; cycle a card (a committed draw), arm a ball (not committed), leave.
func _stage1() -> void:
	_check(not scene.continue_button.visible and scene.enter.has_focus(), "no save yet: Enter League is offered")
	await _enter()
	_check(_saved().ok and _saved().payload.phase == "aim", "a new attempt is saved before the first throw")
	var deck = lab.equipment
	var swap: String = deck.hand[1]
	await _focus_accept(lab.card_hand.cycle_button)
	await _focus_accept(lab.card_hand.button_for(swap))
	_check(deck.cycled and swap in deck.discard, "a card was cycled")
	var ball := ""
	for option in deck.options():
		if option.kind == "ball" and ball.is_empty(): ball = option.uid
	await _focus_accept(lab.card_hand.button_for(ball))
	_check(lab.armed_ball == ball, "a ball is armed (but not thrown)")
	# Backgrounding (as a phone does when the app is switched away) saves at once.
	var before: int = lab.checkpoints
	lab.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_check(lab.checkpoints == before + 1 and _saved().payload.phase == "aim", "backgrounding writes a checkpoint")
	memo = {"hand": deck.hand.duplicate(), "draw": deck.draw_pile.duplicate(), "money": lab.run.money}

## 2: restart before the throw: the cycle stays spent, the arming does not survive.
func _stage2() -> void:
	await _capture("continue_menu")
	await _continue("aim")
	var deck = lab.equipment
	_check(deck.hand == memo.hand and deck.draw_pile == memo.draw and deck.cycled, "the cycled hand and draw pile are restored")
	_check(not deck.can_cycle() and lab.card_hand.cycle_button.disabled, "the cycle stays spent: no second draw by reloading")
	_check(lab.armed_ball.is_empty() and lab.run.money == memo.money and lab._launch_serial == 0, "an armed card is only a selection; nothing was spent")
	await _capture("resumed_hand")
	var ball := ""
	for option in deck.options():
		if option.kind == "ball" and (ball.is_empty() or option.item_id == "ball.lab_coin"): ball = option.uid
	await _focus_accept(lab.card_hand.button_for(ball))
	await _throw_start(STRIKE)
	var saved := _saved()
	_check(saved.ok and saved.payload.phase == "committed" and saved.payload.lab.pending.launch.launch_id == lab.lane.launch.launch_id,
		"the committed launch is saved before the roll plays")
	memo = {"launch": lab.lane.launch.duplicate(true), "card": ball, "ball_id": deck.cards[ball], "hand": deck.hand.duplicate(), "serial": lab._launch_serial}
	# Leave mid-roll, as a crash or a closed app would.

## 3: restart during the throw: the same launch re-simulates; it is never rethrown.
func _stage3() -> void:
	await _continue("committed")
	var deck = lab.equipment
	_check(lab.state == "rolling" and _same_launch(lab.lane.launch, memo.launch), "the saved launch resumes, unchanged")
	_check(memo.card in deck.discard and memo.card not in deck.hand and deck.hand == memo.hand and lab._launch_serial == int(memo.serial),
		"the thrown card stays spent and no launch is added")
	await _capture("resumed_roll")
	await _wait_for(func(): return lab.history.size() == 1, "the resumed roll settles", ROLL_FRAMES)
	var report: Dictionary = lab.history[0]
	_check(report.launch.launch_id == memo.launch.launch_id and report.roll_result.ball_id == memo.ball_id, "the result belongs to the committed launch")
	await _check_replay(report)
	await _wait_for(func(): return lab.state == "scoring", "scoring starts", ROLL_FRAMES)
	var scored: Dictionary = lab.scored_frames[-1]
	var saved := _saved()
	_check(saved.ok and saved.payload.phase == "frame_done" and int(saved.payload.lab.total_score) == lab.total_score, "the frame is banked and saved before its explanation plays")
	memo = {"total": lab.total_score, "banked": scored.banked, "money": lab.run.money, "income": scored.income, "match_score": lab.division.match_score,
		"ledger": lab.run.ledger.size()}
	# Leave while the score is still counting up.

## Field by field: JSON hands back every number as a float.
func _same_launch(a: Dictionary, b: Dictionary) -> bool:
	for key in b:
		var same: bool = (float(a.get(key)) == float(b[key])) if b[key] is float or b[key] is int else a.get(key) == b[key]
		if not same:
			return false
	return a.size() == b.size()

## The resumed roll equals a clean simulation of the same launch on the same rack.
func _check_replay(report: Dictionary) -> void:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	var world: Node3D = LaneWorld.new()
	viewport.add_child(world)
	world.setup(Lane.fresh_rack())
	_check(world.commit(report.launch).is_empty(), "replay launch accepted")
	await _wait_for(func(): return world.state == "finished", "replay settles", ROLL_FRAMES)
	for key in ["roll_result", "knockdown_log", "rack_after"]:
		_check(world.report.get(key) == report[key], "the resumed roll equals a clean replay: " + key)
	viewport.queue_free()

## 4: restart during score resolution: shown once, banked once; then buy in the shop.
func _stage4() -> void:
	await _continue("frame_done")
	await _wait_for(func(): return lab.state == "frame_done", "the banked frame is shown")
	_check(lab.total_score == int(memo.total) and lab.run.money == int(memo.money) and lab.division.match_score == int(memo.match_score)
		and lab.run.ledger.size() == int(memo.ledger), "nothing is banked or paid twice (total %d, $%d)" % [lab.total_score, lab.run.money])
	_check(lab.score_panel.visible and lab.score_panel.displayed().score == int(memo.banked), "the calculation is shown again, not redone")
	await _capture("resumed_frame")
	_check(lab.next_rack.text == "Collect & Shop", "the strike won the opener")
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.state == "shop", "shop")
	var index := -1
	for i in lab.shop.offers.size():
		var plan: Dictionary = lab.shop.plan(i, lab.run)
		if index < 0 and plan.ok and plan.placements.size() == 1 and plan.placements[0].target.ends_with(":new"):
			index = i
	_check(index >= 0, "something affordable to buy")
	if index < 0: return
	var item_id: String = lab.shop.offers[index].item_id
	var owned: int = lab.run.owned_count(item_id)
	await _focus_accept(lab.shop_panel.button_for_offer(index))
	_check(lab.shop.offers[index].sold and lab.run.owned_count(item_id) == owned + 1, "bought " + item_id)
	memo = {"item": item_id, "owned": owned + 1, "money": lab.run.money, "index": index, "offers": lab.shop.offers.duplicate(true)}

## 5: restart after the purchase: owned once, paid once; then reroll.
func _stage5() -> void:
	await _continue("shop")
	_check(lab.state == "shop" and lab.shop_panel.visible, "the shop is open again")
	_check(lab.run.owned_count(memo.item) == int(memo.owned) and lab.run.money == int(memo.money) and lab.shop.offers[int(memo.index)].sold,
		"the purchase stands exactly once (no refund, no second copy)")
	await _capture("resumed_shop")
	var money: int = lab.run.money
	await _focus_accept(lab.shop_panel.reroll_button)
	_check(lab.run.money == money - Economy.reroll_cost(0) and lab.shop.reroll_cost() == Economy.reroll_cost(1), "a paid reroll")
	memo = {"offers": lab.shop.offers.map(func(o): return o.item_id), "money": lab.run.money, "cost": lab.shop.reroll_cost()}

## 6: restart after the reroll: same offers, same price; then leave between rolls.
func _stage6() -> void:
	await _continue("shop")
	_check(lab.shop.offers.map(func(o): return o.item_id) == memo.offers and lab.run.money == int(memo.money) and lab.shop.reroll_cost() == int(memo.cost),
		"reloading neither repeats nor refunds a reroll")
	await _capture("resumed_reroll")
	await _focus_accept(lab.shop_panel.continue_button)
	await _wait_for(func(): return lab.state == "aim" and lab.division.current().kind == "feature", "the feature starts", ROLL_FRAMES)
	var report := await _throw(LEAVE)
	_check(not report.knockdown_log.standing.is_empty() and lab.state == "result", "roll one leaves pins")
	memo = {"standing": report.knockdown_log.standing.duplicate(), "rack_after": report.rack_after.duplicate(true)}
	# Leave during the result hold, before roll two.

## 7: restart between rolls: roll two on the same standing pins; win the Division.
func _stage7() -> void:
	await _continue("roll_resolved")
	await _aim()
	_check(lab.roll_index == 2 and lab.rack.standing.map(func(p): return int(p.position)) == memo.standing.map(func(p): return int(p)), "roll two faces the same standing pins")
	_check(JSON.stringify(lab.rack, "", true, true) == JSON.stringify(memo.rack_after, "", true, true), "their positions are exact")
	await _capture("resumed_roll2")
	await _throw(CLEANUP)
	await _scored()
	await _focus_accept(lab.next_rack)
	await _throw(STRIKE)
	await _scored()
	_check(lab.division.match_over() and lab.next_rack.text == "Collect & Shop", "the feature is won")
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.state == "shop", "shop before the boss")
	await _focus_accept(lab.shop_panel.continue_button)
	await _wait_for(func(): return lab.state == "intro", "the boss introduction")
	await _focus_accept(lab.hud.intro_button)
	# The Charm bought in stage 4 scores too, so one strike may already beat the target.
	for frame in 2:
		await _throw(STRIKE)
		await _scored()
		if lab.division.match_over():
			break
		await _focus_accept(lab.next_rack)
	_check(lab.division.outcome == "won" and lab.next_rack.text == "Division Result", "the boss is defeated")
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.hud.result.visible, "the victory screen")
	var store = SaveStore.create(save_dir)
	var career: Dictionary = store.read("career")
	_check(career.ok and career.payload.first_clears.has("rival.lab_custodian") and "gate.lab_rival" in career.payload.unlocked, "the first clear is on disk with its unlock")
	_check(_saved().payload.phase == "division_over", "the attempt's end is saved after the Career award")
	memo = {"clears": career.payload.first_clears.size(), "unlocked": career.payload.unlocked.size()}

## 8: restart after the unlock: kept once; a new attempt; then corrupt its latest save.
func _stage8() -> void:
	_check(not scene.continue_button.visible, "a finished attempt is not offered to continue")
	_check(scene.career.first_clears.size() == int(memo.clears) and scene.career.unlocked.size() == int(memo.unlocked)
		and scene.career.first_clears.has("rival.lab_custodian"), "the Career record survived the restart, not duplicated")
	await _capture("career_kept")
	await _enter()
	_check("gate.lab_rival" in lab.shop.unlocked, "the unlock is in the new attempt's shop pool")
	var before: Array = lab.equipment.hand.duplicate()
	await _focus_accept(lab.card_hand.cycle_button)
	await _focus_accept(lab.card_hand.button_for(lab.equipment.hand[0]))
	_check(lab.equipment.cycled, "cycled (a newer checkpoint)")
	memo = {"backup_hand": before}
	# Corrupt the newest checkpoint as a torn write would.
	var path := save_dir.path_join("attempt.json")
	var text := FileAccess.get_file_as_string(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text.substr(0, floori(text.length() / 3.0)))
	file.close()

## 9: a corrupt save falls back to the previous checkpoint; then corrupt every copy.
func _stage9() -> void:
	_check(scene.notice.text.contains("restored the previous checkpoint") and FileAccess.file_exists(save_dir.path_join("attempt.json.corrupt")),
		"the menu explains the fallback and keeps the damaged file aside")
	await _capture("fallback")
	await _continue("aim")
	_check(lab.equipment.hand == memo.backup_hand and not lab.equipment.cycled, "the previous checkpoint (before the cycle) is resumed")
	for name in ["attempt.json", "attempt.json.bak"]:
		var file := FileAccess.open(save_dir.path_join(name), FileAccess.WRITE)
		file.store_string("{\"format\": \"roguewood\"}")
		file.close()

## 10: no usable save: say so, keep the Career, start fresh.
func _stage10() -> void:
	_check(not scene.continue_button.visible and scene.notice.text.contains("could not be read"), "no usable checkpoint is reported")
	_check(scene.career.first_clears.has("rival.lab_custodian"), "the Career is untouched by a broken attempt save")
	await _capture("no_save")
	await _enter()
	_check(lab.state == "aim" and lab.run.money == Economy.STARTING_MONEY and _saved().ok, "a new attempt starts and saves")
