shader_type spatial;
uniform int identity = 0;
varying vec3 local;
void vertex(){local=VERTEX;}
void fragment(){
 vec3 p=floor(local*420.0)/420.0;
 vec3 ink;
 float glow=0.0;
 if(identity==0){
  float ribbon=abs(sin(p.y*24.0+p.x*17.0+sin(p.z*25.0)*1.6));
  glow=1.0-smoothstep(.08,.25,ribbon);
  ink=mix(vec3(.015,.16,.16),vec3(.58,.93,.72),glow);
 }else{
  // Opaque facets retain the pin silhouette under every lane light.
  vec2 tile=floor(vec2(atan(p.z,p.x)*2.9,p.y*24.0));
  float facet=mod(tile.x+tile.y*2.0,4.0);
  ink=facet<1.0 ? vec3(.36,.73,.77) : facet<2.0 ? vec3(.68,.52,.81) : facet<3.0 ? vec3(.94,.87,.71) : vec3(.68,.75,.8);
  float neck=step(.267,p.y)*(1.0-step(.278,p.y))+step(.294,p.y)*(1.0-step(.305,p.y));
  ink=mix(ink,vec3(.76,.81,.82),min(neck,1.0));
 }
 ALBEDO=ink;METALLIC=.22;ROUGHNESS=.28;EMISSION=ink*glow*.18;
}
