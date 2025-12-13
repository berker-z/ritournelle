# Ritournelle – Ideas & Direction

This document is a **directional compass**, not a spec. It captures design intent, constraints, and high‑level systems to guide decisions without over‑engineering. If something here conflicts with fun or clarity, this document yields.

---

## Core Pillars

Ritournelle is a RuneScape‑like idle RPG focused on preparation, attrition, and legibility rather than reflexes. Player skill expresses itself in routing, loadouts, timing, and risk tolerance. Combat and harvesting are resource conversion processes, not tests of execution. Short sessions, explainable outcomes, and long‑term mastery are non‑negotiable.

The log is the product. Everything meaningful must be representable as readable text first. Visuals decorate outcomes; they do not define them.

---

## Harvest / Combat Split (Unified Danger Model)

Harvesting and combat are not separate systems; they are different _intentions_ applied to the same danger model.

Zones define danger parameters: encounter rate, encounter tier range, escape cost, and loot variance. Harvest nodes advance a hidden encounter meter as actions are taken. When the meter triggers, a combat encounter occurs. Combat zones skip the meter and trigger encounters immediately, in exchange for higher expected rewards.

This keeps harvesting tense without making it combat‑centric, and allows combat to be a chosen risk rather than a constant interruption.

Key idea: difficulty is not “can you win,” but “how expensive was staying.”

---

## Combat System (RuneScape‑Style, Semi‑Deterministic)

Combat is auto‑resolved and log‑driven. Internally it may run in rounds, but the player never inputs per turn.

Baseline outcomes are deterministic from stats, skills, gear, and node tier. RNG exists only as bounded variance around the baseline. Misses are rare once appropriately leveled. Damage variance tightens as combat skill increases.

Player agency happens before combat, not during it.

### Pre‑Combat Choices

- **Loadout**: gear, food, consumables.
- **Stance** (optional, single tap):

  - Aggressive: faster fights, higher incoming/outgoing damage.
  - Guarded: slower fights, reduced damage variance.
  - Escape‑minded: higher flee chance, worse rewards.

- **Commit or Flee**: always allow leaving at a cost.

### During Combat

- HP drains over time.
- Food auto‑consumes below thresholds.
- Status effects are rare, legible, and persistent (e.g. Injured).
- Logs narrate the exchange.

### Outcomes

- Victory: items, XP, sometimes injuries.
- Defeat: loss of carried items, forced return, lingering penalties. No permanent death.

High‑level combat feels _safer_, not swingier. Mastery reduces variance and waste.

---

## Crafting & Economy

Crafting is the backbone of progression and social meaning.

Crafting chains are intentionally shallow but wide. Many parallel paths, few deep trees. Tools and intermediate goods matter more than raw materials.

Crafting consumes time, inputs, and sometimes durability or catalysts. Outputs feed directly into combat efficiency, harvesting yield, or economic value.

Key principles:

- Crafting is always useful.
- The
