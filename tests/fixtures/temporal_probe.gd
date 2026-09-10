extends CompositorEffect
## Observe actual render buffers; requested viewport flags alone cannot prove FSR.
var records := {}
var mutex := Mutex.new()

func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT

func _render_callback(_type: int, data: RenderData) -> void:
	var buffers := data.get_render_scene_buffers() as RenderSceneBuffersRD
	var key := str(buffers.get_render_target().get_id())
	mutex.lock()
	var count := int(records.get(key, {}).get("count", 0)) + 1
	records[key] = {"count": count, "taa": buffers.get_use_taa(),
		"scaling_mode": buffers.get_scaling_3d_mode(),
		"color_usage_bits": RenderingServer.get_rendering_device().texture_get_format(buffers.get_color_layer(0)).usage_bits,
		"internal_width": buffers.get_internal_size().x, "target_width": buffers.get_target_size().x}
	mutex.unlock()

func snapshot() -> Dictionary:
	mutex.lock()
	var result := records.duplicate(true)
	mutex.unlock()
	return result
