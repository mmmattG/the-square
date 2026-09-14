#!/usr/bin/env python3
"""Build a local asset catalogue from Factorio prototype and icon exports."""
from __future__ import annotations

import argparse
import base64
from collections import defaultdict
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[2]
IMAGE = re.compile(r"__([^/]+)__/([^\s\"']+\.(?:png|jpg|jpeg|webp))$", re.I)
# Only references that explicitly display a sprite belong in this gallery.
DISPLAY_SPRITE = re.compile(r"(?:\bsprite|[A-Z_]+_SPRITE)\s*=\s*[\"']([^\"']+)[\"']")
RICH_ICON = re.compile(r'\[(img|item|fluid|entity|technology|recipe|tile)=([^\]]+)\]')


def ui_references(repo: Path) -> dict[str, set[str]]:
    references: dict[str, set[str]] = defaultdict(set)
    for path in sorted((repo / 'lib').glob('*.lua')):
        for number, line in enumerate(path.read_text().splitlines(), 1):
            if line.lstrip().startswith('--'):
                continue
            for match in DISPLAY_SPRITE.finditer(line):
                reference = match[1]
                if not reference.endswith(('/', '.')):
                    references[reference].add(f'{path.relative_to(repo)}:{number}')
    for path in sorted((repo / 'locale').rglob('*.cfg')):
        for number, line in enumerate(path.read_text().splitlines(), 1):
            for match in RICH_ICON.finditer(line):
                reference = match[2] if match[1] == 'img' else f'{match[1]}/{match[2]}'
                references[reference].add(f'{path.relative_to(repo)}:{number}')
    return references


def resource_icons(repo: Path) -> list[tuple[str, str, str]]:
    lua = os.environ.get('LUA') or shutil.which('luajit') or shutil.which('lua')
    if not lua:
        raise RuntimeError('The gallery needs lua or luajit to read the mod resource catalogue.')
    result = subprocess.check_output([lua, str(Path(__file__).with_name('runtime-icons.lua'))],
                                     cwd=repo, text=True)
    return [tuple(line.split('\t')) for line in result.splitlines() if line]


def visible_mod_prototypes(raw: dict, mod_name: str):
    for kind, prototypes in sorted(raw.items()):
        for name, prototype in sorted(prototypes.items()):
            if not name.startswith(mod_name + '-'):
                continue
            if prototype.get('hidden') or 'hidden' in prototype.get('flags', []):
                continue
            # The Anchor slot proxy is invisible implementation machinery. Its
            # placeholder info icon is not a finished visual shown to players.
            if name == mod_name + '-anchor-slot-proxy':
                continue
            yield kind, name, prototype


def asset_path(reference: str, data_dir: Path, repo: Path, mod_name: str) -> Path | None:
    match = IMAGE.fullmatch(reference)
    if not match:
        return None
    owner, relative = match.groups()
    if owner in ('.', '..') or '\\' in owner or '\\' in relative:
        return None
    root = repo if owner == mod_name else data_dir / owner
    path = (root / relative).resolve()
    if not path.is_relative_to(root.resolve()):
        return None
    return path if path.is_file() else None


def discover_data_dir() -> Path | None:
    if os.environ.get('FACTORIO_DATA_DIR'):
        return Path(os.environ['FACTORIO_DATA_DIR']).expanduser()
    # Read Steam's library list instead of assuming the default library/disk.
    steam_roots = [Path.home() / '.local/share/Steam', Path.home() / '.steam/steam',
                   Path.home() / 'Library/Application Support/Steam']
    if os.environ.get('PROGRAMFILES(X86)'):
        steam_roots.append(Path(os.environ['PROGRAMFILES(X86)']) / 'Steam')
    libraries = set(steam_roots)
    for root in steam_roots:
        config = root / 'steamapps/libraryfolders.vdf'
        if config.is_file():
            libraries.update(Path(p.replace('\\\\', '\\'))
                             for p in re.findall(r'"path"\s+"([^"\n]+)"', config.read_text()))
    for library in sorted(libraries):
        game = library / 'steamapps/common/Factorio'
        for data in (game / 'data', game / 'factorio.app/Contents/data'):
            if (data / 'base/info.json').is_file() and (data / 'core').is_dir():
                return data
    return None


def export_prototypes(binary: Path, data_dir: Path, mode: str, destination: Path):
    """Use an isolated mod/config directory; never touch a player's mods or saves."""
    artifact = subprocess.check_output(['sh', str(REPO / 'scripts/build-mod.sh')],
                                       cwd=REPO, text=True).strip()
    with tempfile.TemporaryDirectory(prefix='the-square-assets-') as temp:
        work = Path(temp)
        # Steam's documented direct-launch mechanism keeps export arguments in
        # this process instead of relaunching through the client's normal UI.
        (work / 'steam_appid.txt').write_text('427520')
        mods = work / 'mods'
        mods.mkdir()
        shutil.copy2(artifact, mods)
        mod_name = json.loads((REPO / 'info.json').read_text())['name']
        names = ['base', 'quality', 'elevated-rails', 'space-age', mod_name]
        (mods / 'mod-list.json').write_text(json.dumps({'mods': [
            {'name': name, 'enabled': name in ('base', mod_name) or mode == 'space-age'}
            for name in names]}))
        write_data = work / 'write-data'
        write_data.mkdir()
        config = work / 'config.ini'
        config.write_text(f'[path]\nread-data={data_dir.resolve().as_posix()}\n'
                          f'write-data={write_data.as_posix()}\n')
        destination.mkdir(parents=True, exist_ok=True)
        # Exporting icons lets Factorio resolve layered/tinted icons accurately.
        # Neither invocation creates a world or uses game.take_screenshot.
        for flag in ('--dump-data', '--dump-icon-sprites'):
            log = destination / (flag[2:] + '.log')
            print(f'Exporting {mode}: {flag}', flush=True)
            with log.open('w') as output:
                result = subprocess.run([str(binary), flag, '--config', str(config),
                                         '--mod-directory', str(mods), '--disable-audio'],
                                        cwd=work, stdout=output, stderr=subprocess.STDOUT)
            if result.returncode:
                raise RuntimeError(f'Factorio export failed. See {log}')
        source = write_data / 'script-output'
        if not (source / 'data-raw-dump.json').is_file():
            raise RuntimeError(f'Factorio did not create a prototype export. See {destination}')
        if not (source / 'item').is_dir():
            raise RuntimeError(f'Factorio did not create an icon export. See {destination}')
        shutil.copytree(source, destination, dirs_exist_ok=True)


def exported_icon(directory: Path, kind: str, name: str, prototype: dict) -> Path | None:
    # SpritePath groups entity/item/equipment subclasses under their base type.
    groups = [kind]
    if kind == 'planet':
        groups.append('space-location')
    if 'stack_size' in prototype:
        groups.append('item')
    elif kind not in ('tips-and-tricks-item', 'utility'):
        groups.extend(['entity', 'decorative', 'equipment'])
    for group in groups:
        path = directory / group / (name + '.png')
        if path.is_file():
            return path
    return None


def build_catalogue(repo: Path, data_dir: Path, exports: dict[str, Path], output: Path,
                    resources: list[tuple[str, str, str]] | None = None) -> dict:
    info = json.loads((repo / 'info.json').read_text())
    references = ui_references(repo)
    if resources is None:
        resources = resource_icons(repo)
    entries: dict[tuple[str, str], dict] = {}
    warnings: list[str] = []
    output.mkdir(parents=True, exist_ok=True)
    (output / 'assets').mkdir(exist_ok=True)

    def save_image(content: bytes, suffix: str) -> str:
        digest = hashlib.sha256(content).hexdigest()[:24]
        target = Path('assets') / (digest + suffix)
        if not (output / target).exists():
            (output / target).write_bytes(content)
        return target.as_posix()

    def cropped_sprite(sprite: dict) -> str | None:
        # SVG is just a self-contained crop of an existing PNG, not new art.
        # This preserves standalone GUI sprites and tips icons without exposing
        # their source atlas, mipmaps, or component layers as gallery entries.
        path = asset_path(sprite.get('filename', ''), data_dir, repo, info['name'])
        if path is None:
            return None
        content = path.read_bytes()
        if content[:8] != b'\x89PNG\r\n\x1a\n':
            raise ValueError(f'Expected a PNG sprite: {path}')
        image_width, image_height = struct.unpack('>II', content[16:24])
        size = sprite.get('size')
        width = sprite.get('width', size if isinstance(size, int) else image_width)
        height = sprite.get('height', size if isinstance(size, int) else image_height)
        x, y = sprite.get('position', [sprite.get('x', 0), sprite.get('y', 0)])
        encoded = base64.b64encode(content).decode('ascii')
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
               f'viewBox="{x} {y} {width} {height}"><image width="{image_width}" '
               f'height="{image_height}" href="data:image/png;base64,{encoded}"/></svg>')
        return save_image(svg.encode(), '.svg')

    def add(image: str | None, name: str, category: str, usage: str, mode: str,
            section: str = 'mod'):
        # One finished design per card, even when multiple research levels,
        # recipes or game modes use exactly the same exported image.
        # Scope follows the use, not the pixels: a bootstrap recipe may still
        # use a vanilla egg icon while needing its own art review.
        key = (section, image or usage)
        if key not in entries:
            entries[key] = {'name': name, 'image': image, 'categories': set(),
                            'usages': set(), 'modes': set(), 'section': section}
        entries[key]['categories'].add(category)
        entries[key]['usages'].add(usage)
        entries[key]['modes'].add(mode)
        if image is None:
            warnings.append(f'{mode}: missing preview for {usage}')

    for mode, directory in exports.items():
        raw = json.loads((directory / 'data-raw-dump.json').read_text())
        if not any(name.startswith(info['name'] + '-')
                   for group in raw.values() for name in group):
            raise ValueError(f'{mode} export does not contain {info["name"]} prototypes')
        for kind, name, prototype in visible_mod_prototypes(raw, info['name']):
            icon = exported_icon(directory, kind, name, prototype)
            image = save_image(icon.read_bytes(), '.png') if icon else None
            category = ('Research' if kind == 'technology' else
                        'Tips' if kind == 'tips-and-tricks-item' else
                        'Items & recipes' if kind in ('item', 'recipe') else 'Entity icons')
            if kind == 'tips-and-tricks-item' and prototype.get('icon'):
                image = cropped_sprite({'filename': prototype['icon'],
                                        'size': prototype.get('icon_size', 64)})
            elif (not icon and not prototype.get('icon') and not prototype.get('icons')
                  and kind not in ('item', 'recipe', 'technology')):
                continue  # Categories and input bindings do not have visuals.
            title = name.removeprefix(info['name'] + '-')
            if kind == 'technology':
                title = re.sub(r'-\d+$', '', title)
            add(image, title.replace('-', ' ').capitalize(),
                category, f'{kind}/{name}', mode)

        displayed = {reference: set(usages) for reference, usages in references.items()}
        for planet, kind, name in resources:
            if mode == 'base' and planet != 'nauvis':
                continue
            displayed.setdefault(f'{kind}/{name}', set()).add(f'{planet}: Anchor resource selector')
        for reference, locations in sorted(displayed.items()):
            parts = re.split(r'[/\.]', reference, maxsplit=1)
            if len(parts) == 2:
                kind, name = parts
                icon = directory / kind / (name + '.png')
                if icon.is_file():
                    image = save_image(icon.read_bytes(), '.png')
                elif kind == 'utility':
                    image = cropped_sprite(raw.get('utility-sprites', {}).get('default', {}).get(name, {}))
                else:
                    image = None
            else:
                name = reference
                image = cropped_sprite(raw.get('sprite', {}).get(name, {}))
            for location in locations:
                section = 'mod' if name.startswith(info['name'] + '-') else 'reference'
                add(image, name.replace('-', ' ').capitalize(), 'UI',
                    f'{reference} — {location}', mode, section)

    thumbnail = repo / 'thumbnail.png'
    if thumbnail.is_file():
        add(save_image(thumbnail.read_bytes(), '.png'), 'The Square', 'Mod listing',
            'Mod manager thumbnail', 'local')
    rows = list(entries.values())
    for row in rows:
        for key in ('usages', 'modes', 'categories'):
            row[key] = sorted(row[key])
    rows.sort(key=lambda row: (row['categories'][0], row['name']))
    return {'version': info['version'], 'modes': list(exports), 'entries': rows,
            'warnings': sorted(set(warnings)),
            'missing': sum(row['image'] is None for row in rows)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data-dir', type=Path, default=discover_data_dir(),
                        help='Factorio data directory; also FACTORIO_DATA_DIR or Steam autodetection')
    parser.add_argument('--factorio', type=Path, default=os.environ.get('FACTORIO'),
                        help='Factorio executable; otherwise inferred from the data directory')
    parser.add_argument('--mode', choices=('base', 'space-age', 'both'), default='both')
    parser.add_argument('--reuse-exports', action='store_true',
                        help='Skip Factorio; rebuild using the previous exports (may be stale)')
    args = parser.parse_args()
    if not args.data_dir or not (args.data_dir / 'base/info.json').is_file():
        parser.error('Factorio assets not found. Set FACTORIO_DATA_DIR=/path/to/Factorio/data.')
    data_dir = args.data_dir.resolve()
    modes = ['base', 'space-age'] if args.mode == 'both' else [args.mode]
    if 'space-age' in modes and not (data_dir / 'space-age/info.json').is_file():
        parser.error('Space Age assets not found. Install the DLC or use --mode base.')
    binary = args.factorio
    if binary is None:
        candidates = [data_dir.parent / 'bin/x64/factorio',
                      data_dir.parent / 'bin/x64/factorio.exe', data_dir.parent / 'MacOS/factorio']
        binary = next((path for path in candidates if path.is_file()), None)
    if not args.reuse_exports and (binary is None or not binary.is_file()):
        parser.error('Factorio executable not found. Set FACTORIO=/path/to/factorio.')
    exports = {mode: REPO / 'build/asset-exports' / mode for mode in modes}
    for mode, destination in exports.items():
        if args.reuse_exports:
            if not (destination / 'data-raw-dump.json').is_file():
                parser.error(f'No cached {mode} export. Run without --reuse-exports first.')
        else:
            if destination.exists():
                shutil.rmtree(destination)
            export_prototypes(binary.resolve(), data_dir, mode, destination)
    destination = REPO / 'build/asset-gallery'
    with tempfile.TemporaryDirectory(prefix='asset-gallery-', dir=REPO / 'build') as temporary:
        output = Path(temporary)
        catalogue = build_catalogue(REPO, data_dir, exports, output)
        catalogue['cached'] = args.reuse_exports
        payload = json.dumps(catalogue, ensure_ascii=True).replace('<', '\\u003c')
        template = (Path(__file__).parent / 'index.html').read_text()
        (output / 'index.html').write_text(template.replace('/* CATALOGUE */', payload))
        (output / 'catalogue.json').write_text(json.dumps(catalogue, indent=2))
        if destination.exists():
            shutil.rmtree(destination)
        shutil.copytree(output, destination)
    print(f'{len(catalogue["entries"])} entries; {catalogue["missing"]} missing previews; '
          f'{len(catalogue["warnings"])} preview warnings')
    print(destination / 'index.html')
    if catalogue['missing'] or catalogue['warnings']:
        raise SystemExit('Catalogue generated with missing previews; see its coverage details.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, RuntimeError, OSError) as error:
        raise SystemExit(str(error)) from error
