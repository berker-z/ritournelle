# TODO / Open Tasks

This file tracks outstanding work that is **not** part of the core architecture already implemented. It’s intentionally high-level and grouped by theme.

## Game Design & Content

- Apply stats/skills to outcomes:
  - Fold power/speed/craft into harvest yields, combat damage, and action timers.
  - Tune XP curves across skills so progression feels paced rather than flat.
- Persist and enrich crafting:
  - Persist the active crafting queue across saves and restore it on load.
  - Optionally tick crafting jobs by elapsed real time (idle/offline progress).
- Shared stash:
  - Expose shared stash in the UI; allow moving items between character inventory and stash.
  - Support stash-based crafting where recipes can draw from shared stash contents.
- Content expansion:
  - Add more nodes, recipes, and backgrounds with distinct starting stats/gear.
  - Link items to bonuses (stat modifiers, skill boosts) and add more equipment slots.
- Progression systems:
  - Add energy regeneration over time or via rest/sleep timers; log session durations for idle play.
  - Add richer failure/recovery flows (e.g., lose carried items on defeat and retrieve them via low‑risk nodes).
- Content backlog (world/systems):
  - Material categories (wood, ore, raw fish, herbs, hides/meat) with tiered processing chains.
  - Tool‑gated harvesting (fishing pole, skinning knife, axe, mining picks, etc.) and quality tiers for tools/weapons/armor.
  - New resources: coins, hunger, item weights + carry limits.
  - New skill: cooking, and extending node rewards into food/hunger loops.
  - Expanded encounters: harvest nodes that can trigger attacks with options to flee/leave loot/fight; zone‑specific encounter rates and a combat‑focused zone.

## Architecture & Systems

- Crafting results:
  - (Optional) Introduce a `CraftingTickOutcome` typed result for crafting ticks, so completion data is structured instead of only log strings.
- Domain services:
  - Continue extracting any remaining business rules from UI/controller helpers into pure services/domain types where appropriate.
  - Keep services free of direct SceneTree/UI/autoload coupling; they should compute outcomes that `GameState` applies.
- Eventing:
  - Consider adding a lightweight event bus (or similar) for non‑core, broadcast‑style UI events if wiring starts to fan out again, while keeping core gameplay flows on `GameState.state_changed`.
- Data/layout:
  - Evaluate migrating static `data/*.gd` (items, maps, recipes) into Godot Resources for easier tooling, if/when that becomes valuable.
