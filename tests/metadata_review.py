"""Independently check MP4 relocation, V2 recognition and exact media preservation.

python tests/metadata_review.py SOURCE_ENCODED_MP4 SPHERICAL_MP4 --ffmpeg PATH --ffprobe PATH
Uses only Python's standard library and FFmpeg. No scene capture or source writes.
"""
import argparse
import hashlib
import json
import struct
import subprocess
from pathlib import Path

SPHERICAL_UUID = bytes.fromhex("ffcc8263f8554a938814587a02521fdd")


def u32(data, offset=0):
    return struct.unpack_from(">I", data, offset)[0]


def boxes(data, start=8):
    result = []
    while start < len(data):
        assert start + 8 <= len(data), "Truncated nested box"
        size, kind = struct.unpack_from(">I4s", data, start)
        assert size >= 8 and start + size <= len(data), "Invalid nested size"
        result.append((kind, start, size))
        start += size
    return result


def child(data, name):
    matches = [data[offset:offset + size] for kind, offset, size in boxes(data) if kind == name]
    assert len(matches) == 1, ("Expected one box", name)
    return matches[0]


def layout(path):
    result = []
    with path.open("rb") as file:
        length = path.stat().st_size
        while file.tell() < length:
            offset = file.tell()
            size, kind = struct.unpack(">I4s", file.read(8))
            header = 8
            if size == 1:
                size = struct.unpack(">Q", file.read(8))[0]
                header = 16
            assert header <= size <= length - offset
            result.append({"kind": kind.decode("ascii"), "offset": offset, "size": size, "header": header})
            file.seek(offset + size)
    return result


def hash_region(path, start=0, size=None):
    size = path.stat().st_size - start if size is None else size
    digest = hashlib.sha256()
    with path.open("rb") as file:
        file.seek(start)
        while size:
            block = file.read(min(size, 1024 * 1024))
            assert block, "Truncated media"
            digest.update(block)
            size -= len(block)
    return digest.hexdigest()


def movie(path, top):
    matches = [box for box in top if box["kind"] == "moov"]
    assert len(matches) == 1
    box = matches[0]
    assert box["size"] <= 64 * 1024 * 1024
    with path.open("rb") as file:
        file.seek(box["offset"])
        return file.read(box["size"]), box["offset"]


def tracks(moov):
    result = []
    for kind, offset, size in boxes(moov):
        if kind != b"trak":
            continue
        track = moov[offset:offset + size]
        mdia = child(track, b"mdia")
        handler = child(mdia, b"hdlr")[16:20]
        stbl = child(child(mdia, b"minf"), b"stbl")
        tables = [(kind, stbl[start:start + length]) for kind, start, length in boxes(stbl) if kind in (b"stco", b"co64")]
        assert len(tables) == 1
        table_kind, table = tables[0]
        count = u32(table, 12)
        stride = 4 if table_kind == b"stco" else 8
        assert len(table) == 16 + count * stride
        offsets = [struct.unpack_from(">I" if stride == 4 else ">Q", table, 16 + i * stride)[0] for i in range(count)]
        stsd = child(stbl, b"stsd")
        assert u32(stsd, 12) == 1
        result.append({"handler": handler, "offsets": offsets, "entry": stsd[16:], "track": track})
    return result


def projection(track):
    entry = track["entry"]
    assert entry[4:8] == b"avc1"
    entries = boxes(entry, 86)
    names = [kind for kind, _, _ in entries]
    assert names.count(b"st3d") == names.count(b"sv3d") == 1
    assert names.index(b"avcC") < names.index(b"st3d") < names.index(b"sv3d")
    for optional in (b"pasp", b"clap"):
        if optional in names:
            assert names.index(b"sv3d") < names.index(optional)
    children = {kind: entry[offset:offset + size] for kind, offset, size in entries}
    assert children[b"st3d"][8:] == bytes(5), "Expected version zero mono layout"
    sv3d = children[b"sv3d"]
    svhd = child(sv3d, b"svhd")
    assert svhd[8:12] == bytes(4) and svhd[-1] == 0
    metadata_source = svhd[12:-1].decode("utf-8")
    proj = child(sv3d, b"proj")
    assert child(proj, b"prhd")[8:] == bytes(16), "Unexpected pose"
    assert child(proj, b"equi")[8:] == bytes(20), "Unexpected projection bounds"
    uuid = [track["track"][offset:offset + size] for kind, offset, size in boxes(track["track"]) if kind == b"uuid"]
    assert len(uuid) == 1 and uuid[0][8:24] == SPHERICAL_UUID
    assert b"<GSpherical:StereoMode>mono</GSpherical:StereoMode>" in uuid[0]
    return metadata_source


def run(arguments):
    completed = subprocess.run([str(arg) for arg in arguments], capture_output=True, check=True, timeout=300)
    return completed.stdout.decode("utf-8")


def probe(path, executable):
    return json.loads(run([executable, "-v", "error", "-count_frames", "-show_streams", "-of", "json", path]))


def packet_hashes(path, executable):
    data = json.loads(run([executable, "-v", "error", "-show_packets", "-show_data_hash", "sha256", "-show_entries",
                          "packet=stream_index,pts,dts,duration,size,data_hash", "-of", "json", path]))
    return data["packets"]


def decoded_hashes(path, executable):
    return run([executable, "-v", "error", "-i", path, "-map", "0:v:0", "-map", "0:a:0?",
                "-c:v", "rawvideo", "-threads:v", "2", "-c:a", "pcm_s16le", "-f", "streamhash", "-hash", "sha256", "-"]).strip()


def v2_only(path, destination, moov, moov_offset):
    # Replace the V1 UUID's type with free at its exact location. Box lengths and
    # all sample offsets remain unchanged, so FFprobe can only use V2 metadata.
    changes = []
    for kind, offset, size in boxes(moov):
        if kind == b"trak":
            track = moov[offset:offset + size]
            for leaf_kind, leaf_offset, leaf_size in boxes(track):
                if leaf_kind == b"uuid" and track[leaf_offset + 8:leaf_offset + 24] == SPHERICAL_UUID:
                    changes.append(moov_offset + offset + leaf_offset + 4)
    assert len(changes) == 1
    with path.open("rb") as source, destination.open("xb") as output:
        while block := source.read(1024 * 1024):
            output.write(block)
        output.seek(changes[0])
        output.write(b"free")


def review(args):
    source, final = args.source.resolve(), args.final.resolve()
    assert source != final
    before = hash_region(source)
    old_top, new_top = layout(source), layout(final)
    old_moov, old_offset = movie(source, old_top)
    new_moov, new_offset = movie(final, new_top)
    old_media = [box for box in old_top if box["kind"] == "mdat"]
    new_media = [box for box in new_top if box["kind"] == "mdat"]
    assert old_offset > old_media[-1]["offset"]
    assert new_offset < new_media[0]["offset"]
    old_other = [box for box in old_top if box["kind"] != "moov"]
    new_other = [box for box in new_top if box["kind"] != "moov"]
    assert len(old_other) == len(new_other)
    for old, new in zip(old_other, new_other):
        assert (old["kind"], old["size"]) == (new["kind"], new["size"])
        assert hash_region(source, old["offset"], old["size"]) == hash_region(final, new["offset"], new["size"])
    old_tracks, new_tracks = tracks(old_moov), tracks(new_moov)
    assert len(old_tracks) == len(new_tracks)
    checked_chunks = 0
    for old, new in zip(old_tracks, new_tracks):
        assert old["handler"] == new["handler"]
        assert new["offsets"] == [offset + len(new_moov) for offset in old["offsets"]]
        assert all(any(box["offset"] + box["header"] <= offset < box["offset"] + box["size"] for box in new_media) for offset in new["offsets"])
        checked_chunks += len(new["offsets"])
    videos = [track for track in new_tracks if track["handler"] == b"vide"]
    assert len(videos) == 1
    software = projection(videos[0])
    old_probe, new_probe = probe(source, args.ffprobe), probe(final, args.ffprobe)
    video = next(stream for stream in new_probe["streams"] if stream["codec_type"] == "video")
    assert any(side.get("projection") == "equirectangular" for side in video.get("side_data_list", []))
    for old, new in zip(old_probe["streams"], new_probe["streams"]):
        for key in ("codec_name", "nb_read_frames", "r_frame_rate", "duration", "time_base", "start_time", "width", "height", "sample_rate", "channels"):
            assert old.get(key) == new.get(key), ("Changed stream field", key)
    packets = packet_hashes(source, args.ffprobe)
    assert packets == packet_hashes(final, args.ffprobe), "Packet payload or timestamps changed"
    print(f"Structure, {checked_chunks} offsets and {len(packets)} packet hashes match.", flush=True)
    decoded = decoded_hashes(source, args.ffmpeg)
    assert decoded == decoded_hashes(final, args.ffmpeg), "Decoded video/audio changed"
    isolated = final.with_name(final.stem + "-v2-only.mp4")
    v2_only(final, isolated, new_moov, new_offset)
    isolated_probe = probe(isolated, args.ffprobe)
    isolated_video = next(stream for stream in isolated_probe["streams"] if stream["codec_type"] == "video")
    assert any(side.get("projection") == "equirectangular" for side in isolated_video.get("side_data_list", [])), "V2 alone was not recognized"
    assert decoded == decoded_hashes(isolated, args.ffmpeg), "V2-only decode changed"
    assert hash_region(source) == before, "Source file changed"
    report = {"ok": True, "source": str(source), "final": str(final), "metadata_source": software,
              "source_sha256": before, "final_sha256": hash_region(final), "fast_start": True,
              "all_non_moov_bytes_preserved": True, "chunk_offsets_checked": checked_chunks,
              "packet_hashes_and_timestamps_checked": len(packets), "decoded_stream_hashes": decoded,
              "decoded_frames": int(video["nb_read_frames"]), "v2_only_recognized": True,
              "v2_only_decode_identical": True, "v2_only_file": str(isolated)}
    output = args.report or final.with_name("metadata-review.json")
    with output.open("x", encoding="utf-8") as file:
        json.dump(report, file, indent=2)
    print(json.dumps(report, indent=2), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("final", type=Path)
    parser.add_argument("--ffmpeg", required=True, type=Path)
    parser.add_argument("--ffprobe", required=True, type=Path)
    parser.add_argument("--report", type=Path)
    review(parser.parse_args())
