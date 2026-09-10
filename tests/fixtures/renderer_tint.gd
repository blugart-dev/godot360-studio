extends CompositorEffect
## Stateless compute effect: every view must receive the same channel tint.
var shader := RID()
var pipeline := RID()
var rd: RenderingDevice
var sampler := RID()

func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	access_resolved_color = true
	rd = RenderingServer.get_rendering_device()

func _render_callback(_type: int, data: RenderData) -> void:
	if rd == null:
		return
	var buffers := data.get_render_scene_buffers() as RenderSceneBuffersRD
	var size := buffers.get_internal_size()
	var original := buffers.get_color_layer(0)
	var format := rd.texture_get_format(original)
	var sampled := not (format.usage_bits & RenderingDevice.TEXTURE_USAGE_STORAGE_BIT)
	if not shader.is_valid():
		var source := RDShaderSource.new()
		source.source_compute = """#version 450
layout(local_size_x=8, local_size_y=8, local_size_z=1) in;
layout(rgba16f, set=0, binding=0) uniform image2D target;
#ifdef SAMPLED_INPUT
layout(set=0, binding=1) uniform sampler2D native_color;
#endif
void main() {
    ivec2 p = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(p, imageSize(target)))) return;
    #ifdef SAMPLED_INPUT
    vec4 c = texelFetch(native_color, p, 0);
    #else
    vec4 c = imageLoad(target, p);
    #endif
    imageStore(target, p, vec4(c.rgb * vec3(0.25, 1.0, 0.5), c.a));
}
"""
		if sampled:
			source.source_compute = source.source_compute.replace("#version 450", "#version 450\n#define SAMPLED_INPUT")
			sampler = rd.sampler_create(RDSamplerState.new())
		var spirv := rd.shader_compile_spirv_from_source(source)
		if not spirv.compile_error_compute.is_empty():
			push_error(spirv.compile_error_compute)
			return
		shader = rd.shader_create_from_spirv(spirv)
		pipeline = rd.compute_pipeline_create(shader)
	var target := original
	# Mobile's resolved attachment is sampled, then receives the tinted copy.
	# The renderer review authors 4x MSAA so this destination supports copying.
	if sampled:
		target = buffers.create_texture(&"g360_tint_test", &"work", format.format,
			RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT,
			RenderingDevice.TEXTURE_SAMPLES_1, size, 1, 1, false, false)
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0
	uniform.add_id(target)
	var bindings: Array[RDUniform] = [uniform]
	if sampled:
		var input := RDUniform.new()
		input.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		input.binding = 1
		input.add_id(sampler)
		input.add_id(original)
		bindings.append(input)
	var uniforms := UniformSetCacheRD.get_cache(shader, 0, bindings)
	var list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(list, pipeline)
	rd.compute_list_bind_uniform_set(list, uniforms, 0)
	rd.compute_list_dispatch(list, ceili(size.x / 8.0), ceili(size.y / 8.0), 1)
	rd.compute_list_end()
	if sampled:
		var error := rd.texture_copy(target, original, Vector3.ZERO, Vector3.ZERO, Vector3(size.x, size.y, 1), 0, 0, 0, 0)
		if error != OK:
			push_error("Cannot return the tint fixture's native color buffer.")

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and shader.is_valid() and rd != null:
		rd.free_rid(shader)
		if sampler.is_valid():
			rd.free_rid(sampler)
