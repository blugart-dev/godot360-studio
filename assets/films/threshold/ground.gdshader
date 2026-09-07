shader_type spatial;
render_mode cull_disabled;
uniform vec3 sand : source_color = vec3(0.13, 0.25, 0.29);
uniform vec3 accent : source_color = vec3(0.12, 0.7, 0.65);
uniform float world = 0.0;
uniform float clock = 0.0;
varying vec3 point;
void vertex() { point = VERTEX; }
void fragment() {
    float ripple = sin(point.x * 2.5 + point.z * 0.8 + sin(point.z * 0.14) * 7.0);
    ALBEDO = sand * (0.94 + ripple * 0.06);
    ROUGHNESS = 0.92;
    if (world < 0.5) {
        float a = sin(point.x * 0.65 + sin(point.z * 0.36 + clock * 0.14));
        float b = cos(point.z * 0.57 + sin(point.x * 0.3 - clock * 0.12));
        float caustic = pow(max(0.0, 1.0 - abs(a + b) * 2.0), 12.0);
        EMISSION = accent * caustic * 0.13;
    } else {
        float vein = pow(max(0.0, 1.0 - abs(sin(point.x * 0.12 + point.z * 0.05 + sin(point.z * 0.08) * 2.0)) * 18.0), 2.0);
        EMISSION = accent * vein * 0.34;
    }
}
