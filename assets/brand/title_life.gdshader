shader_type canvas_item;
uniform float clock = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
// Source atlas pixels: only the first House hall panel is used by the title.
float plant(vec2 p, vec4 box, float phase) {
 vec2 edge = smoothstep(box.xy, box.xy + vec2(5.0), p) * (1.0 - smoothstep(box.zw - vec2(5.0), box.zw, p));
 float height = clamp((box.w - p.y) / (box.w - box.y), 0.0, 1.0);
 return edge.x * edge.y * height * height * sin(clock * 0.85 + phase) * 1.6;
}
void fragment() {
 vec2 px = UV / TEXTURE_PIXEL_SIZE;
 vec4 original = texture(TEXTURE, UV);
 float foliage = smoothstep(0.0, 0.035, original.g - original.r) * smoothstep(0.0, 0.03, original.g - original.b);
 float bend = plant(px, vec4(118.0,112.0,153.0,196.0),0.2) + plant(px,vec4(350.0,112.0,390.0,181.0),2.1)
   + plant(px,vec4(1.0,58.0,40.0,115.0),1.3) + plant(px,vec4(461.0,60.0,509.0,168.0),3.4);
 vec4 color = texture(TEXTURE, UV + vec2(bend * foliage,0.0) * TEXTURE_PIXEL_SIZE);
 // Existing bright sky pixels twinkle in sparse groups; wood and moon stay still.
 float sky = step(174.0,px.x)*step(px.x,314.0)*step(78.0,px.y)*step(px.y,136.0);
 float star = smoothstep(0.3,0.65,max(original.r,max(original.g,original.b)));
 float group = fract(sin(dot(floor(px/3.0),vec2(12.7,78.2)))*43758.5);
 float pulse = pow(max(0.0,sin(clock*(0.6+group*0.6)+group*30.0)),8.0);
 color.rgb *= 1.0 + sky * star * pulse * 0.45;
 COLOR = tint * color;
}
