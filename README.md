# factorio-expanding-square

Local development commands:

```sh
make build
make install
```

`make build` creates a versioned Factorio mod zip in `./build/` using the `name` and `version` from `info.json`.

The starting square size is a per-save map setting (`runtime-global` in Factorio terms). Set it when creating a run. Changing it after the bootstrap surface already exists does not resize the current save.

`Tiles per research pack` is also a startup setting. It defaults to `7`, which means each required science pack in square-expansion research pays for about seven newly unlocked tiles. The first expansion level is fixed at `5` packs, and later levels round up to the next `10`.

`Enable logistic network automation` is also a per-save map setting. It is off by default, which blocks `active provider`, `buffer`, `requester`, and `storage` chests while still allowing passive providers, roboports, and logistic/construction bots.

Square growth is now driven directly by research. Each completed level of `Square expansion` immediately expands the map by one ring and awards expansion points for the newly unlocked tiles.

Research now includes custom expanding-square technologies:

- `Square expansion` is a repeatable research line that starts with red science, then steps up to broader science-pack bands every 10 completed levels.

For manual testing, enable the per-player `Developer mode` runtime setting. That adds an `Expand square` button to the top-left UI plus a debug panel showing the current square-expansion progression state.

`make install` builds the zip and copies it into your local Factorio mods directory. By default the install script auto-detects:

- macOS: `~/Library/Application Support/factorio/mods`
- Linux: `~/.factorio/mods`

Override the destination with `FACTORIO_MODS_DIR`:

```sh
FACTORIO_MODS_DIR="/path/to/factorio/mods" make install
```

The install step removes previously installed copies of this mod before copying the new zip, so the game sees a single current version.
