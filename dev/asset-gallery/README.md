# Development asset gallery

Run `make asset-gallery`, then open `build/asset-gallery/index.html` in your browser.
The page works directly from disk, with no development server or web dependencies.
It contains finished visuals shown by the mod, with usage details, Base/Space Age
filters, and adjustable icon preview sizes. Repeated designs share one card within
each section. Mod features and their placeholder art appear first; unchanged Base/Space
Age resource and utility icons live in a separate, initially collapsed reference section.

The generator discovers Steam libraries automatically. For another installation:

```sh
FACTORIO_DATA_DIR="/path/to/Factorio/data" FACTORIO="/path/to/factorio" make asset-gallery
```

By default it exports both Base and Space Age. Without the DLC, use
`make asset-gallery GALLERY_ARGS="--mode base"`.
Factorio runs its prototype and icon export commands in a temporary isolated
configuration. It does not create a world, take screenshots, or change your installed
mods, settings or saves. Fresh exports pick up generated prototypes and layered/tinted
icons. Rebuilding after only gallery UI changes can skip Factorio with
`make asset-gallery GALLERY_ARGS="--reuse-exports"` (add `--mode base` if needed).
Cached exports do not pick up mod changes.

The gallery includes visible mod item, recipe, research and entity icons; icons
explicitly displayed by its UI and settings; tips artwork; and the mod thumbnail.
Resource selector icons come directly from `lib/planet_catalog.lua` via Lua, so its
resource list stays in sync. It needs `lua` or `luajit` (or a `LUA` override).
It excludes raw sprite sheets, component layers, invisible helpers, and vanilla
assets that are only ingredients, prerequisites or implementation references.
Entity previews are finished icons, not in-world scenes. Standalone GUI sprites
and tips icons are cropped to their declared dimensions, without exposing atlases.
Missing expected previews are reported on the page and fail the command.

All tooling lives in `dev/asset-gallery/`; generated pages, copied game assets and exports
live in ignored `build/` folders. The mod builder's explicit runtime-file allowlist
excludes both directories. `make asset-gallery-test` checks discovery and packaging
without launching Factorio.
