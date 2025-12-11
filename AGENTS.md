# Repository Guidelines

## Project Structure
- Main scene: `scenes/Main.tscn` (text harness). Gameplay runs via full-screen overlays:
  - `MapPanel`, `TownPanel`, `ZonePanel`, `NodePanel` (navigation and actions)
  - `InventoryPanel`, `SkillsPanel`, `AccountPanel` (management overlays)
  - Shared UI pieces: `ActionBar` (Inventory/Skills/Save) and `InfoBox` (scrollable log/info)
- Core logic: `scripts/systems` (`game_state.gd`, `save_system.gd`, `encounter_system.gd`, `crafting_system.gd`)
- Data: `data/` (skills, items, maps, recipes)
- Models: `scripts/core/` (character, stats, skills, inventory, item_data, map_node, recipe, account)
- User data: `userdata/<account>/<character>.json` + `sharedstash.json` (also in `user://userdata`); `nuke.sh` wipes both.

## Build / Run
- Run: `godot4 --path . --run`
- Save/Exit is in the UI (`ActionBar`); autosaves on quit. `nuke.sh` clears saves for a fresh state.

## UI & Controllers
- Overlays are full-screen, opaque `Control` scenes with a ColorRect background. All input should be captured; avoid translucency.
- Panels emit intent signals only; wiring belongs in controllers, not in panel scripts.
- Controllers in use:
  - `AccountController` + `AccountPanel` for account/character create/select/delete.
  - `InventorySkillsController` for inventory/skills open/refresh, equip/unequip, save/exit.
  - `TownController` for town intents (rest/craft/map/inventory/skills/save).
- Reusable components: `ActionBar` (Inventory/Skills/Save) and `InfoBox` (log/info, scrollable).
- Keep Main.gd thin: bootstrap controllers, logging, status refresh, map/zone/node wiring until migrated.

## Gameplay Data & Rules
- Skills registry: `data/skills.gd` (combat: swordsmanship/archery/unarmed; harvest: fishing/mining/woodcutting/foraging/hunting; craft: crafting).
- Items: `data/items.gd` with types (weapon/hat/armor/projectile/material/consumable), optional `slot` and `skill` (for combat XP routing).
- Travel: submap entry cost (10). Node travel uses zone-specific per-step cost (lake/forest=2, mountain=3) * abs(node distance); returning to town costs energy. Town has no nodes.
- Actions: node actions consume node energy; harvest XP by submap (harvest.*); combat XP by equipped weapon skill or unarmed if no weapon.
- Starter kit: swordsmanship 1, rusty + wooden sword, leather hat/armor, 100 camping supplies.

## Coding Practices
- Use controllers to mediate between UI signals and systems; panels should stay dumb/presentational.
- Keep overlays full-screen, opaque; anchor all to viewport (Layout → Full Rect).
- Prefer `rg` for searches; avoid destructive git commands unless asked.
- Keep comments minimal and purposeful; default to ASCII.
- Persist new logic under `scripts/` or `data/`; avoid embedding rules in UI scenes.

## Testing & Debug
- Use `nuke.sh` to clear `res://userdata` and `user://userdata` between runs when needed.
- Validate flows: account/character selection, map → zone → node travel, inventory equip/unequip, skills display, rest/craft, save & exit.
