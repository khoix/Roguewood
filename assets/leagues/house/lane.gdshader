shader_type spatial;
render_mode specular_schlick_ggx;
// World meters, +forward = -Z, so moving a slab's local origin cannot move the oil.
uniform bool dry_backend = false;
uniform float oil_end_f = 12.192;
uniform float deck_start_f = 17.288;
varying vec3 world_at;
float hash(float x){return fract(sin(x*127.1)*43758.5453);}
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=floor(world_at.xz*vec2(384.0,64.0))/vec2(384.0,64.0);
 float board=floor((p.x+0.52705)*24.0);
 float seam=step(.94,fract((p.x+0.52705)*24.0));
 float joint=step(.983,fract(p.y*.54+hash(board)*3.0));
 float grain=sin(p.y*9.0+sin(p.x*240.0)*1.2+board)*.025;
 vec3 wood=mix(vec3(.43,.235,.105),vec3(.69,.43,.21),hash(board+4.0));
 wood=(wood+grain)*(1.0-max(seam*.42,joint*.27));
 float f=-world_at.z;
 bool backend=f>=oil_end_f && f<deck_start_f;
 bool deck=f>=deck_start_f;
 float oil=1.0-smoothstep(oil_end_f-.12,oil_end_f+.12,f);
 // Broken, spatially stable reflections: quiet enough to preserve aim/rack marks.
 float band=step(.75,cos(p.x*15.0+sin(p.y*.85)*.18))*step(.16,fract(p.y*.75));
 float sheen=oil*.14+(backend && !dry_backend ? .065 : .0);
 vec3 cool=vec3(.40,.57,.53);
 wood=mix(wood,cool,band*sheen);
 if(backend && dry_backend){
  float scuff=step(.68,hash(floor(p.y*8.0)+board*31.0));
  wood=mix(wood,vec3(.59,.44,.29),.38)+scuff*.035;
 }
 ALBEDO=wood;
 ROUGHNESS=deck ? .60 : (backend ? (dry_backend ? .96 : .57) : .30);
 SPECULAR=deck ? .20 : (backend && dry_backend ? .06 : .35);
 METALLIC=.0;
}
