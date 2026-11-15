shader_type spatial;
render_mode unshaded;
// Static enamel/acoustic panels on the existing Neon kickbacks and cushion.
// No TIME, lighting, displacement, geometry or collision changes.
void fragment() {
 vec2 p=floor(UV*128.0)/128.0;
 float edge=min(min(p.x,1.0-p.x),min(p.y,1.0-p.y));
 vec3 ink=vec3(0.043,0.063,0.086);
 vec3 enamel=vec3(0.075,0.102,0.149);
 vec3 brass=vec3(0.40,0.30,0.18);
 float weave=mod(floor(p.x*64.0)+floor(p.y*64.0),2.0);
 vec3 c=enamel+vec3(0.008)*weave;
 if(edge<0.025)c=ink;
 else if(edge<0.04)c=brass;
 else if(edge<0.065)c=ink;
 // Recessed lower rail: a narrow, steady cyan enamel inlay, never a flash.
 if(p.x>0.12 && p.x<0.88 && p.y>0.82 && p.y<0.84)c=vec3(0.20,0.43,0.46);
 if(p.x>0.12 && p.x<0.88 && p.y>0.85 && p.y<0.87)c=brass;
 // Quiet vertical panel joins and squared brass fasteners.
 if(p.y>0.11 && p.y<0.76 && abs(fract(p.x*4.0)-0.5)<0.015)c=ink;
 vec2 rivet=min(abs(p-vec2(0.085)),abs(p-vec2(0.915)));
 if(rivet.x<0.012 && rivet.y<0.012)c=brass;
 ALBEDO=c;
}
