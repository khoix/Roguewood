extends Node3D
## UI-A8 (owner, 2026-11-25): the alley's structure in 3D around the one lane, so it
## follows the camera with the lane. The owner's notes:
## - "the alley looks like it's just floating in the air";
## - "This should be the only alley... an alley floor and ceiling, but columns...";
## - "The columns should be out to the width of the alley back wall";
## - a sketch: seen from above, the alley is a T, whose top edge is the back wall.
## Parts:
## - **The stem:** the floor around the lane, narrower than the back wall, open to the
##   sky, with the League's decorations on its shoulders (no columns: owner, 2026-11-25).
## - **The crossbar:** across the far end, exactly as wide as the back wall. The room
##   picture (assets/leagues/*/environment.gd, 9 m at z -21) is the back wall, the
##   whole top edge of the T. Columns stand along its front edge and at its back
##   corners, under its own roof.
## - **The U:** a low surround round the pin deck (kickback height), so the room
##   picture above it stays in view.
## The League's night backdrop shows between the columns, beyond the floor's edges and
## through the roof (its horizon follows the camera's eye line; throw_lab sets it).
## Each Division dresses it its own way, building to the Championship (owner,
## 2026-11-25: "style every Division"):
## - **House:** pines and ferns in its planters, then flowers, topiary and brass urns.
##   The Championship brings trophy pedestals, a red runner, bunting and gold trim.
## - **Neon:** each room's tube colours, and a feature from its art intent. The lounge
##   has palms; the precision gallery, light posts; the listening room and DJ balcony,
##   speakers; the oil hall, drums; the prism salon, prisms; the colonnade, arches; the
##   title antechamber, trophies; the Championship, gold crowns.
## Cosmetic only: no collision, no physics, never touched by a roll. Each material's
## boxes are merged into one mesh, a few draws in all.
const Lane = preload("res://src/simulation/lane_spec.gd")
const STEM_HALF := 1.9 # the stem's half width
const BACK_Z := -21.0 # the room picture: the U's back wall
const FRONT_Z := 3.0
const CROSS_FRONT := -16.0 # the crossbar's front edge
const CROSS_BACK := -21.0 # the back wall: nothing beyond it
const CROSS_HALF := 4.6 # the back wall's width (the room picture spans ±4.5)
const CEILING := 6.0
const CROSS_COLUMNS := [2.55, 3.4, 4.3] # along the crossbar's front edge, each side (|x|)

var league := "house"
var division := 1
var championship := false
var _parts: Dictionary = {} # material key -> SurfaceTool

## Builds the T for a League and room. Call again to rebuild.
func build(at_league: String, at_division: int, at_championship: bool) -> void:
	league = at_league
	division = at_division
	championship = at_championship
	for child in get_children(): child.queue_free()
	_parts.clear()
	var palette := _palette()
	var stem_mid := (FRONT_Z + CROSS_FRONT) * 0.5
	var stem_len := FRONT_Z - CROSS_FRONT
	var cross_mid := (CROSS_FRONT + CROSS_BACK) * 0.5
	var cross_len := CROSS_FRONT - CROSS_BACK
	# Floors, and fascias down into the dark at every outer edge (a built platform).
	_box("floor", Vector3(0, -0.08, stem_mid), Vector3(STEM_HALF * 2.0, 0.04, stem_len))
	# The crossbar's floor leaves the pin pit open (knocked pins fall into it, below
	# the floor's level).
	var pit_x := Lane.LANE_HALF_WIDTH + Lane.GUTTER_WIDTH + 0.12
	var pit_front := -Lane.PIT_F + 0.02
	for side in [-1, 1]:
		_box("floor", Vector3(side * (pit_x + CROSS_HALF) * 0.5, -0.08, cross_mid), Vector3(CROSS_HALF - pit_x, 0.04, cross_len))
	_box("floor", Vector3(0, -0.08, (CROSS_FRONT + pit_front) * 0.5), Vector3(pit_x * 2.0, 0.04, absf(pit_front - CROSS_FRONT)))
	for side in [-1, 1]:
		_box("fascia", Vector3(side * STEM_HALF, -0.9, stem_mid), Vector3(0.1, 1.64, stem_len))
		_box("edge", Vector3(side * (STEM_HALF - 0.04), -0.04, stem_mid), Vector3(0.1, 0.05, stem_len))
		var wing_mid: float = side * (STEM_HALF + CROSS_HALF) * 0.5
		var wing_len := CROSS_HALF - STEM_HALF
		_box("fascia", Vector3(wing_mid, -0.9, CROSS_FRONT), Vector3(wing_len, 1.64, 0.1))
		_box("edge", Vector3(wing_mid, -0.04, CROSS_FRONT - 0.04), Vector3(wing_len, 0.05, 0.1))
		_box("fascia", Vector3(side * CROSS_HALF, -0.9, cross_mid), Vector3(0.1, 1.64, cross_len))
		_box("edge", Vector3(side * (CROSS_HALF - 0.04), -0.04, cross_mid), Vector3(0.1, 0.05, cross_len))
	_box("fascia", Vector3(0, -0.9, CROSS_BACK - 0.05), Vector3(CROSS_HALF * 2.0, 1.64, 0.1))
	# The U: a low surround round the pin deck, at kickback height.
	var u_back := -Lane.PIT_F - Lane.PIT_LENGTH - 0.1
	for side in [-1, 1]:
		_box("wall", Vector3(side * STEM_HALF, Lane.KICKBACK_HEIGHT * 0.5, (CROSS_FRONT + u_back) * 0.5), Vector3(0.2, Lane.KICKBACK_HEIGHT, absf(u_back - CROSS_FRONT)))
	_box("wall", Vector3(0, Lane.KICKBACK_HEIGHT * 0.5, u_back), Vector3(STEM_HALF * 2.0 + 0.2, Lane.KICKBACK_HEIGHT, 0.2))
	# Columns along the crossbar's front edge and at its back corners (owner, 2026-11-25:
	# none along the alleyway).
	var columns: Array = []
	for side in [-1, 1]:
		for x in CROSS_COLUMNS: columns.append(Vector2(side * x, CROSS_FRONT + 0.3))
		columns.append(Vector2(side * CROSS_COLUMNS[-1], CROSS_BACK + 0.35))
	for at in columns:
		_box("column", Vector3(at.x, CEILING * 0.5, at.y), Vector3(0.36, CEILING, 0.36))
		_box("base", Vector3(at.x, 0.12, at.y), Vector3(0.52, 0.24, 0.52))
		_box("capital", Vector3(at.x, CEILING - 0.14, at.y), Vector3(0.52, 0.2, 0.52))
	# The crossbar's beams and slatted roof; the alleyway itself is open to the sky.
	for side in [-1, 1]:
		_box("beam", Vector3(side * CROSS_COLUMNS[-1], CEILING - 0.02, cross_mid), Vector3(0.3, 0.3, cross_len))
	_box("beam", Vector3(0, CEILING - 0.02, CROSS_FRONT + 0.3), Vector3(CROSS_COLUMNS[-1] * 2.0 + 0.3, 0.3, 0.3))
	_box("beam", Vector3(0, CEILING - 0.02, CROSS_BACK + 0.35), Vector3(CROSS_COLUMNS[-1] * 2.0 + 0.3, 0.3, 0.3))
	var slat := CROSS_BACK + 0.5
	while slat < CROSS_FRONT + 0.3:
		_box("ceiling", Vector3(0, CEILING + 0.16, slat), Vector3(CROSS_COLUMNS[-1] * 2.0 + 0.6, 0.06, 0.12))
		slat += 0.55
	if league == "neon":
		_neon_tubes(columns)
		_neon_shoulders()
	else:
		_house_lights()
		_house_shoulders()
	_commit(palette)

## A swag of warm bulbs from a to b (wire and bulbs), sagging in the middle.
func _swag(a: Vector3, b: Vector3) -> void:
	for i in 15:
		var u := i / 14.0
		var p := a.lerp(b, u) - Vector3(0, 0.55 * 4.0 * u * (1.0 - u), 0)
		var step := a.distance_to(b) / 14.0 + 0.02
		_box("wire", p, Vector3(0.015, 0.015, step) if absf(b.z - a.z) > absf(b.x - a.x) else Vector3(step, 0.015, 0.015))
		if i % 3 == 1:
			_box("bulb", p - Vector3(0, 0.07, 0), Vector3(0.09, 0.11, 0.09))

func _house_lights() -> void:
	# Bulbs swagged across the crossbar's front between its columns, and across its
	# middle deeper in the League.
	for side in [-1, 1]:
		var xs: Array = [STEM_HALF - 0.2] + CROSS_COLUMNS
		for k in xs.size() - 1:
			_swag(Vector3(side * xs[k], CEILING - 0.5, CROSS_FRONT + 0.3), Vector3(side * xs[k + 1], CEILING - 0.5, CROSS_FRONT + 0.3))
	if division >= 4 or championship:
		_swag(Vector3(-CROSS_COLUMNS[-1], CEILING - 0.5, CROSS_BACK + 0.35), Vector3(CROSS_COLUMNS[-1], CEILING - 0.5, CROSS_BACK + 0.35))

## Where things stand on the shoulders: the stem's floor between the gutters and its
## edge (z), nearest the player first.
func _spots() -> Array:
	var out := []
	var z := -1.5
	while z > CROSS_FRONT + 1.0:
		out.append(z)
		z -= 3.2
	return out

## House: a low brass rail along the edge, lantern posts, and planters with small
## pines and ferns, alternating; all below waist height but the lanterns.
func _house_shoulders() -> void:
	var shoulder := (Lane.LANE_HALF_WIDTH + Lane.GUTTER_WIDTH + STEM_HALF) * 0.5
	for side in [-1, 1]:
		var rail_x: float = side * (STEM_HALF - 0.12)
		_box("rail", Vector3(rail_x, 0.45, (0.0 + CROSS_FRONT) * 0.5), Vector3(0.04, 0.04, -CROSS_FRONT))
		var post := 0.0
		while post > CROSS_FRONT:
			_box("rail", Vector3(rail_x, 0.225, post), Vector3(0.035, 0.45, 0.035))
			post -= 1.6
		var spots := _spots()
		for k in spots.size():
			var z: float = spots[k] + (0.0 if side < 0 else 1.6)
			var x: float = side * shoulder
			if k % 2 == 0: # a lantern post
				_box("post", Vector3(x, 0.6, z), Vector3(0.08, 1.2, 0.08))
				_box("brass", Vector3(x, 1.24, z), Vector3(0.2, 0.04, 0.2))
				_box("bulb", Vector3(x, 1.36, z), Vector3(0.14, 0.2, 0.14))
				_box("brass", Vector3(x, 1.49, z), Vector3(0.22, 0.05, 0.22))
			else:
				_house_feature(x, z, k)
		if championship: # a red runner down each shoulder
			_box("runner", Vector3(side * shoulder, -0.055, (0.0 + CROSS_FRONT) * 0.5), Vector3(0.7, 0.01, -CROSS_FRONT))
	if championship: _bunting()

## The House's planters by Division (1–2 pines and ferns, 3–4 flowers, 5–6 topiary,
## 7–8 brass urns); the Championship's trophy pedestals.
func _house_feature(x: float, z: float, k: int) -> void:
	if championship:
		_box("planter", Vector3(x, 0.35, z), Vector3(0.42, 0.7, 0.42))
		_box("brass", Vector3(x, 0.72, z), Vector3(0.48, 0.04, 0.48))
		_box("brass", Vector3(x, 0.8, z), Vector3(0.12, 0.12, 0.12)) # stem
		_box("brass", Vector3(x, 0.98, z), Vector3(0.3, 0.24, 0.3)) # cup
		for side in [-1, 1]: _box("brass", Vector3(x + side * 0.19, 1.0, z), Vector3(0.06, 0.14, 0.04)) # handles
		return
	if division >= 7: # a brass urn with a pine
		_box("brass", Vector3(x, 0.08, z), Vector3(0.32, 0.16, 0.32))
		_box("brass", Vector3(x, 0.3, z), Vector3(0.46, 0.3, 0.46))
		_box("brass", Vector3(x, 0.5, z), Vector3(0.38, 0.1, 0.38))
		for t in 3:
			var width := 0.4 - t * 0.12
			_box("pine", Vector3(x, 0.66 + t * 0.2, z), Vector3(width, 0.22, width))
		return
	_box("planter", Vector3(x, 0.2, z), Vector3(0.5, 0.4, 0.5))
	_box("brass", Vector3(x, 0.41, z), Vector3(0.54, 0.03, 0.54))
	if division >= 5: # clipped topiary: a ball on a short trunk
		_box("trunk", Vector3(x, 0.55, z), Vector3(0.06, 0.3, 0.06))
		for layer in [[0.72, 0.26], [0.82, 0.4], [0.94, 0.44], [1.06, 0.4], [1.16, 0.26]]:
			_box("topiary", Vector3(x, layer[0], z), Vector3(layer[1], 0.12, layer[1]))
	elif division >= 3: # flowers over a fern
		for f in 6:
			var yaw := f * PI / 3.0
			_box("fern", Vector3(x, 0.5, z) + Vector3(cos(yaw), 0.0, sin(yaw)) * 0.14, Vector3(0.26, 0.05, 0.1), yaw)
		for b in 7:
			var at := Vector3(x, 0.6 + 0.05 * (b % 3), z) + Vector3(cos(b * 0.9), 0.0, sin(b * 0.9)) * (0.05 + 0.03 * (b % 4))
			_box("blossom_a" if b % 2 == 0 else "blossom_b", at, Vector3(0.07, 0.07, 0.07))
	elif k % 4 == 1: # a small pine
		for t in 3:
			var width := 0.42 - t * 0.12
			_box("pine", Vector3(x, 0.55 + t * 0.2, z), Vector3(width, 0.22, width))
	else: # a fern
		for f in 6:
			var yaw := f * PI / 3.0
			_box("fern", Vector3(x, 0.5, z) + Vector3(cos(yaw), 0.0, sin(yaw)) * 0.16, Vector3(0.3, 0.05, 0.1), yaw)

## The Championship's pennants across the crossbar's front.
func _bunting() -> void:
	var y := CEILING - 0.6
	var z := CROSS_FRONT + 0.3
	var span := CROSS_COLUMNS[-1] * 2.0
	var count := 26
	for i in count:
		var x := -CROSS_COLUMNS[-1] + (i + 0.5) * span / count
		var dip := 0.35 * sin(fposmod(x + CROSS_COLUMNS[-1], span / 3.0) / (span / 3.0) * PI)
		var key: String = ["flag_a", "flag_b", "flag_c"][i % 3]
		_box(key, Vector3(x, y - dip - 0.1, z), Vector3(0.14, 0.18, 0.02))
		_box("wire", Vector3(x, y - dip, z), Vector3(span / count + 0.02, 0.015, 0.015))

## Neon: glowing bollards, potted palms, and chevrons on the floor pointing to the pins.
func _neon_shoulders() -> void:
	var shoulder := (Lane.LANE_HALF_WIDTH + Lane.GUTTER_WIDTH + STEM_HALF) * 0.5
	for side in [-1, 1]:
		var spots := _spots()
		for k in spots.size():
			var z: float = spots[k] + (0.0 if side < 0 else 1.6)
			var x: float = side * shoulder
			if k % 2 == 0: # a bollard with a glowing cap
				_box("bollard", Vector3(x, 0.4, z), Vector3(0.22, 0.8, 0.22))
				_box("tube_a" if k % 4 == 0 else "tube_b", Vector3(x, 0.84, z), Vector3(0.24, 0.08, 0.24))
				_box("tube_a" if k % 4 == 0 else "tube_b", Vector3(x, 0.4, z + 0.115), Vector3(0.04, 0.6, 0.01))
			else:
				_neon_feature(x, z, k)
			# A chevron on the floor between the items, pointing down the lane.
			var cz: float = z - 1.6
			if cz > CROSS_FRONT + 0.6:
				for arm in [-1, 1]:
					# Each arm runs back from the tip (toward the pins is -z) at 45 degrees.
					_box("tube_floor", Vector3(x + arm * 0.09, -0.03, cz + 0.09), Vector3(0.26, 0.02, 0.04), -PI / 4.0 if arm > 0 else -3.0 * PI / 4.0)

## The Neon feature for each room (its art intent, E22-L02).
func _neon_feature(x: float, z: float, k: int) -> void:
	match 9 if championship else division:
		1: _palm(x, z)
		2: # the precision gallery: a slim light post with a glowing ring
			_box("bollard", Vector3(x, 0.7, z), Vector3(0.06, 1.4, 0.06))
			for edge in [[0.0, 0.18], [0.0, -0.18], [0.18, 0.0], [-0.18, 0.0]]:
				_box("tube_b", Vector3(x + edge[0], 1.45, z + edge[1]), Vector3(0.36 if edge[0] == 0.0 else 0.04, 0.04, 0.04 if edge[0] == 0.0 else 0.36))
		3, 6: # the listening room and the DJ balcony: a speaker stack
			_box("speaker", Vector3(x, 0.4, z), Vector3(0.44, 0.8, 0.36))
			_box("speaker", Vector3(x, 1.0, z), Vector3(0.36, 0.4, 0.3))
			for cone in [[0.25, 0.12], [0.58, 0.14], [1.0, 0.1]]:
				var face: float = z + 0.19
				for edge in [[0.0, 1.0], [0.0, -1.0], [1.0, 0.0], [-1.0, 0.0]]:
					var r: float = cone[1]
					_box("tube_b", Vector3(x + edge[0] * r, cone[0] + edge[1] * r, face), Vector3(0.03 if edge[0] != 0.0 else r * 2.0, 0.03 if edge[1] != 0.0 else r * 2.0, 0.01))
			if (9 if championship else division) == 6 and k % 4 == 1: _palm(x, z - 0.9)
		4: # the oil hall: a drum with glowing bands
			for layer in [[0.35, 0.44], [0.35, 0.5]]:
				_box("drum", Vector3(x, layer[0], z), Vector3(layer[1], 0.7, 0.94 * layer[1]))
			for band in [0.2, 0.5]:
				_box("tube_a", Vector3(x, band, z), Vector3(0.52, 0.03, 0.5))
		5: # the prism salon: a glowing prism
			for t in 5:
				var width := 0.5 - t * 0.1
				_box("tube_a" if t % 2 == 0 else "tube_b", Vector3(x, 0.1 + t * 0.2, z), Vector3(width, 0.18, width))
		7: # the colonnade: a little arch
			for side in [-1, 1]:
				_box("bollard", Vector3(x, 0.55, z + side * 0.3), Vector3(0.1, 1.1, 0.1))
			_box("tube_a", Vector3(x, 1.12, z), Vector3(0.06, 0.06, 0.7))
			_box("tube_b", Vector3(x, 1.2, z), Vector3(0.04, 0.04, 0.5))
		8: # the title antechamber: a trophy on a pedestal
			_box("pot", Vector3(x, 0.35, z), Vector3(0.4, 0.7, 0.4))
			_box("cup", Vector3(x, 0.8, z), Vector3(0.1, 0.12, 0.1))
			_box("cup", Vector3(x, 0.98, z), Vector3(0.28, 0.24, 0.28))
		_: # the Championship: a gold crown on a pedestal, between palms
			_box("pot", Vector3(x, 0.35, z), Vector3(0.4, 0.7, 0.4))
			_box("cup", Vector3(x, 0.78, z), Vector3(0.36, 0.1, 0.36))
			for p in 5:
				var px := x - 0.14 + p * 0.07
				_box("cup", Vector3(px, 0.9 + (0.06 if p % 2 == 0 else 0.0), z), Vector3(0.05, 0.16 + (0.1 if p % 2 == 0 else 0.0), 0.05))
			if k % 4 == 1: _palm(x, z - 0.9)

func _palm(x: float, z: float) -> void:
	_box("pot", Vector3(x, 0.22, z), Vector3(0.4, 0.44, 0.4))
	_box("trunk", Vector3(x, 0.8, z), Vector3(0.07, 0.8, 0.07))
	for f in 6:
		var yaw := f * PI / 3.0
		_box("palm", Vector3(x, 1.18, z) + Vector3(cos(yaw), -0.08, sin(yaw)) * 0.3, Vector3(0.6, 0.04, 0.14), yaw)

func _neon_tubes(columns: Array) -> void:
	var k := 0
	for at in columns:
		# A tube up each column's face toward the lane, alternating colours.
		_box("tube_a" if k % 2 == 0 else "tube_b", Vector3(at.x, CEILING * 0.5, at.y + 0.19), Vector3(0.05, CEILING - 0.6, 0.05))
		k += 1
	for side in [-1, 1]:
		_box("tube_floor", Vector3(side * (STEM_HALF - 0.1), -0.01, (FRONT_Z + CROSS_FRONT) * 0.5), Vector3(0.04, 0.02, FRONT_Z - CROSS_FRONT))
		_box("tube_floor", Vector3(side * (STEM_HALF + CROSS_HALF) * 0.5, -0.01, CROSS_FRONT - 0.1), Vector3(CROSS_HALF - STEM_HALF, 0.02, 0.04))
	_box("tube_a", Vector3(0, CEILING - 0.2, CROSS_FRONT + 0.48), Vector3(CROSS_COLUMNS[-1] * 2.0, 0.04, 0.04))

## Each part's colour and whether it glows (unshaded).
func _palette() -> Dictionary:
	if league == "neon":
		var pair: Array = _neon_pair()
		var a: Color = pair[0]
		var b: Color = pair[1]
		return {
			"floor": [Color("140e2a"), false], "fascia": [Color("0c0820"), false], "edge": [Color("2c2160"), false], "cap": [Color("1c1535"), false],
			"column": [Color("1d1440"), false], "base": [Color("2a1f58"), false], "capital": [Color("2a1f58"), false], "wall": [Color("1a1238"), false],
			"beam": [Color("160f33"), false], "ceiling": [Color("0b0820"), false],
			"tube_a": [a, true], "tube_b": [b, true], "tube_floor": [a.darkened(0.3), true],
			"bollard": [Color("1a1238"), false], "pot": [Color("2a1f58"), false], "trunk": [Color("5a3b2a"), false], "palm": [Color("2f7a5a"), false],
			"speaker": [Color("120c26"), false], "drum": [Color("2b2050"), false], "cup": [Color("f5cb69"), true],
		}
	var brass := Color("e9b768") if championship else Color("b79050")
	return {
		"floor": [Color("5a3b22"), false], "fascia": [Color("24170d"), false], "edge": [brass, false], "cap": [Color("3a281a"), false],
		"column": [Color("4a321e"), false], "base": [brass.darkened(0.25), false], "capital": [brass.darkened(0.25), false], "wall": [Color("3a2718"), false],
		"beam": [Color("33231a"), false], "ceiling": [Color("1e140d"), false],
		"bulb": [Color("ffd27a"), true], "wire": [Color("141010"), true],
		"rail": [brass, false], "brass": [brass, false], "post": [Color("2a1c12"), false], "planter": [Color("5b3a20"), false],
		"pine": [Color("1f4a32"), false], "fern": [Color("3f7a3a"), false],
		"trunk": [Color("3a2616"), false], "topiary": [Color("2d5a36"), false],
		"blossom_a": [Color("d0505a"), false], "blossom_b": [Color("f0c860"), false],
		"runner": [Color("8a1f2a"), false], "flag_a": [Color("e9b768"), false], "flag_b": [Color("c4404a"), false], "flag_c": [Color("4fa3a0"), false],
	}

## Neon's two tube colours for the room (each Division its own pair).
func _neon_pair() -> Array:
	if championship: return [Color("f5cb69"), Color("fff6ff")]
	match division:
		2: return [Color("3ff2ff"), Color("e8f6ff")] # the precision gallery: cool and white
		3: return [Color("b48cff"), Color("ff4fd8")] # the listening room
		4: return [Color("ffb347"), Color("3ff2ff")] # the oil hall: amber
		5: return [Color("7dffb0"), Color("ff4fd8")] # the prism salon
		6: return [Color("ff4fd8"), Color("b48cff")] # the DJ balcony
		7: return [Color("3ff2ff"), Color("b48cff")] # the colonnade
		8: return [Color("f5cb69"), Color("ff4fd8")] # the title antechamber
	return [Color("ff4fd8"), Color("3ff2ff")] # the entry lounge

func _box(key: String, centre: Vector3, extent: Vector3, yaw: float = 0.0) -> void:
	if not _parts.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_parts[key] = st
	var st: SurfaceTool = _parts[key]
	var turn := Basis(Vector3.UP, yaw)
	var h := extent * 0.5
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = sgn
			var u := Vector3.ZERO
			var v := Vector3.ZERO
			u[(axis + 1) % 3] = h[(axis + 1) % 3]
			v[(axis + 2) % 3] = h[(axis + 2) % 3]
			var c := n * h[axis]
			var quad := [c - u - v, c + u - v, c + u + v, c - u + v]
			var order := [0, 1, 2, 0, 2, 3] if sgn > 0.0 else [0, 2, 1, 0, 3, 2]
			for k in order:
				st.set_normal(turn * n)
				st.add_vertex(centre + turn * quad[k])

func _commit(palette: Dictionary) -> void:
	for key in _parts:
		var spec: Array = palette.get(key, [Color.MAGENTA, true])
		var material := StandardMaterial3D.new()
		material.albedo_color = spec[0]
		material.roughness = 0.9
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		if spec[1]: material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var node := MeshInstance3D.new()
		node.name = "Alley_" + key
		node.mesh = (_parts[key] as SurfaceTool).commit()
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
	_parts.clear()
