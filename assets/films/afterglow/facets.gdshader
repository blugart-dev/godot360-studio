shader_type spatial;
render_mode unshaded;
uniform float clock = 0.0;
uniform float pulse = 0.0;
uniform float build = 0.0;
varying float seed;
varying vec3 normal_world;

void vertex() {
    seed = INSTANCE_CUSTOM.x;
    normal_world = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
    float flicker = pow(max(0.0, sin(seed * 128.0 + clock * 0.9)), 28.0);
    float facing = max(0.0, dot(normal_world, normalize(vec3(-0.3, 0.8, 0.5))));
    vec3 color = mix(vec3(0.035, 0.012, 0.065), vec3(0.72, 0.43, 0.20), facing);
    color *= 0.48 + 0.52 * fract(sin(seed * 87.0) * 4375.0);
    color = mix(color, vec3(1.0, 0.88, 0.62), flicker * (0.3 + 0.7 * build));
    ALBEDO = color * (0.48 + 0.5 * facing);
    EMISSION = color * (0.10 + flicker * (2.0 + pulse * 2.5) + pulse * 0.15);
}
