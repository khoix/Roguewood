extends "res://tests/rule_art_journey.gd"
const RivalArt = preload("res://src/presentation/rival_art.gd")
var seen_portraits := {}
var checked_sound := false
func _focus_accept(control: Control) -> void:
	if lab != null and control == lab.hud.intro_button:
		var rival: Dictionary = lab.division.rival_for(lab.division.current())
		var id: String = rival.id
		if not RivalArt.entry(id).is_empty():
			_check(lab.hud.intro_portrait.texture == RivalArt.portrait(id,"entrance"),"actual intro portrait " + id)
			_check(lab.hud.intro_reward.texture == Assets.slot(RivalArt.entry(id).reward,"icon"),"actual first-clear reward identity")
			await _capture(id.replace(".","_")+"_intro")
	await super._focus_accept(control)
func _capture(label: String) -> void:
	for i in 12: await process_frame
	if lab != null and not checked_sound:
		checked_sound = true
		var audio: Node = lab.motion.sound
		var before: int = audio.played
		audio.mute_button.button_pressed = true
		audio.cue("test_mute",Assets.slot("boss_rule.dead_straight","sound"),3)
		_check(audio.played == before,"mute suppresses rule sound")
		audio.mute_button.button_pressed = false
		audio.volume_slider.value = 0
		audio.cue("test_zero",Assets.slot("boss_rule.dead_straight","sound"),3)
		_check(audio.played == before,"zero-volume suppresses rule sound")
		audio.volume_slider.value = 0.65
		audio.effects_button.button_pressed = false
		await process_frame
		_check(not lab.motion.abilities.glyph.enabled,"effects toggle reaches renderer")
		audio.effects_button.button_pressed = true
	if lab != null and lab.division.is_boss():
		var rival: Dictionary = lab.division.rival_for(lab.division.current())
		var id: String = rival.id
		if not RivalArt.entry(id).is_empty():
			for state in RivalArt.STATES:
				_check(RivalArt.portrait(id,state) != null,"authored state " + id + ":" + state)
			seen_portraits[id] = true
			_check(lab.lane.has_node("RivalLaneArt"),"actual rival lane meshes")
			if lab.hud.reaction.visible:
				_check(lab.hud.reaction_portrait.texture == RivalArt.portrait(id,lab.hud.reaction_portrait.mood),"actual cooldown-selected reaction")
			if lab.hud.result.visible:
				_check(lab.hud.result_portrait.texture == RivalArt.portrait(id,"defeated"),"actual win portrait")
	await super._capture(label)
