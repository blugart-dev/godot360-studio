shader_type spatial;

varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 p = world_position.xz;
    float radius = length(p);
    float angle = atan(p.y, p.x);
    float rings = 1.0 - smoothstep(0.02, 0.065, abs(fract(radius * 0.25) - 0.5));
    float spokes = 1.0 - smoothstep(0.015, 0.045, abs(sin(angle * 24.0)) * max(radius, 1.0));
    float grid = max(rings * 0.4, spokes * 0.2);
    ALBEDO = mix(vec3(0.028, 0.045, 0.063), vec3(0.06, 0.16, 0.19), grid);
    EMISSION = vec3(0.035, 0.18, 0.2) * grid;
    METALLIC = 0.35;
    ROUGHNESS = 0.48;
}
