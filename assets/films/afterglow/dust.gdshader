shader_type spatial;
render_mode unshaded;
uniform float clock = 0.0;
uniform float build = 0.0;
uniform float pulse = 0.0;
varying float twinkle;
void vertex() {
    vec4 seed = INSTANCE_CUSTOM;
    VERTEX.y += sin(clock * 0.4 + seed.x * 50.0) * 0.30;
    VERTEX.x += sin(clock * 0.12 + seed.y * 20.0) * 0.45;
    twinkle = pow(max(0.0, sin(clock * (0.7 + seed.z) + seed.w * 24.0)), 6.0);
}
void fragment() {
    vec3 color = mix(vec3(0.38, 0.16, 0.65), vec3(1.0, 0.67, 0.25), twinkle);
    ALBEDO = color * 0.4;
    EMISSION = color * (0.2 + twinkle * (0.6 + build + pulse));
}
