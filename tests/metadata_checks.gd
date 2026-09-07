extends SceneTree
## Structural, relocation, large-offset and failure contracts without GPU capture.
const M = preload("res://addons/godot360/spherical_metadata.gd")
const F = preload("res://tests/fixtures/mp4.gd")
var checks := 0
var failures := 0
var folder: String
var prefix := M.atom("ftyp", "isom0000".to_ascii_buffer()) + M.atom("free", PackedByteArray([7, 8, 9]))
var calls := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	folder = ProjectSettings.globalize_path("res://.godot360/metadata-" + str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(folder)
	_regular()
	_large_offsets()
	_invalid()
	_cancellation()
	print("METADATA CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _regular() -> void:
	var media := M.atom("mdat", PackedByteArray([11, 22, 33, 44, 55, 66, 77, 88]))
	var first := prefix.size() + 8
	var moov := M.atom("moov", F.track([first, first + 2]) + F.track([first + 1, first + 3], true, true))
	var source := prefix + media + moov
	_write("source.mp4", source)
	check(M.inject(_path("source.mp4"), _path("final.mp4"), 2048, 1024).is_empty(), "Mixed stco video and co64 audio inject successfully")
	var final := FileAccess.get_file_as_bytes(_path("final.mp4"))
	var relocated := M.child(M.atom("root", final), "moov")
	check(final.slice(0, prefix.size()) == prefix, "File type and leading padding bytes remain exact")
	check(final.slice(prefix.size() + relocated.size()) == media, "Entire mdat including its header remains exact")
	check(FileAccess.get_file_as_bytes(_path("source.mp4")) == source, "Source MP4 remains byte-identical")
	var tracks := M.children(relocated)
	for index in range(2):
		var track := relocated.slice(tracks[index].offset, tracks[index].offset + tracks[index].size)
		var table := F.table(track)
		var offset := M.u32(table, 16) if index == 0 else M.u64(table, 16)
		check(offset == first + index + relocated.size() and final[offset] == source[first + index], "Track %d offset resolves to its original media byte" % index)
	var video := M.child(relocated, "trak")
	var entry := F.entry(video)
	var children := M.children(entry, 86)
	var names: Array = []
	for box in children:
		names.append(box.kind)
	check(names == ["avcC", "st3d", "sv3d", "pasp"], "V2 boxes follow avcC and precede optional pixel aspect ratio")
	var sv3d := entry.slice(children[2].offset, children[2].offset + children[2].size)
	var svhd := M.child(sv3d, "svhd")
	check(M.u32(svhd, 8) == 0 and svhd[-1] == 0 and svhd.slice(12, -1).get_string_from_utf8() == M.SOFTWARE, "V2 header is version zero with null-terminated UTF-8 source")
	var proj := M.child(sv3d, "proj")
	check(M.child(proj, "prhd") == M.atom("prhd", _zeros(16)), "V2 pose is zero yaw, pitch and roll")
	check(M.child(proj, "equi") == M.atom("equi", _zeros(20)), "V2 equirectangular bounds cover the full panorama")
	check(M.inspect(_path("final.mp4")).get("spherical_v2", false), "Output inspector recognizes V2")
	check(M.inspect(_path("final.mp4")).get("fast_start", false), "Output inspector confirms moov before media")
	check(M.inspect(_path("final.mp4")).get("chunk_offsets", false), "Output inspector checks all chunk starts lie in media")
	check(not M.inspect(_path("source.mp4")).get("spherical_v2", true), "V1-free ordinary MP4 cannot pass V2 inspection")
	var corrupt := final.duplicate()
	corrupt[_position(corrupt, "st3d") + 8] = 1
	_write("stereo.mp4", corrupt)
	check(not M.inspect(_path("stereo.mp4")).get("error", "").is_empty(), "Wrong stereo mode fails inspection")
	corrupt = final.duplicate()
	_put(corrupt, _position(corrupt, "stco") + 12, 0)
	_write("bad-final-offset.mp4", corrupt)
	check(not M.inspect(_path("bad-final-offset.mp4")).get("error", "").is_empty(), "A relocated offset outside media fails output inspection")
	corrupt = final.duplicate()
	_put(corrupt, _position(corrupt, "prhd") + 8, 1)
	_write("rotated.mp4", corrupt)
	check(not M.inspect(_path("rotated.mp4")).get("error", "").is_empty(), "An unexpected V2 pose fails output inspection")
	# A second media box has the same shift, including intervening padding.
	var second := M.atom("free", PackedByteArray([4])) + M.pack_u32(1) + "mdat".to_ascii_buffer() + M.pack_u64(20) + PackedByteArray([91, 92, 93, 94])
	var second_offset := prefix.size() + media.size() + 9 + 16
	_write("multi.mp4", prefix + media + second + M.atom("moov", F.track([first, second_offset])))
	check(M.inject(_path("multi.mp4"), _path("multi-final.mp4"), 2048, 1024).is_empty(), "Multiple media boxes and an extended mdat header are supported")
	var multi := FileAccess.get_file_as_bytes(_path("multi-final.mp4"))
	var multi_moov := multi.slice(prefix.size(), prefix.size() + M.u32(multi, prefix.size()))
	check(multi.slice(prefix.size() + multi_moov.size()) == media + second, "All media and intervening padding bytes survive relocation")
	var multi_table := F.table(M.child(multi_moov, "trak"))
	check(multi[M.u32(multi_table, 20)] == 91, "Chunk in extended second mdat resolves correctly")


func _large_offsets() -> void:
	var regions := [{"start": 24, "end": 0x200000000}]
	var baseline := M.prepare(M.atom("moov", F.track([24]) + F.track([25], false, true)), regions, 2048, 1024)
	var a: int = 0xffffffff - baseline.shift + 1
	var b: int = 0xffffffff - baseline.shift - 2
	var result := M.prepare(M.atom("moov", F.track([a]) + F.track([b], false, true)), regions, 2048, 1024)
	check(result.error.is_empty() and result.shift == baseline.shift + 8, "Cascading 4 GiB promotions converge using the final moov size")
	var boxes := M.children(result.moov)
	for index in range(2):
		var table := F.table(result.moov.slice(boxes[index].offset, boxes[index].offset + boxes[index].size))
		check(table.slice(4, 8).get_string_from_ascii() == "co64" and M.u64(table, 16) == (a if index == 0 else b) + result.shift, "Promoted track %d retains the exact 64-bit offset" % index)
	var wide := M.prepare(M.atom("moov", F.track([0x100000020], true)), regions, 2048, 1024)
	check(wide.error.is_empty() and M.u64(F.table(M.child(wide.moov, "trak")), 16) == 0x100000020 + wide.shift, "Existing offsets above 4 GiB relocate without truncation")
	var boundary := M.prepare(M.atom("moov", F.track([0xffffffff])), regions, 2048, 1024)
	check(boundary.error.is_empty() and F.table(M.child(boundary.moov, "trak")).slice(4, 8).get_string_from_ascii() == "co64", "Maximum unsigned 32-bit offset promotes instead of wrapping")
	var overflow := M.prepare(M.atom("moov", F.track([0x7ffffffffffffffe], true)), [{"start": 24, "end": 0x7fffffffffffffff}], 2048, 1024)
	check(not overflow.error.is_empty(), "Signed 64-bit overflow is rejected before wrapping")


func _invalid() -> void:
	var first := prefix.size() + 8
	var media := M.atom("mdat", PackedByteArray([1, 2, 3, 4]))
	var good := M.atom("moov", F.track([first]))
	_reject("offset-header", prefix + media + M.atom("moov", F.track([first - 1])))
	_reject("offset-end", prefix + media + M.atom("moov", F.track([first + 4])))
	_reject("empty-offsets", prefix + media + M.atom("moov", F.track([])))
	_reject("negative-co64", prefix + media + M.atom("moov", F.track([-1], true)))
	_reject("multiple-video", prefix + media + M.atom("moov", F.track([first]) + F.track([first])))
	_reject("audio-only", prefix + media + M.atom("moov", F.track([first], false, true)))
	_reject("fragmented", prefix + M.atom("moof", PackedByteArray()) + media + good)
	_reject("indexed", prefix + M.atom("sidx", _zeros(16)) + media + good)
	_reject("duplicate-moov", prefix + media + good + good)
	_reject("faststart-input", prefix + good + media)
	_reject("truncated-child", prefix + media + M.atom("moov", F.track([first]) + PackedByteArray([0])))
	_reject("existing-v2", prefix + media + M.atom("moov", F.track([first], false, false, M.v2())))
	var uuid_track := F.track([first])
	uuid_track = M.atom("trak", uuid_track.slice(8) + M.atom("uuid", M.SPHERICAL_UUID.hex_decode() + "old".to_utf8_buffer()))
	_reject("existing-v1", prefix + media + M.atom("moov", uuid_track))
	check(M.inspect(_path("existing-v1.mp4")).get("spherical_v1", false) and not M.inspect(_path("existing-v1.mp4")).get("spherical_v2", true), "V1-only metadata cannot satisfy the new V2 delivery check")
	for item in [{"kind": "stco", "distance": 8, "value": 2}, {"kind": "stsd", "distance": 8, "value": 2}, {"kind": "url ", "distance": 4, "value": 0}]:
		var damaged := good.duplicate()
		_put(damaged, _position(damaged, item.kind) + item.distance, item.value)
		_reject("malformed-" + item.kind.strip_edges(), prefix + media + damaged)
	var unsupported := good.duplicate()
	_put(unsupported, _position(unsupported, "stco"), 0x7361696f) # saio has offsets we do not support.
	_reject("auxiliary-offsets", prefix + media + unsupported)
	_write("valid.mp4", prefix + media + good)
	check(not M.inject(_path("valid.mp4"), _path("wrong-size.mp4"), 100, 100).is_empty() and not FileAccess.file_exists(_path("wrong-size.mp4")), "Invalid panorama dimensions fail before creating output")
	check(not M.inject(_path("valid.mp4"), _path("valid.mp4"), 2048, 1024).is_empty(), "In-place output is rejected")
	_write("existing.mp4", PackedByteArray([77]))
	check(not M.inject(_path("valid.mp4"), _path("existing.mp4"), 2048, 1024).is_empty() and FileAccess.get_file_as_bytes(_path("existing.mp4")) == PackedByteArray([77]), "Existing destination is preserved")


func _cancellation() -> void:
	var source := prefix + M.atom("mdat", _zeros(3 * 1024 * 1024)) + M.atom("moov", F.track([prefix.size() + 8]))
	_write("large.mp4", source)
	check(M.inject(_path("large.mp4"), _path("cancel-before.mp4"), 2048, 1024, func(): return true).begins_with("Cancelled") and not FileAccess.file_exists(_path("cancel-before.mp4")), "Cancellation before copying creates no output")
	calls = 0
	var error := M.inject(_path("large.mp4"), _path("cancel-during.mp4"), 2048, 1024, func():
		calls += 1
		return calls >= 4)
	check(error.begins_with("Cancelled") and FileAccess.get_file_as_bytes(_path("cancel-during.mp4")).size() < source.size(), "Cancellation during media copy stops with retained partial output")
	check(FileAccess.get_file_as_bytes(_path("large.mp4")) == source, "Cancellation leaves the source unchanged")


func _reject(name: String, data: PackedByteArray) -> void:
	_write(name + ".mp4", data)
	var destination := _path(name + "-out.mp4")
	check(not M.inject(_path(name + ".mp4"), destination, 2048, 1024).is_empty() and not FileAccess.file_exists(destination), name + " fails before output creation")


func _path(name: String) -> String:
	return folder.path_join(name)


func _write(name: String, data: PackedByteArray) -> void:
	FileAccess.open(_path(name), FileAccess.WRITE).store_buffer(data)


func _position(data: PackedByteArray, kind: String) -> int:
	return data.hex_encode().find(kind.to_ascii_buffer().hex_encode()) / 2


func _put(data: PackedByteArray, offset: int, value: int) -> void:
	var bytes := M.pack_u32(value)
	for index in range(4):
		data[offset + index] = bytes[index]


func _zeros(size: int) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(size)
	return data


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
