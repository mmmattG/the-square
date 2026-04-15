# the-square

Monorepo for both Factorio mods:

- `mods/base`: the vanilla `the-square` mod
- `mods/space-age`: the Space Age-only `the-square-space-age` mod

Top-level commands run across the monorepo:

```sh
make build
make install
make deploy-space-age
make test
make lint
make fmtk-package
make tools-bootstrap
make luals-meta
```

`make build` builds both mods.

`make install` installs both mods into the same Factorio mods directory. `make deploy-space-age` is kept as an alias for that combined install flow.
By default, the top-level `Makefile` auto-detects the standard mods directory on macOS, Linux, and WSL-to-Windows Factorio installs.

`make test`, `make lint`, `make fmtk-package`, `make tools-bootstrap`, and `make luals-meta` run the matching target in both mod workspaces.

If you only want one mod, use the specific targets:

```sh
make build-base
make build-space-age
make install-base
make install-space-age
make test-base
make test-space-age
```

Override the install destination for both mods with:

```sh
FACTORIO_MODS_DIR="/path/to/factorio/mods" make install
```
