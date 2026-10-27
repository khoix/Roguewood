extends SceneTree
## Read-only compatibility probe against an explicitly supplied E13 LeagueRun.
## Run: --script tools/test_campaign_league.gd -- --league-source=res://artifacts/e14/league_run.gd
const Generator = preload("res://src/procedural/campaign_generator.gd")
const Division = preload("res://src/rules/division_run.gd")
func _initialize() -> void:
	var source := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--league-source="): source = arg.trim_prefix("--league-source=")
	if source.is_empty():
		printerr("Supply the actual E13 LeagueRun source; this is not a replacement controller.")
		quit(1)
		return
	var model = load(source)
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/fixtures/lab_division.json"))
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/fixtures/lab_catalogue.json"))
	var profile := {"id": "integration.fixture", "division_template": base, "bosses": [], "lanes": [{"id": "lane.normal", "text": "Normal"}], "targets": []}
	for i in range(8):
		var boss: Dictionary = base.rivals[0].duplicate(true)
		boss.id = "rival.fixture%d" % i
		boss["compatible_lanes"] = ["lane.normal"]
		profile.bosses.append(boss)
		profile.targets.append([100 + 400 * i, 200 + 400 * i, 300 + 400 * i])
	var schedule := Generator.generate(42, profile, catalogue)
	var failures: Array[String] = []
	if not schedule.errors.is_empty(): failures.append("generation failed")
	else:
		var run = _new_run(model, schedule.divisions)
		for i in range(24):
			if run.target() != 100 + 400 * (i / 3) + 100 * (i % 3):
				failures.append("target mismatch")
			if not run.record_frame(run.target()).won: failures.append("exact-target win failed")
			if i < 23:
				if run.upcoming().is_empty(): failures.append("missing pre-shop preview")
				if not run.next_match().is_empty(): failures.append("advance refused")
		if run.outcome != "won" or run.results.size() != 24: failures.append("campaign win failed")
		var continued := Generator.extend_endless(schedule, profile, catalogue, [3200, 3300, 3400], run.outcome == "won")
		run.specs = continued.divisions
		if run.is_finished() or not run.division_cleared(): failures.append("endless did not reopen progression")
		if not run.next_match().is_empty() or run.division_number() != 9: failures.append("endless advance failed")
		for i in range(3):
			run.record_frame(run.target())
			if i < 2: run.next_match()
		if run.outcome != "won" or run.results.size() != 27: failures.append("endless win failed")
		for match_index in range(24):
			var lost = _new_run(model, schedule.divisions)
			for i in range(match_index):
				lost.record_frame(lost.target())
				lost.next_match()
			lost.record_frame(0)
			lost.record_frame(0)
			if lost.outcome != "lost" or lost.next_match().is_empty(): failures.append("loss did not terminate attempt")
		# Explicit evidence of the current shared-contract mismatch, not a success claim.
		print("E13_VALIDATOR_FINDINGS: ", model.validate({"schema_version": 1, "divisions": schedule.divisions}, catalogue))
	for failure in failures: printerr("FAIL: " + failure)
	if failures.is_empty(): print("ROGUEWOOD_CAMPAIGN_LEAGUE_PROBE_OK (24 matches, 24 loss positions, endless)")
	quit(0 if failures.is_empty() else 1)

func _new_run(model: GDScript, specs: Array) -> RefCounted:
	# Avoid static create's hardcoded resource path while probing an unmerged script.
	var run = model.new()
	run.specs = specs.duplicate(true)
	run.active = Division.create(run.specs[0])
	return run
