shader_type spatial;
render_mode specular_schlick_ggx;
uniform int kind = 0;
uniform vec4 base : source_color = vec4(0.95,0.9,0.8,1.0);
varying vec3 p;
void vertex(){ p = VERTEX; }
void fragment(){
 vec3 c = base.rgb;
 float metal = 0.0;
 float rough = 0.3;
 if(kind == 0){
   float plank = floor(p.x*23.0);
   float seam = step(0.94,fract(p.x*23.0));
   float grain = sin(p.z*6.0+sin(p.x*190.0)*2.0+plank)*0.018;
   float stagger = step(0.985,fract(p.z*0.65+sin(plank*13.0)));
   c = mix(vec3(0.57,0.31,0.13),vec3(0.78,0.52,0.26),fract(sin(plank*17.0)*153.0));
   c += grain;
   c *= 1.0 - max(seam*0.3,stagger*0.22);
   rough=0.58;
 } else if(kind == 1){
   float vein = sin(p.y*90.0+sin(p.x*70.0)+sin(p.z*65.0)*3.0);
   c=mix(vec3(0.02,0.18,0.2),vec3(0.12,0.48,0.46),smoothstep(-0.7,0.8,vein));
   c=mix(c,vec3(0.72,0.53,0.22),smoothstep(0.94,1.0,vein));
   rough=0.15; metal=0.25;
 } else if(kind == 2){
   if((p.y>0.247 && p.y<0.262)||(p.y>0.272 && p.y<0.287)){ c=vec3(0.63,0.1,0.16); }
 } else if(kind == 3){
   c=mix(base.rgb,vec3(0.92,0.7,0.32),step(0.8,fract(p.y*65.0)));
   metal=0.75; rough=0.25;
 } else if(kind == 4){
   c=mix(base.rgb,vec3(0.55,0.85,0.86),step(0.94,abs(sin(p.y*60.0))));
   metal=0.35; rough=0.18;
 } else if(kind == 5){
   vec2 tile=fract(p.xz*3.0);
   float diamond=abs(tile.x-0.5)+abs(tile.y-0.5);
   c=mix(vec3(0.025,0.045,0.065),vec3(0.12,0.22,0.23),step(0.44,diamond)*step(diamond,0.48));
   c=mix(c,vec3(0.36,0.26,0.14),step(diamond,0.035));
   rough=0.95;
 } else if(kind == 6){
   float rim=pow(1.0-max(dot(NORMAL,VIEW),0.0),2.0);
   float facet=abs(sin(p.x*110.0+p.y*36.0));
   c=mix(vec3(0.05,0.2,0.25),vec3(0.63,0.88,0.85),max(rim,facet*0.25));
   rough=0.08; metal=0.4;
 }
 ALBEDO=c; METALLIC=metal; ROUGHNESS=rough; SPECULAR=0.25;
}
