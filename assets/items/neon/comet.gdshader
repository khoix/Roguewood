shader_type spatial;
// Static enamel identity. The broad oblique sweep wraps every hemisphere;
// mesh-local coordinates keep it painted on the ball through roll and spin.
varying vec3 local;
void vertex() { local = VERTEX; }
void fragment() {
 vec3 n = normalize(floor(local * 480.0) / 480.0);
 float orbit = dot(n, normalize(vec3(0.78, 0.41, 0.47)));
 float bend = 0.17 + 0.10 * sin(n.z * 4.0 + n.x * 2.0);
 float distance = abs(orbit - bend);
 float tail = 1.0 - smoothstep(0.055, 0.14, distance);
 float edge = (1.0 - smoothstep(0.018, 0.045, abs(orbit - bend + 0.22))) * 0.55;
 vec3 head = normalize(vec3(-0.45, 0.72, 0.53));
 vec3 across = normalize(cross(head, vec3(0.0, 1.0, 0.0)));
 vec3 up = cross(across, head);
 vec2 d = abs(vec2(dot(n, across), dot(n, up)));
 float star = (1.0 - step(1.0, d.x / 0.18 + d.y / 0.26)) * step(0.8, dot(n, head));
 vec3 ink = mix(vec3(0.055, 0.016, 0.14), vec3(0.08, 0.69, 0.78), max(tail, edge));
 ink = mix(ink, vec3(0.93, 0.68, 0.24), star);
 ALBEDO = ink; METALLIC = 0.38; ROUGHNESS = 0.24;
 EMISSION = ink * tail * 0.07;
}
