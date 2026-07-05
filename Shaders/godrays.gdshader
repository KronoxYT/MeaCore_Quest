shader_type canvas_item;
render_mode blend_add;

uniform vec2 light_origin : hint_range(0.0, 1.0) = vec2(0.5, 0.0);
uniform float ray_length : hint_range(0.0, 2.0) = 1.0;
uniform float ray_intensity : hint_range(0.0, 2.0) = 0.6;
uniform int ray_samples : hint_range(8, 64) = 32;
uniform float decay : hint_range(0.9, 1.0) = 0.97;
uniform float density : hint_range(0.0, 1.0) = 0.5;
uniform float weight : hint_range(0.0, 2.0) = 1.2;
uniform float exposure : hint_range(0.0, 2.0) = 0.8;
uniform sampler2D occlusion_texture : hint_white;

void fragment() {
    vec2 uv = UV;
    vec2 delta_uv = (uv - light_origin) * (1.0 / float(ray_samples) * density);
    float illumination_decay = 1.0;
    vec2 sample_uv = uv;
    float godray_value = 0.0;
    for (int i = 0; i < ray_samples; i++) {
        sample_uv -= delta_uv;
        float occlusion = texture(occlusion_texture, sample_uv).r;
        godray_value += illumination_decay * occlusion * weight;
        illumination_decay *= decay;
    }
    godray_value *= ray_intensity * exposure / float(ray_samples);
    vec3 ray_color = vec3(1.0, 0.9, 0.7);
    COLOR = vec4(ray_color * godray_value, godray_value);
}
