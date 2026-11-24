extends "res://tests/house_league_journey.gd"
## Actual House boss wins with candidate art supplied only through the review override.
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
	alley.variants_override = {"boss_defeated":paths}
	var before: int = alley.played.size()
	await super._play_match(division,m)
	if m.kind != "boss":
		_check(alley.played.size() == before,"ordinary match has no boss celebration")
		return
	_check(alley.played.size() == before+1,"one celebration per actual boss win")
	_check(alley.playing() and alley.current_event == "boss_defeated","boss art plays before Division Result")
	_check(alley.current_path in paths[m.rival] and alley.current_context.rival_id == m.rival,"actual rival selects its own endings")
	_check(not lab.next_rack.visible,"Division Result waits for celebration")
	await _capture("boss_d%02d" % division)
	if division % 2 == 1:
		alley.skip()
	else:
		await _wait_for(func(): return not alley.playing(),"boss ending finishes naturally",240)
	_check(lab.next_rack.visible,"Division Result appears after skip or natural end")
