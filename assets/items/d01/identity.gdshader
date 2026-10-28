shader_type spatial;
render_mode cull_disabled;
uniform int identity = 0;
uniform bool solid = false;
varying vec3 local;
void vertex() {
 local = VERTEX;
 if (identity == 4) { float flute = 1.0 + 0.055*cos(atan(VERTEX.z,VERTEX.x)*12.0); VERTEX.xz *= flute; }
}
void fragment() {
 vec3 n = normalize(local);
 vec3 ivory=vec3(0.88,0.82,0.65), brass=vec3(0.68,0.40,0.12), dark=vec3(0.035,0.11,0.14);
 vec3 color=ivory;
 float metal=0.2;
 if(identity==0) {
  float panels=abs(sin(atan(n.x,n.z)*6.0 + floor(n.y*4.0)*0.4));
  float rows=abs(sin(n.y*13.0));
  color=mix(dark,brass,step(0.10,min(panels,rows)));
  metal=0.72;
 } else if(identity==1) {
  float ray=abs(sin(atan(n.y,n.x)*4.0));
  color=mix(dark,brass,step(0.94,ray)*step(0.65,abs(n.z)));
  metal=0.35;
 } else if(identity==2) {
  float bands=abs(sin(atan(n.y,n.x)*1.5+n.z*2.0));
  float checker=mod(floor(local.x*550.0)+floor(local.y*550.0)+floor(local.z*550.0),2.0);
  if(!solid && bands<0.42 && abs(n.x)>0.25 && abs(n.z)>0.15) discard;
  if(!solid && bands<0.7 && checker<0.5 && abs(n.z)>0.15) discard;
  color=mix(vec3(0.22,0.39,0.42),ivory,step(0.72,bands));
  if(!solid) color=mix(color,ivory,checker*0.16);
 } else if(identity==3) {
  color=ivory;
  if(abs(local.x)<0.016) color=brass;
  if(abs(local.x)<0.004) color=dark;
  float chevron=abs(abs(n.x)-0.38-abs(n.y)*0.75);
  if(chevron<0.045 && abs(n.y)<0.30 && n.z< -0.5) color=brass;
 } else {
  float flute=abs(sin(atan(local.z,local.x)*6.0));
  float checker=mod(floor(local.x*900.0)+floor(local.y*900.0),2.0);
  if(flute<0.65 && checker<0.5) discard;
  color=mix(vec3(0.23,0.44,0.47),vec3(0.85,0.96,0.91),pow(flute,4.0));
  float crack=abs(local.x - 0.009*sin(local.y*90.0));
  if(local.y>0.09 && local.y<0.18 && crack<0.0015)color=ivory;
 }
 ALBEDO=color; METALLIC=metal; ROUGHNESS=0.28; SPECULAR=0.6;
}
