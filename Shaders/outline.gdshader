shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
uniform bool only_outline : hint_range(0, 1) = false;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    float alpha = base_color.a;

    float w = outline_width / float(textureSize(TEXTURE, 0).x);
    float h = outline_width / float(textureSize(TEXTURE, 0).y);

    float outline = 0.0;
    outline += texture(TEXTURE, UV + vec2(w, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(-w, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, h)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, -h)).a;

    outline += texture(TEXTURE, UV + vec2(w, h)).a;
    outline += texture(TEXTURE, UV + vec2(-w, h)).a;
    outline += texture(TEXTURE, UV + vec2(w, -h)).a;
    outline += texture(TEXTURE, UV + vec2(-w, -h)).a;

    outline = min(outline, 1.0);
    outline *= (1.0 - alpha);

    if (only_outline) {
        COLOR = outline_color * outline;
        COLOR.a = outline;
    } else {
        vec4 result = mix(base_color, outline_color, outline);
        result.a = max(alpha, outline);
        COLOR = result;
    }
}
