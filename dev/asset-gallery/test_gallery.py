"""Offline checks for discovery, missing assets, and the mod package boundary."""
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('gallery', Path(__file__).with_name('gallery.py'))
gallery = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gallery)


class GalleryTests(unittest.TestCase):
    def test_only_own_visible_prototypes_are_selected(self):
        raw = {
            'item': {'the-square-line': {'icon': '__base__/line.png'},
                     'the-square-hidden': {'hidden': True},
                     'the-square-hidden-flag': {'flags': ['hidden']},
                     'iron-plate': {'icon': '__base__/ingredient.png'}},
            'simple-entity-with-owner': {'the-square-anchor-slot-proxy': {'icon': '__base__/info.png'}},
        }
        selected = list(gallery.visible_mod_prototypes(raw, 'the-square'))
        self.assertEqual([name for _, name, _ in selected], ['the-square-line'])

    def test_ui_discovery_ignores_ingredients_prerequisites_and_components(self):
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary)
            (repo / 'lib').mkdir()
            (repo / 'locale/en').mkdir(parents=True)
            (repo / 'lib/runtime.lua').write_text(
                'sprite = "item/iron-ore"\n'
                'defs.INFO_SPRITE = "info"\n'
                'ingredient = "iron-plate"\n'
                'prerequisite = "logistics"\n'
                'icon = "__core__/graphics/white-square.png"\n'
                'sprite_prefix = "fluid/"\n'
                '-- sprite = "item/unused"')
            (repo / 'locale/en/text.cfg').write_text('hint=Use [item=copper-ore] [img=tile/grass-1]')
            references = gallery.ui_references(repo)
            self.assertEqual(set(references), {'item/iron-ore', 'info', 'item/copper-ore', 'tile/grass-1'})

    def test_finished_designs_are_grouped_and_no_raw_sheets_are_copied(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            repo, data, export, output = (root / name for name in ('repo', 'data', 'export', 'output'))
            repo.mkdir()
            (repo / 'lib').mkdir()
            (export / 'item').mkdir(parents=True)
            (export / 'technology').mkdir()
            (repo / 'info.json').write_text(json.dumps({'name': 'the-square', 'version': '0.1.6'}))
            (export / 'item/iron-ore.png').write_bytes(b'resource-icon')
            for name in ('the-square-expansion-1', 'the-square-expansion-2'):
                (export / 'technology' / (name + '.png')).write_bytes(b'same-finished-icon')
            raw = {
                'technology': {name: {'icon': '__base__/icon.png'}
                               for name in ('the-square-expansion-1', 'the-square-expansion-2')},
                'item': {'the-square-missing': {'icon': '__base__/missing.png'},
                         'iron-ore': {'icon': '__base__/ore.png'},
                         'iron-plate': {'icon': '__base__/ingredient.png'}},
                'underground-belt': {'unrelated-belt': {'structure': {'filename': '__base__/sheet.png'}}}}
            (export / 'data-raw-dump.json').write_text(json.dumps(raw))
            catalogue = gallery.build_catalogue(repo, data, {'base': export, 'space-age': export}, output,
                                                resources=[('nauvis', 'item', 'iron-ore')])
            entries = catalogue['entries']
            research = next(row for row in entries if 'Research' in row['categories'])
            self.assertEqual(len(research['usages']), 2)
            self.assertEqual(research['modes'], ['base', 'space-age'])
            self.assertEqual(len(list((output / 'assets').iterdir())), 2)
            self.assertEqual(catalogue['missing'], 1)
            self.assertEqual(len(entries), 3)
            self.assertFalse(any('Source images' in row['categories'] for row in entries))
            self.assertFalse(any('iron-plate' in str(row) or 'unrelated-belt' in str(row) for row in entries))

    def test_gui_sprite_crop_is_self_contained(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            repo, data, export, output = (root / name for name in ('repo', 'data', 'export', 'output'))
            (repo / 'lib').mkdir(parents=True)
            (data / 'core').mkdir(parents=True)
            export.mkdir()
            (repo / 'info.json').write_text('{"name":"the-square", "version":"0.1.6"}')
            (repo / 'lib/gui.lua').write_text('sprite = "info"')
            # Only PNG metadata is read by the crop wrapper.
            (data / 'core/info.png').write_bytes(b'\x89PNG\r\n\x1a\n' + b'0' * 8 +
                                               gallery.struct.pack('>II', 128, 64))
            raw = {'sprite': {'info': {'filename': '__core__/info.png', 'width': 16, 'height': 40,
                                      'x': 32, 'y': 4}},
                   'custom-input': {'the-square-binding': {}}}
            (export / 'data-raw-dump.json').write_text(json.dumps(raw))
            catalogue = gallery.build_catalogue(repo, data, {'base': export}, output, resources=[])
            self.assertEqual(len(catalogue['entries']), 1)
            self.assertEqual(catalogue['missing'], 0)
            image = output / catalogue['entries'][0]['image']
            self.assertEqual(image.suffix, '.svg')
            self.assertIn('viewBox="32 4 16 40"', image.read_text())
            self.assertIn('data:image/png;base64,', image.read_text())
            self.assertEqual(len(list((output / 'assets').iterdir())), 1)

    def test_mod_placeholder_and_unchanged_icon_stay_in_separate_sections(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            repo, data, export, output = (root / name for name in ('repo', 'data', 'export', 'output'))
            repo.mkdir()
            (export / 'recipe').mkdir(parents=True)
            (export / 'item').mkdir()
            (repo / 'info.json').write_text('{"name":"the-square", "version":"0.1.6"}')
            for icon in ('recipe/the-square-egg-bootstrap.png', 'item/egg.png'):
                (export / icon).write_bytes(b'identical-placeholder-and-reference')
            raw = {'recipe': {'the-square-egg-bootstrap': {}}, 'item': {'egg': {}}}
            (export / 'data-raw-dump.json').write_text(json.dumps(raw))
            catalogue = gallery.build_catalogue(repo, data, {'base': export}, output,
                                                resources=[('nauvis', 'item', 'egg')])
            entries = catalogue['entries']
            self.assertEqual(len(entries), 2)
            self.assertEqual({row['section'] for row in entries}, {'mod', 'reference'})
            self.assertEqual(entries[0]['image'], entries[1]['image'])
            mod = next(row for row in entries if row['section'] == 'mod')
            self.assertIn('recipe/the-square-egg-bootstrap', mod['usages'])

    def test_asset_resolution_cannot_escape_owner_directory(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'base').mkdir()
            (root / 'outside.png').write_bytes(b'not-an-asset')
            self.assertIsNone(gallery.asset_path('__base__/../outside.png', root, root, 'the-square'))

    def test_exported_icons_follow_factorio_sprite_groups(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for group, name in [('item', 'science'), ('entity', 'anchor'),
                                ('space-location', 'nauvis'), ('recipe', 'anchor')]:
                (root / group).mkdir(exist_ok=True)
                (root / group / (name + '.png')).touch()
            self.assertEqual(gallery.exported_icon(root, 'tool', 'science', {'stack_size': 200}),
                             root / 'item/science.png')
            self.assertEqual(gallery.exported_icon(root, 'underground-belt', 'anchor', {}),
                             root / 'entity/anchor.png')
            self.assertEqual(gallery.exported_icon(root, 'planet', 'nauvis', {}),
                             root / 'space-location/nauvis.png')
            self.assertEqual(gallery.exported_icon(root, 'recipe', 'anchor', {}),
                             root / 'recipe/anchor.png')
            self.assertIsNone(gallery.exported_icon(root, 'tips-and-tricks-item', 'anchor', {}))

    def test_mod_archive_excludes_gallery_source_and_generated_output(self):
        repo = gallery.REPO
        # A sentinel proves build output stays out even when a gallery exists.
        generated = repo / 'build/asset-gallery'
        generated.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(prefix='packaging-probe-', dir=generated):
            artifact = subprocess.check_output(['sh', str(repo / 'scripts/build-mod.sh')],
                                               cwd=repo, text=True).strip()
            with zipfile.ZipFile(artifact) as archive:
                paths = [Path(name).parts[1:] for name in archive.namelist()]
        self.assertTrue(any(parts == ('data.lua',) for parts in paths))
        self.assertTrue(any(parts[:1] == ('lib',) for parts in paths))
        self.assertFalse(any(parts and parts[0] in ('dev', 'build', 'tests', 'scripts') for parts in paths))
        self.assertFalse(any('asset-gallery' in '/'.join(parts) for parts in paths))

    def test_generated_gallery_and_exports_are_gitignored(self):
        paths = ['build/asset-gallery/index.html', 'build/asset-gallery/catalogue.json',
                 'build/asset-gallery/assets/preview.png',
                 'build/asset-exports/base/data-raw-dump.json',
                 'build/asset-exports/space-age/item/iron-ore.png']
        ignored = subprocess.check_output(['git', 'check-ignore', '--no-index', '--stdin'],
                                          input='\n'.join(paths) + '\n', cwd=gallery.REPO,
                                          text=True).splitlines()
        self.assertEqual(ignored, paths)


if __name__ == '__main__':
    unittest.main()
