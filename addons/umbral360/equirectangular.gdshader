shader_type canvas_item;
render_mode unshaded;

uniform sampler2D face_right : filter_linear, repeat_disable;
uniform sampler2D face_left : filter_linear, repeat_disable;
uniform sampler2D face_up : filter_linear, repeat_disable;
uniform sampler2D face_down : filter_linear, repeat_disable;
uniform sampler2D face_front : filter_linear, repeat_disable;
uniform sampler2D face_back : filter_linear, repeat_disable;

// Longitude zero looks down Godot's -Z axis. Image right turns toward +X.
// Face UVs are derived from each camera's right/up/forward basis.
void fragment() {
	float longitude = (UV.x - 0.5) * TAU;
	float latitude = (0.5 - UV.y) * PI;
	vec3 d = vec3(sin(longitude) * cos(latitude), sin(latitude), -cos(longitude) * cos(latitude));
	vec3 a = abs(d);
	vec2 p;
	vec4 result;
	if (a.x >= a.y && a.x >= a.z) {
		if (d.x > 0.0) {
			p = vec2(d.z, -d.y) / a.x;
			result = texture(face_right, p * 0.5 + 0.5);
		} else {
			p = vec2(-d.z, -d.y) / a.x;
			result = texture(face_left, p * 0.5 + 0.5);
		}
	} else if (a.y >= a.z) {
		if (d.y > 0.0) {
			p = vec2(d.x, -d.z) / a.y;
			result = texture(face_up, p * 0.5 + 0.5);
		} else {
			p = vec2(d.x, d.z) / a.y;
			result = texture(face_down, p * 0.5 + 0.5);
		}
	} else {
		if (d.z < 0.0) {
			p = vec2(d.x, -d.y) / a.z;
			result = texture(face_front, p * 0.5 + 0.5);
		} else {
			p = vec2(-d.x, -d.y) / a.z;
			result = texture(face_back, p * 0.5 + 0.5);
		}
	}
	COLOR = vec4(result.rgb, 1.0);
}
