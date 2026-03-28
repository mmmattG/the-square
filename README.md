# factorio-expanding-square

Local development commands:

```sh
make build
make install
```

`make build` creates a versioned Factorio mod zip in `./build/` using the `name` and `version` from `info.json`.

The starting square size is a per-save map setting (`runtime-global` in Factorio terms). Set it when creating a run. Changing it after the bootstrap surface already exists does not resize the current save.

Square growth now runs continuously in the background. Once per second the mod evaluates current counted-machine utilization inside the unlocked square, converts that into stored growth progress, and expands the square automatically whenever enough progress has accumulated for the next full ring.

For manual testing, enable the per-player `Developer mode` runtime setting. That adds an `Expand square` button to the top-left UI plus a debug panel showing utilization, growth progress, growth rate, and the counted-footprint breakdown by category and entity type.

`make install` builds the zip and copies it into your local Factorio mods directory. By default the install script auto-detects:

- macOS: `~/Library/Application Support/factorio/mods`
- Linux: `~/.factorio/mods`

Override the destination with `FACTORIO_MODS_DIR`:

```sh
FACTORIO_MODS_DIR="/path/to/factorio/mods" make install
```

The install step removes previously installed copies of this mod before copying the new zip, so the game sees a single current version.
