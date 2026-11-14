shader_type spatial;
render_mode specular_schlick_ggx;
// Cosmetic world-space oil finish. All distances mirror the existing LaneSpec.
uniform float oil_end_f = 14.3256;
uniform float left_oil_end_f = 14.3256;
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
 float boundary=world_at.x<0.0 ? left_oil_end_f : oil_end_f;
 bool dry=f>=boundary && f<deck_start_f;
 bool deck=f>=deck_start_f;
 float oil=1.0-smoothstep(boundary-.06,boundary+.06,f);
 float band=step(.75,cos(p.x*15.0+sin(p.y*.85)*.18))*step(.16,fract(p.y*.75));
 wood=mix(wood,vec3(.40,.57,.53),band*(oil*.14+(dry ? .025 : .0)));
 if(dry){
  // Matte, cross-grain scuffs distinguish dryness even with colour removed.
  float scuff=step(.66,hash(floor(f*11.0)+board*31.0));
  float hatch=step(.76,fract(f*8.0+p.x*9.0));
  wood=mix(wood,vec3(.60,.46,.31),.32)+scuff*.045-hatch*.055;
 }
 // Small twin ivory/brass boundary ticks stay at the outside boards, off aim marks.
 float edge=step(.46,abs(world_at.x));
 float tick=(1.0-step(.035,abs(f-boundary)))*edge;
 float second=(1.0-step(.025,abs(f-boundary-.12)))*edge;
 wood=mix(wood,vec3(.91,.81,.60),max(tick,second*.6)*(deck ? 0.0 : 1.0));
 ALBEDO=wood;
 ROUGHNESS=deck ? .60 : (dry ? .93 : .30);
 SPECULAR=deck ? .20 : (dry ? .07 : .35);
 METALLIC=.0;
}
