"""Render AFTERGLOW in an isolated project through the Godot360 delivery pipeline.

The portable editor recipe is export_profiles/afterglow-4k.tres. This helper uses
fresh output, preserves the working project's settings and records actual cost.
"""
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import time
from pathlib import Path

from render_threshold import folder_size, read_json

ROOT = Path(__file__).resolve().parents[1]


def render(args):
    output = args.output.resolve()
    assert 0 < args.seconds <= 60 and 0 <= args.offset and args.offset + args.seconds <= 60 and args.face_size >= 128
    output.mkdir(parents=True, exist_ok=False)
    project = output / 'project'
    files = ['scripts/films/afterglow.gd', 'scripts/films/threshold_geometry.gd',
             'scenes/films/Afterglow.tscn', 'assets/films/afterglow/sky.gdshader',
             'assets/films/afterglow/facets.gdshader', 'assets/films/afterglow/tiles.gdshader',
             'assets/films/afterglow/beam.gdshader', 'assets/films/afterglow/dust.gdshader',
             'assets/films/afterglow/ribbon.gdshader',
             'assets/audio/afterglow-score.cues.json', 'tests/afterglow_checks.gd', 'tests/afterglow_storyboard.gd',
             'tests/afterglow_clearance.gd',
             'assets/audio/afterglow-score.wav']
    protected = ['project.godot', '.godot360/settings.cfg', 'scenes/Main.tscn',
                 'scenes/films/Threshold.tscn', 'export_profiles/threshold-8k.tres', 'scenes/films/Lumen.tscn', 'scripts/films/lumen.gd']

    def hashes(paths):
        return {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in paths if (ROOT / name).is_file()}

    before = hashes(protected)
    for name in files:
        (project / name).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, project / name)
    shutil.copytree(ROOT / 'addons/godot360', project / 'addons/godot360')
    (project / 'project.godot').write_text('''config_version=5
[application]
config/name="AFTERGLOW / Godot360"
run/main_scene="res://scenes/films/Afterglow.tscn"
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
[rendering]
renderer/rendering_method="forward_plus"
anti_aliasing/quality/msaa_3d=2
''')
    env = os.environ.copy()
    for key in (['APPDATA', 'LOCALAPPDATA'] if os.name == 'nt' else ['XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME']):
        path = output / 'profile' / key
        path.mkdir(parents=True)
        env[key] = str(path)
    with (output / 'import.log').open('w') as log:
        result = subprocess.run([str(args.godot), '--headless', '--path', str(project), '--editor', '--import', '--quit'], env=env, stdout=log, stderr=log, timeout=120)
    assert result.returncode == 0 and 'SCRIPT ERROR' not in (output / 'import.log').read_text(errors='replace'), (output / 'import.log').read_text(errors='replace')
    if args.prepare_only:
        print(json.dumps({'project': str(project), 'prepared': True}))
        return
    destination = output / 'film'
    job = {'scene_path': 'res://scenes/films/Afterglow.tscn', 'camera_path': 'Camera3D',
           'width': args.width, 'height': args.width // 2, 'face_size': args.face_size,
           'fps': 30, 'frames': round(args.seconds * 30), 'warmup_frames': 2,
           'capture_border_percent': 12.5, 'frame_writer': 'fast_png', 'crf': 17,
           'rendering_method': 'forward_plus', 'rendering_driver': args.driver,
           'random_seed': 116360, 'afterglow_offset': args.offset, 'soundtrack_trim_seconds': args.offset, 'audio_mode': 'soundtrack',
           'soundtrack_path': 'res://assets/audio/afterglow-score.wav',
           'ffmpeg': str(args.ffmpeg.resolve()), 'ffprobe': str(args.ffprobe.resolve()),
           'output_dir': str(destination)}
    request = output / 'job.json'
    request.write_text(json.dumps(job, indent=2))
    observations = []
    started = time.monotonic()
    with (output / 'pipeline.log').open('w') as log:
        process = subprocess.Popen([str(args.godot), '--headless', '--path', str(project), '--script', 'res://addons/godot360/pipeline.gd', '--', '--job=' + str(request)], env=env, stdout=log, stderr=log)
        try:
            last = -10
            while process.poll() is None:
                elapsed = time.monotonic() - started
                if elapsed - last >= 10:
                    state = read_json(destination / 'status.json')
                    progress = read_json(destination / 'render-progress.json')
                    retained = folder_size(destination) if destination.exists() else 0
                    row = {'seconds': round(elapsed, 2), 'stage': state.get('stage'), 'frame': progress.get('frame'), 'retained_gib': round(retained / 2**30, 3)}
                    observations.append(row)
                    print(json.dumps(row), flush=True)
                    assert retained < args.max_storage_gib * 2**30, 'Storage budget exceeded'
                    assert shutil.disk_usage(output).free > 12 * 2**30, 'Free-space floor reached'
                    last = elapsed
                assert elapsed < args.timeout, 'Render timeout exceeded'
                time.sleep(.2)
            assert process.returncode == 0, (output / 'pipeline.log').read_text(errors='replace')
        finally:
            if process.poll() is None:
                (destination / 'cancel.request').write_text('AFTERGLOW monitor stopped the render')
                try:
                    process.wait(timeout=20)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
    report = read_json(destination / 'report.json')
    capture = read_json(destination / 'capture-result.json')
    assert report.get('ok') and all(report['checks'].values()), report
    assert capture.get('ok') and capture['rendered'] == job['frames'] + 2, capture
    assert len(list((destination / 'frames').glob('*.png'))) == job['frames'] + 2
    assert report['capture_settings']['renderer'] == 'forward_plus'
    assert before == hashes(protected), 'Protected source/settings changed'
    for name in ['capture.log', 'capture-stderr.log']:
        path = destination / name
        if path.is_file():
            assert 'SCRIPT ERROR' not in path.read_text(errors='replace'), str(path)
    result = {'ok': True, 'wall_seconds': round(time.monotonic() - started, 2),
              'retained_bytes': folder_size(destination), 'protected_files_unchanged': True,
              'protected_hashes': before, 'source_hashes': hashes(files),
              'capture_settings': report['capture_settings'], 'checks': report['checks'],
              'observations': observations, 'pipeline_timings': report.get('pipeline_timings')}
    (output / 'render-review.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'ok': True, 'wall_seconds': result['wall_seconds'], 'retained_gib': round(result['retained_bytes'] / 2**30, 3)}), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ['godot', 'ffmpeg', 'ffprobe', 'output']:
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--width', type=int, choices=[2048, 4096, 7680], default=4096)
    parser.add_argument('--face-size', type=int, default=1536)
    parser.add_argument('--seconds', type=float, default=60)
    parser.add_argument('--offset', type=float, default=0)
    parser.add_argument('--prepare-only', action='store_true')
    parser.add_argument('--driver', default='vulkan', choices=['vulkan', 'd3d12', 'metal'])
    parser.add_argument('--max-storage-gib', type=float, default=48)
    parser.add_argument('--timeout', type=float, default=3600)
    render(parser.parse_args())
