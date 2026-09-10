shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform float clock = 0.0;
uniform float strength = 0.0;
uniform float phase = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 0.42, 0.12, 1.0);
varying float arc;
void vertex() {
    arc = atan(VERTEX.x, VERTEX.z);
    VERTEX.y += sin(arc * 3.0 + phase + clock * .32) * .75;
}
void fragment() {
    float head = pow(max(0.0, cos(arc - clock * .9 - phase)), 38.0);
    float tail = pow(max(0.0, cos(arc - clock * .9 - phase + .45)), 12.0);
    ALBEDO = tint.rgb;
    EMISSION = tint.rgb * 2.5;
    ALPHA = (head + tail * .3) * strength;
}
