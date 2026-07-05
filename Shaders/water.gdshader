shader_type canvas_item;

uniform sampler2D depth_texture : hint_screen_texture, repeat_disable;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_amplitude : hint_range(0.0, 0.1) = 0.02;
uniform float wave_frequency : hint_range(0.0, 50.0) = 15.0;
uniform vec4 shallow_color : source_color = vec4(0.3, 0.7, 0.9, 0.8);
uniform vec4 deep_color : source_color = vec4(0.05, 0.2, 0.4, 0.95);
uniform float reflectivity : hint_range(0.0, 1.0) = 0.4;
uniform float depth_fade_distance : hint_range(0.0, 2.0) = 0.5;
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 0.6);
uniform float foam_threshold : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec2 uv = UV;
    float wave1 = sin(uv.x * wave_frequency + TIME * wave_speed) * wave_amplitude;
    float wave2 = cos(uv.y * wave_frequency * 0.7 + TIME * wave_speed * 1.3) * wave_amplitude * 0.7;
    vec2 distorted_uv = uv + vec2(wave1, wave2);
    float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    float depth_factor = smoothstep(0.0, depth_fade_distance, edge_dist);
    vec4 water_color = mix(shallow_color, deep_color, depth_factor);
    vec2 screen_uv = SCREEN_UV + vec2(wave1, wave2) * 0.5;
    vec4 reflected = textureLod(SCREEN_TEXTURE, screen_uv, 1.0);
    vec4 final_color = mix(water_color, reflected, reflectivity * depth_factor);
    if (edge_dist < foam_threshold) {
        float foam_noise = fract(sin(dot(uv * 30.0 + TIME * 0.5, vec2(12.9898, 78.233))) * 43758.5453);
        final_color = mix(final_color, foam_color, foam_noise * (1.0 - edge_dist / foam_threshold));
    }
    float specular = pow(max(0.0, sin(uv.x * 30.0 + TIME * 2.0) * sin(uv.y * 30.0 - TIME * 1.5)), 8.0);
    final_color.rgb += vec3(specular) * 0.3 * depth_factor;
    COLOR = final_color;
}
