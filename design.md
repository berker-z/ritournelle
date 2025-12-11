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
