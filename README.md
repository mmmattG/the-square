# the-square

The Square is a Factorio challenge mod where your factory begins inside a tiny square and can grow by researching Square expansion.
Each square expansion level adds one buildable tile in each direction.

The intended purpose of this mod is to constrain space and force efficient design of the factory.

Feedback: Join the discord! https://discord.gg/HytACasPxY

## The Slop Line

Everything below this was written by my LLMs, not me.

## How it plays

- **A tiny Square.** Nauvis starts as a 7x7 Square surrounded by the Void. With Space Age,
  Vulcanus, Fulgora, Gleba and Aquilo each have their own 17x17 Square.
- **Grow it with research.** Each level of `Square expansion` adds a Ring: one tile on every
  side. Nauvis levels step up through science packs every ten levels, then continue forever
  with all science through space. Each other Planet has one infinite expansion research paid
  in its own science pack.
- **Resources come from Managed Lines.** There are no ore patches. Click an empty Anchor on
  the edge of the Square to place a Managed Line. Ingress lines bring a Planet's native
  resources in; egress lines send support materials out. Placing one uses a Managed Line
  item. Nauvis starts with three in your inventory, and you craft more.
- **Some resources have a price.** Nauvis uranium ore needs sulfuric acid sent out through an
  egress line, and Gleba fruit needs its seeds sent out. What you send out builds a small
  budget that the ingress line spends.
- **Faster lines.** `Dual-lane ingress` (after Logistics) fills both lanes of yellow lines.
  `Red ingress` and `Blue ingress` (after Logistics 2 and 3) unlock red and blue Managed Line
  items, and Space Age adds turbo. Each copies the science cost of the logistics research it
  follows.
- **Space Age eggs.** With no nests to capture, `Captivity` unlocks a hand-only recipe for five
  fresh biter eggs on Nauvis, and `Biochamber` one for a pentapod egg on Gleba.
- **Tools.** Top-bar buttons can move the Square or its contents one tile, and save a
  screenshot of the Square to `script-output/the-square/`.

Tips and tricks in game explain the rules. Their art is placeholder for now.

## Settings

| Setting | Kind | What it does |
| --- | --- | --- |
| Starting square size (one per Planet) | Startup | Square width on a new save. Changing it later does not resize an existing save. |
| Tiles per research pack | Startup | About how many new tiles each science pack of expansion research pays for. Default 7. |
| Background tile | Map | The floor of the Nauvis Square, including a lab checkerboard. Water, concrete and brick are left out on purpose. |
| Screenshot pixels per tile, alt mode | Map | How the screenshot button captures the Square. |
| Developer mode | Per player | Adds an `Expand square` button, a status panel and, with Space Age, buttons to jump to a test platform over each Planet. |
| Cliff explosives button | Per player | Adds a button that gives one cliff explosive, for cliffs that block progress on Vulcanus. |

Nauvis expansion research is built before any save exists, so its costs assume the default
starting size of 7. The difference fades quickly as the Square grows.

## Development

```sh
make build         # build/the-square_<version>.zip from info.json
make install       # build, then copy into your Factorio mods folder
make test          # plain-Lua specs in tests/
make syntax-check  # check that every Lua file parses
make playtest      # create and launch an isolated playtest save
```

`make test` needs `luajit` or `lua` on your `PATH`; force one with `make test LUA=lua`. The
specs only cover pure logic, so check anything that uses the Factorio API in game.

`make install` finds the mods folder for macOS, Linux, WSL (your Windows `%APPDATA%`) and
Windows shells, and replaces any older copy of the mod there. Override it with
`FACTORIO_MODS_DIR=/path/to/mods make install`. On Windows, close Factorio first if an old
zip is locked.

`make playtest` builds a save in `build/playtest/` with helper tools and launches Factorio.
Set `PLAYTEST_SPACE_AGE=0` for base game only, or `PLAYTEST_NO_LAUNCH=1` to only create the save.
Set `FACTORIO=/path/to/factorio` if the game is not found.

`make asset-gallery` builds a local page of every visual the mod shows. See
[dev/asset-gallery/README.md](dev/asset-gallery/README.md).

### Code map

[CONTEXT.md](CONTEXT.md) defines the game terms used in the code.

- `data.lua` loads `prototypes/`: Managed Line items and Anchors, research, tips, and egg recipes.
- `control.lua` only routes events to the modules in `lib/`.
- Shared by both stages: `managed_line_definitions` (names, tiers, throughput),
  `planet_catalog` (each Planet's resources and starter content), `mod_settings`,
  `square_layout` and `expansion_research`.
- Runtime: `planet_state` and `managed_line_state` (what is stored), `planet_runtime`
  (setup and updates), `square_runtime` (painting and expansion), `anchor_runtime` (Anchor
  entities), `anchor_config_gui`, `managed_line_pump`, `square_move_runtime` and
  `square_move_gui`, and `gui_runtime` (top-bar buttons and the dev panel).
- `migrations/` upgrades older saves. Each file is self-contained, so changes in `lib/` can't
  break it.
