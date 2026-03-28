# Ubiquitous Language

## Core World Model

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Square** | The entire currently unlocked playable area. | Base, map, arena |
| **Boundary** | The current outer edge of the Square. | Wall, border zone |
| **Ring Expansion** | One growth event that adds exactly one tile on every side of the Square. | Expansion tick, map pulse |
| **Void** | The inaccessible non-play-space outside the Square. | Outside map, wilderness |
| **Unlocked Tile** | A buildable tile currently inside the Square. | Owned tile, active tile |
| **Newly Unlocked Tiles** | The set of tiles added by the most recent Ring Expansion. | Expansion tiles, gained area |

## Growth And Economy

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Utilization** | The percentage of Unlocked Tiles occupied by counted active-machine footprint. | Efficiency, density |
| **Active Footprint** | The tile area of counted entities that are active on the current tick. | Used tiles, productive area |
| **Growth Rate** | The current tile-growth speed derived from Utilization and modifiers. | Expansion rate, EPS |
| **Stored Growth Progress** | Accumulated progress toward the next Ring Expansion. | Expansion bar, saved progress |
| **Expansion Points** | The currency awarded when the Square grows and spent on ingress growth. | Points, expansion currency |
| **Ingress Tier** | The current global throughput level applied to all owned input lines. | Belt tier, pipe tier, lane tier |
| **Line Cost** | The Expansion Point price of buying one additional input line. | Lane cost, input price |

## Inputs And Resources

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Input Line** | One owned resource ingress that can be placed on the Boundary. | Lane, source, port |
| **Input Anchor** | The single Boundary tile where an Input Line enters the Square. | Input tile, port tile |
| **Starter Inputs** | The free initial Input Lines available at game start. | Starting resources, default lines |
| **Unlocked Resource** | A resource type for which the player owns at least one Input Line. | Bought resource, enabled resource |
| **Relocation** | Moving an Input Line to a new side and coordinate on the Boundary. | Repositioning, moving input |
| **Disabled Input** | An owned Input Line that remains assigned but emits nothing. | Turned-off line, inactive input |
| **Stashed Input** | An owned Input Line removed from the map and holding no coordinate. | Backpack input, stored line |
| **Raw Input** | A source resource that can arrive directly from outside the Square. | Free resource, void resource |

## Counted Production

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Counted Machine** | An entity class eligible to contribute to Active Footprint when active. | Working machine, productive entity |
| **Active Machine** | A Counted Machine that is actively crafting, researching, processing, launching, or generating power on the current tick. | Busy machine, running machine |
| **Support Infrastructure** | Non-counted entities that enable production without contributing directly to Active Footprint. | Utility infrastructure, logistics footprint |
| **Power Generation** | Counted power-producing or steam-producing activity inside the Square. | Utility power, grid production |
| **Dummy Research** | A repeatable research that exists only to keep labs meaningfully active at a current science tier. | Filler research, placeholder tech |
| **Expansion-Speed Research** | The custom repeatable research that multiplies Growth Rate. | Expansion tech, growth research |

## Challenge Framing

| Term | Definition | Aliases to avoid |
| --- | --- | --- |
| **Compression Challenge** | The deliberate gameplay pressure to fit more effective production into less space. | Difficulty, cramped mode |
| **Rebuild Loop** | The repeated act of tearing down and improving the factory as the Square evolves. | Refactor cycle, redesign loop |
| **Speedrun Benchmark** | Rocket launch time used as the natural competitive measure for a run. | Score, ranking |

## Relationships

- The **Square** is bounded by exactly one **Boundary**.
- A **Ring Expansion** increases the **Square** by one tile on every side and creates a set of **Newly Unlocked Tiles**.
- **Expansion Points** awarded from a **Ring Expansion** equal the number of **Newly Unlocked Tiles**.
- **Utilization** is calculated from **Active Footprint** divided by all **Unlocked Tiles**.
- **Active Footprint** is composed only of tiles occupied by **Active Machines** that belong to a **Counted Machine** class.
- Every placed **Input Line** owns exactly one **Input Anchor**.
- A **Disabled Input** keeps ownership of the **Input Line** but does not emit resources.
- A **Stashed Input** keeps ownership of the **Input Line** and releases any previous **Input Anchor** coordinate.
- The current **Ingress Tier** applies to all owned **Input Lines**, including **Stashed Inputs**.
- **Expansion-Speed Research** increases **Growth Rate**, while **Dummy Research** only preserves lab activity.

## Example Dialogue

> **Dev:** "When the **Square** grows, do I move every **Input Anchor** even if the line is disconnected from the factory?"
>
> **Domain expert:** "Yes. Any enabled **Input Line** follows the **Boundary** during a **Ring Expansion**. Only disabled or stashed lines skip auto-connection behavior."
>
> **Dev:** "And **Utilization** only counts the footprint of an **Active Machine**, not belts or chests around it?"
>
> **Domain expert:** "Correct. Belts, inserters, pipes, poles, and storage are **Support Infrastructure**. They consume space but never contribute to **Active Footprint**."
>
> **Dev:** "So if I buy another crude oil **Input Line**, it uses the current **Ingress Tier** immediately even if I kept it as a **Stashed Input** until later?"
>
> **Domain expert:** "Exactly. **Ingress Tier** is global. Placement timing changes layout options, not throughput level."

## Flagged Ambiguities

- "expansion rate" was used for both continuous **Growth Rate** and discrete growth events; use **Growth Rate** for continuous progress and **Ring Expansion** for the event.
- "machine utilization" and "map utilization" can be confused; use **Utilization** only for the map-wide active-footprint ratio and use "machine uptime" when referring to how often a specific machine is active.
- "line", "lane", and "input" were used interchangeably; use **Input Line** for the owned resource ingress object and reserve "lane" for belt-lane throughput.
- "disabled" and "stashed" are distinct concepts; use **Disabled Input** for an off-but-placed line and **Stashed Input** for an owned line with no current coordinate.
