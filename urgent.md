# Urgent: InfoBox + Overlay Overlay Architecture

This document captures the current InfoBox bug, why it’s tricky, and the architecture changes we want for the overlay components so we stop fighting the UI instead of shipping features.

---

## 1. Status (current)

- Overlay strip refactored to a single `OverlayFrame` used by Main/Map/Town/Zone/Node; InfoBox/StatusBar authored as stacked children, not full-screen anchors.
- Layout now forces a real minimum size (OverlayFrame 420x260; InfoBox 220px tall) to stop the “sliver” issue; needs in-editor verification on target resolutions.
- Fix applied: `InfoBox.tscn` now anchors its internal `PanelContainer` to full-rect (previously it could remain effectively 0-sized inside container layouts), and log/status line rendering now converts to `PackedStringArray` before `join()` to avoid type-related no-op rendering.
- Log + status aggregation is centralized in `Main.gd`, pushing into each visible overlay frame via `set_log_lines` / `set_status_lines`.
- Remaining risk: if a parent container still constrains the frame, the InfoBox could shrink. Next step would be adjusting parent slot flags/margins on specific panels if the sliver persists.

In short: **the data is correct and flowing, but the bottom InfoBox in overlays is not reliably visible or sized**, especially in town.

---

## 2. Root Causes (Why it’s Misbehaving)

From the history of changes, the main causes are:

1. **Conflicting layout intentions**
   - `InfoBox.tscn` was originally authored as a “full panel” control (anchored on all sides, growing vertically).
   - We then started instancing it inside stacked containers (e.g. `BottomStack` in `OverlayFrame`, or `VBoxContainer` in Town/Node panels).
   - Anchors + grow flags from the “full‑screen” version conflict with the expected “stacked child” behavior, so **Godot’s container tries to reconcile them and ends up starving InfoBox of height**.

2. **Multiple competing bottom‑strip layouts**
   - Main uses its own scroll + `LogBox` + `StatusBar` layout.
   - NodePanel and TownPanel each have their own `VBoxContainer` with a local `ActionBar` and InfoBox.
   - We introduced `OverlayFrame` as a third pattern (ActionBar + StatusBar + InfoBox in a bottom strip) and partially wired TownPanel to it.
   - This created **parallel layouts for the same conceptual UI**, with overlapping responsibilities and inconsistent anchoring.

3. **Too many owners for log rendering**
   - `Main.gd` maintains `_log_lines` and pushes them into:
     - Main’s `LogBox`.
     - TownPanel/ZonePanel/NodePanel via `panel.set_log_lines(...)`.
   - Controllers also emit `log_produced` and sometimes trigger refresh paths.
   - The “who actually paints the log here?” responsibility is smeared across Main, panels, and (attempted) overlay components.

The combination of “layout objects fighting” and “log rendering responsibility spread across three layers” is why simple tweaks keep breaking InfoBox instead of fixing it.

---

## 3. Desired Overlay Architecture (End State)

We need a clean, boring, **one–way** flow for status + logs in all full‑screen panels.

### 3.1 Single Overlay Component per Screen

- Introduce a **single reusable `OverlayFrame`** that lives at the bottom of all full‑screen screens (Main, Map, Town, Zone, Node):
  - Anchored to the bottom of the viewport.
  - Internally stacked as:
    - `ActionBar` (Inventory / Skills / Save).
    - `StatusBar` (location + HP + energy).
    - `InfoBox` (global action log).
- Every full‑screen panel that needs the bottom strip **hosts exactly one `OverlayFrame` instance**.
  - Panels never re‑implement their own ActionBar + InfoBox combos.
  - There is exactly one layout definition for this strip.

### 3.2 Dumb Views, Smart State

- `StatusBar`:
  - A dumb component that knows how to render an array of lines.
  - It does **not** pull from GameState or compute anything; it only paints what it is given.
- `InfoBox`:
  - A dumb component that renders an array of log lines and scrolls.
  - It does not know about GameState, controllers, or panels.
- `OverlayFrame`:
  - Knows how to find its `ActionBar`, `StatusBar`, and `InfoBox`.
  - Exposes a minimal API:
    - `set_status_lines(lines: Array)`
    - `set_log_lines(lines: Array)`
  - This keeps the bottom strip a black box from the outside: **call OverlayFrame with data; don’t poke into its children**.

### 3.3 Single Aggregator for Status + Logs

- **Logs**:
  - `Main` (or a small `UiLogController`) owns `_log_lines` as the global rolling buffer.
  - When logs change:
    - It updates Main’s own view.
    - It calls `overlay_frame.set_log_lines(_log_lines)` on whichever overlay(s) are currently visible.
  - Panels do not compute or store logs; they just pass them into `OverlayFrame` if they need.

- **Status**:
  - `Main._refresh_status()` continues to compute the status view‑model from `GameState`:
    - Either “No account selected” / “No active character…” or
    - A single line like `Location: X | HP a/b | Energy c/d`.
  - It writes that into:
    - Main’s StatusBar.
    - Each visible overlay frame via `overlay_frame.set_status_lines(status_lines)`.

**Important:** Panels themselves don’t format strings or introspect GameState. They should only:

- Emit intent signals (rest, craft, open_map, etc.).
- Hold references to their local `OverlayFrame` and hand data to it when the controller/aggregator asks them to.

---

## 4. Why These Changes Matter

1. **Fixes InfoBox sizing deterministically**
   - With one OverlayFrame layout and InfoBox authored as a normal stacked child, we eliminate the anchor vs. container fight that is currently shrinking InfoBox to a sliver.
   - All full‑screen panels share the same bottom strip, so one fix applies everywhere.

2. **Restores clear ownership**
   - GameState + services own state and log content.
   - A single place (Main or a dedicated UI controller) owns the status/log view‑model.
   - OverlayFrame owns rendering of status + logs + bottom actions.
   - Panels are dumb containers and signal emitters.

3. **Reduces the chance of future breakage**
   - Today, changing InfoBox’s scene or a panel’s layout can silently break another panel because there are multiple ad‑hoc layouts.
   - With one OverlayFrame:
     - Layout is changed in exactly one place.
     - The contract is narrow: “call `set_status_lines` and `set_log_lines`”.

4. **Keeps us aligned with project guidelines**
   - “UI is dumb. UI emits requests and re‑renders from state.”
   - “One UI router. Exactly one place decides visibility and mode switching.”
   - “No duplicate refresh paths. State changes trigger exactly one canonical re‑render path.”

Right now, InfoBox being tiny / empty is the visible symptom of underlying architectural drift. The plan above is about fixing both: **make InfoBox clearly visible and functional again, and converge the overlay architecture so we stop re‑breaking it every time we touch panels.**
