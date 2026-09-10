"""Check every tracked or non-ignored source file before sharing this repository.

Python 3.10+ and Git only; no engine, network access or third-party packages.
Use --output .godot360/publication-review/inventory.json to retain the file audit.
This checks repository hygiene, not renderer correctness or legal clearance.
"""
import argparse
import ast
from collections import Counter
import hashlib
import json
from pathlib import Path
import posixpath
import re
import subprocess
import sys
from urllib.parse import unquote, urlsplit
import wave
import xml.etree.ElementTree as ET


TEXT_SUFFIXES = {'.gd', '.gdshader', '.tscn', '.tres', '.godot', '.cfg', '.uid',
                 '.import', '.py', '.md', '.txt', '.json', '.yml', '.yaml', '.svg', '.html'}
BINARY_SUFFIXES = {'.png', '.jpg', '.jpeg', '.gif', '.mp4', '.wav', '.glb'}
LOCAL_PARTS = {'.git', '.godot', '.godot360', '.umbral360', '.agents', '.codex',
               '__pycache__', 'renders', 'dist', '.venv', 'venv'}
PRIVATE_PATH = re.compile(r'(?:[A-Za-z]:[/\\]Users[/\\]|/Users/|/home/)[A-Za-z0-9_. -]+[/\\]', re.I)
SECRET = re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|'
                    r'\bgh[pousr]_[A-Za-z0-9]{30,}\b|\bgithub_pat_[A-Za-z0-9_]{40,}\b|'
                    r'\bAKIA[A-Z0-9]{16}\b')
LINK = re.compile(r'\]\(<?([^\s)>]+)>?(?:\s+"[^"]*")?\)')
REFERENCE_LINK = re.compile(r'^\s*\[[^\]]+\]:\s*<?([^\s>]+)>?', re.M)
# Preserve vendor notices byte-for-byte. Their links describe the upstream tree.
UPSTREAM_DOCUMENTS = {'tests/fixtures/cesium_man/LICENSE.md'}


def source_names(root):
    top = subprocess.run(['git', 'rev-parse', '--show-toplevel'], cwd=root,
                         check=True, capture_output=True)
    if Path(top.stdout.decode().strip()).resolve() != root.resolve():
        raise ValueError('Use the repository root; an extracted source snapshot needs its own Git checkout.')
    result = subprocess.run(['git', '-c', 'core.quotepath=false', 'ls-files', '-z',
                             '--cached', '--others', '--exclude-standard'],
                            cwd=root, check=True, capture_output=True)
    return sorted(set(result.stdout.decode('utf-8').rstrip('\0').split('\0')) - {''})


def markdown_body(value):
    """Exclude fenced examples and inline code from link parsing."""
    value = re.sub(r'^(`{3,}|~{3,}).*?^\1\s*$', '', value, flags=re.M | re.S)
    return re.sub(r'`[^`\n]+`', '', value)


def heading_ids(value):
    ids = set()
    counts = Counter()
    value = re.sub(r'^(`{3,}|~{3,}).*?^\1\s*$', '', value, flags=re.M | re.S)
    for heading in re.findall(r'^#{1,6}\s+(.+?)\s*#*$', value, flags=re.M):
        heading = re.sub(r'\[([^\]]+)\]\([^)]*\)', r'\1', heading)
        heading = re.sub(r'<[^>]+>', '', heading).lower()
        slug = re.sub(r'[^\w\- ]', '', heading).replace(' ', '-')
        number = counts[slug]
        ids.add(slug + (f'-{number}' if number else ''))
        counts[slug] += 1
    ids.update(re.findall(r'(?:id|name)=["\']([^"\']+)["\']', value))
    return ids


def review(root, names):
    root = root.resolve()
    names = set(names)
    records, issues, texts = [], [], {}
    folded = {}

    def issue(name, message):
        issues.append({'path': name, 'message': message})

    for name in sorted(names):
        path = root / name
        parts = Path(name).parts
        if Path(name).is_absolute() or '..' in parts or not path.resolve().is_relative_to(root):
            issue(name, 'Path escapes the source root')
            continue
        if any(part in LOCAL_PARTS for part in parts):
            issue(name, 'Local/generated content is included in the source inventory')
        if any((root.joinpath(*parts[:i])).is_symlink() for i in range(1, len(parts) + 1)):
            issue(name, 'Symlinks are not portable source assets')
            continue
        if not path.is_file():
            issue(name, 'Tracked file is missing; stage intentional deletions before review')
            continue
        key = name.casefold()
        if key in folded:
            issue(name, 'Case-insensitive path collision with ' + folded[key])
        folded[key] = name
        if path.name.startswith('.env') and path.name not in {'.env.example', '.env.template'}:
            issue(name, 'Private environment file')
        if path.suffix.lower() in {'.exe', '.zip', '.7z', '.pem', '.key', '.p12', '.pfx', '.log'} or path.name == 'export_credentials.cfg':
            issue(name, 'Local executable, archive, credential or log in source')
        data = path.read_bytes()
        record = {'path': name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
        records.append(record)
        if len(data) > 25 * 1024 * 1024:
            issue(name, 'Exceeds the 25 MiB source-asset budget; optimize the preview or distribute the master separately')
        if path.suffix.lower() in BINARY_SUFFIXES:
            if path.suffix == '.wav':
                try:
                    with wave.open(str(path), 'rb') as audio:
                        record['audio'] = {'channels': audio.getnchannels(), 'sample_rate': audio.getframerate(),
                                           'frames': audio.getnframes()}
                        expected = audio.getnframes() * audio.getnchannels() * audio.getsampwidth()
                        if len(audio.readframes(audio.getnframes())) != expected:
                            issue(name, 'Truncated WAV samples')
                except (wave.Error, EOFError) as error:
                    issue(name, 'Invalid WAV: ' + str(error))
            continue
        if path.suffix.lower() not in TEXT_SUFFIXES and path.name not in {
                'LICENSE', '.gitignore', '.gitattributes', '.gdignore', '.editorconfig'}:
            issue(name, 'Unclassified source file; update the explicit inventory policy')
            continue
        try:
            value = data.decode('utf-8')
        except UnicodeError:
            issue(name, 'Text is not UTF-8')
            continue
        texts[name] = value
        record['lines'] = len(value.splitlines())
        if '\x00' in value or value.startswith('\ufeff'):
            issue(name, 'Text contains NUL bytes or a UTF-8 BOM')
        if PRIVATE_PATH.search(value):
            issue(name, 'Personal machine path; use a portable example (value redacted)')
        if SECRET.search(value):
            issue(name, 'Possible credential (value redacted); review with Gitleaks')
        try:
            if path.suffix == '.py':
                ast.parse(value, filename=name)
            elif path.suffix == '.json':
                json.loads(value)
            elif path.suffix == '.svg':
                ET.fromstring(value)
        except (SyntaxError, ValueError, ET.ParseError) as error:
            issue(name, 'Invalid syntax: ' + str(error))
        if path.suffix == '.uid' and not re.fullmatch(r'uid://[a-z0-9]+\s*', value):
            issue(name, 'Invalid Godot UID sidecar')

    link_count = 0
    for name, value in texts.items():
        path = Path(name)
        if path.suffix == '.md' and name not in UPSTREAM_DOCUMENTS:
            body = markdown_body(value)
            for target in LINK.findall(body) + REFERENCE_LINK.findall(body):
                parsed = urlsplit(target)
                if parsed.scheme or parsed.netloc:
                    continue
                link_count += 1
                # Preserve spelling: Windows resolve() can silently correct wrong case.
                relative = posixpath.normpath(posixpath.join(path.parent.as_posix(), unquote(parsed.path))) if parsed.path else name
                destination = (root / relative).resolve()
                if not destination.is_relative_to(root):
                    issue(name, 'Documentation link leaves the repository: ' + target)
                    continue
                if relative not in names and not any(item.startswith(relative.rstrip('/') + '/') for item in names):
                    issue(name, 'Documentation link is absent from the public source: ' + target)
                elif parsed.fragment and relative in texts and destination.suffix == '.md':
                    if unquote(parsed.fragment) not in heading_ids(texts[relative]):
                        issue(name, 'Missing documentation heading: ' + target)
        if path.suffix in {'.tscn', '.tres', '.import', '.godot'}:
            for resource in re.findall(r'"res://([^"\n]+)"', value):
                if resource.startswith('.godot/'):
                    continue  # Import descriptors deliberately point at generated caches.
                if resource not in names:
                    issue(name, 'Resource is absent from source (including exact case): res://' + resource)
        if path.suffix == '.uid' and name[:-4] not in names:
            issue(name, 'Orphan Godot UID sidecar')

    # Provenance must describe the documentation files actually being shipped.
    provenance_count = 0
    for name, value in texts.items():
        if not name.startswith('docs/media/') or not name.endswith('provenance.json'):
            continue
        try:
            manifest = json.loads(value)
        except ValueError:
            continue
        for asset, expected in manifest.get('files', manifest.get('outputs', {})).items():
            relative = (Path(name).parent / asset).as_posix()
            actual = next((item for item in records if item['path'] == relative), None)
            if actual is None or any(actual.get(key) != expected.get(key) for key in ('bytes', 'sha256')):
                issue(name, 'Media provenance differs from source: ' + asset)
            provenance_count += 1

    return {'ok': not issues, 'files_checked': len(records), 'bytes': sum(r['bytes'] for r in records),
            'local_links_checked': link_count, 'media_hashes_checked': provenance_count,
            'folders': dict(sorted(Counter(str(Path(r['path']).parent).replace('\\', '/') for r in records).items())),
            'issues': issues, 'files': records}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = review(args.root, source_names(args.root))
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: value for key, value in result.items() if key not in {'files', 'folders'}}, indent=2))
    return 0 if result['ok'] else 1


if __name__ == '__main__':
    sys.exit(main())
