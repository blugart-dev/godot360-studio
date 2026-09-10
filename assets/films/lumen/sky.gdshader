shader_type spatial;
render_mode unshaded, cull_front, fog_disabled;

uniform float clock = 0.0;
varying vec3 direction;

void vertex() { direction = VERTEX; }

void fragment() {
    vec3 d = normalize(direction);
    vec3 color = mix(vec3(0.018, 0.045, 0.075), vec3(0.003, 0.009, 0.025), smoothstep(0.0, 0.9, d.y));
    float cloud = 0.55 + 0.23 * sin(d.x * 8.0 + sin(d.z * 6.0) + clock * 0.015) * cos(d.y * 9.0 - d.z * 3.0);
    // Multiplication remains defined on both sides of the cloud band. GLSL pow
    // with a negative base is undefined even when its exponent happens to be 2.
    float axis = (d.y - 0.18 - sin(d.x * 4.0 + d.z) * 0.12) * 5.0;
    float band = exp(-axis * axis);
    color += mix(vec3(0.018, 0.08, 0.095), vec3(0.115, 0.045, 0.14), smoothstep(-0.5, 0.5, d.x)) * band * smoothstep(0.25, 0.75, cloud);
    ALBEDO = color;
}
