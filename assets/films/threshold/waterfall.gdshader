shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform float clock = 0.0;
void fragment() {
    float strands = pow(0.5 + 0.5 * sin(UV.x * 110.0 + sin(UV.y * 17.0 - clock * 1.5)), 8.0);
    float edge = sin(UV.x * PI) * sin(UV.y * PI);
    ALBEDO = vec3(0.48, 0.9, 0.9);
    ALPHA = edge * (0.16 + strands * 0.7);
}
