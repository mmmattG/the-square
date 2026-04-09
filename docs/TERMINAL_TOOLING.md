# Terminal Tooling

This repo now treats terminal-first CLI commands as the source of truth for development tooling. Editor integrations should call into the same checked-in config and wrapper scripts instead of maintaining separate local settings.

## Tooling split

- Node tooling lives in [`package.json`](/Users/mmmatt/projects/the-square/package.json) and is installed repo-locally with `npm install`.
- Python-only tooling stays Python-only and is installed into an optional repo-local virtualenv from [`requirements/factorio-tools.txt`](/Users/mmmatt/projects/the-square/requirements/factorio-tools.txt).
- LuaLS is configured by the repo, but the `lua-language-server` binary itself stays an external install because it is not part of the npm/PyPI split used here.

## Supported commands

```sh
make tools-bootstrap
make luals-meta
make lint
make fmtk-package
make factorio-tools-install
```

- `make tools-bootstrap`: installs the repo-local Node dependency set, currently FMTK.
- `make luals-meta`: generates Factorio LuaLS metadata into `.cache/fmtk/luals-addon`.
- `make lint`: runs `lua-language-server --check` with the repo-owned [`.luarc.json`](/Users/mmmatt/projects/the-square/.luarc.json).
- `make fmtk-package`: runs FMTK packaging into `build/fmtk/` as a packaging and metadata validation pass in addition to the existing custom builder.
- `make factorio-tools-install`: creates `.venv/factorio-tools` and installs Hornwitser's tools there.

The wrapper scripts are:

- [`scripts/fmtk.sh`](/Users/mmmatt/projects/the-square/scripts/fmtk.sh)
- [`scripts/generate-luals-addon.sh`](/Users/mmmatt/projects/the-square/scripts/generate-luals-addon.sh)
- [`scripts/lua-ls-check.sh`](/Users/mmmatt/projects/the-square/scripts/lua-ls-check.sh)
- [`scripts/factorio-tools.sh`](/Users/mmmatt/projects/the-square/scripts/factorio-tools.sh)

Use those directly from Codex CLI or shell automation when you need arguments that do not fit neatly into a `make` variable.

## Node and FMTK

Install the repo-local Node toolchain with:

```sh
make tools-bootstrap
```

That installs [`factoriomod-debug`](https://www.npmjs.com/package/factoriomod-debug) into `node_modules/` and gives the repo a stable FMTK CLI entrypoint through [`scripts/fmtk.sh`](/Users/mmmatt/projects/the-square/scripts/fmtk.sh).

Current FMTK workflows:

```sh
make fmtk-package
./scripts/fmtk.sh package --outdir build/fmtk
./scripts/fmtk.sh luals-addon -o latest .cache/fmtk/luals-addon
```

This repo does not commit the generated LuaLS addon. It is generated on demand into `.cache/` because it is derived from upstream Factorio API docs and should stay easy to refresh when Factorio patch releases update the API surface.

If you need to pin the generated addon to an exact Factorio docs release instead of `latest`, set:

```sh
FACTORIO_DOCS_VERSION=2.0.76 make luals-meta
```

## LuaLS

Install `lua-language-server` yourself through your preferred package manager. For terminal-first macOS setups, Homebrew is the simplest path:

```sh
brew install lua-language-server
```

Then run:

```sh
make lint
```

The repo-owned [`.luarc.json`](/Users/mmmatt/projects/the-square/.luarc.json) defines:

- Lua 5.2 runtime expectations for Factorio mod code.
- Workspace libraries for `lib/`, `tests/`, and the generated FMTK addon.
- Factorio globals used in this repo.
- An ignore list for generated and tooling-only directories.

Expected baseline: `make lint` should pass at the default `Warning` threshold once `lua-language-server` is installed and the FMTK addon has been generated.

If you installed the binary somewhere unusual, point the wrapper at it:

```sh
LUA_LANGUAGE_SERVER=/path/to/lua-language-server make lint
```

### Neovim

Point Neovim's Lua LSP at the repo root so it picks up [`.luarc.json`](/Users/mmmatt/projects/the-square/.luarc.json) automatically. With `nvim-lspconfig`, the important part is not to duplicate repo-specific settings in your personal config:

```lua
require("lspconfig").lua_ls.setup({
  root_dir = require("lspconfig.util").root_pattern(".luarc.json", "info.json", ".git"),
})
```

That keeps the shared repo config authoritative for Neovim, Codex CLI, and any other LuaLS client.

## Hornwitser Factorio Tools

Install the optional Python tools with:

```sh
make factorio-tools-install
```

That creates `.venv/factorio-tools` and installs the pinned [`hornwitser.factorio_tools`](https://pypi.org/project/hornwitser.factorio_tools/) package.

Once installed, use the stable wrapper:

```sh
./scripts/factorio-tools.sh dat2json path/to/script.dat
./scripts/factorio-tools.sh desync path/to/desync-report
```

Common expectations:

- `dat2json` reads a Factorio `.dat` file and writes JSON to stdout.
- `desync` expects a Factorio desync-report directory as input.
- If you want to keep artifacts in-repo, put them under `build/` or another explicitly named scratch directory instead of writing into source folders.

This integration is optional by design. Contributors who only need the build/test/package loop do not need to install the Python tooling.
