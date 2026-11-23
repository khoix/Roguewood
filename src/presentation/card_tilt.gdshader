shader_type canvas_item;
// Card inspection (owner, 2026-11-19): the whole card tilts as one unit, in
// perspective, toward the pointer. Drawn over the card's own off-screen render
// (CardInspector's TiltView), which has `margin` of empty space on each side so
// the nearer corners have room to grow.

uniform vec2 tilt = vec2(0.0);     // radians: x turns about the vertical axis, y about the horizontal
uniform vec2 margin = vec2(0.08);  // the empty share of the view on each side
uniform float card_aspect = 0.7;   // the card's width / height
uniform float depth = 3.0;         // the eye's distance, in card heights

void fragment() {
	vec2 p = (UV - 0.5) / (1.0 - 2.0 * margin); // the card spans [-0.5, 0.5] untilted
	p.x *= card_aspect;
	vec3 eye = vec3(0.0, 0.0, -depth);
	vec3 ray = vec3(p, 0.0) - eye;
	float cy = cos(tilt.x), sy = sin(tilt.x);
	float cx = cos(tilt.y), sx = sin(tilt.y);
	mat3 turn = mat3(vec3(cy, 0.0, -sy), vec3(0.0, 1.0, 0.0), vec3(sy, 0.0, cy))
		* mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, cx, sx), vec3(0.0, -sx, cx));
	vec3 normal = turn * vec3(0.0, 0.0, 1.0);
	float t = dot(-eye, normal) / dot(ray, normal);
	vec3 local = transpose(turn) * (eye + ray * t);
	vec2 card_uv = vec2(local.x / card_aspect, local.y) + 0.5;
	vec2 inside = step(vec2(0.0), card_uv) * step(card_uv, vec2(1.0));
	vec4 colour = texture(TEXTURE, (card_uv - 0.5) * (1.0 - 2.0 * margin) + 0.5);
	COLOR = colour * inside.x * inside.y;
}
