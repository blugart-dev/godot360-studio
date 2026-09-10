"""Serve LUMEN on loopback with an explicit four-file allowlist and video seeking."""
import argparse
from functools import partial
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]


class Player(BaseHTTPRequestHandler):
    def __init__(self, *args, directory, **kwargs):
        self.files = {'/': (ROOT / 'tools/lumen_player.html', 'text/html; charset=utf-8'),
                      '/lumen-browser.mp4': (directory / 'lumen-browser.mp4', 'video/mp4'),
                      '/lumen-tour.mp4': (directory / 'lumen-tour.mp4', 'video/mp4'),
                      '/video-360.mp4': (directory / 'film/video-360.mp4', 'video/mp4')}
        super().__init__(*args, **kwargs)

    def do_GET(self):
        self.send_file(True)

    def do_HEAD(self):
        self.send_file(False)

    def send_file(self, body):
        entry = self.files.get(urlsplit(self.path).path)
        if not entry or not entry[0].is_file():
            self.send_error(404)
            return
        path, kind = entry
        size = path.stat().st_size
        start, end = 0, size - 1
        header = self.headers.get('Range')
        if header:
            try:
                assert header.startswith('bytes=') and ',' not in header
                left, right = header[6:].split('-', 1)
                if left:
                    start = int(left)
                    end = min(int(right), size - 1) if right else size - 1
                else:
                    assert int(right) > 0
                    start = max(0, size - int(right))
                assert 0 <= start <= end < size
            except (ValueError, AssertionError):
                self.send_response(416)
                self.send_header('Content-Range', f'bytes */{size}')
                self.send_header('Content-Length', '0')
                self.end_headers()
                return
        self.send_response(206 if header else 200)
        self.send_header('Content-Type', kind)
        self.send_header('Content-Length', str(end - start + 1))
        self.send_header('Accept-Ranges', 'bytes')
        self.send_header('Cache-Control', 'no-cache')
        if header:
            self.send_header('Content-Range', f'bytes {start}-{end}/{size}')
        self.end_headers()
        if body:
            try:
                with path.open('rb') as source:
                    source.seek(start)
                    remaining = end - start + 1
                    while remaining:
                        chunk = source.read(min(1024 * 1024, remaining))
                        if not chunk:
                            break
                        self.wfile.write(chunk)
                        remaining -= len(chunk)
            except (ConnectionAbortedError, ConnectionResetError, BrokenPipeError):
                pass


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, default=ROOT / 'renders/lumen-4k-final')
    parser.add_argument('--port', type=int, default=8361)
    args = parser.parse_args()
    directory = args.directory.resolve()
    assert (directory / 'lumen-browser.mp4').is_file(), 'Build the browser copy first; see docs/lumen.md'
    server = ThreadingHTTPServer(('127.0.0.1', args.port), partial(Player, directory=directory))
    print(f'LUMEN: http://127.0.0.1:{args.port}', flush=True)
    server.serve_forever()
