# Design Overview

You play as a single character card who gains skills, inventory, and progression through daily expeditions and crafting. The game is deterministic and legible—every action is inspectable. Time, energy, and resource management are central, designed for mobile idling and asynchronous play, with potential economic interactions later.

## Game Structure
1. **Character Card**  
   - Name and background (class/origin) define starting stats and skills (e.g., Miner, Wanderer, Witch's Apprentice).  
   - Skills (Fishing, Combat, Crafting, etc.), inventory (equip slots + backpack), and daily energy/action points.
2. **Home**  
   - Bed to rest and recover energy.  
   - Crafting stations to process raw materials.  
   - Storage chest with limited capacity.  
   - Decor optional; expansions add rooms, upgrade tools, and bonuses.
3. **Town (Shared Hub)**  
   - Market to sell loot or buy basic gear.  
   - Job Board with procedurally generated contracts.  
   - Inn to recover energy for coin.  
   - Public crafting stations with limited daily uses (replaced by personal ones later).  
   - Can be visualized as menus or a static town map.
4. **Overworld Map**  
   - Node-based navigation; tap to send expeditions.  
   - Zones with sub-zones: Lake (fishing, herbs), Forest (wood, mushrooms, beasts), Mountains (mining, ambushes), Ruins/Caves (combat-focused, higher risk/reward).  
   - Each node defines energy cost, time delay, yield table, and risk (encounter chance and enemy tier).

## Core Loops
- **Harvest Loop**: Travel to a zone (energy cost), wait (active or idle), receive yield with possible encounter, return → craft → sell or store.  
- **Combat Loop**: Encounter triggers during expedition, auto-resolves using equipment, skills, RNG, and terrain modifiers. Win yields loot; loss causes partial or total carried-item loss.  
- **Crafting Loop**: Combine materials at a station, wait for a timer, receive output (tools, gear, potions) to use, sell, or upgrade.

## Systems
- **Stats & Skills**: Level up through use (Runescape-style); influence harvesting yield, combat efficiency, crafting success.  
- **Energy System**: Energy regenerates over time or by sleeping; encourages daily check-ins, not grinding.  
- **Failure State**: No death; losing an expedition risks losing carried items. Recovery is always possible via low-risk zones or market purchases.  
- **Progression**: Unlock new zones, expand home, learn recipes, gain tiered equipment, and possibly reputation/favor.  
- **Optional Additions**: Pets/followers for expeditions, player market for asynchronous economy, events/seasons with modifiers, lore system (journals/notes), cosmetics/supporter pass without pay-to-win.

## Current Design & Structure (Single Source of Truth)
- **Project wiring**: `project.godot` autoloads `SaveSystem`, `GameState`, `EncounterSystem`, `CraftingSystem`; main scene `scenes/Main.tscn` is a text harness with account/character selection (hidden after choose), travel/node movement, and action buttons (harvest, combat, return to town, craft, rest, save & exit); logic in `scenes/Main.gd`.
- **Accounts & saves**: Per-account folder under `userdata/<account>/`; one JSON per character plus `sharedstash.json` (inventory, unused in UI). No passwords; names sanitized. Save layout example: `userdata/berkerz/berkerz.json`, `userdata/berkerz/testo.json`, `userdata/berkerz/sharedstash.json`.
- **Character model** (`scripts/core/character.gd`): `name`, `background` (harvester/fighter), `location` (e.g., `town` or `lake>node_id`), `stats` (`stats.gd`: HP/energy max now 100, power/defense/gather/craft/speed), `skills` (`skill.gd`: combat/gather/craft XP/level), `inventory` (`inventory.gd`: id→count). Background sets a starting skill level. Item metadata in `data/items.gd` (id, name, type, rarity, value, bonuses).
- **Items**: Added `camping_supplies` (consumable, stackable) used for resting; starters give 100 supplies plus basic materials.
- **Maps/Encounters** (`data/maps.gd`, `map_node.gd`, `encounter_system.gd`): world has submaps `town`, `lake`, `forest`, `mountain`. Town has no nodes. Traveling to a submap costs 10 energy; nodes are indexed arrays (1–5) and moving from entrance to node N costs `(N)*2` energy. Moving between nodes uses exit-cost (current node index *2) + entry-cost (target index *2); returning to town adds +10. Node actions (harvest/combat) consume the node’s own energy cost; travel cost is separate. Nodes carry rewards/XP/damage; encounter resolver applies damage/rewards; gather/power not yet in rolls.
- **Crafting** (`data/recipes.gd`, `recipe.gd`, `crafting_system.gd`): recipes define inputs/output/time/XP; jobs queue with timers and grant output + XP on completion. Queue resets when switching account/character; not persisted yet.
- **Orchestration** (`game_state.gd`): manages current account selection, character lifecycle, seeds starter items/supplies, tracks location, handles travel and node movement, and saves after actions. Resting consumes 1 camping supply.

## Recent Changes (for iteration tracking)
- Wiped old saves (`userdata/`); new save layout per account/character remains.
- Added camping supplies item; seed 100 supplies on character creation; rest consumes 1 supply.
- Set max energy to 100; travel to submaps costs 10 energy; node travel cost uses distance-based steps (index * 2); node actions consume node energy.
- Replaced nodes data with submaps (`town`, `lake`, `forest`, `mountain`) each with 5 distance-graded nodes (town has none); location is persisted (e.g., `town`, `lake>deepwater`).
- Text harness updated for account → character → travel/node flow; nodes hidden/disabled until you travel to a submap; added move/harvest/combat/return controls and removed old quick buttons.

## Roadmap / Next Refinements
- Apply skills/stats to outcomes: fold gather/power/speed into yields, damage, timers; tune XP curves.
- Persist active crafting queue and restore on load; optionally tick when idle by elapsed real time.
- Expose shared stash: move items between character and stash; allow stash-based crafting.
- Enrich content: more nodes/recipes/backgrounds with distinct starting gear/stats; link items to bonuses.
- Add energy regen over time or via rest/sleep timers; log session durations for idle play.
- Add failure states/recovery flows (e.g., lose carried items on defeat, retrieve via low-risk nodes).
