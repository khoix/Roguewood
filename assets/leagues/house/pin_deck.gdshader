shader_type spatial;
render_mode unshaded;
// Original static walnut panels, brass rails and club diamond inlays.
void fragment() {
 vec2 p=floor(UV*128.0)/128.0;
 float edge=min(min(p.x,1.0-p.x),min(p.y,1.0-p.y));
 vec3 dark=vec3(.055,.035,.025);
 vec3 brass=vec3(.56,.37,.15);
 float grain=sin(p.x*180.0+sin(p.y*19.0)*1.4);
 vec3 c=vec3(.22,.115,.055)+grain*vec3(.025,.014,.006);
 float join=abs(fract(p.x*4.0)-.5);
 if(join<.014)c=dark;
 if(edge<.025)c=dark;
 else if(edge<.045)c=brass;
 else if(edge<.07)c=dark;
 if(p.y>.79 && p.y<.82 && p.x>.08 && p.x<.92)c=brass;
 vec2 d=vec2(fract(p.x*4.0)-.5,(p.y-.4)*2.0);
 float diamond=abs(d.x)+abs(d.y);
 if(diamond<.12 && diamond>.075)c=brass;
 ALBEDO=c;
}
