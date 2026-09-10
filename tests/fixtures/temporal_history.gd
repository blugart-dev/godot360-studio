extends CompositorEffect
## Deliberately visible afterimage. Correct history belongs to each render buffer.
## The shared-history switch is an intentional failing control, never addon code.
var shared_history := false
var direct_only := false
var shader := RID()
var pipeline := RID()
var shared_textures := {}
var rd: RenderingDevice
var sampler := RID()
var counts := {}
var mutex := Mutex.new()

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
	var original_format := rd.texture_get_format(original)
	var sampled := not direct_only and not (original_format.usage_bits & RenderingDevice.TEXTURE_USAGE_STORAGE_BIT)
	if not shader.is_valid():
		var source := RDShaderSource.new()
		source.source_compute = """#version 450
layout(local_size_x=8, local_size_y=8, local_size_z=1) in;
layout(rgba16f, set=0, binding=0) uniform image2D target;
layout(rgba16f, set=0, binding=1) uniform image2D history;
#ifdef SAMPLED_INPUT
layout(set=0, binding=2) uniform sampler2D native_color;
#endif
layout(push_constant, std430) uniform Params { vec4 values; } params;
void main() {
    ivec2 p = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(p, imageSize(target)))) return;
    #ifdef SAMPLED_INPUT
    vec4 c = texelFetch(native_color, p, 0);
    #else
    vec4 c = imageLoad(target, p);
    #endif
    if (params.values.x > 0.5) c.rgb = mix(c.rgb, imageLoad(history, p).rgb, 0.65);
    imageStore(history, p, c);
    imageStore(target, p, c);
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
	# Mobile allows sampling and copying TO its attachment, not copying FROM it
	# or binding it as a storage image. Sample into our writable work texture.
	if sampled:
		target = buffers.create_texture(&"g360_temporal_test", &"work", original_format.format,
			RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT,
			RenderingDevice.TEXTURE_SAMPLES_1, size, 1, 1, false, false)
	var initialized := buffers.has_texture(&"g360_temporal_test", &"history")
	var history: RID
	if shared_history:
		# Deliberately share between equal-sized faces, without invalid accesses
		# from the differently sized main viewport.
		var key := str(size)
		initialized = shared_textures.has(key)
		if not initialized:
			var format := RDTextureFormat.new()
			format.width = size.x
			format.height = size.y
			format.format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
			format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
			shared_textures[key] = rd.texture_create(format, RDTextureView.new())
		history = shared_textures[key]
	else:
		history = buffers.create_texture(&"g360_temporal_test", &"history",
			RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT, RenderingDevice.TEXTURE_USAGE_STORAGE_BIT,
			RenderingDevice.TEXTURE_SAMPLES_1, size, 1, 1, false, false)
	var uniforms: Array[RDUniform] = []
	for texture in [target, history]:
		var uniform := RDUniform.new()
		uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		uniform.binding = uniforms.size()
		uniform.add_id(texture)
		uniforms.append(uniform)
	if sampled:
		var uniform := RDUniform.new()
		uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		uniform.binding = 2
		uniform.add_id(sampler)
		uniform.add_id(original)
		uniforms.append(uniform)
	var set_id := UniformSetCacheRD.get_cache(shader, 0, uniforms)
	var list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(list, pipeline)
	rd.compute_list_bind_uniform_set(list, set_id, 0)
	rd.compute_list_set_push_constant(list, PackedFloat32Array([1.0 if initialized else 0.0, 0, 0, 0]).to_byte_array(), 16)
	rd.compute_list_dispatch(list, ceili(size.x / 8.0), ceili(size.y / 8.0), 1)
	rd.compute_list_end()
	if target != original:
		var copy_error := rd.texture_copy(target, original, Vector3.ZERO, Vector3.ZERO, Vector3(size.x, size.y, 1), 0, 0, 0, 0)
		if copy_error != OK:
			push_error("Cannot return the history fixture's native color buffer.")
			return
	mutex.lock()
	var key := str(buffers.get_render_target().get_id())
	counts[key] = int(counts.get(key, 0)) + 1
	mutex.unlock()

func snapshot() -> Dictionary:
	mutex.lock()
	var result := counts.duplicate()
	mutex.unlock()
	return result

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and rd != null:
		for texture in shared_textures.values():
			rd.free_rid(texture)
		if shader.is_valid():
			rd.free_rid(shader)
		if sampler.is_valid():
			rd.free_rid(sampler)
