shader_type spatial;
render_mode specular_schlick_ggx;
varying vec3 local;
void vertex(){
 local=VERTEX;
 // Visual dents only. Collision geometry remains the production pin profile.
 float dent=exp(-pow((VERTEX.y-.13)*36.0,2.0))*pow(max(0.0,NORMAL.z),8.0);
 VERTEX-=NORMAL*dent*.007;
}
void fragment(){
 vec3 p=floor(local*900.0)/900.0;
 float patches=sin(p.x*110.0+sin(p.y*54.0))*cos(p.z*89.0+p.y*47.0);
 vec3 color=mix(vec3(.26,.29,.29),vec3(.64,.65,.60),smoothstep(-.8,.8,patches));
 float rings=step(.255,p.y)*step(p.y,.27)+step(.293,p.y)*step(p.y,.307);
 color=mix(color,vec3(.025,.15,.17),clamp(rings,0.0,1.0));
 float seam=(1.0-smoothstep(.001,.003,abs(p.x-.02)))*step(0.0,p.z)*step(p.y,.24);
 color=mix(color,vec3(.48,.34,.15),seam);
 ALBEDO=color;METALLIC=.7;ROUGHNESS=.48;
}
