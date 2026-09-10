shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color = vec4(1.0, 0.53, 0.19, 0.1);
uniform float strength = 0.0;
uniform float clock = 0.0;
varying float height;
void vertex() { height = VERTEX.y + 0.5; }
void fragment() {
    float edge = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 1.8);
    float taper = sin(clamp(height, 0.0, 1.0) * 3.14159265);
    float haze = 0.85 + 0.15 * sin(height * 25.0 + clock * 0.3);
    ALBEDO = tint.rgb;
    ALPHA = tint.a * strength * edge * taper * haze;
}
