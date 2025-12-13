# AGENTS.md – Godot Project Guidelines

This repo is a Godot 4 project. When you change it, optimize for **correctness, legibility, and stable ownership boundaries**, not cleverness or churn.

This document is intentionally **project‑agnostic**, and it assumes each project maintains a single architectural reference file (in this repo: `structure.md`). Always keep that file in sync with the code, and read it before performing non‑trivial changes. If you're initializing a new project, create the structure.md file and make sure to keep it up to date as a living documentation file for the project's architecture, including all files and functions.

---

## 1. Architectural Principles

### 1.1 Central State

- There must be a **single source of truth** for runtime game state (typically an autoloaded state singleton).
- That central state owns:
  - The authoritative data for the current session (player/account/world snapshot).
  - Applying outcomes from domain logic to state (health changes, inventory, location, etc.).
  - Triggering persistence at well‑defined checkpoints.
  - Emitting a **single canonical signal** when state changes (e.g. `state_changed`).

### 1.2 Services and Domain Logic

- Services and domain modules:
  - Perform calculations and apply game rules.
  - Operate on plain data (stats, skills, inventories, locations) and return **typed outcomes** (result objects, not raw dictionaries).
  - Should be **strictly typed** and preferably stateless (any necessary state lives in the central state singleton).
- Domain logic must not:
  - Touch the SceneTree or UI nodes.
  - Know about scenes, panels, or specific controllers.
  - Emit signals to drive UI directly.

### 1.3 Controllers and UI

- UI components (panels, widgets):
  - Should be “dumb”: they receive data and render, and emit **semantic intent signals** (e.g. `rest_requested`, `equip_item(item_id)`).
  - Should not read or mutate global state directly.
- Controllers/routers:
  - Listen to UI signals and call central state/services.
  - Own view‑level orchestration (which panel is visible, which UI gets refreshed).
  - Must not implement game rules or hold long‑lived game state.
- There should be **exactly one place** that decides visibility/routing for a given family of panels (e.g., one navigation/overlay router).

---

## 2. Public API and State Mutation Rules

### 2.1 Method Visibility

- Treat underscore‑prefixed methods (`_on_*`, `_something_internal`) as **private**:
  - Do not call them across scripts.
  - They are for signals and internal wiring only.
- Anything called cross‑script must be a **public verb**:
  - Examples: `open_map()`, `request_travel_to()`, `apply_damage()`, `start_craft_job()`.

### 2.2 Mutating State

- UI code must never assign into central state directly.
- All state mutations should go through:
  - A central state method (e.g., `apply_*` or high‑level action methods), or
  - A service/domain method that returns an outcome which the central state applies.
- After any mutation that affects gameplay state:
  - Emit exactly one canonical state change signal from the central state singleton.
  - Avoid multiple overlapping signals for the same change; this leads to “signal soup”.

### 2.3 Signals and Eventing

- Use a central state signal (e.g. `state_changed`) to inform controllers/UI that state needs re‑rendering.
- If a global event bus/autoload exists:
  - Reserve it for **ephemeral, non‑authoritative events** (toasts, SFX, analytics).
  - Do not use it as the backbone of gameplay state propagation.
- Every signal should have:
  - A clear owner.
  - A clear consumer.
  - A clear purpose (documented by its name and parameter types).

---

## 3. Type Safety and Data Contracts

- Use strict typing for:
  - Variables, function arguments, and returns.
  - Collections (`Array[T]`, `Dictionary[String, T]`).
- Typed collections:
  - Never return untyped `[]` from a function declared as `-> Array[String]`.
  - Construct typed arrays explicitly and return those.
- Dictionaries:
  - Dictionaries are glue, not long‑term contracts.
  - Prefer dedicated result/resource classes (`RefCounted` with fields) for structured responses (e.g., encounter outcomes, travel outcomes).

---

## 4. UI Rendering and Refresh

- Panels should render **from state**, not derive state on their own.
  - Prefer a single `render(snapshot)` / `bind(state)` style API.
- Routing and visibility:
  - One router/controller should own which overlay/screen is visible.
  - Panels should not hide/show themselves except as a local response to user input; instead, they emit intents (`close_requested`, `open_x_requested`) that the router uses.
- Avoid duplicate refresh paths:
  - After a state change, there should be exactly one canonical path that updates the UI tree.
  - Do not manually “poke” nodes from multiple places to reflect the same state.

---

## 5. Project Structure (Guidance)

This is a recommended layout; follow the existing structure in this repo if it differs, and do **not** invent parallel taxonomies.

- `scenes/` – Godot scenes and their attached scripts (panels, widgets, HUD).
- `scripts/core/` – Data models, value objects, typed results, constants.
- `scripts/services/` – Stateless or light‑state coordinators for domain logic (travel, actions, session).
- `scripts/systems/` – Long‑lived singletons/autoloads (central state, persistence, global systems).
- `scripts/controllers/` – Controllers/routers that mediate between UI and the central state/services.
- `data/` – Static data (maps, items, recipes, skills). Consider moving to Resources when it adds value.

When adding new files, keep responsibilities narrow and consistent with these domains.

> If you are creating a new Godot project, add a `structure.md` (or similarly named) architecture file at the root as early as possible. Treat it as the source of truth for how the project is wired and keep it updated as the code evolves.

---

## 6. Refactoring and Change Management

### 6.1 Prime Directive

- Preserve the existing architecture unless there is a compelling reason to change it.
- If a proposed change violates:
  - Single source of truth for state,
  - Separation between domain logic and UI,
  - Controller‑as‑mediator (not god object),
    then stop and consider an alternative.

### 6.2 Scope Discipline

- Work in the smallest coherent slice:
  - Prefer one responsibility change per PR/patch.
  - If a refactor touches many files, break it into staged changes that each keep the game runnable.
- Never introduce new autoload “Manager” singletons just to work around wiring.
  - Fix ownership boundaries and data flow instead.

### 6.3 Behavior Changes

- Refactors should be behavior‑preserving unless explicitly requested.
- If you must change behavior:
  - Be explicit about **what** changed and **why**.
  - Document how you manually verified the new behavior (steps to reproduce/use).

---

## 7. Constants and Magic Values

- Add new stable string keys, IDs, and numeric constants to a dedicated constants module (e.g. a `GameConstants` script).
- Do not scatter raw strings like `"weapon"`, `"forest"`, or `"combat"` across random scripts.
- When updating constants:
  - Ensure all dependent maps/tables are updated consistently (e.g., travel costs, node costs).

---

## 8. Verification Guidelines

For any non‑trivial change, perform a minimal smoke test (or describe how to perform it):

- Launch the game.
- Navigate UI overlays:
  - Open/close inventory and skills.
  - Open the map and travel between zones/nodes.
- Perform at least one core action:
  - Harvest or combat at a node (if available).
- Equip/unequip an item and confirm UI + state stay in sync.
- Save and reload, verifying that account/character state and location persist correctly.

If a step is not applicable (e.g., combat not yet implemented), say so explicitly.

---

## 9. Communication for Agents

- When reasoning about changes, describe **ownership** in simple sentences:
  - “X owns Y.”
  - “X calls Y via Z.”
- If you cannot explain the ownership path for a feature in one short paragraph, reconsider the design or ask for guidance.
- When unsure about structure or intent:
  - Ask for specific files or examples.
  - Offer two or more options with trade‑offs spelled out (complexity vs. clarity, performance vs. simplicity, etc.).
