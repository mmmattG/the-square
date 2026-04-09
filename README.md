# the-square

Contact: https://discord.gg/HytACasPxY

Local development commands:

```sh
make build
make install
make test
make tools-bootstrap
make luals-meta
make lint
make fmtk-package
```

`make build` creates a versioned Factorio mod zip in `./build/` using the `name` and `version` from `info.json`.

`make test` runs every Lua spec in `tests/*_spec.lua` and stops on the first failure. It requires either `luajit` or `lua` to be available on `PATH`; the target prefers `luajit` when both are installed.

`make tools-bootstrap` installs the repo-local Node toolchain from `package.json`. Right now that is the checked-in FMTK CLI dependency used for packaging and LuaLS metadata generation.

`make luals-meta` generates the FMTK LuaLS addon into `.cache/fmtk/luals-addon`. The default input is Factorio API docs from `latest`; override that with `FACTORIO_DOCS_VERSION=<exact-version>` if you need to pin analysis to a specific Factorio patch release.

`make lint` runs LuaLS in terminal mode with the repo-owned [`.luarc.json`](/Users/mmmatt/projects/the-square/.luarc.json). It expects `lua-language-server` to already be installed on your machine or exposed through `LUA_LANGUAGE_SERVER=/path/to/lua-language-server`.

`make fmtk-package` runs FMTK packaging into `build/fmtk/` as an additional packaging/metadata check alongside the existing custom `make build`.

Optional Python tooling for desync and `.dat` inspection lives behind a separate install step:

```sh
make factorio-tools-install
./scripts/factorio-tools.sh dat2json script.dat
./scripts/factorio-tools.sh desync /path/to/desync-report
```

That path creates `.venv/factorio-tools` and installs the pinned PyPI package from [`requirements/factorio-tools.txt`](/Users/mmmatt/projects/the-square/requirements/factorio-tools.txt). It is intentionally optional so contributors who only need the build/test loop do not need Python tooling on day one.

Terminal-first setup details, including Neovim/LSP usage, live in [docs/TERMINAL_TOOLING.md](/Users/mmmatt/projects/the-square/docs/TERMINAL_TOOLING.md).

If you need to force a specific runtime, override `LUA` directly:

```sh
make test LUA=lua
```

The starting square size is a per-save map setting (`runtime-global` in Factorio terms). Set it when creating a run. Changing it after the bootstrap surface already exists does not resize the current save.

`Tiles per research pack` is also a startup setting. It defaults to `7`, which means each required science pack in square-expansion research pays for about seven newly unlocked tiles.

Because square-expansion technologies are generated in the data stage, their precomputed finite costs and infinite count formula use the default starting square size of `7` even if a save overrides the map setting. That mismatch is acceptable in practice because the ring costs quickly converge toward the same values as the square grows.

`Ingress and egress line cost` is a per-save map setting. It defaults to `1000` expansion points for each additional owned ingress or egress line.

`Enable logistic network automation` is also a per-save map setting. It is off by default, which blocks `active provider`, `buffer`, `requester`, and `storage` chests while still allowing passive providers, roboports, and logistic/construction bots.

`Background tile` is a per-save map setting under `Mod settings -> Map`. It repaints the square floor uniformly, with curated dry tiles plus lab tiles and a special checkerboard option. Water, concrete, and stone-brick style tiles are intentionally excluded.

Square growth is now driven directly by research. Each completed level of `Square expansion` immediately expands the map by one ring and awards expansion points for the newly unlocked tiles.

Research now includes custom expanding-square technologies:

- `Square expansion` is a repeatable research line that uses science bands in blocks: levels `1-10`, `11-20`, `21-30`, and `31-40` step through broader pack sets, then level `41+` continues infinitely with all science through space.
- `Dual-lane ingress`, `Red ingress`, and `Blue ingress` are one-time researches unlocked after `Logistics`, `Logistics 2`, and `Logistics 3`. Each copies the science cost of the logistics technology that gates it.

Tips and tricks are currently text-first and use base-game icons as placeholders. Proper custom instructional art is deferred for later work.

For manual testing, enable the per-player `Developer mode` runtime setting. That adds an `Expand square` button to the top-left UI plus a debug panel showing the current square-expansion progression state.

Issue `#18` was resolved by `PR #52`, which fixed the border/background rendering regressions that prompted the earlier experiments here.

`make install` builds the zip and copies it into your local Factorio mods directory. By default the install script auto-detects:

- macOS: `~/Library/Application Support/factorio/mods`
- Linux: `~/.factorio/mods`

Override the destination with `FACTORIO_MODS_DIR`:

```sh
FACTORIO_MODS_DIR="/path/to/factorio/mods" make install
```

The install step removes previously installed copies of this mod before copying the new zip, so the game sees a single current version.
