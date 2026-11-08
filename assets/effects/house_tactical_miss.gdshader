shader_type canvas_item;
render_mode unshaded;
// A spent Called Shot retains its silhouette with no success colour or pulse.
void fragment() {
 vec4 ink = COLOR;
 float grey = dot(ink.rgb, vec3(0.2126, 0.7152, 0.0722));
 COLOR = vec4(vec3(grey), ink.a);
}
