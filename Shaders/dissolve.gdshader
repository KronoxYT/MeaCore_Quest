shader_type canvas_item;

uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;
uniform vec4 edge_color : source_color = vec4(1.0, 0.4, 0.1, 1.0);
uniform float noise_scale : hint_range(1.0, 50.0) = 10.0;
uniform bool use_vortex : hint_range(0.0, 1.0) = false;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float n = noise(UV * noise_scale);
    float cut = dissolve_amount - n;
    if (cut > 0.0) {
        discard;
    }
    float edge = smoothstep(-edge_width, 0.0, cut);
    vec4 final_color = mix(edge_color, tex_color, edge);
    if (use_vortex) {
        vec2 center = vec2(0.5, 0.5);
        vec2 dir = UV - center;
        float dist = length(dir);
        float angle = dissolve_amount * 10.0;
        vec2 rotated = vec2(
            dir.x * cos(angle) - dir.y * sin(angle),
            dir.x * sin(angle) + dir.y * cos(angle)
        );
        float vortex_alpha = smoothstep(0.5, 0.0, dist + dissolve_amount);
        final_color.a *= vortex_alpha;
    }
    COLOR = final_color;
}
