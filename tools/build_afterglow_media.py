"""Create AFTERGLOW's local player copies and inspect the delivered picture/audio."""
import argparse
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tests'))
from audio_review import compare, decode


def build(args):
    folder = args.render.resolve()
    master = folder / 'film/video-360.mp4'
    original = folder / 'film/encoded.mp4'
    report = json.loads((folder / 'film/report.json').read_text())
    assert report['ok'] and all(report['checks'].values())
    assert report['audio']['soundtrack_source']['sha256'] == hashlib.sha256((ROOT / 'assets/audio/afterglow-score.wav').read_bytes()).hexdigest()

    def run(arguments):
        subprocess.run([str(args.ffmpeg), '-nostdin', '-hide_banner', '-loglevel', 'error', '-y',
                        *map(str, arguments)], check=True, timeout=900)

    # Use the untagged source: a perspective view must not inherit spherical metadata.
    filters = ('[0:v]split=3[p][f][q];[p]scale=3072:1536[pano];'
               '[f]v360=equirect:flat:yaw=0:pitch=14:h_fov=106:v_fov=70:w=1600:h=900[flat];'
               '[q]scale=160:80:flags=area,format=rgb24[qa]')
    print('Building 3K spherical player copy, 900p flat film, and frame audit', flush=True)
    run(['-i', original, '-filter_complex_threads', 4, '-filter_complex', filters,
         '-map', '[pano]', '-map', '0:a:0', '-c:v', 'libx264', '-threads', 4,
         '-crf', 19, '-preset', 'fast', '-pix_fmt', 'yuv420p', '-c:a', 'copy',
         '-map_metadata', -1, '-movflags', '+faststart', folder / 'afterglow-browser.mp4',
         '-map', '[flat]', '-map', '0:a:0', '-c:v', 'libx264', '-threads', 4,
         '-crf', 19, '-preset', 'fast', '-pix_fmt', 'yuv420p', '-c:a', 'copy',
         '-map_metadata', -1, '-movflags', '+faststart', folder / 'afterglow-tour.mp4',
         '-map', '[qa]', '-c:v', 'rawvideo', '-threads', 1, '-f', 'rawvideo', folder / 'audit.rgb'])
    assert (folder / 'audit.rgb').stat().st_size == 1800 * 160 * 80 * 3
    frames = np.memmap(folder / 'audit.rgb', mode='r', dtype=np.uint8, shape=(1800, 80, 160, 3))
    means = frames.mean(axis=(1, 2, 3))
    blank = np.flatnonzero(means < 2).tolist()
    frozen = [i for i in range(1, 1800) if np.array_equal(frames[i], frames[i - 1])]
    assert not blank, ('Unexpected black frame', blank)
    assert not frozen, ('Repeated decoded frame', frozen)
    sheet = Image.new('RGB', (1200, 6 * 122), '#100919')
    draw = ImageDraw.Draw(sheet)
    for index, second in enumerate(range(0, 60, 2)):
        x, y = (index % 5) * 240, (index // 5) * 122
        sheet.paste(Image.fromarray(frames[second * 30]).resize((232, 100)), (x, y + 20))
        draw.text((x + 5, y + 3), f'{second:02}s', fill='#e9bf7e')
    sheet.save(folder / 'film-contact-sheet.jpg', quality=92)
    audio = compare(decode(master, args.ffmpeg), decode(ROOT / 'assets/audio/afterglow-score.wav', args.ffmpeg))
    print(f"Audio correspondence passed: {audio['snr_db']:.2f} dB SNR, max lag {max(map(abs, audio['cue_lags_samples']))} samples", flush=True)
    views = [('afterglow', 49, 0, 14), ('afterglow-suspended', 43, -30, -3),
             ('afterglow-rear', 51, 165, 17), ('afterglow-crown', 36, 5, 38)]
    for name, timestamp, yaw, pitch in views:
        run(['-ss', timestamp, '-i', original, '-vf', f'v360=equirect:flat:yaw={yaw}:pitch={pitch}:h_fov=106:v_fov=70:w=1600:h=900',
             '-frames:v', 1, '-update', 1, '-q:v', 2, folder / (name + '.jpg')])
    run(['-ss', 49, '-i', original, '-vf', 'scale=1600:800', '-frames:v', 1, '-update', 1, '-q:v', 2, folder / 'afterglow-panorama.jpg'])
    media = ROOT / 'docs/media'
    names = ['afterglow-tour.mp4', 'afterglow.jpg', 'afterglow-suspended.jpg',
             'afterglow-rear.jpg', 'afterglow-crown.jpg', 'afterglow-panorama.jpg']
    for name in names:
        shutil.copy2(folder / name, media / name)
    # Keep the complete 900p local tour; ship a smaller 720p documentation copy.
    run(['-i', folder / 'afterglow-tour.mp4', '-vf', 'scale=1280:720',
         '-c:v', 'libx264', '-crf', 24, '-preset', 'slow', '-threads', 4,
         '-pix_fmt', 'yuv420p', '-c:a', 'copy', '-map_metadata', -1,
         '-movflags', '+faststart', media / 'afterglow-tour.mp4'])
    assert (media / 'afterglow-tour.mp4').stat().st_size <= 25 * 1024 * 1024, 'Documentation video exceeds the source budget'
    run(['-i', media / 'afterglow-tour.mp4', '-f', 'null', '-'])
    evidence = {'ok': True, 'decoded_frames': 1800, 'seconds': 60,
                'unexpected_blank_frames': blank, 'duplicate_frames': frozen, 'audio': audio,
                'source': master.relative_to(ROOT).as_posix(),
                'source_sha256': hashlib.sha256(master.read_bytes()).hexdigest(),
                'stills': views, 'flat_view': {'yaw': 0, 'pitch': 14, 'width': 1600, 'height': 900},
                'documentation_video': {'width': 1280, 'height': 720, 'crf': 24,
                                        'preset': 'slow', 'audio': 'copied without re-encoding'},
                'files': {name: {'bytes': (media / name).stat().st_size,
                                'sha256': hashlib.sha256((media / name).read_bytes()).hexdigest()} for name in names}}
    (folder / 'media-review.json').write_text(json.dumps(evidence, indent=2) + '\n')
    (media / 'afterglow-provenance.json').write_text(json.dumps(evidence, indent=2) + '\n')
    print(json.dumps({'ok': True, 'decoded_frames': 1800, 'blank_frames': 0, 'frozen_frames': 0,
                      'source_sha256': evidence['source_sha256']}, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', type=Path, default=ROOT / 'renders/afterglow-clearance-4k')
    parser.add_argument('--ffmpeg', type=Path, required=True)
    build(parser.parse_args())
