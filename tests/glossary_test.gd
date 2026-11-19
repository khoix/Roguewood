extends RefCounted
## UI-24: Talk the Talk's content and its pictures' geometry.
const Glossary = preload("res://src/clubhouse/glossary.gd")
const Diagram = preload("res://src/presentation/glossary_diagram.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	var data := Glossary.data()
	var errors := Glossary.validate(data)
	if not errors.is_empty():
		failures.append("glossary: " + "; ".join(errors))
	var ids: Array = Glossary.terms().map(func(t): return t.id)
	for id in ["opener", "feature", "boss", "open", "hook", "strike", "spare", "split", "pocket", "turkey", "value", "mult", "charms"]:
		if id not in ids: failures.append("glossary: '%s' is missing" % id)
	var sections: Array = Glossary.sections().map(func(s): return s.name)
	if sections != ["The Run", "Frames", "Lane & Ball", "Scoring", "Your Cards"]:
		failures.append("glossary: the five tabs are %s" % str(sections))
	# The checks catch a broken entry.
	var broken := data.duplicate(true)
	broken.sections[0].terms[0].diagram = {"kind": "rack", "roll1": [1, 11], "roll2": [1]}
	broken.sections[0].terms[1].id = broken.sections[0].terms[0].id
	broken.sections[1].terms[0].diagram = {"kind": "art", "textures": ["res://missing.png"]}
	broken.sections[1].terms[1].diagram = {"kind": "spiral"}
	broken.sections[2].terms[0].text = "x".repeat(Glossary.TEXT_MAX + 1)
	var found := " ".join(Glossary.validate(broken))
	for needle in ["is not 1-10", "falls twice", "repeated", "missing art", "unknown diagram kind", "text must be"]:
		if not found.contains(needle): failures.append("glossary: validate misses '%s'" % needle)
	# The rack is the frame review's: head pin nearest, 2 on the left, 3 on the right, the back row furthest.
	var head := Diagram.spot(1)
	if not (Diagram.spot(2).x < head.x and Diagram.spot(3).x > head.x and Diagram.spot(7).y < Diagram.spot(4).y and Diagram.spot(4).y < Diagram.spot(2).y and Diagram.spot(2).y < head.y):
		failures.append("glossary: rack spots are out of place")
	if not (is_equal_approx(Diagram.spot(7).y, Diagram.spot(10).y) and Diagram.spot(7).x < Diagram.spot(10).x):
		failures.append("glossary: the back row runs 7 to 10, left to right")
	# A throw's picture follows the hand.
	var right := Diagram.new({"kind": "rack", "pocket": true}, "right")
	var left := Diagram.new({"kind": "rack", "pocket": true}, "left")
	if not (right.side() > 0 and left.side() < 0):
		failures.append("glossary: a left-hander's picture is mirrored")
	left.set_handedness("right")
	if left.side() < 0: failures.append("glossary: the hand can change")
	if Diagram._frame_name(["", "X"]) != "Strike" or Diagram._frame_name(["8", "/"]) != "Spare" or Diagram._frame_name(["8", "1"]) != "Open":
		failures.append("glossary: the score sheet names frames")
	right.free()
	left.free()
	return failures
