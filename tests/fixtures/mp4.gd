extends RefCounted
## Small structural fixtures; these are not decodable media.
const M = preload("res://addons/godot360/spherical_metadata.gd")


static func track(offsets: Array, wide: bool = false, audio: bool = false, extra: PackedByteArray = PackedByteArray()) -> PackedByteArray:
	var table := M.pack_u32(0) + M.pack_u32(offsets.size())
	for offset in offsets:
		table.append_array(M.pack_u64(offset) if wide else M.pack_u32(offset))
	var entry := PackedByteArray()
	entry.resize(28 if audio else 78)
	entry[7] = 1 # Self-contained data_reference_index.
	entry.append_array(M.atom("esds" if audio else "avcC", PackedByteArray([1, 2, 3, 4])))
	if not audio:
		entry.append_array(M.atom("pasp", M.pack_u32(1) + M.pack_u32(1)))
	entry.append_array(extra)
	var stsd := M.atom("stsd", M.pack_u32(0) + M.pack_u32(1) + M.atom("mp4a" if audio else "avc1", entry))
	var stbl := M.atom("stbl", stsd + M.atom("co64" if wide else "stco", table))
	var dinf := M.atom("dinf", M.atom("dref", M.pack_u32(0) + M.pack_u32(1) + M.atom("url ", M.pack_u32(1))))
	var handler := M.atom("hdlr", M.pack_u32(0) + M.pack_u32(0) + ("soun" if audio else "vide").to_ascii_buffer())
	return M.atom("trak", M.atom("mdia", handler + M.atom("minf", dinf + stbl)))


static func table(track_data: PackedByteArray) -> PackedByteArray:
	var stbl := M.child(M.child(M.child(track_data, "mdia"), "minf"), "stbl")
	var result := M.child(stbl, "stco")
	return M.child(stbl, "co64") if result.is_empty() else result


static func entry(track_data: PackedByteArray) -> PackedByteArray:
	var stsd := M.child(M.child(M.child(M.child(track_data, "mdia"), "minf"), "stbl"), "stsd")
	return stsd.slice(16)
