shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float glow_strength : hint_range(0.0, 2.0) = 0.0;

void fragment() {
    vec4 base = texture(TEXTURE, UV) * COLOR;
    // Add simple glow effect by mixing the color
    vec3 glow_mix = mix(base.rgb, glow_color.rgb, glow_strength * 0.5);
    COLOR = vec4(glow_mix, base.a);
}
