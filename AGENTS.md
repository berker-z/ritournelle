# Godot Development Guidelines & Best Practices

This document outlines the architectural principles and coding standards for this Godot 4 project. It reflects the recent refactoring to a Service-Oriented + MVC Architecture.

## 1. Architectural Patterns

### Composition Root (Main.gd)
- **Role**: Wiring only.
- **Responsibilities**:
  - Instantiates Controllers.
  - Injects dependencies (UI Panels, Services) into Controllers.
  - Connects top-level signals (e.g., `SignalBus` to Controller methods).
- **Anti-Pattern**: DO NOT put game logic, state management, or complex signal references in `Main.gd`.

### Controllers (`scripts/controllers/`)
- **Role**: Mediators between UI (View) and Logic (Services/State).
- **Responsibilities**:
  - Listen to UI signals (e.g., `button_pressed`).
  - Call Service methods (via `GameState` facade or direct Service injection).
  - Listen to State keys/signals (e.g., `state_changed`) to trigger UI updates.
  - Manage UI visibility and mode switching.
- **Rules**:
  - Controllers should NOT contain business logic (damage calc, travel costs).
  - Controllers should NOT hold game state (player inventory, etc.).

### Services (`scripts/services/`)
- **Role**: Pure business logic and data manipulation.
- **Example**: `TravelService`, `SessionService`, `ActionService`.
- **Responsibilities**:
  - Perform calculations (costs, damage, RNG).
  - Update data models (`Character`, `Inventory`).
  - Return detailed results (Logs, Success/Fail status) to the caller.
- **Rules**:
  - Services should be strictly typed.
  - Services should generally be stateless or managed by `GameState`.
  - Services should NOT access the SceneTree or UI nodes directly.

### Facade (`GameState.gd`)
- **Role**: Central access point for global state and persistence.
- **Responsibilities**:
  - Holds the "Source of Truth" (`account`, `player`, `current_submap`).
  - Delegates specific actions to Services (`_travel_service.travel_to_submap()`).
  - Triggers Persistence (`_save_game()`) after state mutations.
  - Emits global `state_changed` signal.

---

## 2. Coding Standards

### Type Safety
- **Strict Typing**: ALWAYS use strict typing for variables and function returns.
  - **Good**: `func get_items() -> Array[String]:`
  - **Bad**: `func get_items() -> Array:`
- **Collections**: Use typed arrays `Array[Type]` whenever possible. Godot 4 optimizes these significantly.
- **Dictionaries**: Add comments describing the shape of Dictionaries if strict typing isn't possible, or prefer custom `RefCounted` classes/Resources.

### Signal Management
- **SignalBus**: Use `SignalBus` (Autoload) for global, cross-cutting events (e.g., `inventory_requested`, `game_over`, `level_up`).
- **Direct Connections**: Use direct signal connections `object.signal.connect(callable)` instead of the editor UI for dynamic components.
- **No Bubbling**: Do not "proxy" or re-emit signals up a UI hierarchy component-by-component.
  - **Bad**: `Button` -> `Panel` -> `Main` -> `Controller`.
  - **Good**: `Button` emits to `SignalBus` OR `Controller` connects directly to `Button` via `Scene` ownership.

### Constants & Magic Values
- **GameConstants**: Store all magic strings ("town", "combat"), paths, and configuration numbers (costs, IDs) in `scripts/core/game_constants.gd`.
- **Enums**: Prefer `const` or `enum` over string literals.

---

## 3. Project Structure conventions

- `scenes/`: `.tscn` files. Segregate by domain (`UI`, `World`, `Characters`).
- `scripts/`:
  - `core/`: Data models (`Character`, `Account`, `Inventory`).
  - `controllers/`: Logic mediators (`NavigationController`).
  - `services/`: Business logic (`TravelService`).
  - `systems/`: Global managers (`GameState`, `SaveSystem`).
- `data/`: Static data files (`items.gd`, `maps.gd`) - *Consider moving to Resources in future*.

---

## 4. Workflows

### Creating a New Feature
1. **Model**: Define data structures in `scripts/core/`.
2. **Service**: Implement business logic in a Service class.
3. **Facade**: Expose relevant methods via `GameState` (if global) or inject Service.
4. **UI**: Create the View (Scene/Panel).
5. **Controller**: Create a Controller to wire the View to the Service/Facade.
6. **Main**: Register the Controller.

### Refactoring Legacy Code
1. Identify logic in `Main.gd` or UI scripts.
2. Extract logic to a Service.
3. Replace direct calls with Service calls.
4. Clean up `has_method` or dynamic calls; replace with Signals or Types.
