extends "res://tests/slice_journey.gd"
## J03C02 (E18-C02): Glass Pin breaking in the real game, on the production slice
## in Practice. Fixture setup (logged, as J05 does) racks ten Glass pins and seats
## Glass Cutter through the inventory API; everything else is real input.
##   frame 1: a strike knocks down ten Glass pins; the bank equals an independent
##            resolution; each break equals an independent replay of the attempt's
##            effects stream and is named in the frame's explanation;
##   reload:  Clubhouse, then Continue Attempt rebuilds the rack and the stream
##            from disk; nothing is rerolled;
##   frame 2: another strike breaks exactly what an uninterrupted replay predicts.
## Run with --fixed-fps 60.
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.enter.has_focus(), "menu focus")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "throw lab ready")
	lab = scene.lab
	lab.trial_log_path = ""
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.reduced_motion)
	await _focus_accept(lab.settings_panel.assist)
	await _focus_accept(lab.settings_panel.practice)
	await _focus_accept(lab.settings_panel.close)
	for position in range(1, 11):
		lab.run.rack[position] = Inventory._entry("pin.glass", 0)
	_check(lab.run.place("charm.glass_cutter", 0, "charm:new").is_empty(), "fixture: seat Glass Cutter")
	print("J03C02 fixture: ten Glass pins racked and Glass Cutter seated through the inventory API; effects stream %d" % lab.run.effects_state)
	_check(lab.run.effects_state > 0, "the attempt's effects stream is seeded")
	var first := await _glass_frame("frame 1")
	await _capture("c02_breaks")
	# Reload from disk: the frame_done checkpoint holds the rack after the breaks and the stream.
	var rack_after: Array = _rack()
	var state_after: int = lab.run.effects_state
	await _focus_accept(scene.back)
	await _wait_for(func(): return scene.screen == "menu" and scene.continue_button.visible, "Continue Attempt offered")
	await _focus_accept(scene.continue_button)
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "frame_done", "the attempt resumes at the banked frame")
	lab = scene.lab
	lab.trial_log_path = ""
	_check(_rack() == rack_after and lab.run.effects_state == state_after, "after the reload the rack and the stream are unchanged (no reroll)")
	await _capture("c02_reloaded")
	await _focus_accept(lab.next_rack)
	for position in range(1, 11): # re-rack Glass where it broke, so frame 2 tests ten falls again
		if lab.run.rack[position].item_id != "pin.glass":
			lab.run.rack[position] = Inventory._entry("pin.glass", 0)
	print("J03C02 fixture: Glass re-racked for frame 2")
	var second := await _glass_frame("frame 2")
	print("J03C02 breaks: frame 1 %s, frame 2 %s" % [str(first), str(second)])
	_check(first.size() + second.size() > 0, "at least one Glass pin broke across the two frames")
	await _capture("c02_second")
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false, "Injected diagnostic failure")
	if failures.is_empty(): print("ROGUEWOOD_J03C02_OK")
	quit(0 if failures.is_empty() else 1)

func _rack() -> Array:
	return range(1, 11).map(func(p): return lab.run.rack[p].item_id)

## A strike on a Glass rack: checks the bank and the breaks against independent replays.
func _glass_frame(label: String) -> Array:
	var streak: int = lab.run.strike_streak
	var match_frame: int = lab.match_frame
	var state_before: int = lab.run.effects_state
	var loadout: Dictionary = lab.run.loadout()
	var before: int = lab.history.size()
	await _throw(STRIKE)
	if lab.state != "scoring" and not lab.history[-1].knockdown_log.standing.is_empty():
		await _throw(STRIKE)
	var scored := await _scored()
	var built := Builder.build(loadout, lab.content.catalogue, lab.history.slice(before), {}, {"match_frame": match_frame, "strike_streak": streak})
	var result := Rules.resolve(built.frame)
	_check(built.ok and scored.banked == result.score, "%s banks the independent resolution (%d vs %d)" % [label, scored.banked, result.score])
	# Replay the breaks on a fresh inventory with the same rack and stream state.
	var replay = Inventory.create(lab.content.catalogue, range(1, 11).map(func(p): return loadout.pins[p]), [])
	replay.effects_state = state_before
	replay.apply_frame(result, built.frame)
	var broke: Array = replay.transformed.map(func(t): return t.position)
	_check(lab.run.transformed.map(func(t): return t.position) == broke and lab.run.effects_state == replay.effects_state,
		"%s breaks exactly the replayed pins %s" % [label, str(broke)])
	for position in broke:
		_check(lab.run.rack[position].item_id == "pin.wood", "%s: Glass at %d is now Wood" % [label, position])
		_check(_log_lines().any(func(l): return l.contains("Glass Pin at %d cracked: now a Wood Pin." % position)), "%s: the explanation names the break at %d" % [label, position])
	_check(_log_lines().any(func(l): return l.contains("20% chance to become Wood Pin")) and _log_lines().any(func(l): return l.contains("Glass Cutter")),
		"%s: the log shows the chance and Glass Cutter" % label)
	return broke

func _capture(label: String) -> void:
	print("J03C02 %s lab=%s rack=%s stream=%d" % [label, lab.state, str(_rack()), lab.run.effects_state])
	if artifact_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(artifact_dir.path_join(label + ".png")) != OK:
		_check(false, "Cannot capture " + label)
