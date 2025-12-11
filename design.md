
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
- **Project wiring**: `project.godot` autoloads `SaveSystem`, `GameState`, `EncounterSystem`, `CraftingSystem`; main scene `scenes/Main.tscn` is a text harness with account/character selection (hidden after choose), travel/node movement, actions (harvest, combat, return, craft, rest, save), plus full-screen overlays for Inventory and Skills; logic in `scenes/Main.gd`.
- **Accounts & saves**: Per-account folder under `userdata/<account>/`; one JSON per character plus `sharedstash.json` (inventory, unused in UI). No passwords; names sanitized. Save layout example: `userdata/berkerz/berkerz.json`, `userdata/berkerz/testo.json`, `userdata/berkerz/sharedstash.json`.
- **Character model** (`scripts/core/character.gd`): `name`, `background` (harvester/fighter), `location` (e.g., `town` or `lake>node_id`), `stats` (`stats.gd`: HP/energy max 100, power/defense/craft/speed), skills loaded from `data/skills.gd` (harvest: harvest.fishing/mining/woodcutting/foraging/hunting; combat: combat.swordsmanship/archery/unarmed; craft: craft.crafting), `inventory` (`inventory.gd`: id→count), `equipped` slots (`weapon`, `hat`, `armor`). New characters start with swordsmanship 1, 100 camping supplies, two swords (rusty, wooden), and test armor pieces (leather hat/armor) for equip flow.
- **Skills registry** (`data/skills.gd`): Categories/ids with `all_ids()` to initialize characters: combat.swordsmanship/archery/unarmed; harvest.fishing/mining/woodcutting/foraging/hunting; craft.crafting.
- **Items** (`data/items.gd`, `item_data.gd`): Items define `type` (weapon/hat/armor/projectile/material/consumable), optional `slot` for equip targets, and optional `skill` used for combat XP routing. Examples: `rusty_sword`, `wooden_sword` (slot weapon, skill combat.swordsmanship), `arrow` (projectile), `leather_hat`/`leather_armor` (slots hat/armor), `camping_supplies` (rest), `log`/`herb` materials.
- **Maps/Encounters** (`data/maps.gd`, `map_node.gd`, `encounter_system.gd`): Submaps `town`, `lake`, `forest`, `mountain`; town has no nodes. Travel costs: `SUBMAP_TRAVEL_COSTS` (lake/forest/mountain 10, town 10). Node movement costs: `abs(distance diff) * SUBMAP_NODE_COSTS[submap]` (lake/forest 2, mountain 3). Node actions (harvest/combat) consume node energy; travel cost is separate. XP routing: harvest XP by submap (harvest.*), combat XP by equipped weapon skill (combat.*) or unarmed if no weapon.
- **Crafting** (`data/recipes.gd`, `recipe.gd`, `crafting_system.gd`): Recipes define inputs/output/time/XP; queued jobs grant output + XP on completion; queue resets on account/character switch (not persisted).
- **Orchestration** (`game_state.gd`): Manages account/character lifecycle, seeds starter gear/supplies, tracks location, handles travel/node movement, equips/unequips items, inventory listing helpers for UI, and saves after actions. Resting consumes 1 camping supply.

## Recent Changes (for iteration tracking)
- Inventory/Skills overlays: “Inventory” opens a full-screen list for equipped slots (weapon/hat/armor) with click-to-unequip, an equipment list (weapons/armor/hats/projectiles) with click-to-equip, and a read-only items list; “Skills” shows skill levels; status panel no longer dumps the skill list.
- Equipment data: items now declare an optional `slot`; new items include `rusty_sword`, `wooden_sword`, `arrow`, `leather_hat`, `leather_armor`. Items of type weapon/hat/armor/projectile are treated as equipment in UI.
- Starter kit: new characters get swordsmanship 1, 100 camping supplies, and two test swords (rusty + wooden) for equip/unequip flow.
- Travel/combat/harvest: unchanged from prior iteration—travel cost by submap/node distance; node actions consume node energy and grant XP based on submap (harvest.*) or equipped weapon skill/unarmed.

## Roadmap / Next Refinements
- Apply skills/stats to outcomes: fold gather/power/speed into yields, damage, timers; tune XP curves.
- Persist active crafting queue and restore on load; optionally tick when idle by elapsed real time.
- Expose shared stash: move items between character and stash; allow stash-based crafting.
- Enrich content: more nodes/recipes/backgrounds with distinct starting gear/stats; link items to bonuses; add bows/projectiles and more equipment slots.
- Add energy regen over time or via rest/sleep timers; log session durations for idle play.
- Add failure states/recovery flows (e.g., lose carried items on defeat, retrieve via low-risk nodes).

## File & API Guide (What to Edit/Call)
- **Scenes/UI**
  - `scenes/Main.tscn` / `scenes/Main.gd`: Text harness UI. Buttons: Travel to Submap, Move to Node, Harvest, Combat, Return to Town, Inventory (opens overlay), Skills (opens overlay), Craft (plank), Rest, Save & Exit. Account/character selectors hide after selection; overlays are full-screen panels with close buttons.
- **Core Models** (`scripts/core/`)
  - `character.gd`: Fields `name`, `background`, `location`, `stats`, `skills` (from `data/skills.gd`), `inventory`, `equipped` slots (`weapon`, `hat`, `armor`). Helpers: `new_with_background`, `equip_item`/`unequip_slot`, `get_equipped_weapon`, `get_equipped_items`, `to_dict/from_dict`. Background currently sets swordsmanship 1.
  - `stats.gd`: HP/energy caps and values, power/defense/craft/speed; rest/damage/energy consumption; serialization.
  - `skill.gd`: Levels/XP; `add_xp`, `to_dict/from_dict`.
  - `inventory.gd`: `{item_id: count}` map; add/remove/can_afford/deduct; `to_dict/from_dict`.
  - `item_data.gd`: Item metadata (`slot`, `skill`, etc.). Extend here for bonuses/types.
  - `map_node.gd`: Node data (id, submap, type, tier, energy_cost, rewards, xp_reward, distance, damage_range); `to_dict`.
  - `recipe.gd`: Recipe data for crafting (inputs/output/time/xp_reward).
  - `account.gd`: Holds characters, active index, shared_stash (Inventory); serialization.
  - `data/skills.gd`: Skill registry grouped by category (`combat.*`, `harvest.*`, `craft.*`); `all_ids()` returns a flat list used to initialize characters.
- **Systems** (`scripts/systems/`)
  - `game_state.gd`: Orchestrator. Key methods:
    - Account/character lifecycle: `create_account`, `select_account`, `create_character`, `select_character_by_name`, `delete_character`.
    - Travel/movement: `travel_to_submap(submap)`, `move_to_node(submap, node_id)`, `return_to_town()`.
    - Actions: `act_in_current_node(action_type)` with "harvest"/"combat" mapped to skills; `equip_item(item_id)`/`unequip(slot)`/`equip_sword()` convenience, `start_craft(recipe_id)`, `rest()`, `tick(delta)` for crafting jobs.
    - Helpers: `list_submaps`, `list_nodes`, `get_location_text`, `get_current_submap`, `get_current_node`, `get_equipped_entries()`, `get_equipment_inventory_entries()`, `get_item_inventory_entries()`.
  - `encounter_system.gd`: Resolves a node (consumes node.energy_cost, applies damage/rewards/xp). Energy costs for travel are handled in `game_state`; node.energy_cost used for actions.
  - `crafting_system.gd`: Queue-based crafting (`start_job`, `tick`, `has_jobs`, `reset`).
  - `save_system.gd`: Per-account saves under `res://userdata/<account>/` (characters + `sharedstash.json`); helpers to list/create accounts, load/save characters, stash.
- **Data** (`data/`)
  - `maps.gd`: Submap definitions (`town`, `lake`, `forest`, `mountain`) with 5 nodes each (town empty). Distances drive travel energy. Edit node rewards/xp here.
  - `recipes.gd`: Sample recipes (plank, tonic). Extend as needed.
  - `items.gd`: Item metadata registry (types: weapon/hat/armor/projectile/material/consumable). Equipment declares `slot` and optional `skill` (used for combat XP routing).
- **Config**
  - `project.godot`: Autoloads systems; main scene `scenes/Main.tscn`.

### How to Use (CLI/UI)
1) Launch: `godot4 --path . --run`. Create/select account and character. Background choice currently just sets swordsmanship 1.
2) Travel: pick a submap -> “Travel to Submap” (cost: exit from current node * zone node cost + submap travel cost).
3) Move to Node: pick node -> “Move to Node” (cost: abs(distance diff) * zone node cost). Town has no nodes.
4) Inventory: click “Inventory” to open the overlay. Top list shows equipped slots (weapon/hat/armor); click to unequip. Middle list shows equipment (weapon/hat/armor/projectile items) and equips on click; bottom list shows other items.
5) Act: from a node, use Harvest (XP based on submap) or Combat (XP based on equipped weapon skill; unarmed if no weapon). Node.energy_cost is consumed here.
6) Return: “Return to Town” pays exit cost + town travel cost.
7) Rest: costs 1 camping supply, restores HP/energy; Craft runs plank recipe; Save & Exit persists active character. Use “Skills” to view current levels.
