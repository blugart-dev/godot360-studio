shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

// Point-facing billboards: all six views share the same camera position.
// World up keeps their roll consistent across faces and camera cuts.
uniform bool point_billboard = true;
uniform vec4 smoke_color : source_color = vec4(0.72, 0.78, 0.86, 0.48);

void vertex() {
	if (point_billboard) {
		vec3 facing = CAMERA_POSITION_WORLD - MODEL_MATRIX[3].xyz;
		facing = length(facing) > 0.00001 ? normalize(facing) : vec3(0.0, 0.0, 1.0);
		vec3 up = abs(facing.y) > 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);
		vec3 right = normalize(cross(up, facing));
		up = cross(facing, right);
		float angle = INSTANCE_CUSTOM.x;
		vec3 x = (right * cos(angle) - up * sin(angle)) * length(MODEL_MATRIX[0].xyz);
		vec3 y = (right * sin(angle) + up * cos(angle)) * length(MODEL_MATRIX[1].xyz);
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(x, 0.0), vec4(y, 0.0), vec4(facing, 0.0), MODEL_MATRIX[3]);
	}
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float edge = 1.0 - smoothstep(0.62, 1.0, length(p));
	float density = exp(-3.2 * dot(p, p));
	density *= 0.78 + 0.13 * sin(p.x * 11.0 + p.y * 7.0) + 0.09 * cos(p.y * 15.0 - p.x * 5.0);
	ALBEDO = smoke_color.rgb * COLOR.rgb;
	ALPHA = smoke_color.a * COLOR.a * density * edge;
}
