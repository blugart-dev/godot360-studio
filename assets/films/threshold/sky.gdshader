shader_type spatial;
render_mode unshaded, cull_front, fog_disabled;
uniform vec3 zenith : source_color = vec3(0.01, 0.05, 0.12);
uniform vec3 horizon : source_color = vec3(0.04, 0.22, 0.29);
uniform vec3 nadir : source_color = vec3(0.005, 0.012, 0.025);
uniform float clock = 0.0;
uniform float world = 0.0;
varying vec3 direction;
float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float noise(vec3 p) {
    vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() { direction = VERTEX; }
void fragment() {
    vec3 d = normalize(direction);
    vec3 col = mix(horizon, zenith, pow(max(d.y, 0.0), 0.6));
    col = mix(col, nadir, smoothstep(0.0, 0.85, -d.y));
    float cloud = sin(d.x * 12.0 + sin(d.z * 9.0 + clock * 0.035) * 2.0 + d.y * 15.0);
    cloud += 0.45 * sin(d.z * 23.0 + d.x * 17.0 - clock * 0.06);
    float band = exp(-pow((d.y - 0.17 - sin(d.x * 5.0) * 0.1) * 6.0, 2.0));
    col += horizon * (0.055 + cloud * 0.025) * (1.0 - abs(d.y));
    float billow = noise(d * 5.0 + vec3(clock * 0.007, 0, 0)) * 0.6 + noise(d * 13.0) * 0.3 + noise(d * 31.0) * 0.1;
    if (world > 1.5 && world < 2.5) {
        float mist = smoothstep(0.41, 0.69, billow) * (1.0 - smoothstep(0.3, 0.8, d.y));
        col = mix(col, vec3(0.89, 0.79, 0.67), mist * 0.65);
    }
    if (world < 0.5) {
        float rays = pow(max(0.0, sin(atan(d.z, d.x) * 22.0 + d.y * 4.0 + clock * 0.045)), 14.0);
        col += vec3(0.06, 0.17, 0.18) * rays * smoothstep(0.1, 1.0, d.y);
    }
    if (world > 2.5) {
        col += vec3(0.25, 0.065, 0.32) * band * smoothstep(0.30, 0.73, billow);
        float star = pow(max(0.0, sin(d.x * 191.0) * sin(d.y * 223.0) * sin(d.z * 173.0)), 54.0);
        col += vec3(0.6, 0.7, 0.95) * star;
    }
    ALBEDO = col;
}
