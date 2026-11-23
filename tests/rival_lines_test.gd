extends RefCounted
## The rivals' library of lines (owner, 2026-11-19): the signature line comes first,
## the library adds to it, a pick is one of them, and never the same twice in a row.
const RivalLines = preload("res://src/presentation/rival_lines.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	var rival := {"id": "rival.surveyor", "reactions": {"impressed": "A true line. Precisely as charted."}}
	var options: Array = RivalLines.candidates(rival, "impressed")
	if options.size() < RivalLines.MIN_PER_MOOD or options[0] != "A true line. Precisely as charted.":
		failures.append("rival lines: the signature leads the library (%d lines)" % options.size())
	RivalLines.rng.seed = 7
	var previous := ""
	var seen := {}
	for i in 400:
		var said: String = RivalLines.line(rival, "impressed")
		if said not in options: failures.append("rival lines: a pick outside the rival's lines"); break
		if said == previous: failures.append("rival lines: the same line twice in a row"); break
		previous = said
		seen[said] = true
	if seen.size() != options.size():
		failures.append("rival lines: every line comes up (%d of %d)" % [seen.size(), options.size()])
	# A rival with only its signature still speaks it, every time.
	var lone := {"id": "rival.nobody", "reactions": {"entrance": "Hello."}}
	if RivalLines.line(lone, "entrance") != "Hello." or RivalLines.line(lone, "entrance") != "Hello.":
		failures.append("rival lines: a single line repeats")
	if RivalLines.line(lone, "defeated") != "":
		failures.append("rival lines: no line, no words")
	return failures
