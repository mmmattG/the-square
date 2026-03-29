# Ubiquitous Language

## Core World Model

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Square** | The entire currently unlocked playable area. | Base, map, arena |
| **Boundary** | The current outer edge of the Square where managed lines may be placed. | Border zone, wall |
| **Void** | The inaccessible non-play-space outside the Square. | Outside map, wilderness |
| **Unlocked Tile** | A buildable tile currently inside the Square. | Owned tile, active tile |
| **Ring** | The outermost layer of tiles added by one growth step of the Square. | Expansion layer, outer band |
| **Newly Unlocked Tiles** | The set of tiles in the newest Ring. | Expansion tiles, gained area |

## Expansion And Progression

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Square Expansion** | The repeatable research line that grows the Square by one Ring per completed level. | Growth meter, expansion tick |
| **Expansion Level** | One completed level of **Square Expansion** research. | Research tick, growth stage |
| **Expansion Points** | The currency awarded when a Ring is unlocked and spent on buying additional managed lines. | Points, expansion currency |
| **Tiles per Research Pack** | The world setting that controls how much science each future **Expansion Level** costs relative to its Ring reward. | Expansion cost, science ratio |
| **Expansion Reward** | The **Expansion Points** awarded for a completed **Expansion Level**, equal to its **Newly Unlocked Tiles**. | Tile payout, ring payout |

## Managed Lines

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Managed Line** | An owned border line controlled by the mod, either ingress or egress. | Port, lane, connector |
| **Ingress Line** | A **Managed Line** that brings a raw resource into the Square from the Void. | Input line, source |
| **Egress Line** | A **Managed Line** that removes a managed output from the Square into the Void. | Output line, drain |
| **Anchor** | The single Boundary tile where a **Managed Line** is currently placed. | Port tile, input tile |
| **Starter Ingress** | A free **Ingress Line** owned at the start of a run. | Starting resource, default line |
| **Unlocked Resource** | A resource type for which the player owns at least one **Managed Line**. | Bought resource, enabled resource |
| **Stashed Line** | An owned **Managed Line** with no current Anchor on the map. | Disabled line, backpack line |
| **Relocation** | Moving a **Managed Line** to a new valid Anchor on the Boundary. | Repositioning, moving input |
| **Anchor Shift** | The automatic outward movement of a placed **Managed Line** when the Square expands. | Auto-move, border slide |

## Throughput And Research

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Ingress Tier** | The current global throughput level shared by all owned ingress lines. | Belt tier, pipe tier, lane tier |
| **Dual-Lane Ingress** | The research upgrade that makes item ingress use both yellow-belt lanes while keeping one Anchor tile. | Yellow upgrade, second lane |
| **Red Ingress** | The research upgrade that raises item ingress to red-belt throughput and fluid ingress to the matching tier. | Red tier, tier 3 ingress |
| **Blue Ingress** | The research upgrade that raises item ingress to blue-belt throughput and fluid ingress to the matching tier. | Blue tier, tier 4 ingress |
| **Line Cost** | The **Expansion Point** price of buying one additional ingress or egress line. | Lane cost, input price |

## Resource Rules

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Raw Resource** | A resource type allowed to enter directly through an **Ingress Line** from outside the Square. | Free resource, external item |
| **Managed Output** | A resource type intentionally removed through an **Egress Line** because another rule depends on it. | Output drain, exported resource |
| **Sulfuric Acid Egress** | The managed sulfuric acid output line used to enable uranium ingress. | Acid drain, uranium output |
| **Uranium Allowance** | The shared uranium-ore budget created by actual sulfuric acid egress and consumed by all active uranium ingress lines. | Uranium budget, acid credit |

## Counted Production

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Counted Machine** | An entity class eligible to contribute to utilization when active. | Working machine, productive entity |
| **Active Machine** | A **Counted Machine** that is actively crafting, researching, processing, launching, or generating power on the current tick. | Busy machine, running machine |
| **Active Footprint** | The tile area occupied by currently active counted machines. | Used tiles, productive area |
| **Utilization** | The ratio of **Active Footprint** to all **Unlocked Tiles** in the Square. | Efficiency, density |
| **Support Infrastructure** | Non-counted entities that enable production without contributing to Utilization. | Utility infrastructure, logistics footprint |

## Challenge Framing

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Compression Challenge** | The deliberate pressure to fit more effective production into a tightly bounded Square. | Difficulty, cramped mode |
| **Rebuild Loop** | The repeated act of tearing down and improving the factory as the Square grows. | Refactor cycle, redesign loop |
| **Rocket Benchmark** | Vanilla rocket launch time used as the default comparative measure for a run. | Score, ranking |

## Relationships

- The **Square** is bounded by exactly one **Boundary** and everything outside it is **Void**.
- One completed **Expansion Level** of **Square Expansion** unlocks exactly one new **Ring**.
- The **Expansion Reward** for an **Expansion Level** equals the number of **Newly Unlocked Tiles** in that Ring.
- Every placed **Managed Line** owns exactly one **Anchor**; a **Stashed Line** owns none.
- An **Ingress Tier** applies globally to all owned ingress lines, including **Stashed Lines**.
- **Dual-Lane Ingress**, **Red Ingress**, and **Blue Ingress** each raise the global **Ingress Tier**.
- **Raw Resources** enter through **Ingress Lines**; **Managed Outputs** leave through **Egress Lines**.
- **Sulfuric Acid Egress** creates **Uranium Allowance**, and all active uranium ingress lines draw from that shared pool.
- **Utilization** is calculated from **Active Footprint** divided by all **Unlocked Tiles**.
- **Support Infrastructure** consumes space inside the **Square** but never contributes to **Active Footprint**.

## Example Dialogue

> **Dev:** "When **Square Expansion** level 12 completes, do all placed **Ingress Lines** move automatically?"
>
> **Domain expert:** "Yes. Each placed **Managed Line** performs an **Anchor Shift** to the new **Boundary**. A **Stashed Line** stays owned but has no map presence to move."
>
> **Dev:** "If I finish **Red Ingress**, do I need to replace older anchors to get the faster throughput?"
>
> **Domain expert:** "No. **Ingress Tier** is global, so every owned ingress line upgrades immediately, including ones that are currently stashed."
>
> **Dev:** "Why does uranium stop if the sulfuric line is idle?"
>
> **Domain expert:** "Because uranium ingress spends from the shared **Uranium Allowance**, and that allowance only exists when **Sulfuric Acid Egress** is actually removing acid from the factory."

## Flagged Ambiguities

- "expansion" was used for both the research and the map-change event; use **Square Expansion** for the research line and **Expansion Level** for one completed level that causes the growth.
- "input", "ingress", and "line" were used interchangeably; use **Ingress Line** for the owned resource entry object and reserve "input" for informal player-facing prose only when precision is not needed.
- "disabled" previously covered multiple states; use **Stashed Line** for an owned line with no current Anchor, and avoid "disabled" unless you mean a placed line that is temporarily not flowing.
- "tier" was previously too vague; use **Ingress Tier** for the shared throughput state, and use **Dual-Lane Ingress**, **Red Ingress**, or **Blue Ingress** for the specific upgrade researches.
- "reward" and "points" were blurred together; use **Expansion Reward** for the event payout and **Expansion Points** for the currency balance itself.
