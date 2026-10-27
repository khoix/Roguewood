shader_type canvas_item;
uniform vec2 tilt = vec2(0.0);
uniform float strength = 0.0;
uniform bool border_only = false;
void fragment() {
 vec4 source = texture(TEXTURE, UV);
 float band = pow(max(0.0, cos((UV.x + UV.y * 0.7 + tilt.x * 0.3 + tilt.y * 0.2) * 12.0)), 10.0);
 vec3 spectrum = 0.5 + 0.5 * cos(vec3(0.0,2.1,4.2) + (UV.x-UV.y+tilt.x)*6.28);
 float edge = step(min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y)),0.12);
 float mask = border_only ? edge : 1.0;
 COLOR = vec4(mix(source.rgb, source.rgb * 0.75 + spectrum * 0.4, band * strength * mask),source.a);
}
