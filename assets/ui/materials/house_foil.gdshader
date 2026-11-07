shader_type canvas_item;
render_mode unshaded;
// Full 210x300 face overlay. Explicit progress: no autonomous shimmer at rest.
uniform float progress : hint_range(0.0,1.0) = 0.0;
uniform int rarity : hint_range(0,4) = 0;
uniform bool reduced = false;
uniform float strength : hint_range(0.0,1.0) = 0.65;
float box(vec2 p,vec2 a,vec2 b){return step(a.x,p.x)*step(a.y,p.y)*step(p.x,b.x)*step(p.y,b.y);}
void fragment(){
 vec2 p=UV*vec2(210.0,300.0);
 float art=box(p,vec2(15.0,41.0),vec2(195.0,222.0));
 art*=1.0-box(p,vec2(15.0,41.0),vec2(46.0,73.0)); // category badge safe area
 float rim=box(p,vec2(3.0,15.0),vec2(9.0,285.0))+box(p,vec2(201.0,15.0),vec2(207.0,285.0));
 float phase=reduced ? 0.42 : progress;
 float sweep=1.0-smoothstep(0.015,0.13,abs(UV.x*.7+UV.y*.3-phase*1.4+.2));
 float grain=step(.72,fract((p.x+p.y)*.25));
 vec3 tint=vec3(.90,.74,.44);
 float alpha=0.0;
 if(rarity==1){alpha=rim*(.12+.25*sweep);}
 if(rarity==2){tint=vec3(.50,.86,.79);alpha=rim*.25+art*(1.0-box(p,vec2(19.0,45.0),vec2(191.0,218.0)))*sweep*.32;}
 if(rarity==3){tint=mix(vec3(.69,.56,.93),vec3(.51,.85,.82),step(.5,fract((p.x-p.y)/48.0)));alpha=rim*.3+art*sweep*(.10+.12*grain);}
 if(rarity==4){tint=mix(vec3(.96,.72,.32),vec3(.66,.84,.78),step(.6,fract((p.x+p.y)/36.0)));alpha=rim*.38+art*sweep*(.15+.15*grain);}
 COLOR=vec4(tint,clamp(alpha*strength,0.0,.22));
}
