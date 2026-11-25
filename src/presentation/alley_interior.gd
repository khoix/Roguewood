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
## UI-A8b (owner, 2026-11-25: "The alleyway shoulders need more details and
## definition. Shadowing, perhaps. It doesn't look done."): the floor's shader draws
## pixel boards (House) or tiles (Neon), darkens beside the gutters and toward the
## edges, lays a soft shadow under everything standing on it, and pools each lamp's
## light on the boards. These hold where things stand, filled as the build places them.
var _lights: Array = [] # [Vector2 at, radius, strength, Color]
var _shadows: Array = [] # Vector3(x, z, radius)
const FLOOR_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec3 tone_a; uniform vec3 tone_b; uniform vec3 seam;
uniform vec3 grid_a; uniform vec3 grid_b;
uniform int style = 0; // 0: boards (House); 1: tiles (Neon)
uniform float texel = 0.03;
uniform float gutter_x; uniform float stem_x; uniform float cross_x; uniform float cross_front;
uniform vec4 lights[24]; uniform vec3 light_colors[24]; uniform int light_count = 0;
uniform vec3 shadows[48]; uniform int shadow_count = 0;
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 p = (floor(world.xz / texel) + 0.5) * texel; // pixel art: one colour per texel
	vec3 col;
	if (style == 0) {
		float board = floor(p.x / 0.18);
		float offset = hash(vec2(board, 3.0)) * 1.4;
		float run = floor((p.y + offset) / 1.4);
		col = mix(tone_a, tone_b, hash(vec2(board, run)));
		col *= 0.9 + 0.1 * hash(floor(p / vec2(texel, texel * 5.0)));
		float across = fract(p.x / 0.18);
		float along = fract((p.y + offset) / 1.4);
		if (across < texel / 0.18 || along < texel / 1.4) col = seam;
		if (abs(along - 0.5) < texel / 1.4 && abs(across - 0.5) < texel / 0.18 * 1.5) col = seam * 1.6; // a nail
	} else {
		vec2 cell = floor(p / 0.6);
		col = mix(tone_a, tone_b, hash(cell) * 0.7);
		vec2 f = fract(p / 0.6);
		if (f.x < texel / 0.6 || f.y < texel / 0.6) col = mix(col, mod(cell.x + cell.y, 2.0) < 1.0 ? grid_a : grid_b, 0.3);
	}
	// Ambient occlusion: darker against the lane's cap and toward the platform's edges.
	float ax = abs(world.x);
	float edge = world.z < cross_front ? cross_x : stem_x;
	float shade = mix(0.5, 1.0, smoothstep(gutter_x, gutter_x + 0.4, ax));
	shade *= mix(0.62, 1.0, smoothstep(edge, edge - 0.35, ax));
	for (int i = 0; i < shadow_count; i++) {
		float d = length(world.xz - shadows[i].xy);
		shade *= mix(0.42, 1.0, smoothstep(shadows[i].z * 0.45, shadows[i].z, d));
	}
	vec3 glow = vec3(0.0);
	for (int i = 0; i < light_count; i++) {
		float d = length(world.xz - lights[i].xy);
		float k = lights[i].w * (1.0 - smoothstep(0.0, lights[i].z, d));
		glow += light_colors[i] * floor(k * 4.0 + 0.5) / 4.0; // stepped, like pixel light
	}
	ALBEDO = col * shade + col * glow * 1.5;
}
"""
## UI-A8b: every standing piece: a darker edge round each face, about a pixel and a half
## wide however far (pixel-art outlines), over the vertex colour, which darkens toward
## the floor where it stands (contact shade).
const PART_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 albedo : source_color;
uniform float rim_px = 1.5;
uniform float rim_shade = 0.7;
void fragment() {
	vec2 d = min(UV, 1.0 - UV) * UV2; // metres to the face's nearest edge
	float e = min(d.x, d.y);
	float w = min(fwidth(e) * rim_px, 0.2 * min(UV2.x, UV2.y));
	ALBEDO = albedo * COLOR.rgb * (e < w ? rim_shade : 1.0);
	ROUGHNESS = 0.9;
}
"""

## Builds the T for a League and room. Call again to rebuild.
func build(at_league: String, at_division: int, at_championship: bool) -> void:
	league = at_league
	division = at_division
	championship = at_championship
	for child in get_children(): child.queue_free()
	_parts.clear()
	_lights.clear()
	_shadows.clear()
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
	# A trim board against the lane's cap on each side (the cap ends 0.862 out): a dark
	# line that frames the shoulder.
	var trim_len := Lane.KICKBACK_START_F + 0.05 # it runs into the kickback, faces apart
	for side in [-1, 1]:
		var tx: float = side * (Lane.LANE_HALF_WIDTH + Lane.GUTTER_WIDTH + 0.1 + 0.06)
		_box("trim", Vector3(tx, -0.025, -trim_len * 0.5), Vector3(0.12, 0.07, trim_len))
	# The U: a low surround round the pin deck, at kickback height.
	# Its back wall stands clear behind the cushion (f PIT_F + PIT_LENGTH to +0.1):
	# UI-A8 had its front face 0.4 mm from the cushion's, and the two fought for
	# depth (the owner saw the pin deck flicker as the camera followed the ball).
	var u_back := -Lane.PIT_F - Lane.PIT_LENGTH - 0.1 - 0.15
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
		_shadows.append(Vector3(at.x, at.y, 0.75))
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
	for x in [-3.4, -1.2, 1.2, 3.4]: # the crossbar's lights, pooled on its floor
		_lights.append([Vector2(x, CROSS_FRONT - 1.2), 1.6, 0.6, _neon_pair()[0] if league == "neon" else Color("ffc46a")])
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
				_lights.append([Vector2(x, z), 1.5, 0.9, Color("ffc46a")])
				_shadows.append(Vector3(x, z, 0.32))
				_box("post", Vector3(x, 0.6, z), Vector3(0.08, 1.2, 0.08))
				_box("brass", Vector3(x, 1.24, z), Vector3(0.2, 0.04, 0.2))
				_box("bulb", Vector3(x, 1.36, z), Vector3(0.14, 0.2, 0.14))
				_box("brass", Vector3(x, 1.49, z), Vector3(0.22, 0.05, 0.22))
			else:
				_shadows.append(Vector3(x, z, 0.75))
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
				var pair: Array = _neon_pair()
				_lights.append([Vector2(x, z), 1.2, 0.8, pair[0] if k % 4 == 0 else pair[1]])
				_shadows.append(Vector3(x, z, 0.42))
				_box("bollard", Vector3(x, 0.4, z), Vector3(0.22, 0.8, 0.22))
				_box("tube_a" if k % 4 == 0 else "tube_b", Vector3(x, 0.84, z), Vector3(0.24, 0.08, 0.24))
				_box("tube_a" if k % 4 == 0 else "tube_b", Vector3(x, 0.4, z + 0.115), Vector3(0.04, 0.6, 0.01))
			else:
				_shadows.append(Vector3(x, z, 0.75))
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
			"floor": [Color("140e2a"), false], "fascia": [Color("0c0820"), false], "trim": [Color("100a24"), false], "edge": [Color("2c2160"), false], "cap": [Color("1c1535"), false],
			"column": [Color("1d1440"), false], "base": [Color("2a1f58"), false], "capital": [Color("2a1f58"), false], "wall": [Color("1a1238"), false],
			"beam": [Color("160f33"), false], "ceiling": [Color("0b0820"), false],
			"tube_a": [a, true], "tube_b": [b, true], "tube_floor": [a.darkened(0.3), true],
			"bollard": [Color("1a1238"), false], "pot": [Color("2a1f58"), false], "trunk": [Color("5a3b2a"), false], "palm": [Color("2f7a5a"), false],
			"speaker": [Color("120c26"), false], "drum": [Color("2b2050"), false], "cup": [Color("f5cb69"), true],
		}
	var brass := Color("e9b768") if championship else Color("b79050")
	return {
		"floor": [Color("5a3b22"), false], "fascia": [Color("24170d"), false], "trim": [Color("2e1d10"), false], "edge": [brass, false], "cap": [Color("3a281a"), false],
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
			var corners := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
			var size := Vector2(extent[(axis + 1) % 3], extent[(axis + 2) % 3])
			var order := [0, 1, 2, 0, 2, 3] if sgn > 0.0 else [0, 2, 1, 0, 3, 2]
			for k in order:
				var at: Vector3 = centre + turn * quad[k]
				# Contact shade: darker toward the floor (not on flat trims, nor below it).
				var contact := 1.0
				if extent.y >= 0.1 and at.y > -0.07:
					contact = lerpf(0.78, 1.0, clampf((at.y + 0.06) / 0.45, 0.0, 1.0))
				st.set_color(Color(contact, contact, contact))
				st.set_uv(corners[k])
				st.set_uv2(size)
				st.set_normal(turn * n)
				st.add_vertex(at)

func _commit(palette: Dictionary) -> void:
	for key in _parts:
		var spec: Array = palette.get(key, [Color.MAGENTA, true])
		var material: Material
		if key == "floor":
			material = _floor_material()
		elif spec[1]: # glows: one flat colour
			var plain := StandardMaterial3D.new()
			plain.albedo_color = spec[0]
			plain.cull_mode = BaseMaterial3D.CULL_DISABLED
			plain.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material = plain
		else:
			if _part_shader == null:
				_part_shader = Shader.new()
				_part_shader.code = PART_SHADER
			var part := ShaderMaterial.new()
			part.shader = _part_shader
			part.set_shader_parameter("albedo", spec[0])
			material = part
		var node := MeshInstance3D.new()
		node.name = "Alley_" + key
		node.mesh = (_parts[key] as SurfaceTool).commit()
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
	_parts.clear()

static var _floor_shader: Shader # compiled once for the session (PERF-3's lesson)
static var _part_shader: Shader

## UI-A8b: the floor's material: boards or tiles, shade, shadows and lamp light.
func _floor_material() -> ShaderMaterial:
	if _floor_shader == null:
		_floor_shader = Shader.new()
		_floor_shader.code = FLOOR_SHADER
	var m := ShaderMaterial.new()
	m.shader = _floor_shader
	var neon := league == "neon"
	var pair: Array = _neon_pair()
	m.set_shader_parameter("style", 1 if neon else 0)
	m.set_shader_parameter("tone_a", Color("1c1440") if neon else Color("664427"))
	m.set_shader_parameter("tone_b", Color("140e2e") if neon else Color("4d311c"))
	m.set_shader_parameter("seam", Color("0a0716") if neon else Color("2a190d"))
	m.set_shader_parameter("grid_a", pair[0])
	m.set_shader_parameter("grid_b", pair[1])
	m.set_shader_parameter("gutter_x", Lane.LANE_HALF_WIDTH + Lane.GUTTER_WIDTH + 0.22)
	m.set_shader_parameter("stem_x", STEM_HALF)
	m.set_shader_parameter("cross_x", CROSS_HALF)
	m.set_shader_parameter("cross_front", CROSS_FRONT)
	var lights := PackedVector4Array()
	var colors := PackedVector3Array()
	for l in _lights.slice(0, 24):
		lights.append(Vector4(l[0].x, l[0].y, l[1], l[2]))
		colors.append(Vector3(l[3].r, l[3].g, l[3].b))
	while lights.size() < 24:
		lights.append(Vector4.ZERO)
		colors.append(Vector3.ZERO)
	var shadows := PackedVector3Array(_shadows.slice(0, 48))
	while shadows.size() < 48: shadows.append(Vector3.ZERO)
	m.set_shader_parameter("lights", lights)
	m.set_shader_parameter("light_colors", colors)
	m.set_shader_parameter("light_count", mini(_lights.size(), 24))
	m.set_shader_parameter("shadows", shadows)
	m.set_shader_parameter("shadow_count", mini(_shadows.size(), 48))
	return m
