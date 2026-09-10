shader_type spatial;
render_mode unshaded, cull_front, fog_disabled;
uniform float clock = 0.0;
uniform float build = 0.0;
varying vec3 direction;
void vertex() { direction = VERTEX; }
void fragment() {
    vec3 d = normalize(direction);
    float cloud = sin(d.x * 5.0 + sin(d.z * 8.0 + clock * 0.008)) * cos(d.y * 7.0 - d.z * 2.0);
    float axis = (d.y - 0.12 + sin(d.x * 4.0 + d.z * 3.0) * 0.09) * 5.0;
    float band = exp(-axis * axis);
    vec3 nebula = mix(vec3(0.065, 0.013, 0.085), vec3(0.12, 0.029, 0.035), smoothstep(-0.7, 0.7, d.x));
    ALBEDO = vec3(0.004, 0.002, 0.012) + nebula * band * (0.45 + cloud * 0.30) * (0.5 + build * 0.5);
}
