shader_type canvas_item;
// UI-20's baseline CRT for the alley screen (Codex owns the final look, UI-A9):
// subtle scanlines, a slight barrel curve, a soft glow on bright shapes and a
// vignette. `power` (0..1) drives a power-on/off; `flicker` is 0 under Reduced Flash.

uniform float scanline_strength = 0.18; // subtle: the share of light a scanline removes
uniform float scanlines = 90.0;         // one per source pixel row (the 252 x 90 canvas)
uniform float curve = 0.06;             // barrel strength
uniform float glow = 0.35;              // phosphor bloom on bright pixels
uniform float vignette = 0.35;
uniform float flicker = 0.0;            // brightness wobble, 0 under Reduced Flash
uniform float power = 1.0;              // 0 = off (a thin line), 1 = fully on
uniform vec2 texel = vec2(0.003968, 0.011111); // one source pixel of the 252 x 90 canvas

vec2 barrel(vec2 uv) {
	vec2 c = uv * 2.0 - 1.0;
	c *= 1.0 + curve * dot(c, c);
	return c * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = barrel(UV);
	// Power: the picture squeezes to a horizontal line at the centre.
	float squeeze = mix(0.004, 1.0, smoothstep(0.0, 1.0, power));
	uv.y = (uv.y - 0.5) / squeeze + 0.5;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec3 colour = texture(TEXTURE, uv).rgb;
		vec3 bloom = vec3(0.0);
		for (int i = -1; i <= 1; i++) {
			for (int j = -1; j <= 1; j++) {
				bloom += max(texture(TEXTURE, uv + vec2(float(i), float(j)) * texel).rgb - 0.55, 0.0);
			}
		}
		colour += bloom / 9.0 * glow * 2.0;
		float line = 0.5 + 0.5 * cos(uv.y * scanlines * 6.2831853);
		colour *= 1.0 - scanline_strength * line;
		vec2 v = UV * 2.0 - 1.0;
		colour *= 1.0 - vignette * dot(v, v) * 0.5;
		colour *= 1.0 + flicker * 0.03 * sin(TIME * 60.0);
		colour *= mix(0.0, 1.0, smoothstep(0.0, 0.3, power)) + (1.0 - power) * 0.6;
		COLOR = vec4(colour, 1.0);
	}
}
