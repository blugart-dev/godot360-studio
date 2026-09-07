extends CompositorEffect
## Stateless compute effect: every view must receive the same channel tint.
var shader := RID()
var pipeline := RID()
var rd: RenderingDevice

func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	access_resolved_color = true
	rd = RenderingServer.get_rendering_device()

func _render_callback(_type: int, data: RenderData) -> void:
	if rd == null:
		return
	if not shader.is_valid():
		var source := RDShaderSource.new()
		source.source_compute = """#version 450
layout(local_size_x=8, local_size_y=8, local_size_z=1) in;
layout(rgba16f, set=0, binding=0) uniform image2D target;
void main() {
    ivec2 p = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(p, imageSize(target)))) return;
    vec4 c = imageLoad(target, p);
    imageStore(target, p, vec4(c.rgb * vec3(0.25, 1.0, 0.5), c.a));
}
"""
		var spirv := rd.shader_compile_spirv_from_source(source)
		if not spirv.compile_error_compute.is_empty():
			push_error(spirv.compile_error_compute)
			return
		shader = rd.shader_create_from_spirv(spirv)
		pipeline = rd.compute_pipeline_create(shader)
	var buffers := data.get_render_scene_buffers() as RenderSceneBuffersRD
	var size := buffers.get_internal_size()
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0
	uniform.add_id(buffers.get_color_layer(0))
	var uniforms := UniformSetCacheRD.get_cache(shader, 0, [uniform])
	var list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(list, pipeline)
	rd.compute_list_bind_uniform_set(list, uniforms, 0)
	rd.compute_list_dispatch(list, ceili(size.x / 8.0), ceili(size.y / 8.0), 1)
	rd.compute_list_end()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and shader.is_valid() and rd != null:
		rd.free_rid(shader)
