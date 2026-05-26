# The Square Context

This glossary defines the ubiquitous language for The Square, a constraint-focused Factorio challenge variant. Use these terms in design sessions, issues, documentation, and code-facing discussion so gameplay concepts stay distinct from implementation details.

## Language

### Product Direction

**Challenge Variant**:
The mod as a harsh constraint-focused version of Factorio rather than a broad overhaul.
_Avoid_: Total conversion, overhaul mode

**Vanilla-First Support**:
The commitment that Nauvis-only play remains a complete first-class mode.
_Avoid_: Legacy mode, fallback mode

**Space Age-Aware Support**:
The extension of the same mod rules across supported Space Age planets.
_Avoid_: Separate DLC version, fork

### Planet Model

**Planet**:
The primary gameplay unit that owns one local square challenge and its progression.
_Avoid_: Surface, map, level

**Planet Instance**:
The runtime state for one managed **Planet** in the current save.
_Avoid_: Bootstrap, singleton state

**Planet Config**:
The static rules and tuning values that define how one **Planet** behaves.
_Avoid_: Special case code, hardcoded planet logic

**Planet Progression**:
The local research, square size, and economy state for one **Planet**.
_Avoid_: Global progress, empire progress

### Square And Growth

**Square**:
The current unlocked playable area on one **Planet**.
_Avoid_: Base, arena, map

**Boundary**:
The outer edge of a **Planet**'s **Square** where **Managed Lines** may be placed.
_Avoid_: Border zone, wall

**Void**:
The inaccessible area outside a **Planet**'s **Square**.
_Avoid_: Outside map, wilderness

**Ring**:
The outer layer of tiles added by one completed square expansion on one **Planet**.
_Avoid_: Expansion layer, band

**Square Expansion**:
The repeatable **Planet**-local research line that unlocks one new **Ring**.
_Avoid_: Growth meter, expansion tick

**Planet-Local Expansion**:
A square growth event that affects only the current **Planet**.
_Avoid_: Global expansion, empire growth

### Economy And Throughput

**Managed Line Tier**:
The current throughput level shared by a **Planet**'s owned **Managed Lines**, including ingress and matching egress tiers.
_Avoid_: Anchor tier, ingress tier, belt tier, pipe tier, lane tier

**Managed Line Upgrade**:
A global research step that raises the throughput of owned **Managed Lines** without changing ownership or placement rules. Turbo Managed Lines are the Space Age final tier for both ingress and egress.
_Avoid_: Anchor upgrade, ingress upgrade, output upgrade

**Difficulty Preset**:
A named package of tuning values that changes harshness without changing core rules.
_Avoid_: Rule set, mode variant

**Expert Preset**:
The intended default high-harshness tuning for the mod.
_Avoid_: Normal mode, standard mode

**Easy Preset**:
A softer tuning preset that mainly increases starting area and eases pacing.
_Avoid_: Casual mode, sandbox mode

### Managed Logistics

**Managed Line**:
A **Planet**-local border line owned by the mod, either ingress or egress.
_Avoid_: Port, connector, lane

**Ingress Line**:
A **Managed Line** that brings a **Planet**-native external resource into the **Square**.
_Avoid_: Input line, source

**Egress Line**:
A **Managed Line** that sends a specific local support resource out of the **Square**.
_Avoid_: Output line, export line

**Anchor**:
A physical **Boundary** slot on the anchor ring where a **Managed Line** can be placed.
_Avoid_: Managed Line, port, connector

**Starter Layout**:
The authored initial placement of a **Planet**'s pre-owned free **Managed Lines** into anchor slots.
_Avoid_: Default spread, generated layout

**Stashed Line**:
An owned **Managed Line** with no current **Anchor** on the map.
_Avoid_: Disabled line, hidden line

**Anchor Slot Configuration**:
The flow where clicking an empty **Anchor** opens a configuration menu, then choosing an ingress or egress resource consumes one matching **Managed Line** item from the player's inventory.
_Avoid_: Cursor placement, placement preview, ghost placement

**Managed Line Shift**:
The automatic outward movement of a placed **Managed Line** from one anchor slot to the next after a **Ring** is added.
_Avoid_: Anchor shift, auto-move, border slide

### Resource Model

**Native Free Resource**:
A **Planet**-native raw resource granted as free ingress on that **Planet**.
_Avoid_: Universal starter resource, free import

**Cultivated Resource**:
A resource that vanilla expects the player to grow or farm inside the **Square**.
_Avoid_: Native crop ingress, free farm input

**External Sourcing**:
The act of bringing a **Planet**-native raw resource into the **Square** through ingress.
_Avoid_: Importing, shipping

**Support Material Dependency**:
A rule where one external source requires a specific local material to be sent out through egress.
_Avoid_: Extraction tax, hidden requirement

**Opt-In Egress Resource**:
A resource definition that explicitly uses the generic egress system.
_Avoid_: Automatic egress, default output

### Interplanetary Logistics

**Vanilla Rocket Logistics**:
The unmodified Space Age system for moving items between planets.
_Avoid_: Ingress import, custom shipping

**Planet-Local Logistics**:
Managed ingress and egress that affect only one **Planet**'s **Square**.
_Avoid_: Interplanetary logistics, rocket network

**Rocket Footprint Pressure**:
The local space cost of rocket and landing infrastructure inside a **Planet**'s **Square**.
_Avoid_: Free logistics, off-map transport

### Delivery Strategy

**Planet-Scoped Refactor**:
The architectural change from one global bootstrap model to per-**Planet** state and rules.
_Avoid_: Minor extension, small patch

**Proof Planet**:
The first non-Nauvis **Planet** used to prove the new shared model.
_Avoid_: Pilot map, demo case

**Alpha Breaking Change**:
An intentional compatibility break accepted in service of cleaner architecture during alpha.
_Avoid_: Regression, accidental break

## Relationships

- A **Challenge Variant** may support both **Vanilla-First Support** and **Space Age-Aware Support** without becoming a separate product.
- One **Planet** owns exactly one local **Square**, one **Planet Config**, and one **Planet Progression**.
- One completed **Square Expansion** adds exactly one **Ring** to one **Planet**.
- A **Difficulty Preset** changes tuning such as starting size and pacing without changing the invariant Square rules.
- A **Starter Layout** places a **Planet**'s initial **Managed Lines** on its **Boundary**.
- **Anchor Slot Configuration** places one **Managed Line** into one empty **Anchor** only after the matching inventory item is consumed.
- A **Native Free Resource** enters through an **Ingress Line**; a **Cultivated Resource** stays inside the **Square**.
- A **Support Material Dependency** is satisfied by an **Opt-In Egress Resource** through an **Egress Line**.
- **Planet-Local Logistics** never replace **Vanilla Rocket Logistics**.
- **Rocket Footprint Pressure** is one of the ways vanilla Space Age systems still consume scarce local **Square** space.
- The **Planet-Scoped Refactor** should be proven first on Nauvis and then on a **Proof Planet**.

## Example Dialogue

> **Dev:** "If Vulcanus is the first **Proof Planet**, does it get a different ruleset from Nauvis?"
>
> **Domain expert:** "No. It uses the same core **Challenge Variant** rules, but with its own **Planet Config** for starting size, native resources, and research pacing."
>
> **Dev:** "So a rocket import to Vulcanus should consume an **Ingress Line** there?"
>
> **Domain expert:** "No. That's **Vanilla Rocket Logistics**. **Ingress Lines** are only for **Planet-Local Logistics** and native external sourcing."
>
> **Dev:** "What about something like sulfuric acid supporting extraction?"
>
> **Domain expert:** "That's a **Support Material Dependency**. The affected resource explicitly opts into the generic **Egress Line** system on that **Planet**."

## Flagged Ambiguities

- "planet" and "surface" were starting to blur together; use **Planet** for the gameplay concept and keep raw surface handling as an internal implementation detail.
- "expansion" was previously used for both the research and the area gain; use **Square Expansion** for the research line and **Ring** or **Planet-Local Expansion** for the resulting map change.
- "free resources" was too vague; use **Native Free Resource** for planet-native raw ingress and **Cultivated Resource** for resources that must stay in-square.
- "imports" was ambiguous between local external sourcing and interplanetary shipping; use **External Sourcing** for ingress and **Vanilla Rocket Logistics** for off-planet movement.
- "egress" risked meaning any export; use **Egress Line** only for **Planet**-local support-material rules, not for interplanetary trade.
- "ghost" conflicts with Factorio ghost entities that construction bots can build; use **Anchor Slot Configuration** for the menu-driven anchor slot flow.
