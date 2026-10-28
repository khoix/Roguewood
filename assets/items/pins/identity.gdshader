shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform int identity = 0;
varying vec3 local;
void vertex() { local = VERTEX; }
float band(float y, float a, float b) { return step(a,y) * (1.0-step(b,y)); }
void fragment() {
    vec3 p = floor(local / 0.0015) * 0.0015;
    float grain = fract(sin(dot(floor(p * 1200.0), vec3(12.9898,78.233,37.719))) * 43758.5453);
    vec3 ivory = vec3(0.94,0.84,0.65);
    vec3 brass = vec3(0.72,0.45,0.14);
    vec3 dark = vec3(0.12,0.10,0.075);
    vec3 color = ivory;
    float metal = 0.05;
    float rough = 0.30;
    float front = step(0.018,abs(p.z));
    if (identity == 0) {
        float stripes = max(band(p.y,0.247,0.262),band(p.y,0.278,0.293));
        color = mix(ivory,vec3(0.37,0.025,0.045),stripes);
        if (p.y < 0.035 + 0.003*sin(p.x*560.0)) {
            float wood = 0.5+0.5*sin(p.x*850.0 + sin(p.y*210.0)*2.0);
            color = mix(vec3(0.19,0.075,0.025),vec3(0.46,0.22,0.07),wood);
            rough = 0.55;
        }
        color = mix(color,brass,band(p.y,0.006,0.010));
    } else if (identity == 1) {
        float diamond = abs(p.x)/0.041 + abs(p.y-0.136)/0.074;
        float neck = abs(p.x)/0.016 + abs(p.y-0.271)/0.024;
        float shape = min(diamond,neck);
        if (shape < 1.13 && front > 0.5) { color = brass; metal = 0.6; }
        if (shape < 0.94 && front > 0.5) {
            float facet = step(0.0,p.x) * 0.22 + step(0.136,p.y)*0.25;
            color = mix(vec3(0.28,0.004,0.025),vec3(0.95,0.07,0.16),facet);
            if (abs(diamond-0.48) < 0.05 || abs(p.x) < 0.002) color *= 1.5;
            metal = 0.32; rough = 0.18;
        }
        color = mix(color,brass,max(band(p.y,0.006,0.014),max(band(p.y,0.246,0.249),band(p.y,0.292,0.295))));
    } else if (identity == 2) {
        color = brass; metal = 0.68; rough = 0.26;
        float grooves = max(band(p.y,0.009,0.014),max(band(p.y,0.025,0.030),band(p.y,0.042,0.047)));
        grooves = max(grooves,max(band(p.y,0.249,0.254),band(p.y,0.274,0.279)));
        float coin = length(vec2(p.x,p.y-0.13));
        if (front > 0.5 && coin < 0.047) {
            grooves = max(grooves,max(band(coin,0.022,0.027),band(coin,0.037,0.042)));
            if (coin < 0.021) color *= 1.2;
        }
        color = mix(color,dark,grooves);
    } else {
        color = vec3(0.025,0.14,0.18); metal = 0.25; rough = 0.29;
        float neck_y = p.y - abs(p.x)*0.7;
        color = mix(color,ivory,max(band(neck_y,0.248,0.260),band(neck_y,0.282,0.294)));
        float cross_brace = min(abs(p.y-0.13-p.x*1.3),abs(p.y-0.13+p.x*1.3));
        if (front > 0.5 && p.y > 0.064 && p.y < 0.192 && cross_brace < 0.010) {
            color = cross_brace > 0.007 ? brass : vec3(0.32,0.32,0.29); metal = 0.65;
        }
        if (p.y < 0.053) {
            color = vec3(0.22,0.25,0.26); metal = 0.70;
            if (p.y < 0.007 || p.y > 0.046) color = brass;
            if (abs(p.y-0.026) < 0.005 && abs(sin(atan(p.z,p.x)*4.0)) < 0.22) color = brass;
        }
    }
    ALBEDO = color * (0.94 + 0.10*grain);
    METALLIC = metal;
    ROUGHNESS = rough;
    EMISSION = color * 0.09;
}
