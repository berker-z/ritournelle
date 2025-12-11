
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
- **Project wiring**: `project.godot` autoloads `SaveSystem`, `GameState`, `EncounterSystem`, `CraftingSystem`; main scene `scenes/Main.tscn` is a text harness with account/character selection (hidden after choose), log/status, and a Map button. Navigation now uses full-screen overlays: `MapPanel` (choose town/lake/forest/mountain), `TownPanel`, and `ZonePanel` (list nodes, move to node, harvest/combat/return/rest/craft). A reusable `ActionBar` (Inventory/Skills/Save & Exit) sits on Main and all overlays. Inventory/Skills remain full-screen overlays; logic is still centralized in `scenes/Main.gd`.
- **Accounts & saves**: Per-account folder under `userdata/<account>/`; one JSON per character plus `sharedstash.json` (inventory, unused in UI). Saves write to both `res://userdata` (for quick local debugging) and `user://userdata` (browser/portable safe); loading falls back to `user://` if `res://` is missing. No passwords; names sanitized. Save layout example: `userdata/berkerz/berkerz.json`, `userdata/berkerz/testo.json`, `userdata/berkerz/sharedstash.json`.
- **Character model** (`scripts/core/character.gd`): `name`, `background` (harvester/fighter), `location` (e.g., `town` or `lake>node_id`), `stats` (`stats.gd`: HP/energy max 100, power/defense/craft/speed), skills loaded from `data/skills.gd` (harvest: harvest.fishing/mining/woodcutting/foraging/hunting; combat: combat.swordsmanship/archery/unarmed; craft: craft.crafting), `inventory` (`inventory.gd`: id→count), `equipped` slots (`weapon`, `hat`, `armor`). New characters start with swordsmanship 1, 100 camping supplies, two swords (rusty, wooden), and test armor pieces (leather hat/armor) for equip flow.
- **Skills registry** (`data/skills.gd`): Categories/ids with `all_ids()` to initialize characters: combat.swordsmanship/archery/unarmed; harvest.fishing/mining/woodcutting/foraging/hunting; craft.crafting.
- **Items** (`data/items.gd`, `item_data.gd`): Items define `type` (weapon/hat/armor/projectile/material/consumable), optional `slot` for equip targets, and optional `skill` used for combat XP routing. Examples: `rusty_sword`, `wooden_sword` (slot weapon, skill combat.swordsmanship), `arrow` (projectile), `leather_hat`/`leather_armor` (slots hat/armor), `camping_supplies` (rest), `log`/`herb` materials.
- **Maps/Encounters** (`data/maps.gd`, `map_node.gd`, `encounter_system.gd`): Submaps `town`, `lake`, `forest`, `mountain`; town has no nodes. Travel costs: `SUBMAP_TRAVEL_COSTS` (lake/forest/mountain 10, town 10). Node movement costs: `abs(distance diff) * SUBMAP_NODE_COSTS[submap]` (lake/forest 2, mountain 3). Node actions (harvest/combat) consume node energy; travel cost is separate. XP routing: harvest XP by submap (harvest.*), combat XP by equipped weapon skill (combat.*) or unarmed if no weapon.
- **Crafting** (`data/recipes.gd`, `recipe.gd`, `crafting_system.gd`): Recipes define inputs/output/time/XP; queued jobs grant output + XP on completion; queue resets on account/character switch (not persisted).
- **Orchestration** (`game_state.gd`): Manages account/character lifecycle, seeds starter gear/supplies, tracks location, handles travel/node movement, equips/unequips items, inventory listing helpers for UI, and saves after actions. Resting consumes 1 camping supply.

## Recent Changes (for iteration tracking)
- UI overlays are now fully opaque with a reusable `ActionBar` (Inventory/Skills/Save) and a scrollable `InfoBox` used for logs on Main and node panels. Map → Zone → Node flow is split into dedicated screens; nodes open their own panel with full action set.
- Inventory/Skills overlays: full-screen, opaque. Inventory lists equipped slots (click to unequip), equipment bucket (click to equip), and items list. Skills shows levels.
- Equipment data: items declare an optional `slot`; equipment includes `rusty_sword`, `wooden_sword`, `arrow`, `leather_hat`, `leather_armor`. Weapon skill is pulled from the item metadata to route combat XP.
- Starter kit: characters start with swordsmanship 1, 100 camping supplies, two swords (rusty + wooden), leather hat/armor for equip testing.
- Travel/combat/harvest: travel cost by submap/node distance; node actions consume node energy and grant XP based on submap (harvest.*) or equipped weapon skill/unarmed.

## Roadmap / Next Refinements
- Apply skills/stats to outcomes: fold gather/power/speed into yields, damage, timers; tune XP curves.
- Persist active crafting queue and restore on load; optionally tick when idle by elapsed real time.
- Expose shared stash: move items between character and stash; allow stash-based crafting.
- Enrich content: more nodes/recipes/backgrounds with distinct starting gear/stats; link items to bonuses; add bows/projectiles and more equipment slots.
- Add energy regen over time or via rest/sleep timers; log session durations for idle play.
- Add failure states/recovery flows (e.g., lose carried items on defeat, retrieve via low-risk nodes).
- Content/Systems backlog (still pending):
  - Material categories (wood, ore, raw fish, herbs, hides/meat) with tiered variants and processing chains (smelt ore → steel, prepare hides, process wood).
  - Tool-gated harvesting (fishing pole, skinning knife, herbalist gloves/shears, axe, mining picks) and quality tiers for weapons/armor/tools (poor/okay/fine/well-made/masterwork; leather/iron/steel, masterwork steel as top end).
  - New resources: coins (smelt gold; humanoid enemies can drop gold; sell items for gold), hunger as a managed stat (ties into cooking/crafting for healing/regen), item weights + character carry limit.
  - New skill: cooking; extend node rewards to hunger/food loops.
  - Expand nodes/encounters: harvest nodes can trigger attacks with flee/leave-loot or fight options; zone-specific encounter rates (lake low, forest medium with hunting grounds, mountain high) and a future combat-focused zone (e.g., badlands).

## File & API Guide (What to Edit/Call)
- **Scenes/UI**
  - `scenes/Main.tscn` / `scenes/Main.gd`: Text harness for account/character selection, log/status, and navigation. Primary controls are Map + `ActionBar` (Inventory, Skills, Save & Exit). No travel/actions live on the main screen; everything routes through overlays.
  - `scenes/MapPanel.tscn`: Zone chooser (town, lake, forest, mountain) with `ActionBar`. Selecting a zone calls `GameState.travel_to_submap` then opens the relevant panel.
  - `scenes/TownPanel.tscn`: Town-only actions (Rest, Craft plank, Map) plus `ActionBar`.
  - `scenes/ZonePanel.tscn`: Non-town zones. Lists nodes (buttons move via `GameState.move_to_node`), offers Rest/Craft + Map + `ActionBar`.
  - `scenes/NodePanel.tscn`: Per-node actions after movement: Harvest, Combat, Return to Town, Rest, Craft, Map/back-to-zone, plus `ActionBar`.
  - `scenes/InfoBox.tscn`: Reusable scrollable info panel (fixed height) used for logs/info on Main and Zone/Node overlays.
  - `scenes/InventoryPanel.tscn` / `scenes/SkillsPanel.tscn`: Full-screen overlays with opaque backgrounds; emit signals to equip/unequip or refresh the skills list.
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
1) Launch: `godot4 --path . --run`. Create/select account and character (both backgrounds seed swordsmanship 1).
2) Hit `Map` on Main to open `MapPanel`; choose town/lake/forest/mountain. Travel cost = exit-from-node energy + submap travel cost.
3) In `ZonePanel`, click a node to move there (cost: abs(distance diff) * zone node cost; town has no nodes). `Return to Town` pays exit + town travel.
4) Use `Harvest` or `Combat` from `ZonePanel` when at a node; XP routes by submap (harvest.*) or equipped weapon skill/unarmed (combat.*); node.energy_cost is consumed here.
5) Rest (town/zone panels) spends 1 camping supply; Craft runs the plank recipe.
6) Inventory/Skills live in the shared `ActionBar` (Main/Map/Town/Zone) and open full-screen overlays. Inventory lists equipped slots (click to unequip), equipment bucket (click to equip), and other items.
7) `Save & Exit` lives on the `ActionBar` and persists the active character before quitting.

## Debug & Refactor Notes (latest)
- Navigation refactor: travel controls moved off Main. Map → Town/Zone panels are full-screen overlays with opaque backgrounds; nodes only appear after choosing a zone. Shared `ActionBar` (Inventory/Skills/Save & Exit) lives on Main and every overlay.
- Inventory/Skills overlays: `InventoryPanel.tscn` and `SkillsPanel.tscn` emit signals to equip/unequip and refresh skill lists; both use opaque backgrounds for readability.
- Layout: portrait-focused ScrollContainer with padding; overlays rely on MarginContainer + PanelContainer for solid backgrounds.
- Saves: dual writes to `res://userdata` and `user://userdata`; `nuke.sh` wipes both locations. Core `class_name` exports restored after warning cleanup rollback to keep the game stable.
- Starter kit: rusty + wooden sword, leather hat/armor, 100 camping supplies. Combat XP routes by equipped weapon (swordsmanship/unarmed); harvesting XP by submap.
- Travel: zones (town/lake/forest/mountain) with distance-based node costs; actions consume node energy, travel cost handled separately. Location persists in saves and is surfaced on Map/Zone panels.
- Known minor warnings: some “class_name matches global” and narrowing conversions remain; left intentionally to avoid further breakage while the UI is stable.
