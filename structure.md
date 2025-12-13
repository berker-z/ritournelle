# Ritournelle Architecture Guide

This document is a **living description of the current system**: what exists, where it lives, and how it fits together. It is not a roadmap or lore document; high‑level game design and future ideas live in `plans.md`.

---

## 1. Runtime Concept (Current Game)

- You control a single character who:
  - Belongs to an account (multiple characters per account).
  - Has stats, skills, inventory, and equipment.
  - Moves on a node‑based overworld (submaps + nodes).
- Core actions:
  - Travel between submaps and nodes (energy cost).
  - Harvest and fight at nodes (consume node energy; gain items + XP).
  - Rest using camping supplies.
  - Craft via a timed queue (recipes that output items + XP).
- The game is deterministic and log‑driven:
  - Every major action returns log lines.
  - Logs are shown on the Main screen and NodePanel for legible, inspectable runs.

---

## 2. High‑Level Architecture

### 2.1 Autoloaded Systems

Configured in `project.godot`:

- `GameState` (`scripts/systems/game_state.gd`)
  - Central facade and source of truth for runtime state:
    - Current account and active character.
    - Location and equipment/inventory derived from `Character`.
  - Owns:
    - Applying service outcomes to the world (travel, actions, crafting, session).
    - Persistence checkpoints (`_save_game()` / `save_checkpoint()`).
    - Emitting `state_changed` after mutations.
- `EncounterSystem` (`scripts/systems/encounter_system.gd`)
  - Resolves node encounters into an `EncounterOutcome` (logs, damage, rewards, flags).
- `CraftingSystem` (`scripts/systems/crafting_system.gd`)
  - Manages crafting jobs and ticks:
    - `start_job(recipe, character) -> CraftingStartOutcome`.
    - `tick(delta, character) -> Array[String]` (job completion logs).
- `SaveSystem` (`scripts/systems/save_system.gd`)
  - File I/O for accounts, characters, and shared stash under `res://userdata` and `user://userdata`.

### 2.2 Services (Domain Coordinators)

All under `scripts/services/`:

- `SessionService`
  - Account/character lifecycle as typed results:
    - `list_accounts() -> Array[String]`.
    - `select_account(name) -> AccountSelectionResult`.
    - `create_account(raw_name) -> AccountCreationResult`.
    - `get_character_names(account) -> Array[String]`.
    - `create_character(account, account_name, name, background) -> CharacterCreationResult`.
    - `select_character_by_name(account, character_name) -> CharacterSelectionResult`.
    - `delete_character(account, account_name, character_name, current_player) -> CharacterDeletionResult`.
  - Does **not** own crafting resets or global state; it just reads/writes save data and constructs results.
- `TravelService`
  - Pure travel math on a node‑based map:
    - `list_submaps() -> Array[String]`.
    - `list_nodes(submap) -> Array[String]`.
    - `travel_to_submap(location, energy, submap) -> TravelOutcome`.
    - `move_to_node(location, energy, target_submap, node_id) -> TravelOutcome`.
  - Never mutates `Character`; returns `TravelOutcome` with logs, `ok`, `energy_cost`, and `new_location`.
- `ActionService`
  - Builds encounters and actions around nodes:
    - `act_in_node(player, base_node, submap, action_type) -> Array[String]`:
      - Constructs a temporary `MapNode` based on a base node + action type (harvest/combat).
      - Calls `EncounterSystem.resolve(...)` and flattens `EncounterOutcome.log` to strings.
    - `rest(player) -> Array[String]`:
      - Consumes one `camping_supplies` and calls `player.rest()`.
    - `start_craft(player, recipe_id) -> Array[String]`:
      - Starts a crafting job via `CraftingSystem.start_job(...)` and returns its log.
  - Does not read/write UI or SceneTree; all feedback is via log arrays.

### 2.3 Core Models (`scripts/core/`)

- `character.gd` (`class_name Character`)
  - Fields:
    - `name`, `background`, `location` (e.g. `"town"` or `"lake>node_id"`).
    - `stats: Stats` (HP, energy, combat/craft stats).
    - `skills: Dictionary[String -> Skill]` (initialized from `data/skills.gd`).
    - `inventory: Inventory` (item counts).
    - `equipped: Dictionary` with slots (`"weapon"`, `"hat"`, `"armor"`).
  - Helpers:
    - `new_with_background(name, background)`.
    - `equip_item(item_id)`, `unequip_slot(slot)`.
    - `get_equipped_weapon()`, `get_equipped_items()`.
    - `apply_rewards(rewards_dict) -> Dictionary` (items/xp/hp/energy).
    - `to_dict()/from_dict()` for saving.
- `stats.gd` (`class_name Stats`)
  - HP/energy caps and values; basic operations:
    - Energy consumption, damage, resting.
    - Serialization helpers.
- `skill.gd` (`class_name Skill`)
  - Per‑skill XP and level; `add_xp(amount) -> Dictionary` describing new level/XP.
- `inventory.gd` (`class_name Inventory`)
  - `items: Dictionary[item_id -> count]`.
  - Operations:
    - `add`, `remove`, `has`, `can_afford`, `deduct`, `to_lines()`, `to_dict()/from_dict()`.
- `account.gd` (`class_name Account`)
  - Holds:
    - `characters: Array[Character]`.
    - `active_index: int`.
    - `shared_stash: Inventory`.
  - Helpers:
    - `add_character`, `set_active`, `delete_character`, `get_character_names`, `get_active()`, `to_dict()/from_dict()`.
- `game_constants.gd` (`class_name GameConstants`)
  - Stable IDs and costs:
    - `SUBMAP_*`, `ACTION_*`, `SLOT_*`.
    - `SUBMAP_TRAVEL_COSTS`, `SUBMAP_NODE_COSTS`.
    - Common recipe IDs (e.g. `RECIPE_PLANK`).
- `item_data.gd`
  - Static item metadata (type, slot, skill, etc.), and helpers:
    - `get_item_static(id)`, `is_equipment(meta)`, `slot_for(meta)`.
- `map_node.gd` (`class_name MapNode`)
  - Discrete node definition:
    - `id`, `submap`, `node_type`, `tier`, `energy_cost`, `rewards`, `xp_reward`, `distance`, `damage_range`.
  - Constructed from `data/maps.gd`.
- `recipe.gd`
  - Crafting recipes: inputs, output, craft time, XP rewards.
- Typed result types:
  - `encounter_outcome.gd` (`EncounterOutcome`).
  - `crafting_outcome.gd` (`CraftingStartOutcome`).
  - `travel_outcome.gd` (`TravelOutcome`).
  - Session results: `account_selection_result.gd`, `account_creation_result.gd`, `character_creation_result.gd`, `character_selection_result.gd`, `character_deletion_result.gd`.

### 2.4 Data Files (`data/`)

- `skills.gd`
  - Registry of skill IDs grouped by category:
    - `combat.*`, `harvest.*`, `craft.*`.
  - `all_ids()` returns the flat list used to initialize `Character.skills`.
- `items.gd`
  - Registry of item metadata (IDs → definitions) consumed by `item_data.gd`.
- `maps.gd`
  - Defines submaps (`"town"`, `"lake"`, `"forest"`, `"mountain"`) and node arrays for each.
  - Drives distances and reward tables used by `TravelService`/`EncounterSystem`.
- `recipes.gd`
  - Defines sample recipes (e.g. plank, tonic) used by `CraftingSystem`.

---

## 3. GameState Facade (`scripts/systems/game_state.gd`)

`GameState` is the **only** place that owns runtime state and persistence side‑effects. Everything else returns values or outcomes.

### 3.1 Session / Accounts / Characters

- Public API:
  - `has_account_selected()`, `has_active_character()`.
  - `list_accounts() -> Array[String]`.
  - `select_account(name) -> Array[String]`:
    - Uses `SessionService.select_account`.
    - Sets `account`, `account_name`, clears `player`.
    - Resets crafting and emits `state_changed`.
  - `create_account(name) -> Array[String]`:
    - Uses `SessionService.create_account`.
    - Sets `account`/`account_name`, clears `player`.
    - Resets crafting and emits `state_changed`.
  - `get_character_names() -> Array[String]`:
    - Delegates to `SessionService.get_character_names(account)`.
  - `create_character(name, background) -> Array[String]`:
    - Uses `SessionService.create_character`.
    - Sets `player`, resets crafting, emits `state_changed`.
  - `select_character_by_name(name) -> Array[String]`:
    - Uses `SessionService.select_character_by_name`.
    - Sets `player`, resets crafting, saves, returns logs.
  - `delete_character(name) -> Array[String]`:
    - Uses `SessionService.delete_character`.
    - Clears `player` when appropriate, resets crafting, emits `state_changed`.

### 3.2 Travel / Location

- Helper getters:
  - `get_location_text() -> String`.
  - `get_current_submap() -> String` (parses from location).
  - `get_current_node() -> String` (parses from location).
- Operations:
  - `list_submaps() -> Array[String]` and `list_nodes(submap) -> Array[String]`:
    - Delegates to `TravelService`.
  - `travel_to_submap(submap) -> Array[String]`:
    - Validates active character.
    - Calls `TravelService.travel_to_submap(player.location, player.stats.energy, submap)`.
    - On success: consumes energy, updates `player.location`, calls `_save_game()`.
  - `move_to_node(submap, node_id) -> Array[String]`:
    - Similar pattern via `TravelService.move_to_node`.
  - `return_to_town() -> Array[String]`:
    - Thin wrapper around `travel_to_submap(GameConstants.SUBMAP_TOWN)`.

### 3.3 Node Actions / Combat / Harvest / Rest / Craft

- `act_in_current_node(action_type: String) -> Array[String]`:
  - Validates active character and current node.
  - Fetches the base `MapNode` from `TravelService`.
  - Calls `ActionService.act_in_node(player, base_node, submap, action_type)`.
  - Saves via `_save_game()` and returns log lines.
- `rest() -> Array[String]`:
  - Calls `ActionService.rest(player)` (consumes camping supplies and calls `player.rest()`).
  - Saves and returns logs.
- `start_craft(recipe_id: String) -> Array[String]`:
  - Calls `ActionService.start_craft(player, recipe_id)`; saves and returns logs.

### 3.4 Inventory / Equipment / Crafting Tick

- Inventory view helpers:
  - `get_inventory_lines() -> Array[String]`.
  - `get_equipped_entries() -> Array[Dictionary]` (for UI listing).
  - `get_equipment_inventory_entries() -> Array[Dictionary]`.
  - `get_item_inventory_entries() -> Array[Dictionary]`.
- Equipment actions:
  - `equip_item(item_id: String) -> Array[String]`:
    - Calls `Character.equip_item`, saves, returns log message.
  - `unequip(slot: String) -> Array[String]`:
    - Calls `Character.unequip_slot`, saves, returns log message.
- Crafting tick:
  - `tick(delta: float) -> Array[String]`:
    - Calls `CraftingSystem.tick(delta, player)` and collects completion logs.
    - Calls `_save_game()` once if any logs were produced.

### 3.5 Persistence

- `_save_game()` (private):
  - Saves the current active character via `SaveSystem.save_character(account_name, player)`.
  - Emits `state_changed`.
- `save_checkpoint()` (public):
  - Thin wrapper around `_save_game()` for callers like Save & Exit.

---

## 4. UI, Controllers, and Flow

### 4.1 Scenes & Panels (`scenes/`)

- `Main.tscn` / `Main.gd`
  - Composition root; owns:
    - Wiring of controllers and panels.
    - Top‑level overlay frame (ActionBar + StatusBar + InfoBox) that mirrors what overlays use.
  - The main screen shows:
    - Navigation row with `Map` button.
    - Bottom `OverlayFrame` with ActionBar/StatusBar/InfoBox for logs + status.
  - All gameplay actions go through overlays and controllers; Main itself has no business logic.
- `AccountPanel.tscn`
  - Full‑screen overlay for account/character management.
  - Emits semantic signals:
    - `create_account_requested(name)`, `select_account_requested(name)`.
    - `create_character_requested(name, archetype)`.
    - `select_character_requested(name)`, `delete_character_requested(name)`.
    - `close_requested`.
- `MapPanel.tscn`
  - Full‑screen overlay for zone selection (town/lake/forest/mountain).
  - Emits:
    - `select_zone(submap: String)`.
    - `close_requested`.
- `TownPanel.tscn`
  - Town actions:
    - Rest, Craft plank, Map.
  - Emits:
    - `rest_pressed`, `craft_pressed`, `open_map`, `close_requested`.
- `ZonePanel.tscn`
  - Non‑town zones:
    - Lists nodes; each node button triggers `move_to_node(submap, node_id)`.
    - Rest, Craft, Map actions.
  - Emits:
    - `move_to_node(submap, node_id)`, `rest_pressed`, `craft_pressed`, `open_map`, `close_requested`.
- `NodePanel.tscn`
  - Per-node actions:
    - Harvest, Combat, Return to Town, Rest, Craft, Map/back to zone.
  - Emits:
    - `harvest_pressed`, `combat_pressed`, `return_pressed`,
      `rest_pressed`, `craft_pressed`, `open_map`, `open_zone`, `close_requested`.
- All full‑screen panels (Main, MapPanel, TownPanel, ZonePanel, NodePanel) host a shared `OverlayFrame` at the bottom; controllers hand status/log lines to the frame instead of poking InfoBox/StatusBar directly.
- Shared UI components:
  - `OverlayFrame.tscn`:
    - Stacked container with `ActionBar`, `StatusBar`, and `InfoBox`.
    - Public API: `set_status_lines(lines)`, `set_log_lines(lines)`, `set_enabled(has_character)`.
    - Re‑emits the ActionBar signals (`open_inventory`, `open_skills`, `save_exit`), so controllers only bind to the frame.
  - `ActionBar.tscn`:
    - Buttons for Inventory, Skills, Save & Exit.
    - Emits `open_inventory`, `open_skills`, `save_exit`.
  - `InfoBox.tscn`:
    - Scrollable log display for global action logs; authored as a normal stacked child (no full‑screen anchors).
    - Instanced inside `OverlayFrame`.
  - `InventoryPanel.tscn`:
    - Full‑screen inventory overlay:
      - Shows equipped slots, equipment pool, and items list.
      - Emits `equip_item(item_id)` and `unequip_slot(slot)`.
  - `SkillsPanel.tscn`:
    - Full‑screen skills overlay that displays per‑skill levels and XP.

### 4.2 Controllers (`scripts/controllers/`)

- `AccountController`
  - Mediates between `AccountPanel` and `GameState`:
    - Responds to create/select/delete signals.
    - Calls the corresponding `GameState` methods.
    - Emits `log_produced(message)` for each log line from `GameState`.
    - Keeps `AccountPanel` enabled/visible based on `GameState.has_active_character()`.
- `InventorySkillsController`
  - Mediates inventory/skills UI and save/exit:
    - Listens to `InventoryPanel` equip/unequip signals and calls `GameState.equip_item/unequip`.
    - Exposes:
      - `request_inventory()`, `request_skills()`, `request_save_exit()`.
      - `register_action_bar(action_bar)` to wire ActionBars to those methods.
    - Emits `log_produced(message)` and keeps panels refreshed when visible.
- `NavigationController`
  - Single UI router for overlays:
    - Owns panel visibility for Map/Town/Zone/Node.
    - Listens to panel intents (zone selection, move_to_node, open_map, return).
    - Calls `GameState.travel_to_submap`, `move_to_node`, `return_to_town` and emits `log_produced` with the resulting logs.
    - Provides public verbs `open_map()` and `open_zone_from_node()` used by Main/TownPanel.
- `ActionController`
  - Mediates rest/harvest/combat/craft intents from Zone/Town/Node panels:
    - Connects panel signals to:
      - `GameState.act_in_current_node(action_type)` for harvest/combat.
      - `GameState.rest()` for rest.
      - `GameState.start_craft(...)` for crafting.
    - Emits `log_produced(message)` for each log line.

---

## 5. Running and Extending the Project

### 5.1 Running Locally

- From the project root:
  - `godot --path .`
  - Main scene: `scenes/Main.tscn` (configured in `project.godot`).

### 5.2 Adding New Features (Architecture Checklist)

When adding or changing behavior:

1. **Model**: Add/extend data structures under `scripts/core/` (e.g., new stats, items, results).
2. **Data**: Update or add static data in `data/` (maps, items, recipes, skills) if content‑driven.
3. **Service/Domain**: Implement a pure service or domain helper under `scripts/services/` or `scripts/core/`:
   - It should compute outcomes (results/logs), not touch UI or SceneTree.
4. **GameState**: Add or extend a `GameState` method that:
   - Calls the service/domain helper.
   - Validates that a character is active.
   - Applies outcomes (mutating stats/location/inventory).
   - Saves via `_save_game()`/`save_checkpoint()` when appropriate.
5. **UI/Controllers**:
   - Wire new actions into the appropriate panel and controller.
   - Panels emit semantic signals; controllers call `GameState` and handle logs.
6. **Docs**:
   - Update this `structure.md` with any new files or responsibilities that matter for others.
