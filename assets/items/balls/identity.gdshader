shader_type spatial;
render_mode specular_schlick_ggx;
// Object-local identity follows the physical rotation; no TIME, noise or flashes.
uniform int identity = 0;
varying vec3 local_position;
void vertex() { local_position = VERTEX; }
float band(float distance, float width) { return 1.0 - smoothstep(width, width + 0.018, abs(distance)); }
void fragment() {
 vec3 n = normalize(local_position);
 // Fixed surface clusters; stable with both reduced-effects settings.
 vec3 p = floor(n * 48.0) / 48.0;
 vec3 petrol = vec3(0.035, 0.18, 0.21);
 vec3 brass = vec3(0.72, 0.43, 0.16);
 vec3 ivory = vec3(0.85, 0.83, 0.66);
 vec3 c = petrol;
 float metal = 0.25;
 float rough = 0.22;
 if (identity == 0) {
  float vein = sin(p.y * 9.0 + sin(p.x * 7.0 + p.z * 4.0) * 1.8);
  c = mix(petrol, vec3(0.07, 0.32, 0.34), smoothstep(-0.8, 0.7, vein));
  c = mix(c, brass, smoothstep(0.95, 1.0, vein));
 } else if (identity == 1) {
  float crescent = band(length(p.xy - vec2(-0.12, 0.12)) - 0.67, 0.12);
  crescent *= smoothstep(-0.3, 0.5, p.x) * smoothstep(-0.5, 0.3, p.z);
  float seam = band(p.x + 0.35 * sin(p.y * 4.0 + p.z), 0.028);
  c = mix(petrol, brass, max(crescent, seam * 0.8));
  c += vec3(0.03) * band(p.y - 0.4, 0.02);
 } else if (identity == 2) {
  float straps = max(band(p.x + p.y * 0.7, 0.16), band(p.y - p.x * 0.7, 0.16));
  c = mix(vec3(0.13, 0.16, 0.19), vec3(0.40, 0.20, 0.10), straps);
  float rivet = band(length(fract(vec2(atan(n.z,n.x)*3.0, n.y*4.0))-0.5), 0.12);
  c = mix(c, brass, rivet * straps);
  metal = 0.78; rough = 0.34;
 } else {
  float rings = band(sin(acos(clamp(n.z, -1.0, 1.0)) * 12.0), 0.15);
  c = mix(ivory, petrol, rings);
  c = mix(c, brass, band(sin(acos(clamp(n.z, -1.0, 1.0)) * 12.0) - 0.28, 0.04));
  rough = 0.27; metal = 0.35;
 }
 ALBEDO = c; METALLIC = metal; ROUGHNESS = rough; SPECULAR = 0.4;
}
