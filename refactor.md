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
1) Restore Main.gd ownership (remove previous UIController indirection) to have a stable baseline.
2) Introduce small mediators for:
   - Inventory/Skills flows (open/close/refresh, equip/unequip, save/exit hookup via ActionBars).
   - TownPanel intents (rest, craft, map/inventory/skills/save exit via injected callbacks).
3) Keep map/zone/node/account flows in Main for now to minimize blast radius.
4) Document touch points so future steps can migrate the remaining flows.

## Progress (current state)
- Main.gd owns bootstrap, logging, account/character, map/zone/node flows.
- InventorySkillsController mediates inventory/skills actions and save/exit, connected to ActionBars and panels.
- TownController mediates TownPanel intents, delegating to shared callbacks (rest/craft/map/inventory/skills/save).
- Main refreshes inventory/skills via controller instead of direct panel calls.
- AccountPanel is now a separate full-screen scene; AccountController mediates account/character intents and handles GameState calls + log/status/visibility updates.

## Next Steps (future passes)
- Apply the same mediator pattern to map/zone/node panels (travel/harvest/combat).
- Extract business logic out of UI helpers into dedicated services (TravelService, InventoryService, etc.).
- Consider a lightweight event bus for intent broadcasts if wiring fans out.
- Gradually collapse Main to: bootstrap, global refresh/log helpers, mediator wiring.
