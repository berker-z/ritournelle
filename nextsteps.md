# Next Steps: UI Ownership Cleanup (Logs + Status)

This document describes the current UI ownership issues around status/log rendering, why they feel “off” relative to `AGENTS.md`, and a low-churn path to bring the code back in line.

It is intentionally a **refactor note** (not a roadmap). The authoritative architecture snapshot remains `structure.md`.

---

## 1) What Feels Wrong Today (And Why)

### 1.1 `Main.gd` is both composition root *and* presenter

Current behavior:

- `Main.gd` instantiates and wires controllers (good; composition root).
- `Main.gd` also:
  - Owns a rolling log buffer (`_log_lines`).
  - Formats the status line strings (`_current_status_lines`).
  - Decides which overlay frames get updated based on panel visibility.

Why this feels wrong:

- It mixes two responsibilities:
  - **Composition** (wiring nodes/controllers; stable, one-time setup).
  - **UI view-model/presentation** (rolling buffers, string formatting, refresh fan-out; frequently changing).
- That increases churn risk: a “layout/view fix” tends to require touching `Main.gd`, which is also where routing and controller wiring live.

### 1.2 Status/log formatting should not live in `GameState`

`GameState` should own authoritative **data** (location, HP/energy values), not UI string formatting.

If `GameState` starts emitting preformatted strings (“Location: … | HP …”), it becomes harder to:

- Change UI presentation without touching domain code.
- Localize text later.
- Reuse the same state for multiple UIs (HUD vs debug vs log view).

So the problem is not “`Main.gd` formats strings” per se — it’s **where** that formatting lives and how it’s wired.

### 1.3 `OverlayFrame.gd` is the correct place for `set_*` methods

Keeping `OverlayFrame.gd` as a thin adapter is good:

- `OverlayFrame` owns how its children (`ActionBar`, `StatusBar`, `InfoBox`) are found and updated.
- Callers own *when* to update and *what* data to pass.

The line we should not cross:

- `OverlayFrame` must not read `GameState` or decide panel visibility.

---

## 2) Target Ownership (Matches `AGENTS.md`)

In one paragraph:

- `GameState` owns the runtime state and emits `state_changed`.
- Controllers own routing/actions and emit semantic outputs (including logs as data).
- A single UI-layer presenter owns the **view-model** (log buffer + status lines) and pushes it into whichever `OverlayFrame` is visible.
- `OverlayFrame` renders what it is given and re-emits user intent signals from `ActionBar`.

---

## 3) Low-Churn Refactor Plan (Suggested)

### Step A — Introduce a UI presenter controller

Create `scripts/controllers/ui_overlay_presenter.gd` (name bikeshed OK) that owns:

- `_log_lines: Array[String]`
- `_status_lines: Array[String]`

Responsibilities:

- Subscribe to `GameState.state_changed` and rebuild `_status_lines` (pure UI view-model).
- Accept log lines from other controllers (e.g. connect to their `log_produced` signals) and append into `_log_lines`.
- Push updates into currently visible overlay frames via `OverlayFrame.set_status_lines()` / `set_log_lines()`.

Key point: this presenter does not route panels; it only pushes view-model to frames.

### Step B — Make `Main.gd` a composition root only

Move these responsibilities out of `Main.gd` into the presenter:

- `_log_lines` buffer management.
- `_refresh_log_outputs()` fan-out.
- `_refresh_status()` string formatting and status push.

`Main.gd` keeps:

- Instantiating controllers.
- Providing references (overlay frames/panels) to the presenter.
- High-level app lifecycle (Save & Exit quit, etc.).

### Step C — Tighten typing contracts (avoid Variant creep)

Common pitfalls we should standardize away:

- Prefer `Array[String]` for log and status lines at boundaries.
- When joining, convert to `PackedStringArray` (or explicitly build `Array[String]`) before `"\n".join(...)`.
- Avoid signals that sometimes emit `String` and sometimes `Array` — pick one.

---

## 4) Definition of Done (Smoke Check)

- Launch the game.
- Create/select account and character.
- Open Map/Town/Zone/Node panels and verify:
  - Status line updates after travel/actions.
  - InfoBox shows log lines at correct size (not a sliver).
  - No panel has its own separate log/status ownership.
