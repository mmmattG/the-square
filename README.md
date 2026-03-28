# factorio-expanding-square

Local development commands:

```sh
make build
make install
```

`make build` creates a versioned Factorio mod zip in `./build/` using the `name` and `version` from `info.json`.

`make install` builds the zip and copies it into your local Factorio mods directory. By default the install script auto-detects:

- macOS: `~/Library/Application Support/factorio/mods`
- Linux: `~/.factorio/mods`

Override the destination with `FACTORIO_MODS_DIR`:

```sh
FACTORIO_MODS_DIR="/path/to/factorio/mods" make install
```

The install step removes previously installed copies of this mod before copying the new zip, so the game sees a single current version.
