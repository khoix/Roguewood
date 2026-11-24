extends "res://tests/house_league_journey.gd"
## Actual House boss wins from the shipping manifest, with no review overrides.
const ENDINGS := {
	"rival.surveyor":["boss_surveyor_tape","boss_surveyor_level"],
	"rival.custodian":["boss_custodian_sweep","boss_custodian_polish"],
	"rival.proprietor":["boss_proprietor_receipt","boss_proprietor_keys"],
	"rival.old_lou":["boss_old_lou_record","boss_old_lou_encore"],
	"rival.custodian_champion":["boss_custodian_champion_crown","boss_custodian_champion_house_lights"],
}

func _play_match(division: int, m: Dictionary) -> void:
	var alley = lab.alley_screen
	var paths := {}
	for id in ENDINGS:
		paths[id] = ENDINGS[id].map(func(key): return "res://assets/ui/alley_screen/house/"+key+".tscn")
	_check(alley.variants_override.is_empty(),"actual boss journey uses live manifest")
	for id in ENDINGS:
		var listed: Array = lab.league_theme.celebrations("boss_defeated",id)
		_check(listed.size() == 2 and listed.all(func(path): return path in paths[id]),"live manifest contains both authored endings: " + id)
	# The House manifest is live (coordinator, 2026-11-24): strikes play their own
	# scenes too, so only boss celebrations are counted, and the boss scene may wait
	# in the queue behind the last strike's.
	var bosses := func(): return alley.played.filter(func(p): return p.event == "boss_defeated").size()
	var before: int = bosses.call()
	await super._play_match(division,m)
	if m.kind != "boss":
		_check(bosses.call() == before,"ordinary match has no boss celebration")
		return
	await _wait_for(func(): return alley.playing() and alley.current_event == "boss_defeated","the boss celebration's turn",600)
	_check(bosses.call() == before+1,"one celebration per actual boss win")
	_check(alley.playing() and alley.current_event == "boss_defeated","boss art plays before Division Result")
	_check(alley.current_path in paths[m.rival] and alley.current_context.rival_id == m.rival,"actual rival selects its own endings")
	_check(not lab.next_rack.visible,"Division Result waits for celebration")
	await _capture("boss_d%02d" % division)
	if division % 2 == 1:
		alley.skip()
	else:
		await _wait_for(func(): return not alley.playing(),"boss ending finishes naturally",240)
	_check(lab.next_rack.visible,"Division Result appears after skip or natural end")
