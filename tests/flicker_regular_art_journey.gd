extends "res://tests/flicker_art_journey.gd"
## Additional fixture only; J21R07 retains the original champion and all checks.
func _champion() -> void:
	tested_id = "rival.dj_flicker"
	var neon: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/leagues/neon.json"))
	var rival: Dictionary = neon.divisions[2].rivals[0].duplicate(true)
	_check(rival.id == tested_id and rival.rule == "boss_rule.strobe", "authored regular DJ identity")
	rival.first_clear.unlocks = []
	lab.division.spec.rivals = [rival]
	lab.division.spec.matches[2].rival = tested_id
	print("J21R07DJ fixture: regular authored DJ in C13 final Division; target retained, Career reward suppressed; separate J21R07 keeps original champion")
	await _to_boss("Regular DJ")
	await _focus_accept(lab.hud.intro_button)
	await _wait_for(func(): return lab.state == "aim", "DJ ready")
	_check(lab.division.rules() == ["boss_rule.strobe"], "regular DJ has Strobe only")
	_check(lab.zone_scale() == 0.5 and lab.hook_scale() == 1.0, "regular DJ halves zones but not hook")
	await _win("Regular DJ")
