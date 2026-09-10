"""Build a flat tour, browser sphere and stills from a verified LUMEN delivery."""
import argparse
import hashlib
import json
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def build(args):
    folder = args.render.resolve()
    master = folder / 'film/video-360.mp4'
    report = json.loads((folder / 'film/report.json').read_text())
    assert report['ok'] and all(report['checks'].values())

    def run(arguments):
        subprocess.run([str(args.ffmpeg), '-hide_banner', '-loglevel', 'error', '-y', *map(str, arguments)], check=True)

    run(['-i', master, '-vf', 'scale=2048:1024', '-c:v', 'libx264', '-crf', 20, '-preset', 'fast',
         '-c:a', 'copy', '-movflags', '+faststart', folder / 'lumen-browser.mp4'])
    views = [(0, 6, 0, 10), (6, 12, 70, 25), (12, 18, 175, 45), (18, 24, 0, 10)]
    filters = []
    for i, (start, end, yaw, pitch) in enumerate(views):
        filters.append(f'[0:v]trim=start={start}:end={end},setpts=PTS-STARTPTS,v360=equirect:flat:yaw={yaw}:pitch={pitch}:h_fov=100:v_fov=67.7:w=1920:h=1080[v{i}]')
    filters.append(''.join(f'[v{i}]' for i in range(4)) + 'concat=n=4:v=1:a=0[tour]')
    run(['-i', master, '-filter_complex', ';'.join(filters), '-map', '[tour]', '-map', '0:a:0',
         '-c:v', 'libx264', '-crf', 19, '-preset', 'fast', '-c:a', 'copy', '-movflags', '+faststart', folder / 'lumen-tour.mp4'])
    for name, timestamp, yaw, pitch in [('lumen', 10, 0, 10), ('lumen-orbits', 14, 100, 40), ('lumen-rear', 16, 180, 25)]:
        run(['-ss', timestamp, '-i', master, '-vf', f'v360=equirect:flat:yaw={yaw}:pitch={pitch}:h_fov=100:v_fov=67.7:w=1600:h=900',
             '-frames:v', 1, '-update', 1, '-q:v', 2, folder / (name + '.jpg')])
    run(['-ss', 10, '-i', master, '-vf', 'scale=1600:800', '-frames:v', 1, '-update', 1, '-q:v', 2, folder / 'lumen-panorama.jpg'])
    media = ROOT / 'docs/media'
    names = ['lumen-tour.mp4', 'lumen.jpg', 'lumen-orbits.jpg', 'lumen-rear.jpg', 'lumen-panorama.jpg']
    for name in names:
        shutil.copy2(folder / name, media / name)
    evidence = {'source': master.relative_to(ROOT).as_posix(), 'source_sha256': hashlib.sha256(master.read_bytes()).hexdigest(),
                'tour_views': views, 'files': {name: {'bytes': (media / name).stat().st_size,
                 'sha256': hashlib.sha256((media / name).read_bytes()).hexdigest()} for name in names}}
    (folder / 'media-provenance.json').write_text(json.dumps(evidence, indent=2) + '\n')
    print(json.dumps(evidence, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', type=Path, default=ROOT / 'renders/lumen-4k-final')
    parser.add_argument('--ffmpeg', type=Path, required=True)
    build(parser.parse_args())
