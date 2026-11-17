shader_type spatial;
// Static enamel identity; no time-driven flash or gameplay geometry.
void fragment(){
 vec2 p=floor(UV*128.0)/128.0;
 float bend=0.5+0.14*sin((p.x-0.2)*6.283185);
 float tail=(1.0-smoothstep(0.012,0.035,abs(p.y-bend)))*smoothstep(0.12,0.7,p.x)*(1.0-step(0.82,p.x));
 vec2 d=abs(p-vec2(0.77,0.44));
 float star=1.0-step(1.0,d.x/0.035+d.y/0.06);
 vec3 ink=mix(vec3(0.055,0.016,0.14),vec3(0.08,0.69,0.78),tail);
 ink=mix(ink,vec3(0.93,0.68,0.24),star);
 ALBEDO=ink;METALLIC=0.38;ROUGHNESS=0.24;EMISSION=ink*tail*0.07;
}
