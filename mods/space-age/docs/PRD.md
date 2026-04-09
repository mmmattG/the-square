## Problem Statement

The current mod delivers a Nauvis-centered challenge variant built around a single expanding square, research-driven growth, and managed local ingress. That works for the base game, but it does not yet provide a coherent path for Space Age. The intended future direction is not a broad overhaul or total conversion. It is a harsher, expert-first challenge variant that preserves the core identity of the mod while extending it across Space Age planets.

The current architecture is still effectively single-surface and single-bootstrap. The future design needs to support multiple independent expanding squares on different planets, planet-specific expansion research, planet-specific tuning, and planet-local ingress and expansion-point economies without turning the mod into a separate game on each surface. The user wants one coherent mod that still feels like the same challenge on Nauvis and on every supported Space Age planet.

The main problem to solve is how to evolve the mod from a single-planet challenge into a Space Age-aware, multi-planet challenge system while preserving clarity, difficulty, and a stable design identity.

## Solution

Refactor the mod into a planet-scoped challenge system where each supported planet owns its own expanding square, local progression state, local expansion research, local expansion-point bank, and local ingress and optional egress rules. Nauvis remains a first-class supported experience. Space Age extends the same core rules to additional planets rather than replacing the original mode.

Each planet keeps the same core loop:

- the player starts inside a deliberately tiny square
- completing that planet's square-expansion research immediately expands that planet's square
- expansion awards expansion points for that planet only
- those points buy additional local ingress rate or lines for that planet only
- native raw resources for that planet can arrive through local ingress according to planet config
- cultivated resources remain in-square production problems
- interplanetary logistics remain vanilla Space Age and are not redefined as ingress

The implementation should first extract a shared planet-scoped model and move Nauvis onto it. After that, Space Age planets should be added in a deliberate order: Vulcanus, then Fulgora, then Gleba, then Aquilo. Breaking changes are acceptable during alpha.

## User Stories

1. As a challenge player, I want the mod to remain a challenge variant rather than a broad overhaul, so that the core appeal stays focused on constrained factory design.
2. As a vanilla-focused player, I want Nauvis-only mode to remain a complete experience, so that the mod is still worth playing without Space Age.
3. As a Space Age player, I want the same expanding-square identity to carry across planets, so that the DLC support feels like an extension of the same mod rather than a different product.
4. As an expert player, I want each planet to have its own independent square, so that every landing creates a fresh compression puzzle.
5. As a progression-focused player, I want planet unlocks to remain aligned with vanilla Space Age technologies, so that the larger campaign still feels recognizable.
6. As a planner, I want each planet to have its own square-expansion research line, so that local progression is legible and self-contained.
7. As a planner, I want each planet's square to expand immediately when its expansion research completes, so that progression stays concrete and responsive.
8. As a challenge player, I want the same core square rules on every planet, so that the ruleset stays coherent even when tuning changes.
9. As a balance-sensitive player, I want starting square sizes to be tuned per planet, so that each planet can be harsh without becoming arbitrarily broken.
10. As a balance-sensitive player, I want expansion research pacing to be tuned per planet, so that different production environments can still produce a fair challenge.
11. As an expert player, I want the default settings to target high difficulty, so that the mod preserves its intended harshness.
12. As a broader audience player, I want a small number of easier presets, so that I can soften the experience without changing the mod's core rules.
13. As a host or curator, I want presets to mainly tune square size and expansion pacing, so that difficulty changes are clear and predictable.
14. As a player landing on a new planet, I want the square challenge to begin immediately, so that the mod's main constraint is never bypassed by a setup grace period.
15. As a player landing on a new planet, I want that planet's free native inputs to already be owned, so that the bootstrap is possible from the start.
16. As a compact-layout player, I want those free inputs to begin pre-placed in a per-planet starter layout, so that each planet has a deliberate opening puzzle.
17. As a rebuilder, I want pre-placed anchors to remain freely movable through stashing and re-placement, so that I can redesign without artificial friction.
18. As a player, I want planets to expose only native free resources, so that the planets feel mechanically distinct.
19. As a player, I want cultivated resources to remain in-square problems rather than free ingress, so that planets like Gleba preserve their unique production challenge.
20. As a Space Age player, I want vanilla interplanetary transport to remain vanilla, so that rockets and cargo mechanics are not replaced by a parallel custom transport system.
21. As a planner, I want local ingress to represent planet-local external sourcing rather than interplanetary logistics, so that the ingress mechanic keeps a clear purpose.
22. As an optimizer, I want each planet to have its own expansion-point bank, so that each planet's throughput economy is earned locally.
23. As an optimizer, I want expansion points to come from square growth on that planet only, so that the local loop remains self-reinforcing and readable.
24. As an optimizer, I want expansion points to buy additional ingress rate or lines on that same planet, so that growth and throughput remain tightly linked.
25. As a strategist, I want cross-planet progress not to directly subsidize another planet's square growth, so that each planet remains a real challenge.
26. As a player, I want the factory footprint required for rockets and landing infrastructure to remain part of the local square pressure, so that vanilla logistics still interact with the challenge.
27. As a systems-minded player, I want egress to remain a local mechanic only, so that off-planet export continues to belong to vanilla rockets.
28. As a systems-minded player, I want the mod to support reusable egress rules for resources that need local external support materials, so that special extraction cases can be modeled consistently.
29. As a content designer, I want individual resources to opt into egress requirements explicitly, so that only the resources that need the mechanic actually use it.
30. As a player, I want planet/resource-specific ingress and egress rules to be documented in tips, so that I can learn the rules without the runtime UI becoming overloaded.
31. As a player, I want runtime UI to focus on live facts like local square state and local economy, so that operational information stays readable.
32. As a developer, I want planet rules to be primarily config-driven, so that adding planets does not require rewriting the core challenge loop.
33. As a developer, I want rare planet-specific hooks only where the shared model truly cannot express the planet, so that the system stays maintainable.
34. As a developer, I want the code to treat planets as the primary domain concept, so that the implementation matches the design language.
35. As a developer, I want runtime surface events mapped internally to planets, so that planet-scoped rules can still respond correctly to Factorio's surface-based APIs.
36. As a developer, I want square state, ingress state, research state, and local economy stored per planet, so that multi-planet support does not depend on singleton global bootstrap state.
37. As a developer, I want Nauvis migrated onto the shared planet-scoped model first, so that the architecture is proven on existing content before more planets are added.
38. As a developer, I want Vulcanus to be the first non-Nauvis proof planet, so that the new model is tested on a materially different but not maximally pathological case.
39. As a developer, I want the follow-up planet order to be Fulgora, then Gleba, then Aquilo, so that the rollout moves from moderate to more complex edge cases.
40. As a tester, I want deterministic behavior-centered tests around planet-local rules, so that refactors can proceed without relying on fragile implementation details.
41. As a tester, I want tests around per-planet research routing, so that one planet's completion cannot expand the wrong square.
42. As a tester, I want tests around per-planet point banks and ingress purchases, so that local economies cannot leak across planets.
43. As a tester, I want tests around native resource catalogs and starter layouts, so that each planet's bootstrap is intentional and stable.
44. As a tester, I want tests around cultivated-resource exceptions, so that non-ingress resources like farmed outputs remain constrained correctly.
45. As an alpha user, I want the mod to prioritize clean architecture over save compatibility, so that early refactors are not blocked by migration baggage.
46. As a long-run player, I want endless optimization to remain supported after nominal completion, so that each planet can continue to reward refinement.
47. As a first-win player, I want the design to optimize first for harsh but understandable completion, so that victory still feels like mastering the constraint rather than grinding a sandbox.
48. As a challenge player, I want rebuild pain and difficulty spikes to remain acceptable, so that the mod does not get softened into a generic convenience mode.
49. As a challenge player, I want blocking rules to remain legible rather than opaque, so that losses feel fair even when the constraints are severe.
50. As a maintainer, I want one DLC-aware codebase rather than divergent vanilla and Space Age variants, so that the mod's shared identity and logic remain unified.

## Implementation Decisions

- The mod remains one codebase with DLC-aware gating rather than splitting into separate vanilla and Space Age variants.
- Vanilla-only Nauvis support remains first-class and should continue to feel complete.
- The mod's future identity is a challenge variant, not a broad overhaul or alternate progression game.
- The architecture should be refactored away from a single global bootstrap/surface model toward a planet-scoped domain model.
- Planets are the primary domain concept for design, balance, and content definition.
- Runtime plumbing may still need an internal mapping from Factorio surfaces to planet instances, but that mapping is an implementation detail, not the product model.
- Each planet owns its own square state, expansion research progress, expansion-point bank, ingress state, optional egress state, starter layout, and tuning constants.
- Each planet keeps the same invariant core rules:
  - square-based play area
  - research-driven ring expansion
  - immediate expansion on research completion
  - local expansion-point rewards on expansion
  - local ingress economy
- Per-planet tuning is allowed for:
  - starting square size
  - expansion research curve
  - starter resource catalog
  - starter anchor layout
  - optional ingress and egress resource definitions
  - preset overrides
- Difficulty should be expressed through a small number of presets rather than many public knobs.
- The easier preset should mostly make planets start larger and secondarily soften expansion pacing.
- Each planet's free ingress resources should be native to that planet rather than a universal bundle.
- Cultivated or farmed resources should remain in-square production problems by default and should not be exposed as free ingress.
- Local ingress represents planet-local external sourcing only; it does not replace interplanetary rockets or cargo systems.
- Vanilla rocket launches, travel, and interplanetary transport remain the mechanism for affecting other planets.
- Rocket and landing infrastructure remain part of the local square-space problem.
- Expansion points remain in the design, but they are planet-local and are spent on local ingress rate or line capacity rather than on cross-planet progression.
- Expansion points are earned only from square growth on the same planet.
- Egress should exist as a reusable system for local extraction-support cases, but specific resources must explicitly opt into using it.
- Egress affects only local planet behavior and never stands in for interplanetary exports.
- Rule explanations that are not immediately operational should live primarily in the tips system.
- Runtime UI should stay focused on live operational state rather than carrying the full rulebook.
- The implementation should be predominantly config-driven with rare escape hatches for genuinely exceptional planets.
- The likely deep modules to build or reshape are:
  - a planet registry/state store that owns all planet-scoped progression state
  - a planet configuration catalog that defines resource sets, research metadata, starter layouts, and tuning constants
  - a square progression module that applies local research completion to the correct planet and handles rewards
  - a local ingress and optional egress domain module that owns anchor state, line ownership, purchases, stashing, and capacity rules per planet
  - a runtime routing layer that maps game events and surfaces to the correct planet context
  - a UI/tips integration layer that surfaces local live facts and planet-specific documentation
- The delivery order should be:
  - refactor to the planet-scoped model
  - move Nauvis onto that model and restabilize behavior
  - add Vulcanus
  - add Fulgora
  - add Gleba
  - add Aquilo
- Breaking changes are acceptable during alpha, especially across the vanilla-only to Space Age-aware transition.

## Testing Decisions

- Good tests should validate externally visible gameplay rules and stable domain behavior, not internal event ordering or storage layout details.
- The strongest tests for this work are deterministic, planet-scoped rule tests that can assert outcomes from a given planet config and local state.
- High-value test targets include:
  - planet-local square progression and expansion rewards
  - routing of completed research to the correct planet
  - local expansion-point accrual and spending
  - ingress ownership, stashing, movement, and capacity rules per planet
  - starter-layout initialization per planet
  - native-resource versus cultivated-resource handling
  - reusable egress behavior for opted-in resources
  - difficulty preset effects on per-planet tuning
  - vanilla-only mode continuing to behave as a complete Nauvis challenge
- The most important deep modules to test are the planet registry/state model, planet config interpretation, square progression, and local ingress/egress economy because they will absorb the highest combinatorial risk.
- UI tests should remain light and behavior-focused, checking that key live facts are surfaced rather than asserting presentation internals.
- Prior art already exists in the repository for behavior-first Lua module specs around expansion research, anchor behavior, runtime definitions, bootstrap layout, item ingress, and resource balance. The new tests should follow that style rather than introduce a different testing philosophy.

## Out of Scope

- Turning the mod into a broad overhaul or rewriting vanilla production chains
- Replacing vanilla Space Age rocket and interplanetary transport systems
- Making imports and exports use the local ingress abstraction
- General-purpose save migration guarantees during alpha
- Implementing all Space Age planets in one step
- Exhaustive live UI explanation of all custom rules
- Large numbers of public difficulty knobs
- Broad generic support for every imaginable external-resource edge case before a planet actually needs it
- Decisions on spaceship-specific challenge mechanics beyond leaving them vanilla for now
- Scoreboards, leaderboards, or a separate metagame outside the square challenge

## Further Notes

- The design target is expert-first. The default should be severe, but the difficulty must remain understandable.
- The intended first-win experience matters more than maximizing asymptotic system depth, though endless optimization should remain available.
- Rebuild pain and difficulty spikes are acceptable tradeoffs. Opaque blockers are not.
- The current codebase already expresses research-driven expansion more strongly than the older continuous-utilization PRD, so future work should preserve that newer identity unless a deliberate redesign says otherwise.
- This PRD is a future-direction document for the alpha roadmap. It is not a promise that every listed planet or edge case will land in one release.
