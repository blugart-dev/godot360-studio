"""Serve only Threshold's playback files on localhost, with video range support."""
import argparse
from functools import partial
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

FILES = {"/": ("index.html", "text/html; charset=utf-8"), "/index.html": ("index.html", "text/html; charset=utf-8"),
         "/threshold-browser.mp4": ("threshold-browser.mp4", "video/mp4"),
         "/threshold-preview.mp4": ("threshold-preview.mp4", "video/mp4"),
         "/video-360.mp4": ("video-360.mp4", "video/mp4")}


class Player(BaseHTTPRequestHandler):
    def __init__(self, *args, directory, **kwargs):
        self.directory = directory
        super().__init__(*args, **kwargs)

    def do_HEAD(self):
        self.send_file(False)

    def do_GET(self):
        self.send_file(True)

    def send_file(self, body):
        entry = FILES.get(urlsplit(self.path).path)
        if not entry or not (self.directory / entry[0]).is_file():
            self.send_error(404)
            return
        path = self.directory / entry[0]
        size = path.stat().st_size
        start, end = 0, size - 1
        header = self.headers.get("Range")
        if header:
            try:
                assert header.startswith("bytes=") and "," not in header
                left, right = header[6:].split("-", 1)
                if left:
                    start = int(left)
                    end = min(int(right), size - 1) if right else size - 1
                else:
                    start = max(0, size - int(right))
                assert 0 <= start <= end < size
            except (ValueError, AssertionError):
                self.send_error(416)
                return
        self.send_response(206 if header else 200)
        self.send_header("Content-Type", entry[1])
        self.send_header("Content-Length", str(end - start + 1))
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Cache-Control", "no-cache")
        if header:
            self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
        self.end_headers()
        if body:
            try:
                with path.open("rb") as source:
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


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=Path(__file__).resolve().parents[1] / "renders/threshold-8k")
    parser.add_argument("--port", type=int, default=8360)
    args = parser.parse_args()
    folder = args.directory.resolve()
    assert (folder / "index.html").is_file(), "Create the playback files first"
    server = ThreadingHTTPServer(("127.0.0.1", args.port), partial(Player, directory=folder))
    print(f"Threshold player: http://127.0.0.1:{args.port} (Ctrl+C to stop)", flush=True)
    server.serve_forever()
