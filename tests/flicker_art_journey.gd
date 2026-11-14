extends "res://tests/neon_c13_journey.gd"
## J21R07: authored champion identity and paired Strobe/Oil Slick seals.
## Retains every original C13 encounter/assertion, including paired-rule layout.
const Art = preload("res://src/presentation/rival_art.gd")
var tested_id := "rival.dj_flicker_champion"

func _focus_accept(control: Control) -> void:
	var intro: bool = lab != null and control == lab.hud.intro_button and lab.state == "intro" and lab.division.rival_for(lab.division.current()).id == tested_id
	var prefix := tested_id.trim_prefix("rival.")
	if intro:
		_check(Art.rule_badge("boss_rule.strobe") != null, "Strobe seal is authored")
		_check(lab.hud.intro_portrait.texture == Art.portrait(tested_id, "entrance"), "exact Flicker intro " + tested_id)
		_check(lab.hud.intro_button.icon == Art.rule_badge("boss_rule.strobe"), "Strobe intro seal")
		_check(lab.hud.intro_portrait.still, "reduced intro is still")
		await super._capture(prefix + "_intro")
		root.size = Vector2i(800,450)
		for i in 12: await process_frame
		_check(lab.hud.intro.size.y + 1 >= lab.hud.intro.get_child(0).get_combined_minimum_size().y, "landscape intro fits")
		await super._capture(prefix + "_landscape")
		root.size = PORTRAIT
		for i in 12: await process_frame
	await super._focus_accept(control)
	if intro:
		await _wait_for(func(): return lab.state == "aim", "Flicker aim")
		for i in 3: await process_frame
		if tested_id.ends_with("_champion"):
			var seals: Array = lab.hud.extra_rule_badges.get_children()
			_check(lab.hud.extra_rule_badges.visible and seals.size() == 2, "champion has both visible seals")
			for seal in seals:
				_check(seal.texture != null and seal.texture == Art.rule_badge(seal.get_meta("rule")), "exact champion seal")
			_check(seals.map(func(s): return s.get_meta("rule")) == ["boss_rule.strobe", "boss_rule.oil_slick"], "paired Strobe and Oil Slick")
			await super._capture("champion_seals")
		await super._focus_accept(scene.options)
		await super._focus_accept(lab.settings_panel.reduced_motion)
		await super._focus_accept(lab.settings_panel.close)
		_check(not lab.hud.intro_portrait.still, "normal portrait motion enabled")
		await super._capture(prefix + "_normal")
		await super._focus_accept(scene.options)
		await super._focus_accept(lab.settings_panel.reduced_motion)
		await super._focus_accept(lab.settings_panel.close)
		_check(lab.hud.intro_portrait.still, "reduced motion restored")
		await super._capture(prefix + "_reduced")

func _rule_frame(shots: Array, spins: Array, label: String) -> Dictionary:
	var is_flicker: bool = lab.division.rival_for(lab.division.current()).get("id", "") == tested_id
	var scored := await super._rule_frame(shots, spins, label)
	if is_flicker:
		_check(lab.hud.reaction_portrait.texture == Art.portrait(tested_id, lab.hud.reaction_portrait.mood), "native selected Flicker reaction")
		_check(lab.hud.reaction_portrait.still, "native reduced reaction")
		if scored.match_over:
			_check(lab.hud.reaction_portrait.mood == "defeated", "native Flicker defeat")
		await super._capture(tested_id.trim_prefix("rival.") + ("_defeated" if scored.match_over else "_reaction"))
	return scored
