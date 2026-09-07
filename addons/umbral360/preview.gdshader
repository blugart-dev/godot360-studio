shader_type canvas_item;
render_mode unshaded;
uniform sampler2D panorama : filter_linear, repeat_enable;
uniform vec2 heading = vec2(0.0);
uniform float aspect = 2.0;

void fragment() {
	vec2 plane = (UV * 2.0 - 1.0) * vec2(aspect, -1.0) * tan(PI / 6.0);
	vec3 d = normalize(vec3(plane, -1.0));
	float cp = cos(heading.y);
	float sp = sin(heading.y);
	d = vec3(d.x, cp * d.y - sp * d.z, sp * d.y + cp * d.z);
	float cy = cos(heading.x);
	float sy = sin(heading.x);
	d = vec3(cy * d.x - sy * d.z, d.y, sy * d.x + cy * d.z);
	vec2 spherical = vec2(atan(d.x, -d.z) / TAU + 0.5, 0.5 - asin(clamp(d.y, -1.0, 1.0)) / PI);
	COLOR = vec4(texture(panorama, spherical).rgb, 1.0);
}
