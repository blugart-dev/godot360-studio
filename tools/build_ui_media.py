"""Copy successful native UI/editor captures and record their current-source hashes.

Run both reviewers first, inspect their PNGs, then use fresh review directories.
Images are copied byte-for-byte. Historical before images remain unchanged.
"""
import argparse
from datetime import date
import hashlib
import json
from pathlib import Path
import shutil


ROOT = Path(__file__).resolve().parents[1]
RUNTIME_SUFFIXES = {'.gd', '.gdshader', '.tscn', '.tres', '.cfg'}
REQUIRED = {
    'empty-1100', 'tools-1100', 'ready-1100', 'advanced-1100',
    'running-1100', 'completed-1100', 'completed-1440', 'details-1100',
    'export-details', 'audio-1440', 'encoding-1440', 'playback-1440',
    'library-1100', 'library-1440', 'scaled-125-percent',
    'cancelling-1100', 'cancelled-1100', 'playback-failed-1100',
    'export-failed-1100', 'help-start', 'help-setup', 'help-quality', 'help-files',
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--review', type=Path, required=True)
    parser.add_argument('--editor-review', type=Path, required=True)
    parser.add_argument('--date', type=date.fromisoformat, default=date.today())
    args = parser.parse_args()
    review, editor = args.review.resolve(), args.editor_review.resolve()
    # Only repository-relative locations are recorded in published provenance.
    review_name = review.relative_to(ROOT).as_posix()
    editor_name = editor.relative_to(ROOT).as_posix()
    report = json.loads((review / 'ui-review.json').read_text())
    native = json.loads((editor / 'editor-review.json').read_text())
    if not (report['ok'] and report['source_unchanged'] and
            native['ok'] and native['addon_unchanged']):
        raise SystemExit('Both native reviews must pass with unchanged source.')
    runtime = {p.relative_to(ROOT).as_posix(): digest(p)
               for p in (ROOT / 'addons/godot360').rglob('*')
               if p.suffix in RUNTIME_SUFFIXES}
    for name, sha in runtime.items():
        if report['source_hashes'].get(name) != sha or native['addon_hashes'].get(name) != sha:
            raise SystemExit('Capture is stale for current runtime: ' + name)
    drivers = {
        'tests/ui_workflow_checks.gd': review / 'project/tests/ui_workflow_checks.gd',
        'tests/fixtures/editor_workflow.gd': editor / 'project/addons/editor_review/plugin.gd',
    }
    for name, captured in drivers.items():
        if digest(ROOT / name) != digest(captured):
            raise SystemExit('Capture driver changed since review: ' + name)
    evidence = review / 'project/.godot360/ui-evidence'
    copies = {'ui-' + name + '.png': evidence / (name + '.png')
              for name in sorted(REQUIRED)}
    copies['ui-native-editor.png'] = editor / 'project/.godot360/editor-review/studio-native-editor.png'
    if any(not path.is_file() for path in copies.values()):
        raise SystemExit('A required native screenshot is missing.')
    media = ROOT / 'docs/media'
    manifest_path = media / 'ui-provenance.json'
    manifest = json.loads(manifest_path.read_text())
    # Keep the separately dated design-history controls.
    outputs = {name: value for name, value in manifest['outputs'].items()
               if name.startswith('ui-before-')}
    for name, path in copies.items():
        shutil.copyfile(path, media / name)
        outputs[name] = {'bytes': path.stat().st_size, 'sha256': digest(path)}
    shutil.copyfile(evidence / 'completed-1440.png', ROOT / 'addons/godot360/media/studio.png')
    manifest.update(
        date=args.date.isoformat(), after=review_name,
        engine='; '.join((review / 'ui.log').read_text(encoding='utf-8').splitlines()[:2]),
        capture='Unmodified native viewport PNGs; programmatic controls, no human click-through.',
        source_delivery_sha256=report['delivery_sha256'], runtime_hashes=runtime,
        driver_hashes={name: digest(ROOT / name) for name in drivers},
        checks=report['checks'], outputs=dict(sorted(outputs.items())),
        historical_before_date='2026-09-13',
        report_sha256=digest(review / 'ui-review.json'),
        packaged_screenshot={'path': 'addons/godot360/media/studio.png',
                             'sha256': digest(ROOT / 'addons/godot360/media/studio.png')},
        native_editor={'source': editor_name, 'kind': native['kind'],
                       'runtime_matches_current_source': True,
                       'package_sha256': native['package_sha256'],
                       'report_sha256': digest(editor / 'editor-review.json'),
                       'checks': sum(len(p['checks']) for p in native['phases'].values())},
    )
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'screenshots_copied': len(copies) + 1,
                      'ui_checks': report['checks'],
                      'editor_checks': manifest['native_editor']['checks']}))


if __name__ == '__main__':
    main()
