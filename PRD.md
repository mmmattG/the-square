# Product Requirements Document

## Problem Statement

Factorio normally rewards scaling outward across effectively unlimited terrain. That makes compact design optional and often temporary. The intended challenge for this mod is the opposite: make space the central strategic pressure by confining the player to a square that only grows when the current factory uses its unlocked area efficiently. The player should feel pushed to solve hard layout problems on purpose, rebuild often, and trade off production, science, and logistics density for faster territorial growth.

The mod should create a run where the fun comes from choosing increasingly difficult factory-design problems:

- How do I fit bootstrap power, smelting, and science into a tiny square?
- When should I buy another input line versus upgrading all ingress throughput?
- When should I dedicate scarce space to labs that accelerate future growth rather than to immediate production?
- When should I rebuild the whole factory to increase active-machine utilization?
- How do I route belts, pipes, trains, and power in a way that keeps machines both compact and highly active?

The player is not trying to avoid constraint. The player is opting into a severe, legible constraint and trying to beat it through design quality.

## Solution

Create a Factorio challenge-mode mod built around an expanding square play area. The player starts in a very small clean square with a fixed set of free raw-resource inputs arriving from the map edge. The square expands symmetrically by one tile on all four sides whenever enough continuous expansion progress has been accumulated. Expansion progress is generated from current utilization of the unlocked square: the percentage of buildable tiles occupied by active production, research, and power-generation machines.

The player earns expansion points whenever the square grows, based on the number of newly unlocked tiles. Expansion points are spent on three things only in v1:

- buying new input lines for resources
- buying additional lines for already unlocked resources
- upgrading the global ingress tier that affects all item and fluid inputs

Resources come from movable edge anchors rather than ore patches. Starter inputs are available from the beginning, additional resources are purchased later, and all inputs can be moved or stashed for free. Logistic bots and the logistic chest ecosystem are disabled by default so the puzzle remains about compact visible automation. Construction and deconstruction bots remain allowed to support frequent redesign.

The result should feel like vanilla Factorio played inside a hostile optimization box: vanilla recipes and progression remain largely intact, but every tile, machine footprint, and second of machine uptime matter.

## User Stories

1. As an early-game player, I want to start in a tiny square with working raw-resource inputs already available, so that the first challenge is layout quality rather than mining setup.
2. As an early-game player, I want water and wood to be available from the start, so that basic power and poles are feasible inside the opening square.
3. As an early-game player, I want the opening map to be clean and deterministic, so that I am solving a compression puzzle instead of rolling for terrain luck.
4. As an early-game player, I want to see my utilization and expansion progress clearly, so that I can understand why my square is or is not growing.
5. As an early-game player, I want 0% utilization to produce 0 growth, so that dead space is a real failure mode I must solve through better design.
6. As a factory optimizer, I want only active machine footprint to count toward utilization, so that machine uptime and footprint efficiency both matter.
7. As a factory optimizer, I want belts, inserters, poles, pipes, chests, and tanks not to count toward utilization, so that support infrastructure remains a real space cost instead of free score.
8. As a factory optimizer, I want labs, beacons, silos, and power-generation machines to count only when truly active, so that the metric reflects real productive use rather than placed-but-idle structures.
9. As a rebuilder, I want redesigning my factory to be cheap and friction-light, so that I can repeatedly refactor the layout without extra punishment beyond downtime.
10. As a rebuilder, I want construction and deconstruction bots to remain available, so that large rewrites are practical even in a dense factory.
11. As a challenge player, I want logistic bots and logistic chests disabled by default, so that the puzzle stays centered on visible space-efficient transport.
12. As a challenge player, I want the square to expand only symmetrically, so that the entire run preserves the identity of an expanding square rather than becoming arbitrary side growth.
13. As a challenge player, I want the world outside the square to be inaccessible void, so that the square feels like my entire playable reality.
14. As a compact-layout player, I want starter inputs to arrive from the edge and be freely movable, so that I can reshape the border around the design I am pursuing.
15. As a compact-layout player, I want multiple inputs on the same side when space allows, so that I can create intentionally skewed, dense layouts.
16. As a compact-layout player, I want inputs to move outward automatically when the square expands, so that the mod preserves the border contract without breaking my factory every growth event.
17. As a compact-layout player, I want stashed inputs to stay owned and re-placeable, so that I can simplify the current layout without losing future options.
18. As a planner, I want stashed inputs to free their border coordinates completely, so that I can reserve edge space only for the lines I actively need.
19. As a planner, I want stashed inputs to inherit current global ingress upgrades when placed later, so that early purchases remain strategically useful.
20. As an economy optimizer, I want expansion points to come from newly unlocked tiles, so that larger expansions naturally produce larger strategic budgets.
21. As an economy optimizer, I want line purchases to be flat-cost while global ingress upgrades scale by level, so that the decision between more anchors now and better anchors later remains readable.
22. As an economy optimizer, I want the first purchased line of a resource to also be its unlock, so that expansion-point spending stays simple and concrete.
23. As a mid-game player, I want crude oil to become available as a purchased raw input, so that oil processing still consumes internal space while extraction itself remains external.
24. As a late-game player, I want uranium ore to become available later as another purchased raw input, so that advanced progression still participates in the ingress economy.
25. As a vanilla-focused player, I want recipes and machines to remain mostly unchanged, so that the challenge comes from the map rule and not from memorizing a rewritten production graph.
26. As a science-focused player, I want a repeatable expansion-speed research, so that labs remain a meaningful long-term lever on map growth.
27. As a science-focused player, I want that repeatable research to start early and continue indefinitely, so that science competes for space and throughput across the whole run.
28. As a science-focused player, I want dummy researches for normal science tiers, so that labs can still matter even when meaningful non-infinite research briefly runs out.
29. As a late-game player, I want vanilla infinite research to remain available, so that the mod augments normal progression instead of replacing it.
30. As a speedrun player, I want the run objective to stay “launch a rocket,” so that I can compare completion times on a recognizable benchmark.
31. As a speedrun player, I want the challenge to be deterministic enough that execution and design matter more than seed luck.
32. As a late-game player, I want play to continue indefinitely after launch, so that I can keep optimizing expansion speed, utilization, and layout quality.
33. As a train player, I want trains to remain allowed, so that I can experiment with whether they can be justified inside a constrained square.
34. As a manual player, I want handcrafting and hand-feeding to remain available, so that the mod does not add unnecessary rule clutter on top of the core constraint.
35. As a power-focused player, I want self-managed power inside the square, so that electricity remains part of the compression problem rather than a free external utility.
36. As a visibility-focused player, I want Factorio-style tips that explain the rules without prescribing strategy, so that I can learn the system and then solve it my own way.
37. As a server host or challenge curator, I want a small set of world settings for difficulty tuning, so that I can keep the same ruleset while adjusting severity.
38. As a mod user, I want logistics disabling to be a toggleable world setting, so that I can choose the pure challenge version or a softer variant.
39. As a post-win optimizer, I want the square and the growth system to be effectively unbounded in design terms, so that endless improvement remains a valid goal.
40. As a player experimenting with extreme layouts, I want the mod to accept severe congestion and awkward movement if the layout still works, so that the challenge does not get softened by quality-of-life reservations.

## Implementation Decisions

- The play space is a centered square that begins at a configurable default size of 7x7 and grows symmetrically by one tile on every side when enough progress for a full ring has accumulated.
- Expansion progress is continuous in the background and uses the current utilization of the unlocked square as its main driver.
- V1 uses a linear utilization-to-growth relationship, with possible nonlinear variants deferred to later playtesting.
- Growth is modeled as tiles per unit time with a slight size-based bonus so larger rings do not feel disproportionately slow.
- Utilization is defined as active counted-machine footprint divided by total currently buildable tiles in the unlocked square.
- Counted entities include active production machines, active labs, active rocket silos, active beacons affecting active machines, and active power-generation/steam-generation structures.
- Non-counted entities include belts, undergrounds, pipes, inserters, power poles, trains-as-infrastructure, roboports, chests, tanks, logistic chests, and other support logistics.
- A machine counts only on ticks where it is actively crafting, researching, processing, launching, or generating power by the applicable rule.
- The world outside the square is inaccessible and unbuildable. Newly unlocked rings are clean buildable space by default.
- Resources enter through single-tile inward-facing border anchors. Anchors can share sides but cannot overlap or collide around corners.
- Starter inputs are iron ore, copper ore, coal, stone, water, and wood; each starts as one free ingress line at the base tier.
- Additional resources are unlocked by buying their first line with expansion points. V1 progression is crude oil first, then uranium ore.
- Only raw or source resources arrive from outside. Processed items and fluids remain internal production responsibilities.
- Inputs may be relocated to any side for free or stashed off-map for later placement. No refund system exists.
- Manual input relocation is detach-and-replace. Automatic extension only occurs when the square expands.
- Placed inputs move outward with every expansion and preserve a simple direct border connection. Stashed inputs do not auto-extend connections because they are off-map.
- Each purchased input line is independent. Additional lines are flat-cost in v1. Global ingress upgrades scale by level.
- Global ingress upgrades apply retroactively to all existing and future owned lines, including stashed lines.
- Item lines start as single-lane throughput and can be improved by later global upgrades, including a double-lane upgrade while still using one anchor tile.
- Fluid lines use the same single-anchor concept and follow the global ingress tier progression.
- Expansion points awarded per growth event equal the number of newly unlocked tiles in the new ring.
- Expansion points are spent only on new lines, additional lines, and global ingress upgrades in v1.
- Power remains the player’s problem and must be solved inside the square using the provided raw inputs.
- Logistic robots and the logistic chest network are disabled by default, but this is exposed as a setting.
- Construction and deconstruction bots remain allowed.
- Vanilla combat systems are left largely untouched but become irrelevant because biters, nests, and random obstacles are absent in the default scenario.
- The primary meaningful custom infinite research is a repeatable expansion-speed multiplier research that begins early and follows vanilla-style science tier progression over time.
- Dummy research exists as explicit always-visible tiered filler research so labs can still have work before later infinite options naturally take over.
- The run objective remains vanilla rocket launch, but endless post-launch play is supported.
- Player onboarding should use concise Factorio-style help/tips entries that explain rules, not strategy.
- Recommended deep modules for implementation are:
  - a boundary and square-state module that owns current size, origin, and ring expansion rules
  - a utilization evaluator that converts live world state into counted active footprint
  - an expansion engine that converts utilization and upgrades into stored growth progress and ring expansions
  - an ingress manager that owns input-line state, movement, stashing, and expansion-time anchor shifting
  - an expansion-point economy that prices purchases and applies rewards
  - a research integration module for expansion-speed research and dummy-research behavior
  - a UI/readout module for metrics, settings surfacing, and help/tips

## Testing Decisions

- Good tests should verify externally visible gameplay behavior and stable domain rules, not implementation details or event ordering internals.
- The highest-value automated tests are the ones around deterministic rules with large combinatorial risk:
  - utilization counting behavior for included versus excluded entity classes
  - ring-expansion progression and reward calculations
  - anchor movement, stashing, and expansion-time preservation rules
  - pricing and upgrade application for line purchases and global ingress tiers
  - research effects on growth-rate multiplication and dummy-research availability
  - settings-driven startup behavior such as square size and logistics-network disabling
- The most important test style is domain-level scenario testing: given a square state, owned inputs, active entities, and progress, the system should produce the correct growth rate, next expansion, and rewards.
- Module-level tests should target the deep modules described above because they encapsulate the most volatile rule combinations behind stable interfaces.
- UI elements should be tested lightly, focusing on whether the right metrics are surfaced, not on incidental presentation details.
- There is no codebase prior art yet in this repository, so testing conventions should be established around behavior-first ruleset tests rather than copied from existing local patterns.

## Out of Scope

- Space Age support and planet-specific resource chains
- Non-raw external resources such as processed fluids or manufactured intermediates
- Scoreboards, leaderboards, or bespoke endless scoring systems beyond natural speedrun timing
- Lore, narrative framing, and thematic presentation of the void or boundary
- Alternative nonlinear utilization formulas for v1, including exponential reward curves and anti-buffer spoilage systems
- Any large-scale vanilla recipe overhaul
- Formal strategy coaching, puzzle hints, or prescriptive tutorialization
- Hard gameplay caps on map size or endless progression
- Final balance numbers for point costs, upgrade levels, research costs, and size-bonus tuning before playtesting
- A decision on whether blueprint ghosts may exist outside the unlocked square
- Terrain-edit systems such as waterfill or lavafill

## Further Notes

- The default design should bias toward harsh constraint. If a setup is possible, it is a valid challenge candidate even if it is uncomfortable.
- Playtesting is expected to decide the numerical balance of starting size, growth constants, input pricing, research scaling, and whether some convenience toggles deserve to graduate into defaults.
- The intended player fantasy is not “escape the box quickly” but “become good enough at Factorio that the box expands because the factory deserves it.”
