shader_type spatial;
render_mode specular_schlick_ggx;
uniform int identity=0;
varying vec3 local_position;
varying vec3 fixed_position;
void vertex(){local_position=VERTEX;fixed_position=(MODEL_MATRIX*vec4(VERTEX,0.0)).xyz;}
void fragment(){
 vec3 p=normalize(local_position);vec3 q=floor(p*90.0)/90.0;
 vec3 c=vec3(.025,.19,.23);float rough=.24;
 if(identity==0){
  // World-oriented, translation-free stripe: deliberately independent of body spin.
  float stripe=1.0-smoothstep(.022,.028,abs(fixed_position.x));
  c=mix(c,vec3(.91,.81,.59),stripe);
  float edge=1.0-smoothstep(.002,.005,abs(abs(fixed_position.x)-.028));
  c=mix(c,vec3(.65,.37,.10),edge);
 }else if(identity==1){
  c=vec3(.23,.055,.035);rough=.53;
  float scratches=step(.985,sin(q.x*73.0+q.y*118.0+sin(q.z*21.0)*3.0));
  float worn=smoothstep(.6,.95,sin(q.x*12.0+q.y*4.0)*cos(q.z*9.0));
  c=mix(c,vec3(.46,.27,.13),worn*.55+scratches*.6);
  float shield=step(abs(p.x),.36)*step(abs(p.y+.1),.32)*step(.65,p.z);
  c=mix(c,vec3(.72,.58,.36),shield);
 }else{
  vec3 v=floor(local_position*1100.0)/1100.0;
  float grain=sin(v.x*680.0+sin(v.y*38.0+v.z*46.0)*1.8);
  c=mix(vec3(.18,.075,.025),vec3(.53,.29,.10),smoothstep(-.9,.9,grain));
  float rings=step(.255,v.y)*step(v.y,.268)+step(.292,v.y)*step(v.y,.302);
  c=mix(c,vec3(.10,.035,.013),clamp(rings,0.0,1.0));rough=.65;
 }
 ALBEDO=c;ROUGHNESS=rough;METALLIC=0.0;
}
