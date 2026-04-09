# Conversation Transcript

This file captures the design interview that led to the current PRD and glossary.

## Space Age Future-Direction Interview

This section records the later design interview that replaced the old single-surface PRD with the current multi-planet direction.

### Starting Intent

**User:** Grill me on future directions for this project.

### Top-Level Product Direction

**Assistant:** Should the mod become a broader overhaul or stay a challenge variant?

**User:** Just a challenge variant. Not broad overhaul. But incorporating in Space Age is planned.

**Assistant:** Should Space Age support be a separate variant or the same core mod?

**User:** Same core mod, space age aware. Also with space age it will still be expanding squares just multiple of them on different planets. Not sure about space ships yet.

### Planet Model

**Assistant:** Should progression be one shared empire-wide system or one independent square per planet?

**User:** Independent expanding squares per planet. With rocket launches like normal space age. Space ships can remain vanilla for now.

**Assistant:** Should planet unlocks stay vanilla?

**User:** Same as vanilla technologies. For unlocking. Progression on the planets themselves will be specific to the planets.

**Assistant:** Should expansion research be local per planet?

**User:** Should simply be research like on base planet Nauvis. But with the planets specific research also required. That planet + prereq. Which means that Aquilo will be all of em except prometheum.

### Rules And Tuning

**Assistant:** Should the same core rules apply everywhere or should planets get distinct square rules?

**User:** Same rules everywhere. Square expands. Costs research although square expansion will be research specific to planets.

**Assistant:** Should expansion curve and starting size be standardized?

**User:** Expansion curve tuned. Especially with playtesting. Same with starter size for planets as might need bigger or smaller for diff planets.

**Assistant:** How harsh should the starting position be?

**User:** Minimum size possible is ideal.

**Assistant:** Expert-only theoretical minimum or realistic minimum?

**User:** Expert, but tunable for an easy mode setting.

**Assistant:** Presets or many knobs?

**User:** A couple of presets.

### Resource Model

**Assistant:** Should the main puzzle remain resource purchasing or local processing?

**User:** Same raw resources for free but job is to process em.

**Assistant:** Should expansion points remain?

**User:** Resources free, resource rate ie. more ingress still costs expansion points. But specific expansion points to that planet.

**Assistant:** Should those points come only from that planet's growth?

**User:** Only that planet.

**Assistant:** Should free resources be universal or planet-native?

**User:** Native. But up to consideration when implementing as Gleba fruit for example is farmable.

**Assistant:** Should cultivated resources get free ingress?

**User:** Cultivated don't get to be free ingress.

### Interplanetary Logistics

**Assistant:** Should imports use the ingress system?

**User:** Imports are just based on normal Space Age. Ingress has nothing to do with rockets.

**Assistant:** Then should vanilla imports simply be allowed, with footprint as the constraint?

**User:** lgtm

**Assistant:** Should the square challenge begin immediately on landing?

**User:** lgtm

### Starter Layouts And Egress

**Assistant:** Should planet starter anchors be pre-owned, manually placed, or auto-placed?

**User:** Pre-placed like on default planet Nauvis. But freely moveable by stashing and placing.

**Assistant:** Hand-authored or generic per-planet layouts?

**User:** Per planet implementation.

**Assistant:** Should egress stay planet local?

**User:** Egress is only planet local. Does not effect other planets. To effect other planets need to launch rockets.

**Assistant:** What is egress for?

**User:** Egress is only in the case where mining would normally consume a material like with sulfuric acid and uranium.

**Assistant:** Should that be generic or explicit?

**User:** Make it a reusable system for more such resources, but specific resources have to choose to use it.

### Documentation And UX

**Assistant:** Where should these special rules be explained?

**User:** Just in the tips menu is okay.

**Assistant:** Should tips hold rules and runtime UI hold live facts?

**User:** lgtm

### Architecture And Delivery

**Assistant:** Should the code refactor to a planet-scoped model first?

**User:** lgtm

**Assistant:** Should the domain concept be planet-first?

**User:** Just by planet is good.

**Assistant:** Common implementation template or early custom code?

**User:** lgtm

**Assistant:** What order should planets land in?

**User:** Vulcanus -> Fulgora -> Gleba -> Aquilo is good order.

**Assistant:** Are breaking changes acceptable during alpha?

**User:** Breaking change is okay. Its space age vs vanilla anyway. Breaking changes are okay until we get out of alpha anyway.

### Final Direction

The interview converged on these decisions:

- The mod remains a challenge variant, not a broad overhaul.
- The codebase remains unified and DLC-aware.
- Nauvis remains first-class.
- Space Age support means one independent expanding square per supported planet.
- Planet unlocks remain vanilla; local square progression is planet-specific.
- Expansion research, expansion points, ingress, and optional egress are local to each planet.
- Native raw resources can be free ingress; cultivated resources stay in-square.
- Rockets and other interplanetary logistics remain vanilla Space Age systems.
- Egress is a reusable local mechanism that only specific resources opt into.
- The implementation should refactor to a planet-scoped model first, then move Nauvis, then add Vulcanus, Fulgora, Gleba, and Aquilo in that order.
- Breaking changes are acceptable during alpha.

## Initial Request

**User:** Help me spec out an idea for a factorio mod with an expanding square. The square should expand in each direction 1 tile every now and then. The rate of expansion should be related (not necessarily proportional) to the percentage of the current unlocked map taken up by active machines. It should heavily incentivise automating your factorio with good space efficiency. ie. Expansion rate is much worse when a lower ratio of the map is being used. Maybe make it logarithmic/exponential? As for resources, they should be free/come in from belts/pipes off the edge of the map. And when the map expands the sources automatically moves out and adds a belt/pipe in between to keep things working. Start off with Iron on the left, copper on the right, coal above and stone below. But the player can move the resource inputs around for free. Also water should come in from another spot too. Rate starts out at 1 yellow belt, but can be upgraded. Upgrades are done manually by the player, but cost expansion points, which are received each time the map expands. Balancing is subject to playtesting. Resource inputs are raw ores. Can also buy oil/uranium/etc later. Working machines includes assembly machines, furnaces, etc, but importantly not belts, or inserters. Bots are disabled, this is a challenge. Construction bots are okay. Grill me. I just want a spec for now, don't care about implementation yet.

## Interview Transcript

**Assistant:** What is the exact loss condition when the player runs out of room?

**User:** If they run out of room, then they just need to organise their factory better to utilise the space better. Also if it is space efficient then running out of room is good because that means you should expand quicker.

**Assistant:** What exactly counts as active machines for the space-usage ratio?

**User:** Sounds good but miners won't exist, and yes machine footprint is better, as otherwise the balancing falls apart when beacons, and similar are introduced.

**Assistant:** Should the ratio be based on machine footprint over total unlocked buildable tiles?

**User:** Sounds good, if the player could use it, then count it.

**Assistant:** Is expansion triggered continuously from the current utilization ratio, or earned in chunks after the ratio has been maintained for some time?

**User:** It should be continuous in the background, with checkpoints where it expands all at once and gives expansion points.

**Assistant:** What shape should the utilization-to-expansion curve have?

**User:** No, as its gets harder to get each additional percentage (especially the last few) each additional percentage should be more rewarding than the last. Significantly so the user can feel it.

**Assistant:** Do you want the curve to become brutally dominant at high utilization?

**User:** Stockpiling is not at issue as the percentage usage will go down after an expansion naturally. But also the curve should be somewhat exponential, with parameters to playtest later. It should feel like each percentage point increase is giving me a multiplier to expansion points per second (ie exponential)

**Assistant:** Should expansion progress use live utilization or a smoothed average?

**User:** Hmmm, hard problem, how about we just use live utilization, but if an item stops on a belt, or a fluid in a pipe takes too long to get used it gets voided/deleted. That way stockpiling is impossible to flick machines on. For items this seems easy, (also in chests just make it like spoilage but it spoilts to nothing), and for fluids just make it like lots of items, ie. each fluid tick has a spoil time if it doesn't get used. Does this seem like it solve sthe problem? Is there any other way you can think that might be better?

**Assistant:** Should we keep that, or simplify?

**User:** Okay, how about we scrap this, and just make it linear instead for now. But mark it down as a future option to explore.

**Assistant:** What is the minimum and maximum intended utilization band for normal play?

**User:** Its hard to say without playtesting, however some of my most optimized builds are still only about 54/90 utilization. And thats literally using every single square with a belt/inserter. So I wouldn't expect to get much higher in a large base. (Could technically get higher with direct insertion builds though)

So maybe 25-50%?

That said I don't think it matters too much as its linear.

**Assistant:** What should the baseline expansion rule be at 0% utilization?

**User:** 0% is 0 expansion. As it should always be possible to have above 0% (so long as the size starts big enough)

**Assistant:** What should the player’s starting square size be?

**User:** As resources are given for free should be very small. 3x3 is good, but subject to playtesting. Also 3x3 allows 100% utilization with an assembly machine, so should expand very quick anyway.

**Assistant:** Can the starting 3x3 realistically support play?

**User:** Perhaps upgrade it to 7x7 so it can fit a single turbine at the start. That way power can be used.

**Assistant:** How does power enter the map at game start?

**User:** Keep power managed by the player. 7x7 is big enough for a turbine + boiler, technically 6x6 is too with pipes, but odd numbers are nicer since there is a center. Water input should just come from map edge as said before.

Also for the last one, too constrained is not a thing here. The fun comes from the constraint, and the challenge. So long as its possible, its good. Although difficulty tuning should be an option later.

**Assistant:** Are the initial resource edge inputs fixed to the center of each side, or does the player choose?

**User:** Player can choose starting positions, but have a default that starts that way anyway and then let them change it after it starts.
Relocation is free.

**Assistant:** Can an input be moved to any side?

**User:** Any side is okay, although mark it for later as a design choice to potentially playtest, perhaps it can be an upgrade to buy later with expansion points? either way for now any side is okay.

**Assistant:** Can multiple inputs occupy the same side simultaneously?

**User:** Yes, that's fine. 4 sides isn't even enough for all the resources anyway, so its necessary

**Assistant:** How exactly does an input occupy space at the border?

**User:** Just a single tile pointing inwards. Also note, they can't be adjacent on corners as they would collide.

**Assistant:** Should every existing border input move outward automatically on expansion?

**User:** Sounds good

**Assistant:** Should the player be allowed to remove an input entirely, not just move it?

**User:** Sure

**Assistant:** How are new resource types unlocked?

**User:** Expansion points, no tech requirement as without the tech, the resource is useless anyway.

**Assistant:** Should all resources be purchasable from the start?

**User:** Sounds good. Eventually should be free to purchase whatever as you upgrade inputs though.

**Assistant:** What is the v1 unlock order for resource inputs?

**User:** I meant as the player progresses not for later versions. Start is good -> Oil -> Uranium -> Other planet stuff - Although keep the other planet stuff to a later version for now.

**Assistant:** Should purchased inputs arrive at the same default throughput regardless of resource type?

**User:** Sounds good, buy resource inputs by the belt/pump for now.

**Assistant:** Does each purchased resource come with exactly one ingress line initially?

**User:** Yes, can buy additional lines, but also are able to upgrade all lines to the next tier belt later on. (For expansion points)

**Assistant:** Is the belt-tier upgrade global across all lines?

**User:** Global, so that it becomes an optimisation problem of when to buy the upgrade. It should be a challenge to optimise.

**Assistant:** Are item and fluid throughput upgrades separate tracks?

**User:** Global for now.

**Assistant:** What exactly are expansion points spent on in v1?

**User:** First 3 is good. Last one is same as 1st anyway

**Assistant:** How many expansion points does the player gain per map expansion event?

**User:** Expansion points are gained proportionally to the number of tiles that are expanded into. Ie. expanding into 15 tiles (49-64) gives 15 points, while expanding into 49 tiles 625-576 gives 49 points.

**Assistant:** Should the reward use the full number of newly added tiles?

**User:** Yes my examples were off as we are expanding by 2 each time not 1. But yes.

Full number is good as the ratio of lanes needed to size should remain similar over time. As both usage should increase as tech unlocks and production as expansion points spent and ingress throughput upgraded.

**Assistant:** Should the time required for each expansion depend only on utilization, or also on current map size?

**User:** Expansion rate is based on tiles per second/minute. With a slight bonus as map size increases as the rate at which tiles can be expanded into increases.

**Assistant:** Should the square always expand symmetrically?

**User:** Always symmetrically

**Assistant:** What is the exact buildable area rule outside the square?

**User:** Sounds good completely inaccessable. Different lore decisions are for after v1 (could be an AI entity controlling it for example like GLADOS) or could just be underground, or literaly in a void. But lore is for later.

**Assistant:** Can the player place ghosts or blueprints outside the current square?

**User:** Decide after playtesting.

**Assistant:** Are cliffs, trees, rocks, enemy nests, and biters present inside the square?

**User:** Sounds good.

**Assistant:** Are military buildings and weapons disabled too, or merely unnecessary?

**User:** Just unneccessary.

**Assistant:** Should labs count as working-machine footprint for utilization?

**User:** Yes labs count. Only when researching though. Although allow the player to have infinite dummy researches to make them use resources if they run out of research to do.

**Assistant:** Should a machine count only while it is actively crafting right now?

**User:** Exact tick actively crafting. As it should reward good ratios that have higher utilization as there is less wastage of machine time.

**Assistant:** Should beacons count?

**User:** Beacons count so long as they are affecting an active machine.

**Assistant:** Should modules inside machines change utilization directly?

**User:** Modules don't matter.

**Assistant:** Should storage tanks and chests count?

**User:** Sounds good, don't count em

**Assistant:** Should rocket silos count?

**User:** Yes sounds good.

**Assistant:** Should Space Age-specific processing machines be in scope for v1?

**User:** v1 is just vanilla, but space age is planned support.

**Assistant:** What is the actual win condition for the scenario?

**User:** Sounds good. Win conditions don't need to change. The fun is the constraint.

**Assistant:** After the rocket is launched, should play continue indefinitely?

**User:** Indefinitely

**Assistant:** Do you want an explicit score or leaderboard metric for endless play?

**User:** Not yet, maybe later. Speedrun time is good enough for now.

**Assistant:** Should the mod expose the current utilization percentage and progress numerically in the UI?

**User:** Yes, show it.

**Assistant:** Should the UI also identify which machines currently count toward utilization?

**User:** Sounds good. Future map mode with heat map style is possible but only in later releases.

**Assistant:** Should there be any penalty for deleting and rebuilding structures?

**User:** Rebuilding is a major part of the challenge. Make it easy and free.

**Assistant:** Should deconstruction/construction bots be available?

**User:** Yes, construction deconstruction is fine. Just no logistic as that simplifies the design challenge too much.

**Assistant:** Should requester, provider, buffer, and storage logistic chests also be disabled?

**User:** Just fully disable it. Although make it a toggleable setting on world creation.

**Assistant:** Should other major difficulty-affecting parameters also be exposed as settings?

**User:** Make it configurable, with defaults as I've said.

**Assistant:** Which settings are mandatory for v1?

**User:** lgtm

**Assistant:** What is the player’s starting loadout and starting tech state?

**User:** Normal start - No rocket crash though. No miners needed either so remove burner miner. Also make it so that a wood input is available as well. From the start as that may be needed (power poles)

**Assistant:** Should the player begin with all six starter inputs already active?

**User:** lgtm

**Assistant:** Should these starter inputs cost zero expansion points?

**User:** lgtm

**Assistant:** Should starter inputs begin as exactly one line each at the base ingress tier?

**User:** lgtm

**Assistant:** What is the base ingress tier exactly in v1 for items and fluids?

**User:** lgtm

**Assistant:** Do item inputs provide a full belt or a single lane of a belt?

**User:** Single lane but one of the ingress upgrades makes it a double lane.

**Assistant:** When an item ingress becomes double-lane, does it still occupy one border anchor?

**User:** One tile width still if thats what you mean. A belt has 2 lanes anyway

**Assistant:** For fluids, should each fluid ingress also stay as a single border anchor?

**User:** Yes, although additional inputs are purchasable for them too.

**Assistant:** Should crude oil arrive as a generic crude-oil pipe input only?

**User:** Only unprocessed comes from the void.

**Assistant:** Do you want to treat wood as a special case forever?

**User:** lgtm

**Assistant:** Should the player be allowed to rotate the inward-facing direction of an input anchor freely?

**User:** Should always face inward as its useless otherwise.

**Assistant:** When moving an input anchor, should the mod preserve the connected belt/pipe if possible?

**User:** lgtm

**Assistant:** Should expansion automatically build only the single missing border belt/pipe segment?

**User:** lgtm

**Assistant:** Should undergrounds be allowed directly adjacent to a border input anchor?

**User:** Can be underground. Shouldn't matter as its not getting replaced on expansion.

**Assistant:** If the player has manually disconnected an input anchor from the factory, should expansion still extend that disconnected stub?

**User:** Yes, lgtm

**Assistant:** Should disabled inputs also move outward on expansion?

**User:** Move them outward, but don't add the belt/pipe to keep it connected.

**Assistant:** When a disabled input is re-enabled later, should it immediately spawn its inward-facing anchor/output again?

**User:** Don't think you need to? As the player can just place the belts/pipe down for it instead if they are manually reenabling?

**Assistant:** What exactly does disabled mean mechanically?

**User:** lgtm - Can also choose to stash it away though. Ie. it doesn't even exist in a ghost state on the map, but just in the backpack

**Assistant:** Should a stashed input still reserve its previous border coordinate?

**User:** Stashing removes the coordinates entirely.

**Assistant:** When a stashed input is re-placed, should it keep its previous side preference somehow?

**User:** lgtm

**Assistant:** Should there be any limit on the number of owned-but-stashed inputs?

**User:** lgtm

**Assistant:** Should bought-but-stashed lines consume any upkeep?

**User:** lgtm

**Assistant:** Should the player ever be able to refund/sell back purchased inputs or upgrades?

**User:** lgtm

**Assistant:** Should repeated purchases of the same thing scale up?

**User:** No scaling for extra lanes necessary.

**Assistant:** Do you want all additional lines for a resource to have a flat cost forever?

**User:** lgtm

**Assistant:** Should unlocking a new resource type have a separate one-time unlock cost?

**User:** lgtm

**Assistant:** Do you want different flat costs for different resource types?

**User:** lgtm but make decisions can be made with playtesting.

**Assistant:** Should global ingress upgrades affect only future lines, or all existing and future owned lines?

**User:** lgtm

**Assistant:** Should upgrades affect stashed inputs too?

**User:** of course

**Assistant:** Should the player be able to downgrade or selectively cap an input line below the global tier?

**User:** lgtm

**Assistant:** Should resource inputs be guaranteed infinite and perfectly steady?

**User:** lgtm always steady infinite. Also had an idea. Make a research into the method of making expansion quicker. ie. More expansion tiles per second rate. Also infinite research. This is not the dummy research as this one will force the player to use better science packs over time.

**Assistant:** Should this expansion-speed research multiply the base tile-growth rate, or add a flat bonus?

**User:** mutliply the growrth rate.

**Assistant:** Should this repeatable research be available from early science onward?

**User:** From early all the way to post megabase. Kinda like current mining prod, but start it even earlier with just red science.

**Assistant:** Should each level require the full set of currently available science packs, or step up in bands?

**User:** Up to playtesting. Decide later.

**Assistant:** Should there also be a repeatable research for expansion points gained per tile expanded?

**User:** No need, maybe consider for later, or even a research that just directly gives expansion later on (ie. post-win the game), but all for after v1

**Assistant:** Should the repeatable expansion-speed research be the only infinite research that matters mechanically?

**User:** Base game infinites still exist too. But it should be worth it to research.

**Assistant:** Should dummy research exist at all if vanilla infinite researches plus the new expansion-speed research already provide ongoing lab work?

**User:** Dummy research still exists, its only really needed for early game where infinite researches don't exist though. Later on it won't be needed.

**Assistant:** Should dummy research be intentionally weak and cheap?

**User:** Just make it keep labs active at the normal rate for other researches. As if there was more tech to research at the current level even if there isn't/

**Assistant:** Should the player be able to choose dummy research explicitly?

**User:** Always visible.

**Assistant:** Should there be one generic dummy research forever, or separate dummy research per science-pack tier?

**User:** Seperate tiers. Use same tiers as base game researches.

**Assistant:** Should the expansion-speed repeatable research also follow those same science-tier bands?

**User:** lgtm

**Assistant:** Should the expansion-speed research be a single continuous repeatable line?

**User:** lgtm thats the way base game infinites work too.

**Assistant:** Should there be any cap on the square size or expansion speed?

**User:** lgtm

**Assistant:** Should the map outside the square be literally non-generated/void, or generated-but-inaccessible?

**User:** lgtm

**Assistant:** Should power-generation entities count toward utilization when they are actively producing power?

**User:** Yes, but not power poles, just power generation/steam generation/etc

**Assistant:** Should offshore pumps or water intake devices count toward utilization?

**User:** lgtm. Leave water and lava etc. (the tiles not the fluid in pipes) to playtesting. Waterfill / lavafill may be a thing later but not for now.

**Assistant:** Should recipes and machines remain otherwise vanilla?

**User:** lgtm

**Assistant:** Should landfill and similar terrain-conversion tools be disabled inside the square?

**User:** lgtm shouldn't have anything even landfillable by default. But playtesting will show.

**Assistant:** Should the player be able to place rails and use trains inside the square?

**User:** Trains are fine. They are fun for this.

**Assistant:** Should cliffs, water, and other natural terrain inside the unlocked square be completely absent forever?

**User:** No cliffs, water, etc by default.

**Assistant:** Should the player spawn in the exact center of the starting square every time?

**User:** lgtm

**Assistant:** Should the starting square always stay centered on the original spawn point as it expands?

**User:** lgtm

**Assistant:** Should there be any hard reservation around the center?

**User:** lgtm

**Assistant:** Should the character’s body occupancy matter as part of the challenge?

**User:** lgtm

**Assistant:** Should the mod prevent hand-feeding and handcrafting exploits?

**User:** lgtm

**Assistant:** Should the player be able to place burner inserters/burner devices if they exist?

**User:** Just keep it vanilla but don't start with a burner miner.

**Assistant:** Should achievements be disabled/ignored?

**User:** lgtm

**Assistant:** Should the map seed matter at all?

**User:** lgtm

**Assistant:** Should there be a formal in-game tutorial or onboarding text?

**User:** Just have it be like the current factorio help/tips book.

**Assistant:** Should those tips be exhaustive and mechanical, or minimal and discovery-oriented?

**User:** Juust document how it works. No need to guide the player to strategies or anything though

## Artifact Requests

**User:** Yes you can write a prd now. There is no github repo yet, so create one with the same name as this folder The Square. Also create a ubiquitous-language document and commit that. Use gh cli. Also for user stories base the as a early game player, as a late game player, as a speedrun player etc for who is playing. And focus it on the problems that they are choosing to solve for fun.

**User:** Repo should be private

**User:** Create a feature list document too. With features sorted by when planned they are planned and loosely ordered by category otheriwse.

**User:** Lastly create a copy of this conversation with all my answers.
