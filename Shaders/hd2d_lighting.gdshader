shader_type canvas_item;

uniform vec2 light_position;
uniform vec3 light_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float light_radius : hint_range(0.0, 1000.0) = 200.0;
uniform float light_intensity : hint_range(0.0, 5.0) = 1.0;
uniform float ambient_intensity : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec2 frag_pos = (SCREEN_PIXEL_SIZE * SCREEN_UV * VIEWPORT_SIZE);
    float dist = distance(frag_pos, light_position);
    float attenuation = 1.0 - smoothstep(0.0, light_radius, dist);
    attenuation *= light_intensity;
    vec3 final_light = mix(vec3(ambient_intensity), light_color, attenuation);
    COLOR.rgb *= final_light;
}
