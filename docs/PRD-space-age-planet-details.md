## Problem Statement

The Space Age architecture now supports planet-scoped square initialization, but the non-Nauvis planets still use placeholder defaults. Players reaching Vulcanus, Fulgora, Gleba, or Aquilo need planet-specific square sizes, tiles, starter ingress/egress rules, and entity presentation that match vanilla Space Age resource acquisition while preserving The Square's constrained-factory challenge.

The current placeholder behavior risks making planets feel generic, under-sized for Space Age logistics, and disconnected from their native resource loops. It also leaves one now-required global behavior unspecified: items thrown or dropped off the managed square into the void should be destroyed on every planet.

## Solution

Define concrete per-planet defaults for supported Space Age planets. Nauvis remains unchanged for this slice. Vulcanus, Fulgora, Gleba, and Aquilo each start with a 17x17 square, enough to fit a cargo landing pad and rocket silo footprint while leaving expansion pressure intact.

Each non-Nauvis planet uses a thematic buildable floor tile, native starter ingresses, and only the egresses required by that planet's external resource abstraction. Ingress and egress definitions are planet-specific even when resource names overlap between planets. Interplanetary logistics remain vanilla Space Age; local ingress represents planet-local external sourcing.

Entity presentation should become consistent across planets:

- item ingress: underground belt flowing inward
- item egress: underground belt flowing outward
- fluid ingress: offshore pump
- fluid egress: underground pipe

Items thrown or dropped into out-of-map void outside any managed square should be destroyed on all supported planets.

## User Stories

1. As a Space Age player, I want each supported planet to have planet-specific square defaults, so that planets do not feel like generic copies of Nauvis.
2. As a player landing on Vulcanus, I want a 17x17 starting square, so that I can fit a cargo landing pad and rocket silo footprint.
3. As a player landing on Fulgora, I want a 17x17 starting square, so that Space Age logistics are possible without removing expansion pressure.
4. As a player landing on Gleba, I want a 17x17 starting square, so that agricultural bootstrapping and rocket logistics have enough initial space.
5. As a player landing on Aquilo, I want a 17x17 starting square, so that late-game logistics can begin inside the challenge constraints.
6. As a Vulcanus player, I want volcanic buildable ground as the playable tile, so that the square matches the planet.
7. As a Fulgora player, I want buildable Fulgoran plateau terrain as the playable tile, so that the square supports factories without using oilsands as the floor.
8. As a Gleba player, I want buildable natural Gleba ground as the playable tile, so that the square is usable without becoming a special farm tile by default.
9. As an Aquilo player, I want buildable snow or ice terrain as the playable tile, so that the square fits the freezing ocean planet while remaining buildable.
10. As a Vulcanus player, I want coal ingress from the start, so that native coal access is represented.
11. As a Vulcanus player, I want calcite ingress from the start, so that native calcite access is represented.
12. As a Vulcanus player, I want tungsten ore ingress from the start, so that native tungsten access is represented.
13. As a Vulcanus player, I want sulfuric acid fluid ingress from the start, so that sulfuric acid geysers are represented as an incoming native resource.
14. As a Vulcanus player, I want lava fluid ingress from the start, so that offshore-pumped lava is represented without needing lava tiles in the square.
15. As a Fulgora player, I want scrap ingress from the start, so that Fulgora's scrap-based economy remains central.
16. As a Fulgora player, I want heavy oil fluid ingress from the start, so that oilsands pumping is represented.
17. As a Fulgora player, I do not want iron, copper, stone, or coal starter ingresses, so that recycling scrap remains the planet's resource puzzle.
18. As a Gleba player, I want stone ingress from the start, so that native stone patches are represented.
19. As a Gleba player, I want water fluid ingress from the start, so that readily pumpable water is represented.
20. As a Gleba player, I want yumako and jellynut ingresses, so that fruit supply can be modeled at normal rates.
21. As a Gleba player, I want yumako seed and jellynut seed egresses, so that fruit ingresses are supplied by returning seeds.
22. As a Gleba player, I want seed egresses to feed their matching fruit ingress at normal rates, so that the mechanic mirrors the vanilla agricultural loop.
23. As an Aquilo player, I want crude oil ingress from the start, so that Aquilo's pumpjack resource is represented.
24. As an Aquilo player, I want ammoniacal solution ingress from the start, so that Aquilo's native ammonia ocean resource is represented.
25. As an Aquilo player, I want fluorine ingress from the start, so that native fluorine extraction is represented.
26. As an Aquilo player, I want lithium brine ingress from the start, so that native lithium brine extraction is represented.
27. As a player, I want ingress and egress rules to be planet-specific, so that the same resource can have different meaning on different planets.
28. As a player, I want Nauvis to remain unchanged in this slice, so that existing gameplay and compatibility are not accidentally redesigned.
29. As a player, I want item ingresses to look like inward underground belts, so that their function is obvious.
30. As a player, I want item egresses to look like outward underground belts, so that output/support direction is obvious.
31. As a player, I want fluid ingresses to look like offshore pumps, so that native fluid extraction feels like Space Age pumping.
32. As a player, I want fluid egresses to remain underground pipes, so that existing sulfuric-acid egress behavior can continue without redesign.
33. As a player, I want starter line exact positions to be merely valid and movable, so that layout can be adjusted during play.
34. As a player, I want items thrown or dropped off the square into the void to be destroyed, so that the void behaves like a real sink rather than an exploit or clutter zone.
35. As a maintainer, I want these planet defaults config-driven, so that new planet rules do not require duplicating bootstrap logic.
36. As a tester, I want per-planet default tests, so that starter resources, tiles, and square sizes cannot regress silently.

## Implementation Decisions

- Nauvis remains unchanged for this implementation slice.
- Vulcanus, Fulgora, Gleba, and Aquilo default starting square size is 17x17.
- Existing per-planet startup settings remain, but their non-Nauvis defaults should be updated to 17.
- Non-Nauvis playable floor tiles should use fixed thematic defaults rather than the legacy global background tile setting.
- Vulcanus starter ingresses are coal, calcite, tungsten ore, sulfuric acid, and lava.
- Vulcanus has no starter egresses.
- Fulgora starter ingresses are scrap and heavy oil.
- Fulgora has no starter egresses.
- Gleba starter ingresses are stone, water, yumako, and jellynut.
- Gleba starter egresses are yumako seed and jellynut seed.
- Gleba seed egresses supply the matching fruit ingress at normal rates.
- Aquilo starter ingresses are crude oil, ammoniacal solution, fluorine, and lithium brine.
- Aquilo has no starter egresses.
- Ingress and egress definitions are planet-local. Resource-name overlap does not imply shared behavior.
- Fluid ingresses are represented as offshore pumps, including sulfuric acid and lava on Vulcanus, heavy oil on Fulgora, water on Gleba, and Aquilo fluids.
- Fluid egresses are represented as underground pipes. Existing Nauvis sulfuric acid egress can remain pipe-like.
- Item ingresses are represented as inward underground belts.
- Item egresses are represented as outward underground belts.
- Starter layout placement only needs to be valid and movable; exact side/coordinate choices are not important for this PRD.
- Items thrown or dropped onto out-of-map void outside the managed square should be destroyed on every supported planet.
- Useful module boundaries are: planet configuration/catalog, planet-scoped ingress/egress definitions, starter layout construction, tile selection, entity presentation for line endpoints, and void-item destruction.
- Prefer deep, isolated modules for config interpretation and starter layout planning so behavior can be tested without Factorio runtime APIs.

## Testing Decisions

- Tests should verify external behavior and configuration interpretation, not exact implementation details.
- Add or extend tests for planet configuration defaults: square size, surface name, floor tile, starter ingress definitions, and starter egress definitions.
- Add or extend tests for starter layout planning: every required starter line is present, all generated positions are valid, and lines remain movable; avoid asserting fragile exact coordinates unless the layout API requires them.
- Add tests for planet-local resource definitions: the same resource name can appear on multiple planets without sharing unlock/egress semantics.
- Add tests for entity presentation mapping: item ingress inward underground belt, item egress outward underground belt, fluid ingress offshore pump, fluid egress underground pipe.
- Add tests for Gleba seed egress behavior supplying yumako and jellynut ingress at normal rates.
- Add tests for void item destruction on all supported planet surfaces.
- Prior art exists in the repository around planet instance specs, bootstrap runtime specs, bootstrap layout specs, ingress runtime specs, and resource balance specs. New tests should follow that behavior-first Lua module style.

## Out of Scope

- Redesigning Nauvis defaults.
- Changing vanilla Space Age planet unlocks, rockets, cargo landing pads, or interplanetary logistics.
- Adding duplicate managed planet surfaces.
- Implementing imports or exports through the ingress system.
- Making exact starter coordinates a balance-critical design decision.
- Adding lava tiles or other fluid source terrain inside the square.
- Broad support for unsupported planets or arbitrary modded planets.
- Rebalancing expansion research pacing beyond the 17x17 non-Nauvis starting-size defaults.
- Redesigning the existing Nauvis sulfuric-acid egress beyond preserving it as a fluid egress/underground pipe.

## Further Notes

The key design principle is that per-planet ingress mirrors native planet-local external resources, not universal Factorio basics. Fulgora gets scrap rather than normal ores. Gleba fruit ingress is special because it is paired with seed egress. Aquilo is mostly fluid extraction. Vulcanus includes sulfuric acid and lava as fluid ingresses because they are native extracted resources there.

This PRD is a concrete implementation slice beneath the broader Space Age PRD. It assumes the existing planet-scoped storage and square initialization work from the prior implementation slice.
