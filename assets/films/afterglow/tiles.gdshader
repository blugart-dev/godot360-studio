shader_type spatial;
render_mode unshaded;
uniform float clock = 0.0;
uniform float bass = 0.0;
uniform float bass_note = 38.0;
uniform float guitar = 0.0;
uniform float build = 0.0;
uniform float suspended = 0.0;
uniform float ending = 1.0;
uniform vec3 core_position = vec3(0.0, 7.3, -7.5);
uniform float lantern_orbit = 0.0;
uniform float dance = 0.0;
uniform vec2 plinth_center = vec2(0.0, -7.5);
uniform float plinth_radius = 3.5;
varying vec4 tile;
varying vec3 local_position;
varying vec3 face_normal;
varying vec3 world_position;

vec3 palette(float n) {
    vec3 gold = vec3(1.0, 0.48, 0.075);
    vec3 pink = vec3(1.0, 0.025, 0.32);
    vec3 violet = vec3(0.31, 0.055, 1.0);
    return mix(mix(gold, pink, smoothstep(0.25, 0.55, n)), violet, smoothstep(0.65, 0.95, n));
}

void vertex() {
    tile = INSTANCE_CUSTOM;
    local_position = VERTEX;
    face_normal = NORMAL;
    float radius = length(tile.xy);
    float outside = smoothstep(3.5, 11.0, radius);
    float ripple = sin(radius * 0.90 - clock * 5.6 + tile.z * 0.8);
    vec2 spread = tile.xy * suspended * outside * 0.045;
    // Test the displaced tile centre. The extra 0.70 covers a whole tile's
    // half-diagonal plus clearance, so tiles under the plinth stay below it.
    float clearance = smoothstep(plinth_radius + 0.70, plinth_radius + 2.0,
        length(tile.xy + spread - plinth_center));
    VERTEX.y += clearance * outside * ((0.13 + build * 0.32) * ripple + bass * 0.34 * sin(tile.x * 0.3 + clock * 3.0));
    VERTEX.y += clearance * suspended * outside * (1.2 + sin(tile.x * 0.47 + tile.y * 0.4) * 0.9);
    VERTEX.xz += spread;
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    float r = length(tile.xy);
    float edge = 1.0 - smoothstep(0.425, 0.461, max(abs(local_position.x), abs(local_position.z)));
    float rim = 1.0 - edge;
    float note_path = pow(max(0.0, cos((tile.x + tile.y) * 0.55 - bass_note * 0.51)), 12.0);
    float wave = pow(max(0.0, cos(r * 0.66 - clock * 3.4)), 14.0);
    float sweep = pow(max(0.0, sin(tile.x * 0.32 + tile.y * 0.48 - clock * 2.0)), 22.0);
    float on = 0.045 + (wave * (0.22 + build * 0.56) + note_path * bass * 0.92 + sweep * guitar * 0.5) * ending;
    float shade = 0.5 + 0.5 * sin(tile.x * 0.26 + tile.y * 0.37 + clock * 0.16);
    vec3 tint = palette(shade);
    float top = step(0.5, face_normal.y);
    // A restrained, direction-independent glass sheen keeps the cube faces coherent.
    float sheen = pow(max(0.0, sin(local_position.x * 2.5 + local_position.z * 3.0 + tile.z * 6.0)), 12.0);
    // Analytic, world-space reflections of the crown and colonnade. No screen
    // texture or per-face history: the reflection also works across cube edges.
    vec3 ray = reflect(normalize(world_position - CAMERA_POSITION_WORLD), vec3(0.0, 1.0, 0.0));
    vec3 to_core = core_position - world_position;
    float along = max(0.0, dot(to_core, ray));
    float distance_to_core = length(to_core - ray * along);
    float mirror = (1.0 - smoothstep(1.55, 2.15, distance_to_core)) * step(0.0, ray.y);
    float mirror_tiles = 0.65 + 0.35 * sin(ray.x * 280.0) * sin(ray.z * 280.0);
    float aa = dot(ray.xz, ray.xz);
    float bb = dot(world_position.xz, ray.xz);
    float cc = dot(world_position.xz, world_position.xz) - 22.56 * 22.56;
    float travel = (-bb + sqrt(max(0.0, bb * bb - aa * cc))) / max(0.001, aa);
    vec3 hit = world_position + ray * travel;
    float angle = atan(hit.x, hit.z) - lantern_orbit;
    float column = pow(max(0.0, cos(angle * 24.0 - 3.14159265)), 95.0);
    float lamp_y = 5.0 + sin(clock / (60.0 / 116.0) * 6.2831853 * .25 + angle * 2.0) * (.13 + dance * 1.15) + bass * .38 * dance;
    float window = smoothstep(lamp_y - 2.5, lamp_y - 1.5, hit.y) * (1.0 - smoothstep(lamp_y + 1.3, lamp_y + 2.3, hit.y));
    float fresnel = 0.13 + 0.32 * pow(1.0 - max(0.0, ray.y), 3.0);
    vec3 reflection = vec3(1.0, 0.55, 0.22) * (mirror * mirror_tiles * 0.9 + column * window * (0.25 + build * 0.6)) * fresnel;
    vec3 glass = vec3(0.006, 0.002, 0.014) + tint * (on * 0.30 + sheen * build * 0.035) + reflection;
    ALBEDO = mix(vec3(0.009, 0.004, 0.015), glass, top);
    EMISSION = tint * ((rim * (0.085 + on * 2.6) + edge * on * 0.23) * top + (1.0 - top) * on * 0.18) + reflection * top * .8;
}
