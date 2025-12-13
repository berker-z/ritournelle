# Ritournelle – Game Design & Plans

This document captures the **high‑level game fantasy and future ideas**. It is intentionally light on implementation detail; the current architecture and file layout are documented in `design.md`.

---

## Core Fantasy

- You play as a single character who:
  - Goes on short, deterministic expeditions from a safe home base.
  - Manages energy, time, and resources across days.
  - Grows through skills, equipment, and crafting rather than fast level‑ups.
- The game is designed for:
  - Mobile‑style, asynchronous play (short sessions, long‑running timers).
  - High legibility: every action is logged; outcomes are explainable.

---

## Current Core Loops

- **Harvest Loop**
  - Travel from town to a zone/node (energy cost).
  - Perform harvest actions at nodes (energy per action).
  - Return to town, craft outputs, and store or “sell” in your own economy.
- **Combat Loop**
  - Encounters can trigger at nodes (or be chosen explicitly).
  - Combat auto‑resolves using stats, skills, equipment, and node tier.
  - On success: gain items + XP; on failure: risk losing carried items, but never permanent death.
- **Crafting Loop**
  - Queue recipes at crafting “stations” (currently abstracted).
  - Wait for timers, collect items and XP when jobs complete.

---

## Planned Systems & Content (High‑Level)

These are **directions**, not commitments; they should be refined before implementation.

### Systems & Progression

- Stats and skills:
  - Make stats and skills materially affect harvest yields, combat damage, and action timers.
  - Tune XP curves to make early gains quick and later gains deliberate.
- Energy and pacing:
  - Add passive energy regeneration and/or sleep timers.
  - Log session durations to tune idle play patterns.
- Failure and recovery:
  - Expand defeat into recoverable states (lose carried items, reclaim them via low‑risk nodes or quests).

### Crafting & Economy

- Crafting:
  - Persist crafting queues and support offline progress via real‑time deltas.
  - Introduce more recipes and recipe tiers that link into specific zones and materials.
- Shared stash and trading:
  - Expose shared stash in the UI and support stash‑based crafting.
  - (Future) Consider simple player‑to‑player or asynchronous trading, ensuring it remains non pay‑to‑win.

### World & Content Backlog

- Materials and tools:
  - Tiered material categories (wood, ore, hides, herbs, etc.) with processing chains (smelting, tanning, preparation).
  - Tool‑gated harvesting with quality tiers for tools, weapons, and armor.
- New resources and loops:
  - Coins as a currency (drops, smelting gold, selling items).
  - Hunger/food as a managed stat tied into cooking and rest.
  - Carry weight limits to shape inventory decisions.
- Encounters and zones:
  - Zone‑specific encounter rates and behaviors (e.g. safer lake, dangerous mountains).
  - A dedicated high‑risk combat zone that leans into the log‑driven combat loop.
