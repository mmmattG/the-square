# Feature List

This document lists planned features for `the-square`, grouped first by planned timeframe and then loosely by category.

## Planned For V1

### Core World Rules

- Centered expanding square play area
- Symmetric ring expansion by 1 tile on each side
- Each completed square-expansion research level triggers the next ring expansion
- Square-expansion research steps up to broader science tiers over time
- Outside of the square is inaccessible void
- Clean newly unlocked space by default
- Fixed center spawn
- Endless post-rocket play
- Vanilla rocket launch remains the default win condition

### Expansion Research And Rewards

- Square-expansion research starts with red science only
- Science requirements step up every 10 completed expansion levels
- Each completed level expands the square immediately
- Next expansion reward shown as newly unlocked tiles / expansion points
- Expansion points awarded equal newly unlocked tiles

### Counted Entities

- Active assembling machines count
- Active furnaces count
- Active chemical plants count
- Active refineries count
- Active centrifuges count
- Active labs count while researching
- Active rocket silos count while doing silo work
- Active beacons count when affecting at least one active machine
- Active power-generation and steam-generation entities count

### Excluded Entities

- Belts do not count
- Inserters do not count
- Pipes do not count
- Power poles do not count
- Chests do not count
- Tanks do not count
- Logistic infrastructure does not count
- General support logistics/infrastructure does not count unless explicitly listed above

### Inputs And Ingress

- Starter inputs: iron ore, copper ore, coal, stone, water, wood
- Starter inputs are free
- Starter inputs begin with one line each
- Input lines arrive from border anchors facing inward
- Inputs can be moved to any side for free
- Multiple inputs may share a side
- Inputs cannot overlap or collide on corners
- Inputs can be stashed off-map
- Stashed inputs free their border coordinates
- Re-placing a stashed input is a fresh placement
- The retired Expansion Point shop has no refunds or purchases
- Manual relocation is detach-and-replace
- Expansion-time border movement preserves enabled inputs automatically
- Disabled inputs move outward on expansion without auto-connection
- Additional input and output lines come from crafted generic anchors: Item Ingress Anchor, Item Egress Anchor, Fluid Ingress Anchor, and Fluid Egress Anchor, each built from an Anchor Frame intermediate.
- Only raw or source resources arrive from outside
- Crude oil is configured on a crafted Fluid Ingress Anchor once available on the planet
- Uranium ore is configured on a crafted Item Ingress Anchor once available on the planet

### Throughput And Economy

- Item lines start at single yellow-belt-lane equivalent
- Fluid lines start at the matching lowest anchor tier
- Research-driven Anchor upgrades affect all shared-tier item and fluid managed lines, whether ingress or egress
- Anchor upgrades apply retroactively to existing and stashed lines
- Logistics unlocks dual-lane yellow anchors, Logistics 2 unlocks red anchors, Logistics 3 unlocks blue anchors, and Space Age turbo belts unlock Turbo Anchors for both ingress and egress
- Additional lines are crafted as generic anchors and configured by selecting a free anchor-configuration recipe on the placed anchor.
- Anchor Frame recipe target: 50 steel plate, 50 electronic circuits, 50 iron gear wheels.
- Generic anchor recipe targets: item anchors use 1 Anchor Frame, 50 transport belts, and 5 underground belts; fluid ingress uses 1 Anchor Frame, 50 pipes, and 1 offshore pump; fluid egress uses 1 Anchor Frame, 50 pipes, and 1 pipe-to-ground.
- Square Expansion research unlocks new tiles but no longer awards Expansion Points.
- Expansion Points and the line-purchase shop are retired; crafted generic anchors are the managed-line economy.
  - additional ingress and egress lines

### Research

- Custom repeatable square-expansion research
- Square-expansion research starts early
- Square-expansion research continues indefinitely
- Square-expansion research follows tiered science-pack progression
- Vanilla infinite researches remain available

### Logistics And Automation Rules

- Logistic bots disabled by default
- Logistic chest ecosystem disabled by default
- Construction bots allowed
- Deconstruction bots allowed
- Manual handcrafting allowed
- Manual hand-feeding allowed
- Trains allowed

### Scenario And Progression

- No rocket crash intro
- No burner miner in the starting loadout/context
- Vanilla recipes and machines remain largely intact
- No biters
- No enemy expansion
- No random terrain obstacles in the square
- Military systems remain present but unnecessary

### UI, Settings, And Onboarding

- Core expansion research metrics shown to the player
- Factorio-style help/tips entries explaining system rules
- World/startup setting: starting square size
- World/startup setting: logistic network enabled/disabled
- World/startup setting: expansion-rate multiplier
- World/startup setting: expansion-point multiplier

## Planned After V1

### Balance And Formula Exploration

- Nonlinear utilization curves
- Exponential or strongly compounding growth formulas
- Alternative smoothing models for utilization
- Revisit the slight size bonus formula
- Full balance passes for costs, rates, and research scaling

### Diagnostics And UX

- Heat-map or overlay showing what currently counts toward utilization
- Better debug readouts for counted versus non-counted entities
- More detailed planner-facing metric displays
- Possible outside-area blueprinting decision and tooling

### Input-System Extensions

- Gating or pricing restrictions on moving inputs to any side
- Alternate rules for side-specific resource identity
- More resource types beyond crude oil and uranium
- Space Age and off-world resource support
- Additional raw-source fluid/resource types if needed

### Endless-Mode Extensions

- Extra post-win research tied to expansion or expansion points
- Formal endless score or leaderboard system
- Additional challenge presets for long-form optimization runs

### Difficulty And Customization

- More difficulty presets built around harshness versus accessibility
- More world settings after playtesting identifies the right knobs
- Optional softer logistics rules
- Optional harsher ingress or movement restrictions

### Terrain, Presentation, And Theme

- Lore/theme for the void and expanding play space
- Alternate presentation such as AI-controller framing
- Waterfill/lavafill and other terrain-shaping decisions
- Possible terrain variants if ever desired after playtesting

## Needs Playtesting Before Finalizing

### Core Numbers

- Default starting square size
- Base growth-rate constants
- Size bonus strength
- Expansion-point costs
- Anchor upgrade ladder
- Dummy research costs
- Expansion-speed research scaling

### Rules That May Change

- Whether blueprint ghosts should be allowed outside the square
- Whether starter input defaults need stronger constraints
- Whether side mobility should remain free forever
- Whether some resources need differentiated pricing or unlock pacing
- Whether trains create healthy or degenerate late-game patterns
- Whether terrain-edit tools need targeted restrictions

### Quality-Of-Life Calls

- How much information the default UI should expose
- Whether some rebuild conveniences should be added
- Whether more settings belong in the initial release
