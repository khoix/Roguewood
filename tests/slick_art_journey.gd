extends "res://tests/neon_c13_journey.gd"
## J21R05 preserves every C13 mechanics assertion and all three encounters.
const Art = preload("res://src/presentation/rival_art.gd")

func _focus_accept(control: Control) -> void:
	var slick_intro: bool = lab != null and control == lab.hud.intro_button and lab.state == "intro" and lab.division.rival_for(lab.division.current()).id == "rival.slick"
	if slick_intro:
		_check(lab.hud.intro_portrait.texture == Art.portrait("rival.slick", "entrance"), "Slick authored intro")
		_check(lab.hud.intro_button.icon == Art.rule_badge("boss_rule.oil_slick"), "Oil Slick seal")
		_check(lab.hud.intro_portrait.still, "reduced intro is still")
		await super._capture("slick_intro")
		root.size = Vector2i(800, 450)
		for i in 12: await process_frame
		_check(lab.hud.intro.size.y + 1 >= lab.hud.intro.get_child(0).get_combined_minimum_size().y, "Slick landscape intro fits")
		await super._capture("slick_landscape")
		root.size = PORTRAIT
		for i in 12: await process_frame
	await super._focus_accept(control)
	if slick_intro:
		await _wait_for(func(): return lab.state == "aim", "Slick aim")
		await super._focus_accept(scene.options)
		await super._focus_accept(lab.settings_panel.reduced_motion)
		await super._focus_accept(lab.settings_panel.close)
		_check(not lab.hud.intro_portrait.still, "normal portrait motion enabled")
		await super._capture("slick_normal")
		await super._focus_accept(scene.options)
		await super._focus_accept(lab.settings_panel.reduced_motion)
		await super._focus_accept(lab.settings_panel.close)
		_check(lab.hud.intro_portrait.still, "reduced motion restored")
		await super._capture("slick_reduced")

func _rule_frame(shots: Array, spins: Array, label: String) -> Dictionary:
	var slick: bool = lab.division.rival_for(lab.division.current()).get("id", "") == "rival.slick"
	var scored := await super._rule_frame(shots, spins, label)
	if slick:
		_check(lab.hud.reaction_portrait.texture == Art.portrait("rival.slick", lab.hud.reaction_portrait.mood), "native selected Slick reaction")
		_check(lab.hud.reaction_portrait.still, "native reduced reaction")
		if scored.match_over:
			_check(lab.hud.reaction_portrait.mood == "defeated", "native Slick defeat")
			await super._capture("slick_defeated")
		else:
			await super._capture("slick_reaction")
	return scored
