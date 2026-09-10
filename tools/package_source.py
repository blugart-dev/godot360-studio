"""Build a deterministic, reviewed source snapshot without Git history or local files."""
import argparse
import hashlib
import json
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

from repository_review import review, source_names


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    root, destination = args.root.resolve(), args.output.resolve()
    report = review(root, source_names(root))
    if not report['ok']:
        raise SystemExit(json.dumps(report['issues'], indent=2))
    if destination.exists() or destination.with_suffix('.json').exists():
        raise SystemExit('Use a fresh source archive destination.')
    # Freeze bytes once and reject edits that happened after the audit.
    files = {}
    for record in report['files']:
        data = (root / record['path']).read_bytes()
        if hashlib.sha256(data).hexdigest() != record['sha256']:
            raise SystemExit('Source changed during packaging: ' + record['path'])
        files[record['path']] = data
    files['SOURCE-MANIFEST.json'] = (json.dumps(report, indent=2) + '\n').encode()
    destination.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(destination, 'x', compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(files.items()):
            entry = ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            archive.writestr(entry, data, compress_type=ZIP_DEFLATED, compresslevel=9)
    with ZipFile(destination) as archive:
        if set(archive.namelist()) != set(files) or archive.testzip() is not None:
            raise SystemExit('Source archive verification failed.')
        for name, data in files.items():
            if archive.read(name) != data:
                raise SystemExit('Source archive content differs: ' + name)
    result = {'files': len(files), 'bytes': destination.stat().st_size,
              'sha256': hashlib.sha256(destination.read_bytes()).hexdigest(),
              'git_history_included': False, 'verified': True}
    destination.with_suffix('.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
