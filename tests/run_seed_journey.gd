extends "res://tests/slice_journey.gd"
## JSEED (owner, 2026-11-19): every new run gets its own seed and the next run
## number, as the real game does (`random_runs`, which journeys otherwise leave off
## for reproducible shops). Two engine processes share one save directory:
##   1 a fresh Career: Enter League is run 1 with a fresh seed; back to the
##     Clubhouse, Enter League again is run 2 with a different seed; Restart Run
##     is run 3 with another; leave run 3 saved;
##   2 restart: Continue resumes run 3 with its own saved seed (the shop and deck
##     streams follow it), and the Tutorial still uses its fixed seed.
var stage := 1

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
		if arg.begins_with("--stage="): stage = int(arg.trim_prefix("--stage="))
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.random_runs = true # the real game's setting
	await _wait_for(func(): return scene.screen == "menu", "menu")
	if stage == 1: await _stage_one()
	else: await _stage_two()
	if failures.is_empty(): print("ROGUEWOOD_JSEED_OK" if stage == 2 else "ROGUEWOOD_JSEED_STAGE%d_OK" % stage)
	quit(0 if failures.is_empty() else 1)

func _enter() -> Dictionary:
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "the run starts", ROLL_FRAMES)
	lab = scene.lab
	return {"attempt": int(scene.session.attempt), "seed": int(scene.session.seed), "lab_seed": int(lab.equipment_seed), "shop": int(lab.shop.rng_seed)}

func _stage_one() -> void:
	_check(not scene.continue_button.visible, "a fresh Career has no run to continue")
	await _focus_accept(scene.enter)
	var first := await _enter()
	_check(first.attempt == 1 and first.seed == first.lab_seed and first.seed != 1, "Enter League is run 1 with its own seed (%d)" % first.seed)
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu", "back in the Clubhouse")
	await _focus_accept(scene.enter)
	var second := await _enter()
	_check(second.attempt == 2 and second.seed != first.seed and second.shop != first.shop,
		"Enter League again is run 2 with a different seed (%d, then %d) and a different shop stream" % [first.seed, second.seed])
	await _focus_accept(scene.reset)
	_check(scene.reset.text.contains("Press Again"), "Restart Run asks to be pressed again")
	await _focus_accept(scene.reset)
	var third := await _enter()
	_check(third.attempt == 3 and third.seed not in [first.seed, second.seed], "Restart Run is run 3 with another seed (%d)" % third.seed)
	print("JSEED runs %s" % str([first, second, third]))

func _stage_two() -> void:
	await _wait_for(func(): return scene.continue_button.visible, "the saved run is offered")
	var saved: Dictionary = scene._saved_attempt()
	_check(saved.ok and int(saved.payload.attempt) == 3 and scene.continue_button.text.contains("Run 3"), "Continue offers run 3 (%s)" % scene.continue_button.text)
	await _focus_accept(scene.continue_button)
	var resumed := await _enter()
	_check(resumed.attempt == 3 and resumed.seed == int(saved.payload.seed) and resumed.lab_seed == resumed.seed,
		"the resumed run keeps its own saved seed (%d)" % resumed.seed)
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu", "back in the Clubhouse")
	scene.start_tutorial()
	await _wait_for(func(): return scene.lab != null and scene.content.id == "tutorial", "the tutorial starts", ROLL_FRAMES)
	_check(int(scene.lab.equipment_seed) == scene.TUTORIAL_SEED, "the tutorial keeps its fixed seed")
