# Plan for creating the Godot spellcraft arena

## Objective
Craft a fast-paced multiplayer arena that relies on Godot primitives (ColorRects, Labels, procedural materials) while enabling local-first and future online multiplayer, spell/weapon crafting, controller-motion combos, target switching, and destructible terrain—all orchestrated from a single `MainArena` scene.

## Central Planning Document
This file will serve as the living blueprint. Each section below can expand into AGENTS.md later, where we describe how autonomous agents can split the work into coordinated phases.

## High-Level Phases
1. **Discovery & Input Language** – Define player actions, feasible controller motion combos, crafting recipes, and desired feel (speed, telegraphing, damage thresholds). Output tables of combos, target behaviors, and crafting outcomes.
2. **Core Scene & Movement** – Build the arena layout, player nodes, input maps, and motion physics. This includes spawning a basic terrain grid with destructible chunks, setting up split/shared-screen cameras, and wiring movement/target lock visuals.
3. **Combat Systems** – Script spell/weapon crafting, combo detection, damage application, and line-of-sight checks. Separate subsystems for spell composition, weapon binding, and attack execution so they can be tuned independently.
4. **Multiplayer & State Sync** – Create local input handling per player and the shared arena state manager; design hooks for future netcode (e.g., synced player positions, arena events). Define scoring/round/state transitions.
5. **Polish & Feedback** – Implement UI feedback, sound cues (via simple ToneGenerators), destruction VFX (color tweens, animated ColorRects), and restart/progression logic.

## Parallel Systems for Agent Workstreams
Agents can work concurrently on the following streams per phase:

| Stream | Description | Dependencies |
|--------|-------------|--------------|
| **Scene/Nodes** | Layout of arena grid, destructible terrain, target indicators, cameras, HUD nodes. | Phase 1 outputs (combo definitions) for indicator labels. |
| **Player Input & Movement** | Player controller mapping, motion parsing, target locking/switching, cooldowns. | Scene structure to attach scripts. |
| **Combat & Crafting** | Spell/weapon crafting UI/data, combo recognition logic, damage/line-of-sight, destructible terrain interactions. | Input system for motion combos. |
| **Multiplayer State** | Local split/shared-screen coordination, arena state manager, scoreboard, matchflow. | Player movement + combat events. |
| **Feedback & Polish** | UI updates, color tweens, sound cues, simple particle effects using shaders or Material overrides. | Combat events for triggers. |

Agents working in parallel should hold regular checkpoints to update the central document with data models (combo tables, crafting recipes, target priority rules) to keep other streams aligned.

## Next Steps
- Finalize workspace for phase details and assign create/update instructions for AGENTS.md.
- Expand each stream with specific tasks (e.g., "Design combo grammar", "Prototype destructible tile damage") and note which agents can own them.
- Gather references for motion combo recognition (e.g., motion buffers, gestures) to seed the Combat stream before scripting.
