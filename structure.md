# Project Structure

- `project.godot` — Godot 4.5 project config; autoloads `SaveSystem`, `GameState`, `EncounterSystem`, `CraftingSystem`; main scene `scenes/Main.tscn`.
- `scenes/Main.tscn` — text harness UI with account selection/creation, character creation/selection (hidden after selection), and action buttons (harvest, combat, craft, rest, save & exit); logic in `scenes/Main.gd`.
- `scripts/core/` — data models:
  - `account.gd` (persisted player account with character list, active index, shared stash inventory)
  - `character.gd` (character state, background, serialization)
  - `stats.gd`, `skill.gd`, `inventory.gd`, `item_data.gd`, `recipe.gd`, `map_node.gd` (stats/skills/items/nodes; all serializable where needed)
- `scripts/systems/` — gameplay systems:
  - `game_state.gd` (owns current account selection, character lifecycle, wiring to encounters/crafting)
  - `encounter_system.gd` (node resolution for harvest/combat/mixed)
  - `crafting_system.gd` (craft queue, ticks over time)
  - `save_system.gd` (per-account JSON saves under `res://userdata/<account>/`; one file per character and `sharedstash.json`; creates directories as needed)
- `data/` — static sample content for items, recipes, and nodes.
- `design.md` — high-level design overview.
- `AGENTS.md` — contributor guidelines.

Save layout example:
- `userdata/berkerz/berkerz.json` — character save
- `userdata/berkerz/testo.json` — another character
- `userdata/berkerz/sharedstash.json` — shared stash (currently unused)
