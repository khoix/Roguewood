extends "res://tests/neon_c13_journey.gd"
## J21R06 preserves every C13 mechanics assertion and all three encounters.
const Art = preload("res://src/presentation/rival_art.gd")

func _focus_accept(control: Control) -> void:
	var laser_lena_intro: bool = lab != null and control == lab.hud.intro_button and lab.state == "intro" and lab.division.rival_for(lab.division.current()).id == "rival.laser_lena"
	if laser_lena_intro:
		_check(lab.hud.intro_portrait.texture == Art.portrait("rival.laser_lena", "entrance"), "Laser Lena authored intro")
		_check(lab.hud.intro_button.icon == Art.rule_badge("boss_rule.narrow_lane"), "Narrow Lane seal")
		_check(lab.hud.intro_portrait.still, "reduced intro is still")
		await super._capture("laser_lena_intro")
		root.size = Vector2i(800, 450)
		for i in 12: await process_frame
		_check(lab.hud.intro.size.y + 1 >= lab.hud.intro.get_child(0).get_combined_minimum_size().y, "Laser Lena landscape intro fits")
		await super._capture("laser_lena_landscape")
		root.size = PORTRAIT
		for i in 12: await process_frame
	await super._focus_accept(control)
	if laser_lena_intro:
		await _wait_for(func(): return lab.state == "aim", "Laser Lena aim")
		await super._focus_accept(scene.options)
		await super._focus_accept(lab.settings_panel.reduced_motion)
		await super._focus_accept(lab.settings_panel.close)
		_check(not lab.hud.intro_portrait.still, "normal portrait motion enabled")
		await super._capture("laser_lena_normal")
		await super._focus_accept(scene.options)
		await super._focus_accept(lab.settings_panel.reduced_motion)
		await super._focus_accept(lab.settings_panel.close)
		_check(lab.hud.intro_portrait.still, "reduced motion restored")
		await super._capture("laser_lena_reduced")

func _rule_frame(shots: Array, spins: Array, label: String) -> Dictionary:
	var laser_lena: bool = lab.division.rival_for(lab.division.current()).get("id", "") == "rival.laser_lena"
	var scored := await super._rule_frame(shots, spins, label)
	if laser_lena:
		_check(lab.hud.reaction_portrait.texture == Art.portrait("rival.laser_lena", lab.hud.reaction_portrait.mood), "native selected Laser Lena reaction")
		_check(lab.hud.reaction_portrait.still, "native reduced reaction")
		if scored.match_over:
			_check(lab.hud.reaction_portrait.mood == "defeated", "native Laser Lena defeat")
			await super._capture("laser_lena_defeated")
		else:
			await super._capture("laser_lena_reaction")
	return scored
