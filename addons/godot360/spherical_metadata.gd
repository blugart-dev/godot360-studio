extends RefCounted
## Original, deliberately narrow MP4 writer for the pipeline's unfragmented files.
## Adds equivalent V1/V2 mono metadata and moves moov before the first mdat.
## Only conventional, self-contained H.264/AAC files with a trailing moov are inputs.

const SPHERICAL_UUID = "ffcc8263f8554a938814587a02521fdd"
const MAX_MOOV = 64 * 1024 * 1024
const SOFTWARE = "Godot360 Studio 0.8.0"
# Unknown structural boxes may contain offsets we cannot safely relocate.
const CONTAINERS = {
	"moov": ["mvhd", "trak", "udta"],
	"trak": ["tkhd", "edts", "mdia", "uuid"],
	"edts": ["elst"],
	"mdia": ["mdhd", "hdlr", "minf"],
	"minf": ["vmhd", "smhd", "dinf", "stbl"],
	"dinf": ["dref"],
	"stbl": ["stsd", "stts", "stss", "ctts", "stsc", "stsz", "stco", "co64", "sgpd", "sbgp"],
	"stsd": ["avc1", "mp4a"],
	"avc1": ["avcC", "st3d", "sv3d", "colr", "pasp", "clap", "btrt", "fiel"],
	"mp4a": ["esds", "btrt"],
	"dref": ["url "],
}


static func u32(data: PackedByteArray, offset: int) -> int:
	return (int(data[offset]) << 24) | (int(data[offset + 1]) << 16) | (int(data[offset + 2]) << 8) | int(data[offset + 3])


static func pack_u32(value: int) -> PackedByteArray:
	return PackedByteArray([(value >> 24) & 255, (value >> 16) & 255, (value >> 8) & 255, value & 255])


static func u64(data: PackedByteArray, offset: int) -> int:
	return (u32(data, offset) << 32) | u32(data, offset + 4)


static func pack_u64(value: int) -> PackedByteArray:
	return pack_u32(value >> 32) + pack_u32(value & 0xffffffff)


static func atom(kind: String, payload: PackedByteArray) -> PackedByteArray:
	return pack_u32(payload.size() + 8) + kind.to_ascii_buffer() + payload


static func children(data: PackedByteArray, start: int = 8) -> Array[Dictionary]:
	var boxes: Array[Dictionary] = []
	var offset: int = start
	while offset < data.size():
		if offset + 8 > data.size():
			return []
		var size: int = u32(data, offset)
		if size < 8 or offset + size > data.size():
			return []
		boxes.append({"kind": data.slice(offset + 4, offset + 8).get_string_from_ascii(), "offset": offset, "size": size})
		offset += size
	return boxes


static func child(data: PackedByteArray, kind: String) -> PackedByteArray:
	for box in children(data):
		if box.kind == kind:
			return data.slice(box.offset, box.offset + box.size)
	return PackedByteArray()


static func is_video(track: PackedByteArray) -> bool:
	var handler := child(child(track, "mdia"), "hdlr")
	return handler.size() >= 20 and handler.slice(16, 20).get_string_from_ascii() == "vide"


static func xml(width: int, height: int) -> String:
	return """<rdf:SphericalVideo xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:GSpherical="http://ns.google.com/videos/1.0/spherical/">
<GSpherical:Spherical>true</GSpherical:Spherical>
<GSpherical:Stitched>true</GSpherical:Stitched>
<GSpherical:StitchingSoftware>%s</GSpherical:StitchingSoftware>
<GSpherical:ProjectionType>equirectangular</GSpherical:ProjectionType>
<GSpherical:StereoMode>mono</GSpherical:StereoMode>
<GSpherical:SourceCount>6</GSpherical:SourceCount>
<GSpherical:FullPanoWidthPixels>%d</GSpherical:FullPanoWidthPixels>
<GSpherical:FullPanoHeightPixels>%d</GSpherical:FullPanoHeightPixels>
<GSpherical:CroppedAreaImageWidthPixels>%d</GSpherical:CroppedAreaImageWidthPixels>
<GSpherical:CroppedAreaImageHeightPixels>%d</GSpherical:CroppedAreaImageHeightPixels>
<GSpherical:CroppedAreaLeftPixels>0</GSpherical:CroppedAreaLeftPixels>
<GSpherical:CroppedAreaTopPixels>0</GSpherical:CroppedAreaTopPixels>
</rdf:SphericalVideo>""" % [SOFTWARE, width, height, width, height]


static func v2() -> PackedByteArray:
	var header := atom("svhd", pack_u32(0) + SOFTWARE.to_utf8_buffer() + PackedByteArray([0]))
	var projection := atom("proj", atom("prhd", pack_u32(0) + pack_u32(0) + pack_u32(0) + pack_u32(0)) +
		atom("equi", pack_u32(0) + pack_u32(0) + pack_u32(0) + pack_u32(0) + pack_u32(0)))
	return atom("st3d", PackedByteArray([0, 0, 0, 0, 0])) + atom("sv3d", header + projection)


static func _layout(input: FileAccess) -> Dictionary:
	var result := {"error": "", "moov": PackedByteArray(), "moov_offset": -1, "media": [], "boxes": []}
	input.big_endian = true
	input.seek(0)
	while input.get_position() < input.get_length():
		var offset := input.get_position()
		if input.get_length() - offset < 8:
			return {"error": "Truncated MP4 header."}
		var size := input.get_32()
		var kind := input.get_buffer(4).get_string_from_ascii()
		var header := 8
		if size == 1:
			if input.get_length() - offset < 16:
				return {"error": "Truncated extended MP4 header."}
			size = input.get_64()
			header = 16
		if size < header or size > input.get_length() - offset:
			return {"error": "Invalid or unsupported MP4 atom size."}
		if kind not in ["ftyp", "free", "wide", "mdat", "moov"]:
			return {"error": "Unsupported top-level MP4 box: " + kind}
		if kind == "ftyp" and (offset != 0 or size < 16):
			return {"error": "Expected one leading MP4 file-type box."}
		if kind == "mdat":
			result.media.append({"start": offset + header, "end": offset + size, "offset": offset})
		if kind == "moov":
			if result.moov_offset >= 0 or header != 8 or size > MAX_MOOV:
				return {"error": "Expected one conventional moov (maximum 64 MiB)."}
			result.moov_offset = offset
			input.seek(offset)
			result.moov = input.get_buffer(size)
			if result.moov.size() != size:
				return {"error": "Could not read the complete moov box."}
		result.boxes.append({"kind": kind, "offset": offset, "size": size})
		input.seek(offset + size)
	if result.moov_offset < 0 or result.media.is_empty() or result.boxes[0].kind != "ftyp":
		return {"error": "Expected ftyp, media, and one moov box."}
	return result


static func _error(state: Dictionary, message: String) -> PackedByteArray:
	state.error = message
	return PackedByteArray()


static func _state(injecting: bool, width: int = 0, height: int = 0) -> Dictionary:
	return {"error": "", "inject": injecting, "width": width, "height": height,
		"video": 0, "audio": 0, "tables": 0, "chunks": 0, "v1": 0, "v2": 0, "stereo": 0}


# This bounded tree walk only rewrites box sizes, sample-entry metadata and chunk
# tables. All other accepted boxes retain their exact encoded bytes.
static func _rewrite(data: PackedByteArray, delta: int, media: Array, state: Dictionary) -> PackedByteArray:
	if data.size() < 8 or u32(data, 0) != data.size():
		return _error(state, "Invalid nested MP4 box.")
	var kind := data.slice(4, 8).get_string_from_ascii()
	if kind in ["stco", "co64"]:
		return _offsets(data, delta, media, state)
	if kind == "url " and (data.size() != 12 or u32(data, 8) != 1):
		return _error(state, "External media references are unsupported.")
	if kind == "uuid":
		if data.size() < 24:
			return _error(state, "Truncated UUID box.")
		if data.slice(8, 24).hex_encode() == SPHERICAL_UUID:
			if state.inject:
				return _error(state, "Input already contains spherical metadata.")
			state.v1 += 1
		return data
	if kind in ["st3d", "sv3d"]:
		if state.inject:
			return _error(state, "Input already contains V2 spherical/stereo metadata.")
		# The output inspector checks this writer's full, unrotated mono profile.
		var expected := PackedByteArray()
		var metadata := v2()
		for box in children(metadata, 0):
			if box.kind == kind:
				expected = metadata.slice(box.offset, box.offset + box.size)
		if data != expected:
			return _error(state, "Unexpected spherical V2 projection or stereo layout.")
		state["v2" if kind == "sv3d" else "stereo"] += 1
		return data
	if not CONTAINERS.has(kind):
		return data
	var start := 8
	if kind in ["stsd", "dref"]:
		if data.size() < 16 or u32(data, 8) != 0 or u32(data, 12) != 1:
			return _error(state, "Expected one conventional sample description or data reference.")
		start = 16
	if kind in ["avc1", "mp4a"]:
		start = 86 if kind == "avc1" else 36
		if data.size() < start or data[14] != 0 or data[15] != 1:
			return _error(state, "Unsupported sample entry or media reference index.")
		if kind == "mp4a" and u32(data, 16) != 0:
			return _error(state, "Unsupported audio sample-entry version.")
	var boxes := children(data, start)
	if boxes.is_empty():
		return _error(state, "Empty or malformed MP4 container: " + kind)
	var counts := {}
	for box in boxes:
		if box.kind not in CONTAINERS[kind]:
			return _error(state, "Unsupported box in %s: %s" % [kind, box.kind])
		counts[box.kind] = int(counts.get(box.kind, 0)) + 1
		if counts[box.kind] > 1 and box.kind not in ["trak", "uuid", "sgpd", "sbgp"]:
			return _error(state, "Duplicate MP4 box: " + box.kind)
	var required := {"moov": ["trak"], "trak": ["mdia"], "mdia": ["hdlr", "minf"],
		"minf": ["dinf", "stbl"], "dinf": ["dref"], "dref": ["url "], "stbl": ["stsd"], "avc1": ["avcC"], "mp4a": ["esds"]}
	for name in required.get(kind, []):
		if not counts.has(name):
			return _error(state, "Missing MP4 box: " + name)
	if kind == "stbl" and int(counts.get("stco", 0)) + int(counts.get("co64", 0)) != 1:
		return _error(state, "Expected one chunk-offset table per track.")
	if kind in ["stsd", "dref"] and boxes.size() != 1:
		return _error(state, "Sample/data-reference count does not match its entries.")
	var video_track := false
	if kind == "trak":
		var handler := child(child(data, "mdia"), "hdlr")
		if handler.size() < 20:
			return _error(state, "Missing track handler.")
		var handler_type := handler.slice(16, 20).get_string_from_ascii()
		if handler_type not in ["vide", "soun"]:
			return _error(state, "Only video and audio tracks are supported.")
		video_track = handler_type == "vide"
		state["video" if video_track else "audio"] += 1
		var stsd := child(child(child(child(data, "mdia"), "minf"), "stbl"), "stsd")
		var descriptions := children(stsd, 16)
		if descriptions.size() != 1 or descriptions[0].kind != ("avc1" if video_track else "mp4a"):
			return _error(state, "Expected an H.264 video or AAC audio sample entry.")
	var payload := data.slice(8, start)
	for box in boxes:
		var rewritten := _rewrite(data.slice(box.offset, box.offset + box.size), delta, media, state)
		if not state.error.is_empty():
			return PackedByteArray()
		payload.append_array(rewritten)
		# avcC is required; insert before optional display/aspect-ratio boxes.
		if kind == "avc1" and box.kind == "avcC" and state.inject:
			payload.append_array(v2())
	if kind == "trak" and video_track and state.inject:
		payload.append_array(atom("uuid", SPHERICAL_UUID.hex_decode() + xml(state.width, state.height).to_utf8_buffer()))
	return atom(kind, payload)


static func _offsets(data: PackedByteArray, delta: int, media: Array, state: Dictionary) -> PackedByteArray:
	var wide := data.slice(4, 8).get_string_from_ascii() == "co64"
	var stride := 8 if wide else 4
	if data.size() < 16 or u32(data, 8) != 0 or u32(data, 12) == 0 or u32(data, 12) * stride != data.size() - 16:
		return _error(state, "Malformed or empty chunk-offset table.")
	var offsets: Array[int] = []
	for index in range(u32(data, 12)):
		var offset := u64(data, 16 + index * stride) if stride == 8 else u32(data, 16 + index * stride)
		var in_media := false
		for region in media:
			if offset >= int(region.start) and offset < int(region.end):
				in_media = true
		if not in_media or offset < 0 or offset > 0x7fffffffffffffff - delta:
			return _error(state, "Chunk offset is outside media or overflows the supported range.")
		offsets.append(offset + delta)
		wide = wide or offset + delta > 0xffffffff
	var payload := data.slice(8, 16)
	for offset in offsets:
		payload.append_array(pack_u64(offset) if wide else pack_u32(offset))
	state.tables += 1
	state.chunks += offsets.size()
	return atom("co64" if wide else "stco", payload)


# Promotion can enlarge moov enough to push another stco table over 4 GiB.
# Rebuild from the original offsets until the inserted size stops changing.
static func prepare(moov: PackedByteArray, media: Array, width: int, height: int) -> Dictionary:
	var delta := 0
	for _iteration in range(4):
		var state := _state(true, width, height)
		var rewritten := _rewrite(moov, delta, media, state)
		if not state.error.is_empty():
			return state
		if state.video != 1 or state.audio > 1:
			return {"error": "Expected one H.264 video track and at most one AAC audio track."}
		if rewritten.size() > MAX_MOOV:
			return {"error": "Rebuilt moov exceeds the 64 MiB limit."}
		if rewritten.size() == delta:
			return {"error": "", "moov": rewritten, "shift": delta, "chunks": state.chunks}
		delta = rewritten.size()
	return {"error": "Chunk-offset promotion did not converge."}


static func inspect(path: String) -> Dictionary:
	var input := FileAccess.open(path, FileAccess.READ)
	if input == null:
		return {"error": "Cannot read spherical MP4."}
	var layout := _layout(input)
	if not layout.error.is_empty():
		return layout
	var state := _state(false)
	_rewrite(layout.moov, 0, layout.media, state)
	if not state.error.is_empty():
		return state
	return {"error": "", "fast_start": layout.moov_offset < layout.media[0].offset,
		"spherical_v2": state.video == 1 and state.v2 == 1 and state.stereo == 1,
		"spherical_v1": state.v1 == 1, "chunk_offsets": state.tables == state.video + state.audio and state.chunks > 0}


static func _copy(input: FileAccess, output: FileAccess, end: int, cancelled: Callable) -> String:
	while input.get_position() < end:
		if cancelled.is_valid() and cancelled.call():
			return "Cancelled. Intermediate files have been retained."
		var count := mini(1024 * 1024, end - input.get_position())
		var chunk := input.get_buffer(count)
		if chunk.size() != count:
			return "Could not copy complete MP4 media."
		output.store_buffer(chunk)
		if output.get_error() != OK:
			return "Could not write spherical MP4 media."
	return ""


static func inject(source: String, destination: String, width: int, height: int, cancelled: Callable = Callable()) -> String:
	if source == destination or FileAccess.file_exists(destination):
		return "Metadata output must be a new file."
	if width <= 0 or height <= 0 or width != height * 2:
		return "Spherical metadata requires a full 2:1 panorama."
	var input := FileAccess.open(source, FileAccess.READ)
	if input == null:
		return "Cannot read encoded MP4."
	var layout := _layout(input)
	if not layout.error.is_empty():
		return layout.error
	if layout.moov_offset + layout.moov.size() != input.get_length() or layout.moov_offset < layout.media[0].offset:
		return "Expected a trailing moov after mdat; fast-start inputs are unsupported."
	var prepared := prepare(layout.moov, layout.media, width, height)
	if not prepared.error.is_empty():
		return prepared.error
	if cancelled.is_valid() and cancelled.call():
		return "Cancelled. Intermediate files have been retained."
	var output := FileAccess.open(destination, FileAccess.WRITE)
	if output == null:
		return "Cannot create spherical MP4."
	input.seek(0)
	var error := _copy(input, output, layout.media[0].offset, cancelled)
	if error.is_empty():
		output.store_buffer(prepared.moov)
		error = _copy(input, output, layout.moov_offset, cancelled)
	output.flush()
	if error.is_empty() and output.get_error() != OK:
		error = "Could not finish spherical MP4."
	output.close()
	return error
