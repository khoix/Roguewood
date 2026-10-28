extends RefCounted
## What the Clubhouse shows (E16, design §16), computed from the Career, the
## validated unlock graph and the catalogue. Pure: no nodes, files or writes, so
## unit tests check every view, and the screen only lays these rows out.
##
## Views:
## - board:    each League with its access, record, titles and trophy;
## - binder:   every collectible item as Locked, Available, Discovered or Mastered,
##             with what unlocks it and its history;
## - trophies: League titles, mastery ribbons, rival plaques and club decorations,
##             each earned or still to earn;
## - goals:    every mastery objective with progress and whether it is tracked;
## - latest:   the most recent unlocks, newest first.
## Every visual slot names a stable asset ID; ClubhouseArt draws the file when one
## exists and a marked placeholder otherwise (E16-ART supplies the files).
const Career = preload("res://src/persistence/career_profile.gd")
## Categories a player collects; boss rules appear on rival plaques instead.
const BINDER_CATEGORIES := ["ball", "pin", "charm", "consumable", "ball_mod", "pin_mod", "upgrade", "kit"]
const CATEGORY_NAMES := {"ball": "Balls", "pin": "Pins", "charm": "Charms", "consumable": "Tactical", "ball_mod": "Ball mods",
	"pin_mod": "Pin mods", "upgrade": "Upgrades", "kit": "Kits"}
const STATE_NAMES := {"locked": "Locked", "available": "Available", "discovered": "Discovered", "mastered": "Mastered"}

## Asset ID for a Clubhouse slot: trophy.<league>, ribbon.<objective>, plaque.<rival>,
## deco.<name>, card.<item id> (unless the catalogue names the item's card art).
static func asset_id(kind: String, id: String) -> String:
	var tail := id.get_slice(".", 1) if id.contains(".") else id
	match kind:
		"trophy": return "trophy." + tail
		"ribbon": return "ribbon." + tail
		"plaque": return "plaque." + tail
		"card": return "card." + id
	return id

## Who or what awards a gate, in the player's words.
static func source_text(graph: Dictionary, source: String) -> String:
	if source.begins_with("mastery:") or source.begins_with("mastery."):
		var objective_id := source.trim_prefix("mastery:")
		for objective in graph.get("objectives", []):
			if objective.id == objective_id:
				return "Complete %s: %s" % [objective.name, objective.text]
		return "Complete a mastery goal"
	if source.begins_with("championship:") or graph.get("leagues", {}).has(source):
		var league_id := source.trim_prefix("championship:")
		return "Win the %s" % graph.leagues.get(league_id, {}).get("name", league_id)
	if not source.contains(":"):
		return "A rival's first clear"
	var rival_id := source.get_slice(":", 1)
	var rival: Dictionary = graph.get("rivals", {}).get(rival_id, {})
	var league: String = graph.get("leagues", {}).get(rival.get("league", ""), {}).get("name", "")
	return "Beat %s%s" % [rival.get("name", rival_id), " (%s)" % league if not league.is_empty() else ""]

## What a locked item waits for: one line per gate, each naming its sources.
static func requirement(graph: Dictionary, item: Dictionary) -> String:
	var lines: Array = []
	for gate in item.get("unlock", {}).get("prerequisites", []):
		var sources: Array = graph.get("gates", {}).get(gate, {}).get("sources", [])
		lines.append(" or ".join(sources.map(func(s): return source_text(graph, s))))
	return "; ".join(lines)

static func board(career: Dictionary, graph: Dictionary) -> Array:
	var rows: Array = []
	for league_id in graph.get("leagues", {}):
		var league: Dictionary = graph.leagues[league_id]
		var record: Dictionary = career.records.get(league_id, {})
		rows.append({"id": league_id, "name": league.name, "content_set": league.content_set,
			"access": _access(career, graph, league_id),
			"attempts": int(record.get("attempts", 0)), "best_division": int(record.get("best_division", 0)),
			"best_total": int(record.get("best_total", 0)), "best_frame": int(record.get("best_frame", 0)),
			"practice_best_frame": int(record.get("practice_best_frame", 0)),
			"titles": int(career.championships.get(league_id, {}).get("wins", 0)), "trophy": asset_id("trophy", league_id)})
	return rows

static func _access(career: Dictionary, graph: Dictionary, league_id: String) -> String:
	var missing: Array = graph.leagues[league_id].access.filter(func(g): return g not in career.unlocked)
	if missing.is_empty():
		return ""
	return "Locked: " + "; ".join(missing.map(func(g): return " or ".join(graph.gates.get(g, {}).get("sources", []).map(func(s): return source_text(graph, s)))))

## One line per League for the board.
static func record_line(row: Dictionary) -> String:
	if row.attempts == 0 and row.practice_best_frame == 0:
		return "%s · not played yet" % row.name
	var text := "%s · %d attempt%s · best Division %d · best total %d · best frame %d · %d title%s" % [row.name, row.attempts,
		"" if row.attempts == 1 else "s", row.best_division, row.best_total, row.best_frame, row.titles, "" if row.titles == 1 else "s"]
	if row.practice_best_frame > 0:
		text += " · practice best frame %d" % row.practice_best_frame
	return text

## Binder entries in catalogue order. category "" lists every collectible category.
static func binder(career: Dictionary, graph: Dictionary, catalogue: Dictionary, category: String = "") -> Array:
	var out: Array = []
	for item in catalogue.get("items", []):
		if item.category not in BINDER_CATEGORIES or (not category.is_empty() and item.category != category):
			continue
		var state := Career.collection_state(career, item)
		var history: Dictionary = career.items.get(item.id, {})
		var card: String = String(item.get("assets", {}).get("card", ""))
		out.append({"id": item.id, "name": item.name, "category": item.category, "rarity": item.rarity, "state": state,
			"requirement": requirement(graph, item) if state == "locked" else "",
			"attempts": int(history.get("attempts", 0)), "league_wins": int(history.get("league_wins", 0)),
			"asset": card if not card.is_empty() else asset_id("card", item.id)})
	return out

## Counts per state across the binder, for the header.
static func binder_counts(entries: Array) -> Dictionary:
	var counts := {"locked": 0, "available": 0, "discovered": 0, "mastered": 0}
	for entry in entries:
		counts[entry.state] += 1
	return counts

## Detail text for one binder entry (the inspect view).
static func inspect(entry: Dictionary, catalogue: Dictionary) -> String:
	var item: Dictionary = {}
	for candidate in catalogue.get("items", []):
		if candidate.id == entry.id:
			item = candidate
	var lines: Array = ["%s · %s %s · %s" % [entry.name, String(entry.rarity).capitalize(), CATEGORY_NAMES.get(entry.category, entry.category).trim_suffix("s"), STATE_NAMES[entry.state]]]
	match entry.state:
		"locked":
			lines.append("Unlock: " + entry.requirement + ". It then joins the pool from your next attempt.")
		"available":
			lines.append("In the pool; not owned in an attempt yet.")
		_:
			lines.append("Owned in %d attempt%s; in %d League win%s." % [entry.attempts, "" if entry.attempts == 1 else "s", entry.league_wins, "" if entry.league_wins == 1 else "s"])
	if entry.state == "discovered":
		lines.append("Win a League with it in your build to master it.")
	if not String(item.get("downside", "")).is_empty():
		lines.append("Tradeoff: " + item.downside)
	lines.append("The binder keeps its history; a new attempt never starts with it.")
	return "\n".join(lines)

## Shelf slots: titles, ribbons, plaques, then decorations.
static func trophies(career: Dictionary, graph: Dictionary) -> Array:
	var out: Array = []
	for league_id in graph.get("leagues", {}):
		var wins := int(career.championships.get(league_id, {}).get("wins", 0))
		out.append({"kind": "trophy", "id": league_id, "name": "%s title" % graph.leagues[league_id].name, "earned": wins > 0,
			"detail": ("Won %d time%s" % [wins, "" if wins == 1 else "s"]) if wins > 0 else "Win the %s" % graph.leagues[league_id].name,
			"asset": asset_id("trophy", league_id)})
	for objective in graph.get("objectives", []):
		var done: bool = career.mastery.has(objective.id)
		out.append({"kind": "ribbon", "id": objective.id, "name": "%s ribbon" % objective.name, "earned": done,
			"detail": objective.reward if done else objective.text, "asset": asset_id("ribbon", objective.id)})
	var rival_ids: Array = graph.get("rivals", {}).keys()
	rival_ids.sort()
	for rival_id in rival_ids:
		var rival: Dictionary = graph.rivals[rival_id]
		if not rival.plaque:
			continue
		var cleared: bool = career.first_clears.has(rival_id)
		out.append({"kind": "plaque", "id": rival_id, "name": "%s plaque" % rival.name, "earned": cleared,
			"detail": "First cleared" if cleared else source_text(graph, rival.league + ":" + rival_id), "asset": asset_id("plaque", rival_id)})
	for cosmetic in graph.get("cosmetics", []):
		var earned := milestone_count(career, cosmetic.requires.keys()[0]) >= int(cosmetic.requires.values()[0])
		out.append({"kind": "decoration", "id": cosmetic.id, "name": cosmetic.name, "earned": earned,
			"detail": cosmetic.get("text", "") if earned else _milestone_text(cosmetic.requires), "asset": cosmetic.id})
	return out

static func milestone_count(career: Dictionary, kind: String) -> int:
	match kind:
		"first_clears": return career.first_clears.size()
		"mastery": return career.mastery.size()
		"championships":
			var titles := 0
			for entry in career.championships.values():
				titles += int(entry.wins)
			return titles
	return 0

static func _milestone_text(requires: Dictionary) -> String:
	var n := int(requires.values()[0])
	match requires.keys()[0]:
		"first_clears": return "Clear %d rival%s for the first time" % [n, "" if n == 1 else "s"]
		"mastery": return "Complete %d mastery goal%s" % [n, "" if n == 1 else "s"]
	return "Win %d League title%s" % [n, "" if n == 1 else "s"]

## Every objective with progress (Career totals, or 0 for a single-attempt goal
## between attempts) and its tracked flag.
static func goals(career: Dictionary, graph: Dictionary) -> Array:
	var out: Array = []
	for objective in graph.get("objectives", []):
		var done: bool = career.mastery.has(objective.id)
		out.append({"id": objective.id, "name": objective.name, "text": objective.text, "reward": objective.reward, "done": done,
			"progress": mini(Career.progress(career, objective, 0), int(objective.threshold)), "threshold": int(objective.threshold),
			"scope": objective.scope, "tracked": objective.id in career.get("tracked", []), "asset": asset_id("ribbon", objective.id)})
	return out

## The newest unlocks first: {gate, name, text}.
static func latest(career: Dictionary, graph: Dictionary, limit: int = 3) -> Array:
	var out: Array = []
	var gates: Array = career.unlocked.duplicate()
	gates.reverse()
	for gate in gates.slice(0, limit):
		var items: Array = graph.get("items_by_gate", {}).get(gate, [])
		var names: Array = items.map(func(id): return _item_name(graph, id))
		var source: String = String(career.awards.get(gate, {}).get("source", ""))
		var how := source_text(graph, source)
		var text: String = "%s: %s join%s the shop pool from your next attempt." % [how, ", ".join(names), "s" if names.size() == 1 else ""] \
			if not names.is_empty() else "%s: %s." % [how, graph.get("gates", {}).get(gate, {}).get("name", gate)]
		out.append({"gate": gate, "name": graph.get("gates", {}).get(gate, {}).get("name", gate), "text": text})
	return out

static func _item_name(graph: Dictionary, id: String) -> String:
	for item in graph.get("catalogue", {}).get("items", []):
		if item.id == id:
			return item.name
	return id
