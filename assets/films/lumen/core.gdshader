shader_type spatial;
render_mode unshaded;

uniform float clock = 0.0;
varying vec3 object_position;

void vertex() {
    object_position = VERTEX;
}

void fragment() {
    vec3 p = normalize(object_position);
    float flow = sin(p.y * 38.0 + sin(p.x * 9.0 + clock * 0.3) * 2.0 + sin(p.z * 7.0) * 3.0);
    float bands = smoothstep(0.2, 0.9, flow);
    float pulse = 0.82 + 0.18 * sin(clock * 1.570796);
    vec3 color = mix(vec3(0.18, 0.016, 0.005), vec3(1.0, 0.52, 0.12), bands);
    ALBEDO = color * pulse;
    EMISSION = color * (0.65 + bands * 0.6);
}
