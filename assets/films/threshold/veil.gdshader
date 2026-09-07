shader_type spatial;
render_mode unshaded, cull_front, depth_test_disabled, depth_draw_never, fog_disabled;
uniform float coverage = 0.0;
uniform float darkness = 0.0;
uniform float clock = 0.0;
uniform vec3 tint : source_color = vec3(0.8, 0.95, 0.88);
varying vec3 direction;
void vertex() { direction = VERTEX; }
void fragment() {
    vec3 d = normalize(direction);
    float streak = pow(0.5 + 0.5 * sin(atan(d.z, d.x) * 16.0 + d.y * 8.0 - clock * 2.5), 12.0);
    vec3 luminous = mix(tint * (0.5 + streak * 0.5), vec3(0.97, 0.99, 0.96), coverage);
    ALBEDO = mix(luminous, vec3(0.003, 0.006, 0.018), darkness);
    ALPHA = max(coverage, darkness);
}
