extends RefCounted
## UI-20: the alley screen's variant pick, the boss lists, the gate (nothing without
## art), the completeness rule and the scene contract.
const AlleyScreen = preload("res://src/presentation/alley_screen.gd")
const LeagueTheme = preload("res://src/presentation/league_theme.gd")
const PLACEHOLDER := "res://src/presentation/alley_screen_placeholder.gd"

static func run() -> Array[String]:
	var failures: Array[String] = []
	var screen = AlleyScreen.new()
	# Uniform pick: with a fixed seed, 10,000 picks over 5 variants land within 5% of 2,000 each.
	screen.rng.seed = 20261119
	var list := ["a", "b", "c", "d", "e"]
	var counts := {}
	for i in 10000:
		var p: String = screen.pick(list)
		counts[p] = int(counts.get(p, 0)) + 1
	for v in list:
		if absi(int(counts.get(v, 0)) - 2000) > 100:
			failures.append("UI-20: uniform pick of %s is %d of 10,000 (expected 2,000 ± 100)" % [v, int(counts.get(v, 0))])
	# Nothing plays without art: no League theme and no override means no variants.
	if screen.has_art("strike") or screen.celebrate("strike"):
		failures.append("UI-20: a celebration played with no art")
	# A boss's pick is only ever that rival's two.
	screen.variants_override = {"boss_defeated": {"rival.a": ["a1", "a2"], "rival.b": ["b1", "b2"]}, "strike": list}
	var boss: Array = screen.variants("boss_defeated", "rival.a")
	if boss != ["a1", "a2"] or not screen.variants("boss_defeated", "rival.c").is_empty():
		failures.append("UI-20: boss variants are that rival's own (%s)" % str(boss))
	for i in 200:
		if screen.pick(boss) not in ["a1", "a2"]:
			failures.append("UI-20: a boss pick left that rival's list")
			break
	screen.free()
	# The manifest lookup and the completeness rule.
	var data := {"league_id": "league.test", "celebrations": {"strike": [PLACEHOLDER, PLACEHOLDER, PLACEHOLDER, PLACEHOLDER, PLACEHOLDER],
		"spare": [PLACEHOLDER, PLACEHOLDER, PLACEHOLDER, PLACEHOLDER], "boss_defeated": {"rival.a": [PLACEHOLDER, PLACEHOLDER]}}}
	if LeagueTheme.celebrations_in(data, "strike").size() != 5 or LeagueTheme.celebrations_in(data, "boss_defeated", "rival.a").size() != 2 \
			or not LeagueTheme.celebrations_in({}, "strike").is_empty():
		failures.append("UI-20: the manifest lookup")
	if not LeagueTheme.celebration_gaps(data, ["rival.a", "rival.b"]).is_empty():
		failures.append("UI-20: an unfinished set is not checked until it is marked complete")
	data["celebrations_complete"] = true
	var gaps: Array[String] = LeagueTheme.celebration_gaps(data, ["rival.a", "rival.b"])
	if gaps.size() != 2 or not gaps[0].contains("spare") or not gaps[1].contains("rival.b"):
		failures.append("UI-20: a complete set needs 5 spares and 2 per rival (%s)" % str(gaps))
	# The placeholder follows the scene contract.
	var scene = load(PLACEHOLDER).new()
	for member in ["play", "skip", "duration"]:
		if not scene.has_method(member): failures.append("UI-20: the placeholder lacks " + member)
	if not scene.has_signal("finished"): failures.append("UI-20: the placeholder lacks finished")
	scene.free()
	return failures
