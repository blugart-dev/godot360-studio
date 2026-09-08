shader_type canvas_item;
render_mode unshaded;

// Both face targets and the output canvas use use_hdr_2d=false. These samples
// already contain tone-mapped sRGB, so no source_color hint or second gamma pass.

uniform sampler2D face_right : filter_linear, repeat_disable;
uniform sampler2D face_left : filter_linear, repeat_disable;
uniform sampler2D face_up : filter_linear, repeat_disable;
uniform sampler2D face_down : filter_linear, repeat_disable;
uniform sampler2D face_front : filter_linear, repeat_disable;
uniform sampler2D face_back : filter_linear, repeat_disable;
// Expanded faces preserve core density and supply valid overlapping directions.
uniform float face_uv_scale = 1.0;

// Longitude zero looks down Godot's -Z axis. Image right turns toward +X.
// Face UVs are derived from each camera's right/up/forward basis.
void fragment() {
	float longitude = (UV.x - 0.5) * TAU;
	float latitude = (0.5 - UV.y) * PI;
	vec3 d = vec3(sin(longitude) * cos(latitude), sin(latitude), -cos(longitude) * cos(latitude));
	vec3 a = abs(d);
	vec2 p;
	vec4 result;
	if (face_uv_scale < 1.0) {
		// Only blend directions inside the expanded frusta. At a cube corner,
		// all three faces contribute; weights and their slopes vanish at the
		// overlap boundary. With no border the original one-face path is exact.
		vec3 weights = smoothstep(vec3(face_uv_scale), vec3(1.0), a / max(a.x, max(a.y, a.z)));
		weights /= weights.x + weights.y + weights.z;
		result = vec4(0.0);
		if (weights.x > 0.0) {
			p = vec2(d.x > 0.0 ? d.z : -d.z, -d.y) / a.x;
			if (d.x > 0.0) {
				result += texture(face_right, p * face_uv_scale * 0.5 + 0.5) * weights.x;
			} else {
				result += texture(face_left, p * face_uv_scale * 0.5 + 0.5) * weights.x;
			}
		}
		if (weights.y > 0.0) {
			p = vec2(d.x, d.y > 0.0 ? -d.z : d.z) / a.y;
			if (d.y > 0.0) {
				result += texture(face_up, p * face_uv_scale * 0.5 + 0.5) * weights.y;
			} else {
				result += texture(face_down, p * face_uv_scale * 0.5 + 0.5) * weights.y;
			}
		}
		if (weights.z > 0.0) {
			p = vec2(d.z < 0.0 ? d.x : -d.x, -d.y) / a.z;
			if (d.z < 0.0) {
				result += texture(face_front, p * face_uv_scale * 0.5 + 0.5) * weights.z;
			} else {
				result += texture(face_back, p * face_uv_scale * 0.5 + 0.5) * weights.z;
			}
		}
	} else if (a.x >= a.y && a.x >= a.z) {
		if (d.x > 0.0) {
			p = vec2(d.z, -d.y) / a.x;
			result = texture(face_right, p * face_uv_scale * 0.5 + 0.5);
		} else {
			p = vec2(-d.z, -d.y) / a.x;
			result = texture(face_left, p * face_uv_scale * 0.5 + 0.5);
		}
	} else if (a.y >= a.z) {
		if (d.y > 0.0) {
			p = vec2(d.x, -d.z) / a.y;
			result = texture(face_up, p * face_uv_scale * 0.5 + 0.5);
		} else {
			p = vec2(d.x, d.z) / a.y;
			result = texture(face_down, p * face_uv_scale * 0.5 + 0.5);
		}
	} else {
		if (d.z < 0.0) {
			p = vec2(d.x, -d.y) / a.z;
			result = texture(face_front, p * face_uv_scale * 0.5 + 0.5);
		} else {
			p = vec2(-d.x, -d.y) / a.z;
			result = texture(face_back, p * face_uv_scale * 0.5 + 0.5);
		}
	}
	COLOR = vec4(result.rgb, 1.0);
}
