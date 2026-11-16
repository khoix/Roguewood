shader_type spatial;
render_mode unshaded;
// Original title illustration, projected onto the actual rotating sphere.
// Split its broad neutral reflection from the enamel so the lamp stays fixed
// while the teal/gold grain, holes and maker's mark travel around the Y axis.
uniform sampler2D illustration : source_color, filter_linear;
uniform float turn = 0.0;
varying vec3 local_point;
void vertex() { local_point = VERTEX; }
vec3 artwork(vec2 p, float limit) {
 // Match the reference pose: holes upper-right, diamond below center.
 p = vec2(p.x + p.y, -p.x + p.y) * 0.70710678;
 p *= min(1.0, limit / max(length(p), 0.001));
 vec2 uv = (vec2(52.0,45.0) + (p * 0.5 + 0.5) * 538.0) / 1280.0;
 return texture(illustration,uv).rgb;
}
float reflection(vec3 c) { return max(0.0,min(c.r,min(c.g,c.b))-0.26); }
void fragment() {
 vec3 n = normalize(local_point);
 vec2 front = vec2(-n.x,-n.y);
 vec3 paint = artwork(front,0.80);
 // The unseen rear uses the illustration's lower enamel field, without
 // duplicating its finger holes. Blend across the side rather than a hard seam.
 vec2 rear_field = vec2(-0.42 + atan(n.x,n.z) / 3.14159265 * 0.32,0.30+n.y*0.40);
 vec3 rear = artwork(vec2(rear_field.x-rear_field.y,rear_field.x+rear_field.y)*0.70710678,0.90);
 float back = 1.0 - pow(max(cos(turn),0.0),4.0);
 paint = mix(paint,rear,back);
 float enamel_mask = smoothstep(0.008,0.055,max(paint.r,max(paint.g,paint.b)));
 paint -= vec3(reflection(paint));
 vec3 view_normal = normalize(NORMAL);
 vec2 lamp_point = vec2(view_normal.x,-view_normal.y);
 vec2 spot = (lamp_point - vec2(-0.04,-0.73)) / vec2(0.38,0.20);
 vec2 broad = (lamp_point - vec2(-0.10,-0.58)) / vec2(0.54,0.40);
 float lamp = exp(-dot(spot,spot)) * 0.70 + exp(-dot(broad,broad)) * 0.13;
 paint *= mix(1.0, 0.45 + 0.55 * max(view_normal.z,0.0), back);
 paint += vec3(1.0,0.94,0.76) * lamp * enamel_mask;
 // Retain the reference's cyan edge reflection in view space, not on the
 // rotating enamel (a baked rim must never roll across the middle of a sphere).
 vec3 edge = artwork(lamp_point,0.975);
 paint = mix(paint,edge,smoothstep(0.84,0.98,length(lamp_point)));
 ALBEDO = max(paint,vec3(0.0));
 ALPHA = 1.0;
}
