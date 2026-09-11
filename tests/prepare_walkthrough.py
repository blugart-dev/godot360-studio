"""Prepare a fresh addon-only editor walkthrough; never marks UI steps as passed.

The authored scene has no addon dependency or capture hook. Use the quick start
in the real editor after preparation. All profile/settings/output stay isolated.
"""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import struct
import subprocess
import wave
from zipfile import ZipFile


def prepare(args):
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    project = output / "project"
    project.mkdir()
    # Install only the documented addon folder from an exact candidate.
    with ZipFile(args.package) as archive:
        manifest = json.loads(archive.read("manifest.json"))
        for name, record in manifest["files"].items():
            if not name.startswith("addons/godot360/"):
                continue
            target = (project / name).resolve()
            assert target.is_relative_to(project)
            data = archive.read(name)
            assert hashlib.sha256(data).hexdigest() == record["sha256"]
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
    (project / "project.godot").write_text('''config_version=5
[application]
config/name="Godot360 clean walkthrough"
run/main_scene="res://room.tscn"
[rendering]
renderer/rendering_method="forward_plus"
rendering_device/driver.windows="vulkan"
''', encoding="utf-8")
    # Ordinary imported stereo WAV: left 440 Hz / right 660 Hz, once per second.
    rate = 48000
    samples = bytearray()
    for i in range(rate * 12):
        phase = i / rate % 1
        envelope = math.sin(math.pi * (phase - .25) / .25) ** 2 if .25 <= phase < .5 else 0
        samples.extend(struct.pack("<hh", *(round(6000 * envelope * math.sin(math.tau * f * i / rate))
                                           for f in [440, 660])))
    with wave.open(str(project / "cues.wav"), "wb") as sound:
        sound.setparams((2, 2, rate, 0, "NONE", "not compressed"))
        sound.writeframes(samples)
    scene = '''[gd_scene load_steps=8 format=3]
[ext_resource type="AudioStream" path="res://cues.wav" id="1"]
[sub_resource type="Environment" id="Environment"]
background_mode = 1
background_color = Color(0.025, 0.04, 0.065, 1)
ambient_light_source = 3
ambient_light_color = Color(1, 1, 1, 1)
ambient_light_energy = 0.7
[sub_resource type="StandardMaterial3D" id="Material"]
albedo_color = Color(1, 0.35, 0.08, 1)
metallic = 0.15
roughness = 0.3
[sub_resource type="SphereMesh" id="Sphere"]
material = SubResource("Material")
radius = 0.55
height = 1.1
[sub_resource type="Animation" id="Move"]
resource_name = "move"
length = 8.0
loop_mode = 1
tracks/0/type = "value"
tracks/0/path = NodePath("Sphere:position")
tracks/0/interp = 1
tracks/0/enabled = true
tracks/0/keys = {
"times": PackedFloat32Array(0, 2, 4, 6, 8),
"transitions": PackedFloat32Array(1, 1, 1, 1, 1),
"update": 0,
"values": [Vector3(-2, -0.5, -4), Vector3(2, -0.5, -4), Vector3(2, 0.5, -4), Vector3(-2, 0.5, -4), Vector3(-2, -0.5, -4)]
}
[sub_resource type="AnimationLibrary" id="Library"]
_data = {"move": SubResource("Move")}
[sub_resource type="PlaneMesh" id="Floor"]
size = Vector2(18, 18)
[node name="Room" type="Node3D"]
[node name="Camera3D" type="Camera3D" parent="."]
current = true
[node name="Environment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment")
[node name="Key" type="DirectionalLight3D" parent="."]
rotation_degrees = Vector3(-50, -30, 0)
[node name="Floor" type="MeshInstance3D" parent="."]
position = Vector3(0, -2, 0)
mesh = SubResource("Floor")
[node name="Sphere" type="MeshInstance3D" parent="."]
position = Vector3(-2, -0.5, -4)
mesh = SubResource("Sphere")
[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
libraries = {&"": SubResource("Library")}
autoplay = "move"
[node name="Audio" type="AudioStreamPlayer" parent="."]
stream = ExtResource("1")
autoplay = true
'''
    for name, position, rotation in [
        ("FRONT -Z", (0, 1.1, -5), (0, 0, 0)),
        ("RIGHT +X", (5, 1.1, 0), (0, -90, 0)),
        ("BACK +Z", (0, 1.1, 5), (0, 180, 0)),
        ("LEFT -X", (-5, 1.1, 0), (0, 90, 0)),
        ("UP +Y", (0, 5, 0), (90, 0, 0)),
        ("DOWN -Y", (0, -1.95, 0), (-90, 0, 0)),
    ]:
        scene += f'''[node name="{name.split()[0]}" type="Label3D" parent="."]
position = Vector3{position}
rotation_degrees = Vector3{rotation}
text = "{name}"
font_size = 80
pixel_size = 0.006
outline_size = 12
'''
    (project / "room.tscn").write_text(scene, encoding="utf-8")
    env = os.environ.copy()
    for name in ["APPDATA", "LOCALAPPDATA"] if os.name == "nt" else ["XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME"]:
        folder = output / "profile" / name
        folder.mkdir(parents=True)
        env[name] = str(folder)
    record = {"package_sha256": hashlib.sha256(args.package.read_bytes()).hexdigest(),
              "project": str(project), "plugin_initially_disabled": True,
              "scene_has_capture_hooks": False, "ui_acceptance": "pending"}
    if args.godot:
        with (output / "editor.log").open("wb") as log:
            child = subprocess.Popen([str(args.godot.resolve()), "--editor", "--path", str(project), "res://room.tscn"],
                                     env=env, stdout=log, stderr=log,
                                     creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        record["editor_pid"] = child.pid
    (output / "prepared.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(record, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--godot", type=Path, help="Open the native editor with an isolated profile")
    prepare(parser.parse_args())
