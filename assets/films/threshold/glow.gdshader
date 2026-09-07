shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform float strength = 0.6;
void fragment() {
    float r = length(UV * 2.0 - 1.0);
    float halo = pow(max(0.0, 1.0 - r), 3.0);
    ALBEDO = tint.rgb * COLOR.rgb;
    ALPHA = halo * tint.a * COLOR.a * strength;
}
