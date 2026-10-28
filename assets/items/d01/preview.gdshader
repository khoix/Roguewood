shader_type canvas_item;
uniform int mode = 0;
void fragment() {
 vec4 source=texture(TEXTURE,UV);
 float gray=dot(source.rgb,vec3(0.2126,0.7152,0.0722));
 COLOR=vec4(mode==2 ? vec3(0.96) : vec3(gray),source.a);
}
