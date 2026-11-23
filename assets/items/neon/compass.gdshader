shader_type spatial;
// Presentation only. Lane sets the quiet needle and enamel light; no time flash.
uniform float needle_angle = 0.0;
uniform float lane_light = 0.0;
varying vec3 local;
void vertex(){local=VERTEX;}
void fragment(){
 vec3 p=floor(local*500.0)/500.0;
 vec3 ivory=vec3(.89,.80,.63), brass=vec3(.75,.47,.13), cyan=vec3(.16,.72,.72);
 float bands=step(.270,p.y)*(1.0-step(.281,p.y))+step(.300,p.y)*(1.0-step(.311,p.y));
 vec3 ink=mix(ivory,vec3(.19,.06,.28),min(bands,1.0));
 ink=mix(ink,brass,1.0-step(.018,p.y));
 vec2 d=vec2(p.x,p.y-.235);
 float radius=length(d);
 float face=(1.0-step(.034,radius))*step(0.0,p.z);
 vec3 rose=mix(vec3(.13,.055,.20),brass,step(.027,radius));
 float a=atan(d.x,d.y)-needle_angle;
 float needle=(1.0-step(.25,abs(sin(a))))*(1.0-step(.027,radius));
 rose=mix(rose,mix(brass,cyan,step(0.0,cos(a))),needle);
 ink=mix(ink,rose,face);
 ALBEDO=ink; METALLIC=mix(.12,.55,face); ROUGHNESS=.35;
 EMISSION=cyan*needle*face*lane_light*.2;
}
