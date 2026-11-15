shader_type spatial;
uniform int identity = 0;
varying vec3 local;
void vertex() { local = VERTEX; }
void fragment() {
 vec3 p=floor(local*440.0)/440.0;
 vec3 ink=vec3(.025,.09,.11);
 float mark=0.0;
 if(identity==0) {
  float wave=sin(p.x*70.0+sin(p.y*90.0)*1.5+p.z*40.0);
  ink=mix(vec3(.015,.035,.05),vec3(.035,.32,.34),smoothstep(.28,.8,wave));
  vec2 bead=fract(vec2(p.x+p.z*.6,p.y)*65.0)-.5;
  mark=1.0-smoothstep(.12,.23,length(bead));
  ink=mix(ink,vec3(.55,.84,.82),mark*.75);
 } else if(identity==1) {
  ink=vec3(.08,.025,.17);
  mark=1.0-step(.0045,abs(p.y));
  float meridian=(1.0-step(.0025,abs(p.x)))*(1.0-step(.025,abs(p.y)));
  mark=max(mark,meridian);
  ink=mix(ink,vec3(.32,.88,.96),mark);
 } else {
  ink=vec3(.89,.83,.67);
  float band=step(.105,p.y)*(1.0-step(.207,p.y));
  ink=mix(ink,vec3(.04,.025,.11),band);
  float ring=(step(.267,p.y)*(1.0-step(.278,p.y)))+(step(.294,p.y)*(1.0-step(.305,p.y)));
  ink=mix(ink,vec3(.15,.62,.66),min(ring,1.0));
  // Dark paired meter housings: paid bars are a separate authoritative cue.
  float bars=step(.112,p.y)*(1.0-step(.186,p.y))*(1.0-step(.008,abs(abs(p.x)-.017)));
  ink=mix(ink,vec3(.23,.18,.11),bars*band);
 }
 ALBEDO=ink; METALLIC=identity==2 ? .12 : .38; ROUGHNESS=identity==0 ? .19 : .3;
 EMISSION=ink*mark*.16;
}
