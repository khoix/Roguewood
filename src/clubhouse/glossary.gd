extends RefCounted
## UI-24 (owner, 2026-11-19): Talk the Talk's words, read from content/glossary.json,
## and the checks `qa.py content` runs on them: stable ids, short enough to read at
## a glance, and a picture of a kind GlossaryDiagram draws, built from real rack
## spots, card icons and art that exists.
const PATH := "res://content/glossary.json"
const KINDS := ["rack", "sheet", "ladder", "target", "lane", "charge", "ring", "formula", "retrigger", "cards", "art"]
const CARD_ICONS := "res://assets/ui/cards/"
const TERM_MAX := 20
const TEXT_MAX := 190

static func data() -> Dictionary:
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null: return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

static func sections() -> Array:
	return data().get("sections", [])

## Every term, in order, each with its section's id.
static func terms() -> Array:
	var out: Array = []
	for section in sections():
		for term in section.get("terms", []):
			out.append((term as Dictionary).merged({"section": section.id}, true))
	return out

## What is wrong with a glossary (empty when it is fit to show).
static func validate(glossary: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if int(glossary.get("schema_version", 0)) != 1:
		errors.append("glossary.json: schema_version must be 1")
	var section_list: Array = glossary.get("sections", [])
	if section_list.is_empty():
		errors.append("glossary.json: no sections")
	var seen := {}
	for section in section_list:
		var sid := String(section.get("id", ""))
		if sid.is_empty() or seen.has("s:" + sid): errors.append("glossary.json: section id '%s' is missing or repeated" % sid)
		seen["s:" + sid] = true
		if String(section.get("name", "")).is_empty(): errors.append("glossary.json: section %s has no name" % sid)
		if String(section.get("tab", section.get("name", ""))).length() > 8: errors.append("glossary.json: section %s's tab label is over 8 characters" % sid)
		if section.get("terms", []).is_empty(): errors.append("glossary.json: section %s has no terms" % sid)
		for term in section.get("terms", []):
			var id := String(term.get("id", ""))
			var where := "glossary.json: %s.%s" % [sid, id]
			if id.is_empty() or seen.has(id): errors.append(where + ": id missing or repeated")
			seen[id] = true
			var word := String(term.get("term", ""))
			if word.is_empty() or word.length() > TERM_MAX: errors.append(where + ": term must be 1-%d characters" % TERM_MAX)
			var text := String(term.get("text", ""))
			if text.is_empty() or text.length() > TEXT_MAX: errors.append(where + ": text must be 1-%d characters (%d)" % [TEXT_MAX, text.length()])
			errors.append_array(_diagram_errors(term.get("diagram", {}), where))
	return errors

static func _diagram_errors(d: Dictionary, where: String) -> Array[String]:
	var errors: Array[String] = []
	var kind := String(d.get("kind", ""))
	if kind not in KINDS:
		return [where + ": unknown diagram kind '%s'" % kind]
	match kind:
		"rack":
			var used := {}
			for key in ["roll1", "roll2", "glow", "special"]:
				for p in d.get(key, []):
					if int(p) < 1 or int(p) > 10: errors.append(where + ": rack spot %s is not 1-10" % str(p))
					if key in ["roll1", "roll2"]:
						if used.has(int(p)): errors.append(where + ": pin %d falls twice" % int(p))
						used[int(p)] = true
		"sheet":
			var marks: Array = d.get("marks", [])
			if marks.is_empty() or marks.size() > 3: errors.append(where + ": a sheet shows 1-3 frames")
			for m in marks:
				if not (m is Array and m.size() == 2): errors.append(where + ": each frame has two roll boxes")
		"ladder":
			var steps := int(d.get("steps", 0))
			if steps not in [3, 8]: errors.append(where + ": a ladder has 3 or 8 steps")
			if d.has("labels") and d.labels.size() != steps: errors.append(where + ": one label per step")
			if d.has("glow") and (int(d.glow) < 0 or int(d.glow) >= steps): errors.append(where + ": glow is not a step")
		"target":
			if int(d.get("target", 0)) <= 0 or int(d.get("score", -1)) < 0: errors.append(where + ": a target needs a score and a target")
		"lane":
			if String(d.get("path", "none")) not in ["none", "straight", "hook", "both", "gutter"]: errors.append(where + ": unknown lane path")
			if String(d.get("zone", "")) not in ["", "backend", "boards"]: errors.append(where + ": unknown lane zone")
		"formula":
			if String(d.get("glow", "")) not in ["value", "mult", "score"]: errors.append(where + ": formula glow is value, mult or score")
		"cards":
			var icons: Array = d.get("icons", [])
			if icons.is_empty() or icons.size() > 4: errors.append(where + ": 1-4 cards")
			for icon in icons:
				if not ResourceLoader.exists(CARD_ICONS + String(icon) + ".svg"): errors.append(where + ": no card icon '%s'" % icon)
			if d.has("tags") and d.tags.size() != icons.size(): errors.append(where + ": one tag per card")
		"art":
			var textures: Array = d.get("textures", [])
			if textures.is_empty() or textures.size() > 2: errors.append(where + ": 1-2 pictures")
			for path in textures:
				if not ResourceLoader.exists(String(path)): errors.append(where + ": missing art " + String(path))
	return errors
