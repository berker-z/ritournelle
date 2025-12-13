# UI Refactor Plan (Monolith → Intent + Mediator)

## Goals

- Move away from a single god-object that wires every button to every action.
- Panels own their local input; they emit semantic intent signals.
- A small mediator/controller listens to intents, calls game/services, and asks panels to refresh.
- Main.gd becomes thin bootstrap + global refresh helpers.

## Current Snapshot (before this pass)

- Main.gd owns all wiring, GameState calls, log/status refresh, and panel visibility.
- Panels already emit signals (e.g., TownPanel.rest_pressed, InventoryPanel.equip_item), but Main handles everything.
- ActionBars in multiple panels emit open_inventory/open_skills/save_exit and are wired directly in Main.

## This Pass (proof of concept scope)

1. Restore Main.gd ownership (remove previous UIController indirection) to have a stable baseline.
2. Introduce small mediators for:
   - Inventory/Skills flows (open/close/refresh, equip/unequip, save/exit hookup via ActionBars).
   - TownPanel intents (rest, craft, map/inventory/skills/save exit via injected callbacks).
3. Keep map/zone/node/account flows in Main for now to minimize blast radius.
4. Document touch points so future steps can migrate the remaining flows.

## Progress (current state)

- Main.gd owns bootstrap, logging, and delegates gameplay flows to injected controllers.
- Scripted controllers live under `scripts/controllers/`:
  - `AccountController` mediates account/character intents and drives `AccountPanel`.
  - `InventorySkillsController` mediates inventory/skills flows and save/exit, wired via ActionBars.
  - `NavigationController` acts as the single UI router for Map/Town/Zone/Node overlays.
  - `ActionController` mediates rest/harvest/combat/craft intents from zone/node/town panels.
- Legacy scene-level controllers (`scenes/AccountController.gd`, `scenes/InventorySkillsController.gd`, `scenes/TownController.gd`) have been removed to avoid parallel architectures.

## Next Steps (future passes)

- Extract remaining business logic out of UI helpers/controllers into dedicated services (TravelService, InventoryService, etc.).
- Consider a lightweight event bus for non-core, broadcast-style UI events if wiring fans out.
- Gradually collapse Main to: bootstrap, global render/log helpers, and controller wiring only.
