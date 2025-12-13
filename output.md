# Ritournelle Diagnosis & Working Fix Plan

This is a codebase-level diagnosis and an execution plan to (1) restore reliability (currently impacted by typed array mismatches), and (2) finish the UI refactor in a way that matches the design goals in `design.md`, the intent/mediator direction in `refactor.md`, and the senior-dev prescriptions.

## Executive Summary (What’s broken / why it feels unstable)

1. **Typed array contract violations are widespread**, especially around `Array[String]` return types. This manifests as non-deterministic runtime errors depending on which branch executes (`return []`, `return ["msg"]`, `append_array(keys())`, etc.).

2. **Ownership is currently split across too many layers**:
   - Main owns routing and refresh (and calls controller “private” `_on_*` methods).
   - Controllers also own routing (they toggle `visible`).
   - Panels toggle their own visibility on close.
   - SignalBus is used for core UI navigation (ActionBar), creating a third routing/wiring mechanism.

3. **The refactor is left mid-transition** with parallel architectures present:
   - Controllers exist in both `scripts/controllers/` and `scenes/*.gd` (legacy callable-based controllers remain).
   - `TownController.gd` still exists in `scenes/` while `Main.gd` says it’s removed.

4. **Services are not pure and leak engine/infrastructure concerns**:
   - `SessionService` calls `SaveSystem` and resets `CraftingSystem` (autoloads) directly.
   - `ActionService` calls `EncounterSystem` and `CraftingSystem` (autoloads) directly.
   - Multiple APIs return `Dictionary` as a contract (explicitly against “No dictionaries as APIs”).

The immediate “game doesn’t run reliably” symptom is mostly (1), but (2–4) are why the refactor feels stalled and the architecture is hard to reason about.

---

## Evidence: Typed Array Mismatches (Primary reliability blocker)

These patterns violate the “Typed arrays are not vibes / Never return [] from a typed function” prescriptions.

### A) Returning untyped array literals from typed functions

- `scripts/systems/crafting_system.gd:25` returns `Array[String]` but does `return []` at `scripts/systems/crafting_system.gd:27`.
- `scripts/systems/game_state.gd:34` and many others return `Array[String]` but use array literals like `return [result.log]` (`scripts/systems/game_state.gd:45`) and `return ["No active character."]` (`scripts/systems/game_state.gd:126`).
- `scripts/systems/game_state.gd:158`, `:173`, `:190` return `Array[Dictionary]` but do `return []` (`scripts/systems/game_state.gd:159`, `:174`, `:191`).
- `scripts/services/session_service.gd:29` returns `Array[String]` but does `return []` (`scripts/services/session_service.gd:31`).
- `scripts/services/travel_service.gd:31` returns `Array[String]` but does `return []` (`scripts/services/travel_service.gd:33`).

### B) Typed arrays receiving untyped arrays

- `scripts/services/travel_service.gd:25` builds `subs: Array[String]` then does `subs.append_array(submap_nodes.keys())` (`scripts/services/travel_service.gd:27`). `Dictionary.keys()` is not `Array[String]`, so this is a frequent mismatch source.

### C) Casting from Dictionary with an untyped default

- `scripts/services/action_service.gd:18` returns `Array[String]` but does `return result.get("log", []) as Array[String]` (`scripts/services/action_service.gd:38`). The default `[]` is untyped and can “poison” the cast path.

### D) Array literals in typed returns (likely to break, depending on engine inference)

- `scripts/systems/save_system.gd:11` returns `Array[String]` but returns `[PRIMARY_BASE_DIR, FALLBACK_BASE_DIR]` (`scripts/systems/save_system.gd:12`).

**Conclusion:** this isn’t a single bug; it’s a systemic pattern. Fixing it requires a consistent strategy, not one-off patches.

---

## Evidence: UI Refactor Left Mid-Transition (Ownership + routing issues)

### A) “One UI router” is currently violated (multiple owners decide visibility)

- Panels directly change visibility on close:
  - e.g. `scenes/MapPanel.gd:35-37` sets `visible = false` and emits `close_requested`.
  - similar patterns in `scenes/TownPanel.gd`, `scenes/ZonePanel.gd`, `scenes/NodePanel.gd`.
- `scripts/controllers/navigation_controller.gd` hides/shows map/town/zone/node panels itself (`scripts/controllers/navigation_controller.gd:49-116`).
- `scenes/Main.gd` also hides/shows panels and handles close requests (`scenes/Main.gd:80-90`), and it maintains its own `_hide_sub_panels()` logic later in the file.

This creates conflicting state transitions and “who wins?” behavior (especially if multiple signals fire in the same frame).

### B) “_on_\* methods are signal handlers, never call cross-file” is violated

- `scenes/Main.gd:73` calls `_navigation_controller._on_open_map_requested()` directly.
- `scenes/Main.gd:96` calls `_navigation_controller._on_open_map_requested()` again from a TownPanel signal.
- `scenes/Main.gd:89` calls `_navigation_controller._on_open_zone_from_node()` directly.

These are private signal handlers being used as public APIs.

### C) Duplicate refresh paths

- `GameState` emits `state_changed` (`scripts/systems/game_state.gd:3`, `:236`).
- Controllers also emit `state_changed` and `Main` listens to them (`scenes/Main.gd:42`, `:48`, `:55`, `:61`), which then triggers `_on_state_changed()` and refresh.
- `Main._refresh_status()` calls `_refresh_open_panels()` again (so refresh cascades twice in some flows).

### D) Parallel/legacy controller architecture remains in `scenes/`

The legacy callable-based controllers still exist:

- `scenes/AccountController.gd`
- `scenes/InventorySkillsController.gd`
- `scenes/TownController.gd`

Meanwhile, the “new” controllers live in `scripts/controllers/`.

Even if these aren’t currently referenced by `.tscn` scripts, they represent “parallel architecture” and will continue to cause confusion/regressions.

---

## Evidence: Services / Systems boundaries don’t match the prescriptions

### A) Services mutate state and call autoloads directly

- `scripts/services/session_service.gd` calls `SaveSystem.*` and `CraftingSystem.reset()` directly.
- `scripts/services/action_service.gd` calls `EncounterSystem.resolve()` and `CraftingSystem.start_job()` directly.
- `scripts/services/travel_service.gd` mutates `player.stats` and `player.location` directly.

This conflicts with:

- “Services don’t own state”
- “One source of truth: GameState owns canonical state”
- “Domain rules don’t know Godot exists”

### B) Dictionary-as-contract is pervasive

Examples:

- `EncounterSystem.resolve(...) -> Dictionary` (`scripts/systems/encounter_system.gd`).
- `CraftingSystem.start_job(...) -> Dictionary` (`scripts/systems/crafting_system.gd:9`).
- `SessionService.select_account/create_account/... -> Dictionary` (`scripts/services/session_service.gd`).
- `Character.apply_rewards(...) -> Dictionary` (`scripts/core/character.gd`).

This conflicts with “No dictionaries as APIs” and is currently a major source of brittle glue code (`result.has("error")`, `result.get("log", [])`, etc.).

---

## End-to-End Trace (one feature path, showing why it’s hard to reason about)

“Open Map and travel to Lake” today looks roughly like:

1. `scenes/Main.gd` Map button calls controller private handler (`scenes/Main.gd:73`).
2. `NavigationController._on_open_map_requested()` toggles visibility itself (`scripts/controllers/navigation_controller.gd:49-60`).
3. `MapPanel` emits `select_zone`.
4. `NavigationController._on_map_zone_selected()` calls `GameState.travel_to_submap()` then toggles visibility and opens the next panel (`scripts/controllers/navigation_controller.gd:27-38`).
5. `GameState.travel_to_submap()` delegates to `TravelService.travel_to_submap()`, which mutates the player and returns logs, then `GameState` saves immediately and emits `state_changed`.
6. Multiple `state_changed` listeners (Main and controllers) refresh multiple times (duplicate paths).

This violates the “one paragraph explainable path” prescription because visibility, state mutation, saving, and refresh all happen in multiple places.

---

## Working Plan (staged, behavior-preserving)

### Phase 0 — Stabilize typing (make it run reliably) (highest priority)

**Goal:** zero typed-array runtime mismatches; game boots and core flows work consistently.

**Strategy choice (pick one, don’t mix):**

1. **Preferred:** Replace most `Array[String]` public APIs with `PackedStringArray`.
   - Pros: easy to construct (`PackedStringArray()` for empty; `PackedStringArray(["a"])` for literals), reduces mismatch risk.
   - Cons: touches many signatures (but the call sites are mostly internal and iterate-friendly).

2. **Alternative:** Keep `Array[String]` but ban array literals in typed returns and ban `return []`.
   - Requires: always build typed variables (`var logs: Array[String] = []; logs.append("..."); return logs`).

**Concrete tasks:**

- Fix every typed function that returns `[]` or `["..."]` or `[x]`.
  - Start with:
    - `scripts/systems/crafting_system.gd:25`
    - `scripts/systems/game_state.gd` (many)
    - `scripts/services/session_service.gd:29`
    - `scripts/services/travel_service.gd:31`
    - `scripts/services/action_service.gd:18` (remove `get(..., [])` with untyped default)
    - `scripts/systems/save_system.gd:11`
- Remove/replace `append_array(submap_nodes.keys())` (`scripts/services/travel_service.gd:27`) with a typed-safe loop.
- Add “typed-empty” helpers if staying with `Array[String]`:
  - e.g., `static func empty_string_array() -> Array[String]` (returns a correctly typed empty array).

**Acceptance criteria:**

- No “cannot convert Array to Array[String]” / typed array mismatch errors during:
  - startup + create account + create character
  - open map + travel + move node
  - harvest/combat once
  - start a craft + wait for completion

### Phase 1 — Single UI Router + single refresh pipeline (completed)

**Goal:** exactly one place owns panel visibility/mode switching, and there is exactly one canonical re-render path on state changes.

**What was implemented:**

- `NavigationController` is now the single UI router:
  - Exposes public methods `open_map()` / `open_zone_from_node()` instead of relying on private `_on_*` calls from `Main.gd`.
  - Owns panel close behavior for Map/Town/Zone/Node by connecting `close_requested` and toggling `visible` itself.
  - `Main.gd` no longer sets overlay `visible` in close handlers and no longer calls controller `_on_*` methods directly.
- Panels are dumb views regarding visibility:
  - `MapPanel`, `TownPanel`, `ZonePanel`, and `NodePanel` emit `close_requested` without mutating `visible` in `_on_close_pressed()`.
- ActionBar uses local signals instead of `SignalBus`:
  - `ActionBar.gd` now emits `open_inventory`, `open_skills`, and `save_exit` signals on button presses.
  - `InventorySkillsController.register_action_bar(action_bar)` wires these signals to `request_inventory()`, `request_skills()`, and `request_save_exit()`.
  - All ActionBars (main and overlays) are registered from `Main.gd` during `_setup_controllers()`.
- NodePanel Rest/Craft actions are mediated by `ActionController`:
  - NodePanel’s `rest_pressed` / `craft_pressed` are connected in `ActionController`, matching Zone/Town behavior, and call `GameState.rest()` / `GameState.start_craft(...)` via the controller.
- Canonical render path is `GameState`-driven:
  - Controller-level `state_changed` signals and emits were removed from `AccountController`, `InventorySkillsController`, `NavigationController`, and `ActionController`.
  - `Main.gd` only listens to `GameState.state_changed` and uses `_on_state_changed()` to call `_refresh_status()` and `_refresh_open_panels()` once per mutation.
  - Controller actions rely on `GameState` methods (which save and emit `state_changed`) to trigger UI updates, eliminating duplicate refresh paths.

**Acceptance criteria status:**

- Only the router (`NavigationController`) changes overlay visibility. ✔
- Only `GameState.state_changed` (plus the craft tick path in `_process`) triggers global re-render logic in Main; controller `state_changed` paths have been removed. ✔
- There are no remaining cross-file calls to controller `_on_*` handlers; public verbs are used instead. ✔

### Phase 2 — Remove parallel architecture (kill duplicate controllers fast)

**Goal:** there is one controller style and one location for controllers.

**Concrete tasks:**

- Delete or archive the legacy controllers in `scenes/` once confirmed unused:
  - `scenes/AccountController.gd`
  - `scenes/InventorySkillsController.gd`
  - `scenes/TownController.gd`
- Ensure `.tscn` files reference only panel/view scripts, not controller scripts.
- Update `refactor.md` to reflect the “single router + mediator controllers” reality (or revise the strategy if choosing a different pattern).

**Acceptance criteria:**

- There is exactly one controllers folder (recommended: `scripts/controllers/`).
- No “shadow” controllers remain that could be accidentally reattached in the editor.

### Phase 3 — Replace Dictionary-as-API with typed result objects (make contracts explicit)

**Goal:** no gameplay/service method returns a `Dictionary` as its contract.

**Concrete tasks (incremental, preserve behavior):**

- Introduce small typed result types in `scripts/core/` (or `scripts/core/results/`), e.g.:
  - `LogResult` (ok, logs, error)
  - `EncounterOutcome` (logs, down, energy_spent, damage, gained_items)
  - `CraftingStartOutcome` / `CraftingTickOutcome`
- Convert:
  - `EncounterSystem.resolve()` from `Dictionary` → `EncounterOutcome`.
  - `CraftingSystem.start_job()` from `Dictionary` → `CraftingStartOutcome`.
  - `SessionService.*` from `Dictionary` → typed session outcomes.
- Update `GameState` to translate outcomes → UI logs (and to decide save checkpoints).

**Acceptance criteria:**

- No call sites use `result.has("error")` / `result.get("log", ...)` for core flows.

### Phase 4 — Re-align services with “GameState owns mutation” + “domain doesn’t know Godot”

**Goal:** services compute outcomes; GameState applies them; infrastructure (saving, autoload systems) is only called from defined boundaries.

**Concrete tasks:**

- Convert services to pure-ish computation:
  - `TravelService` returns a `TravelPlan` (cost, new_location, log) without mutating player.
  - `ActionService` returns an `ActionOutcome` without calling autoloads.
- Move mutation + saving into `GameState`:
  - `GameState.apply_travel(plan)`; `GameState.apply_action(outcome)`.
- Make “engine-facing” dependencies explicit:
  - Persistence stays in `SaveSystem` (infrastructure).
  - `GameState` calls persistence at explicit checkpoints (see Phase 5).

**Acceptance criteria:**

- No `scripts/services/*.gd` file references `SaveSystem`, `CraftingSystem`, `EncounterSystem`, `SignalBus`, or SceneTree.

### Phase 5 — Persistence as a phase (define checkpoints, avoid “save after every mutation”)

**Goal:** saving is predictable, testable, and not a side effect of every small update.

**Concrete tasks:**

- Introduce a `dirty` flag in `GameState` and explicit `checkpoint_save(reason)` calls.
- Decide checkpoint policy (behavior-preserving initial recommendation):
  - Save after discrete player actions (travel/move/harvest/combat/rest/start craft).
  - Save when a craft job completes (not every tick).
  - Save on “Save & Exit”.
- Ensure UI-triggered save/exit does not bypass GameState (avoid duplicate save paths).

**Acceptance criteria:**

- No unconditional `_save_game()` calls inside all facade methods.
- “Save & Exit” uses one path and can be audited.

---

## Suggested immediate next move (most leverage)

Do Phase 0 first with a single type strategy.

Once Phase 0 is done, Phase 1 (single router + single render path) becomes much easier because the game will run reliably while you refactor.

---

## Progress Log

### Phase 0 (Typed array stabilization)

- Audited all `-> Array[String]` and `-> Array[Dictionary]` functions and removed unsafe literals:
  - Replaced `return []` and `return ["msg"]` with typed locals in:
    - `scripts/systems/game_state.gd` (session, action, inventory and tick paths).
    - `scripts/systems/crafting_system.gd:25-35` (crafting tick results).
    - `scripts/systems/save_system.gd:11-13` (`_base_dirs()` now builds a typed array).
    - `scripts/services/session_service.gd:29-32` (character name listing).
    - `scripts/services/travel_service.gd:25-40,42-104` (travel and node movement).
    - `scripts/services/action_service.gd:18-45,47-72` (encounters, rest, crafting).
- Removed typed-array misuse with `append_array`:
  - `scripts/services/travel_service.gd:25-30` now iterates `submap_nodes.keys()` and appends `String(key)` into a typed `Array[String]` instead of `append_array(submap_nodes.keys())`.
- Eliminated dictionary `get("log", [])` casts returning untyped defaults:
  - `scripts/services/action_service.gd:41-45` and `:68-72` copy logs out via `for entry in raw_log: logs.append(str(entry))` into a typed `Array[String]`.
- Verified via search:
  - No `return []` or `return ["..."]` remain in `scripts/`.
  - All `-> Array[String]` functions construct and return typed locals, including early-return branches.
- Quick engine sanity check:
  - A headless `godot4 --path .` run reaches native startup; the crash was in C++ log file handling (`user://logs/...`), not in GDScript parsing or typing. This suggests the script layer now parses and type-checks cleanly enough to load.

### Known Behavioral Issue

- The **NodePanel** rest and craft buttons were initially wired to emit `rest_pressed` / `craft_pressed` but were not connected in `ActionController`, so they had no effect when pressed.
  - This wiring gap explains why rest/craft previously did nothing in node scenes.
  - The Phase 1 routing work below includes ensuring NodePanel rest/craft are mediated through `ActionController` like the Zone/Town equivalents, restoring behavior via the controller path instead of ad-hoc handlers.

---

## Phase-by-Phase TODO (Checklist)

- ~~Phase 0 — Stabilize typing (make it run reliably).~~
- ~~Phase 1 — Single UI router + single refresh pipeline.~~
- ~~Phase 2 — Remove parallel architecture (kill duplicate controllers fast).~~
- Phase 3 — Replace Dictionary-as-API with typed result objects.
- Phase 4 — Re-align services with “GameState owns mutation” + “domain doesn’t know Godot”.
- Phase 5 — Persistence as its own phase with explicit checkpoints (no implicit save-after-every-mutation).
