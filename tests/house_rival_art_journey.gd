extends "res://tests/house_c05_journey.gd"
## Native E21-R04: the unchanged C05 fixture, with champion and Old Lou art.
## E21-R03 subclasses this and logs one runtime-only encounter substitution.
const Art = preload("res://src/presentation/rival_art.gd")
var finishing_lou := false

func _focus_accept(control: Control) -> void:
	if lab != null and control == lab.hud.intro_button and lab.state == "intro":
		var rival: Dictionary = lab.division.rival_for(lab.division.current())
		var id: String = rival.id
		_check(lab.hud.intro_portrait.texture != null and lab.hud.intro_portrait.texture == Art.portrait(id, "entrance"), "exact native intro portrait " + id)
		_check(lab.hud.intro_button.icon != null, "intro carries a rule seal " + id)
		for state in Art.STATES:
			_check(Art.portrait(id, state) != null, "portrait state " + id + ":" + state)
		await super._capture(id + "_intro")
		root.size = Vector2i(800, 450)
		for i in 12: await process_frame
		_check(lab.hud.intro.size.y + 1 >= lab.hud.intro.get_child(0).get_combined_minimum_size().y, "landscape introduction fits " + id)
		await super._capture(id + "_landscape")
		root.size = PORTRAIT
		for i in 12: await process_frame
	await super._focus_accept(control)

func _capture(label: String) -> void:
	await _check_art(label)
	await super._capture(label)
	if label == "c05_house_pins" and not finishing_lou:
		finishing_lou = true
		# The C05 mechanics check stops after one strike; complete Lou's match here.
		await _focus_accept(lab.next_rack)
		await _rule_frame([STRIKE], "Old Lou winning strike")
		await _focus_accept(lab.next_rack)
		await _wait_for(func(): return lab.hud.result.visible, "Old Lou defeat result")
		_check(lab.hud.result_portrait.texture == Art.portrait("rival.old_lou", "defeated"), "actual Old Lou defeat portrait")
		await super._capture("rival.old_lou_defeated")

func _check_art(label: String) -> void:
	for i in 2: await process_frame
	var rival: Dictionary = lab.division.rival_for(lab.division.current())
	var id: String = rival.id
	_check(lab.lane.has_node("RivalLaneArt"), "native cosmetic lane binding " + id)
	if lab.lane.has_node("RivalLaneArt"):
		_check(lab.lane.get_node("RivalLaneArt").get_meta("rival_id") == id, "exact lane identity " + id)
	if label in ["c05_house_pins", "proprietor_reaction"]:
		_check(lab.hud.reaction.visible, "native non-blocking reaction " + id)
		_check(lab.hud.reaction_portrait.texture != null and lab.hud.reaction_portrait.texture == Art.portrait(id, lab.hud.reaction_portrait.mood), "cooldown-selected portrait " + id)
		_check(lab.hud.reaction_portrait.still == lab.hud.reduced_motion, "reduced-motion portrait follows setting")
	_check(lab.hud.intro_portrait.still == lab.hud.reduced_motion, "intro follows reduced-motion setting")
