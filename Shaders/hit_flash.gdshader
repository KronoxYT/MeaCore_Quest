shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_thickness : hint_range(0.0, 5.0) = 2.0;
uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform bool show_outline : hint_range(0.0, 1.0) = false;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    vec4 final_color = mix(tex_color, flash_color, flash_intensity);
    if (show_outline > 0.5) {
        vec2 tex_size = vec2(textureSize(TEXTURE, 0));
        vec2 offset = outline_thickness / tex_size;
        float outline_alpha = 0.0;
        for (float x = -1.0; x <= 1.0; x += 1.0) {
            for (float y = -1.0; y <= 1.0; y += 1.0) {
                if (x == 0.0 && y == 0.0) continue;
                vec4 sample = texture(TEXTURE, UV + vec2(x, y) * offset);
                outline_alpha = max(outline_alpha, sample.a);
            }
        }
        if (tex_color.a < 0.1 && outline_alpha > 0.1) {
            final_color = outline_color;
        }
    }
    COLOR = final_color;
}
