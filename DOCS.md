# Dungeon Cleaner — Project Documentation

**Engine:** Godot 4.6
**Viewport:** 320×180 (nearest-neighbor pixel-perfect)
**Main Scene:** `res://Scenes/General/main.tscn`

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Directory Structure](#2-directory-structure)
3. [Project Configuration](#3-project-configuration)
4. [Architecture & Design Patterns](#4-architecture--design-patterns)
5. [Player System](#5-player-system)
6. [Interactable System](#6-interactable-system)
7. [Resource Data Classes](#7-resource-data-classes)
8. [Manager Systems](#8-manager-systems)
9. [UI System](#9-ui-system)
10. [Main Scene Layout](#10-main-scene-layout)
11. [Gameplay Flow & Mechanics](#11-gameplay-flow--mechanics)
12. [Signals Reference](#12-signals-reference)
13. [Physics Layers](#13-physics-layers)
14. [What's Not Yet Implemented](#14-whats-not-yet-implemented)

---

## 1. Project Overview

A top-down 2D pixel-art dungeon-cleaning game. The player is a janitor tasked with cleaning up a dungeon before a timer runs out. Tasks include:

- Picking up and depositing **bones** in a trashcan
- Cleaning **blood stains** using a mop
- Pushing a **box** to a marked target position

All interactive objects share a common base class and communicate with the level manager via signals.

---

## 2. Directory Structure

```
dungion-cleaner/
├── Assets/
│   ├── Minimal Dungeon - Asset Pack DEMO/   # Dwarf sprite, tileset, palette
│   └── free-2d-top-down-pixel-dungeon-asset-pack/
│       └── PNG/
│           ├── walls_floor.png
│           └── Objects.png                  # Source for all interactable sprites
├── Resources/                               # (empty — for future .tres files)
├── Scenes/
│   ├── General/
│   │   └── main.tscn                        # Main level scene (root)
│   ├── Charecters/Player/
│   │   └── player.tscn
│   ├── Interactables/
│   │   ├── interactable_base.tscn           # Base template (not used directly)
│   │   ├── bone.tscn
│   │   ├── blood.tscn
│   │   ├── box.tscn
│   │   ├── mop.tscn
│   │   ├── trashcan.tscn
│   │   └── cleaning_station.tscn
│   └── Ui/
│       └── hud.tscn
├── Scripts/
│   ├── Charecters/Player/
│   │   └── player.gd
│   ├── Interactables/
│   │   ├── Interactable.gd                  # Base class
│   │   ├── Bone.gd
│   │   ├── Blood.gd
│   │   ├── Box.gd
│   │   ├── Mop.gd
│   │   ├── Trashcan.gd
│   │   └── CleaningStation.gd
│   ├── Managers/
│   │   └── LevelManager.gd
│   ├── Resources/
│   │   ├── InteractableData.gd              # Base resource
│   │   ├── BoneData.gd
│   │   ├── BloodData.gd
│   │   ├── BoxData.gd
│   │   ├── MopData.gd
│   │   ├── TrashcanData.gd
│   │   └── CleaningStationData.gd
│   └── Ui/
│       └── hud.gd
├── project.godot
├── TASKS.md                                 # Phase-by-phase task tracking
└── DOCS.md                                  # This file
```

---

## 3. Project Configuration

**`project.godot` highlights:**

| Setting | Value |
|---|---|
| Window size | 320 × 180 |
| Stretch mode | viewport |
| Canvas texture filter | nearest (pixel-perfect) |
| Input: `interact` | E key (keycode 69) |
| Physics layer 1 | Player |
| Physics layer 2 | Environment |
| Physics layer 3 | Interactables |

---

## 4. Architecture & Design Patterns

### Interactable Base Class
All interactive objects inherit from `Interactable.gd` (extends Node2D). It handles:
- Area2D proximity detection → calls player methods
- Virtual methods (`interact`, `takes_priority_over_carry`, `cleaning_progress`, `cleaning_cancelled`)
- Signal emission (`task_completed`, `player_nearby`)

### Resource Data Objects
Each interactable type has a paired `*Data.gd` class (extends `InteractableData`) for configurable properties like speed multipliers, clean times, push speeds. These are exported on the scene node so values can be tweaked in the Godot editor without touching code.

### Player State Machine
`player.gd` uses an `enum State { IDLE, MOVING, CARRYING, CLEANING, PUSHING }`. State transitions are handled through `change_state()` which also updates speed multipliers.

### Signal-Based Communication
- Interactables emit `task_completed` → caught by `LevelManager`
- `LevelManager` emits `task_updated`, `timer_tick`, `level_complete`, `level_failed`, `interaction_prompt_changed` → caught by `HUD`
- No direct references between unrelated systems

### E Key Priority System
When E is pressed, `player.gd` routes the input based on context:
1. If carrying AND nearby interactable has `takes_priority_over_carry() == true` → interact with that object
2. Else if carrying → drop/interact with carried item
3. Else if nearby interactable → interact with it

### Task Tracking
`LevelManager` only counts interactables where `counts_as_task == true`. Mop, Trashcan, and CleaningStation have `counts_as_task = false` — they are tools, not goals.

---

## 5. Player System

**Script:** [Scripts/Charecters/Player/player.gd](Scripts/Charecters/Player/player.gd)
**Scene:** [Scenes/Charecters/Player/player.tscn](Scenes/Charecters/Player/player.tscn)

### Node Structure
```
CharacterBody2D (player.gd)
├── Sprite2D          — 4×12 frame sheet (prototype_character.png)
├── CollisionShape2D  — CircleShape2D, radius 3.0
└── AnimationPlayer   — 8 animations
```

### States

| State | Description |
|---|---|
| `IDLE` | Standing still |
| `MOVING` | Walking with WASD/arrows |
| `CARRYING` | Holding a bone or mop, speed reduced |
| `CLEANING` | Holding E at a blood stain, mop in hand |
| `PUSHING` | Pushing a box along a locked axis |

### Constants & Properties

| Property | Default | Description |
|---|---|---|
| `BASE_SPEED` | 50 px/s | Walking speed |
| `carry_speed_multiplier` | 1.0 | Set by carried item's data |
| `carried_item` | null | Reference to held Node |
| `push_axis` | `""` | `"horizontal"` or `"vertical"` while pushing |
| `nearby_interactable` | null | Most recent interactable in range |
| `last_direction` | `"down"` | For idle animation facing |

### Key Methods

| Method | Description |
|---|---|
| `_physics_process(delta)` | Movement, state transitions, animation |
| `_handle_interact_input(delta)` | E key press and hold logic |
| `change_state(new_state)` | State transition, updates speed |
| `set_nearby_interactable(node)` | Called by Interactable on body_entered |
| `clear_nearby_interactable(node)` | Called by Interactable on body_exited |
| `_update_carried_item()` | Keeps carried item snapped to player position |

### Animations
`idle_down`, `idle_up`, `idle_left`, `idle_right`,
`move_down`, `move_up`, `move_left`, `move_right`

---

## 6. Interactable System

### Base Class — `Interactable.gd`

**Script:** [Scripts/Interactables/Interactable.gd](Scripts/Interactables/Interactable.gd)

```
Signals:
  task_completed(interactable: Node)
  player_nearby(is_near: bool)

Exports:
  data: InteractableData
  counts_as_task: bool = true

Virtual methods (override in subclasses):
  interact(player: Node) -> void
  takes_priority_over_carry() -> bool   # default: false
  cleaning_progress(delta: float) -> void
  cleaning_cancelled() -> void
```

The base scene (`interactable_base.tscn`) adds:
- `Sprite2D` for visuals
- `InteractionArea` (Area2D + CircleShape2D, radius 12.0) for proximity detection

---

### Bone

**Script:** [Scripts/Interactables/Bone.gd](Scripts/Interactables/Bone.gd)
**Scene:** [Scenes/Interactables/bone.tscn](Scenes/Interactables/bone.tscn)
**Data:** [Scripts/Resources/BoneData.gd](Scripts/Resources/BoneData.gd) — `carry_speed_multiplier: 0.7`
**counts_as_task:** true

- Press E near bone → picked up, reparented to player, player enters CARRYING
- Press E again → dropped at `player.global_position + Vector2(0, 14)`
- Speed reduced to 70% while carried

---

### Blood

**Script:** [Scripts/Interactables/Blood.gd](Scripts/Interactables/Blood.gd)
**Scene:** [Scenes/Interactables/blood.tscn](Scenes/Interactables/blood.tscn)
**Data:** [Scripts/Resources/BloodData.gd](Scripts/Resources/BloodData.gd) — `clean_time: 2.0`, `reset_on_release: false`
**counts_as_task:** true
**takes_priority_over_carry:** true

- Requires player to carry a **clean mop**
- Hold E → player enters CLEANING, ProgressBar fills over `clean_time` seconds
- Release E → progress pauses (or resets if `reset_on_release = true`)
- On completion → `mop.make_dirty()`, task_completed emitted, blood hidden
- Sprite: red-modulated tile from `Objects.png` at region (64, 32, 16×16)
- Has a ProgressBar child shown during cleaning

---

### Box

**Script:** [Scripts/Interactables/Box.gd](Scripts/Interactables/Box.gd)
**Scene:** [Scenes/Interactables/box.tscn](Scenes/Interactables/box.tscn)
**Data:** [Scripts/Resources/BoxData.gd](Scripts/Resources/BoxData.gd) — `push_speed: 30.0`, `target_position: Vector2.ZERO`, `snap_distance: 4.0`
**counts_as_task:** true
**Root node type:** StaticBody2D (blocks physics bodies)

- Press E near box → player enters PUSHING, axis locked based on approach direction
  - Approached from left/right → horizontal-only movement
  - Approached from top/bottom → vertical-only movement
- Box moves at `push_speed` in the locked axis
- `TargetIndicator` ghost sprite shows destination (reparented to scene root on start)
- When within `snap_distance` of target → snaps, ghost hides, task_completed emitted
- Press E to detach from box → player returns to IDLE

---

### Mop

**Script:** [Scripts/Interactables/Mop.gd](Scripts/Interactables/Mop.gd)
**Scene:** [Scenes/Interactables/mop.tscn](Scenes/Interactables/mop.tscn)
**Data:** [Scripts/Resources/MopData.gd](Scripts/Resources/MopData.gd) — `carry_speed_multiplier: 0.8`
**counts_as_task:** false

- Pickup/drop like Bone
- `is_dirty: bool` tracks state
- `make_dirty()` → sprite modulate = `Color(0.6, 0.4, 0.2, 1.0)` (brownish)
- `make_clean()` → sprite modulate = `Color(1.0, 1.0, 1.0, 1.0)` (white)
- Must be clean to use on blood

---

### Trashcan

**Script:** [Scripts/Interactables/Trashcan.gd](Scripts/Interactables/Trashcan.gd)
**Scene:** [Scenes/Interactables/trashcan.tscn](Scenes/Interactables/trashcan.tscn)
**counts_as_task:** false
**takes_priority_over_carry:** true

- Press E while carrying a bone → bone is hidden and emits `bone.task_completed`
- Does not emit its own `task_completed`
- Only works if player is in CARRYING state

---

### CleaningStation

**Script:** [Scripts/Interactables/CleaningStation.gd](Scripts/Interactables/CleaningStation.gd)
**Scene:** [Scenes/Interactables/cleaning_station.tscn](Scenes/Interactables/cleaning_station.tscn)
**counts_as_task:** false
**takes_priority_over_carry:** true

- Press E while carrying a dirty mop → calls `mop.make_clean()`
- Only works if player carries a Mop that `is_dirty == true`

---

## 7. Resource Data Classes

All extend `InteractableData` which extends `Resource`.

**Base — `InteractableData.gd`:** [Scripts/Resources/InteractableData.gd](Scripts/Resources/InteractableData.gd)
```
display_name: String = "Object"
interaction_prompt: String = "Interact [E]"
```

| Class | File | Extra Properties |
|---|---|---|
| `BoneData` | [Scripts/Resources/BoneData.gd](Scripts/Resources/BoneData.gd) | `carry_speed_multiplier: float = 0.7`, `is_weapon: bool = false` |
| `BloodData` | [Scripts/Resources/BloodData.gd](Scripts/Resources/BloodData.gd) | `clean_time: float = 2.0`, `reset_on_release: bool = false` |
| `BoxData` | [Scripts/Resources/BoxData.gd](Scripts/Resources/BoxData.gd) | `push_speed: float = 30.0`, `target_position: Vector2 = ZERO`, `snap_distance: float = 4.0` |
| `MopData` | [Scripts/Resources/MopData.gd](Scripts/Resources/MopData.gd) | `carry_speed_multiplier: float = 0.8` |
| `TrashcanData` | [Scripts/Resources/TrashcanData.gd](Scripts/Resources/TrashcanData.gd) | (inherits base only) |
| `CleaningStationData` | [Scripts/Resources/CleaningStationData.gd](Scripts/Resources/CleaningStationData.gd) | (inherits base only) |

---

## 8. Manager Systems

### LevelManager

**Script:** [Scripts/Managers/LevelManager.gd](Scripts/Managers/LevelManager.gd)
**Node type:** Node (added directly to main.tscn)

**Exports:**
```
time_limit: float = 120.0   # seconds
```

**Emitted Signals:**

| Signal | When |
|---|---|
| `task_updated(task_key, task_label, completed)` | Any interactable emits task_completed |
| `timer_tick(seconds_left)` | Every frame (for HUD countdown) |
| `level_complete` | All tasks done |
| `level_failed` | Timer reaches 0 |
| `interaction_prompt_changed(text, show)` | Player enters/exits interactable range |

**Responsibilities:**
- On `_ready`: finds all nodes in group `"interactables"`, connects to their `task_completed` and `player_nearby` signals
- Counts only interactables where `counts_as_task == true`
- Ticks countdown timer each frame, emits `timer_tick`
- Emits `level_complete` when `_tasks_done >= _tasks_total`

> **Note:** All interactable scenes must be in the `"interactables"` group for LevelManager to detect them.

---

## 9. UI System

### HUD

**Script:** [Scripts/Ui/hud.gd](Scripts/Ui/hud.gd)
**Scene:** [Scenes/Ui/hud.tscn](Scenes/Ui/hud.tscn)
**Node type:** CanvasLayer

**Scene structure:**
```
CanvasLayer (hud.gd)
├── TimerLabel              — top-left, MM:SS countdown
├── TasksPanel              — top-right, PanelContainer > VBoxContainer > [Labels]
├── InteractionPrompt       — bottom-center, Label (hidden when no interactable nearby)
└── CarryingIndicator       — bottom-left, HBoxContainer > Icon + ItemName Label
```

**Key Methods:**

| Method | Description |
|---|---|
| `update_timer(seconds_left)` | Formats float to MM:SS string |
| `add_task(task_key, task_label)` | Appends Label to TasksPanel |
| `complete_task(task_key)` | Prepends "[x] " to task label text |
| `show_prompt(text)` / `hide_prompt()` | Toggles InteractionPrompt visibility |
| `show_carrying(item_name)` / `hide_carrying()` | Toggles CarryingIndicator |

- Listens to `LevelManager.task_updated` and `LevelManager.interaction_prompt_changed`
- `_process()` polls player state to update CarryingIndicator each frame

---

## 10. Main Scene Layout

**Scene:** [Scenes/General/main.tscn](Scenes/General/main.tscn)

```
Node2D "Main"
└── Level (Node2D)
    ├── Floor (TileMapLayer)          — walkable floor tiles
    ├── Walls (TileMapLayer)          — collision walls
    ├── Player                        @ (149, 86)
    ├── Bone                          @ (299, 71)
    ├── Blood                         @ (72, 73)
    ├── Blood2                        @ (65, 109)
    ├── Blood3                        @ (66, 152)
    ├── Box                           @ (297, 153)
    ├── Mop                           @ (71, 37)
    ├── Trashcan                      @ (301, 36)
    └── CleaningStation               @ (179, 37)
LevelManager (Node)
HUD (CanvasLayer)
```

**Task summary for this level:**
- 1× Bone → deposit in Trashcan
- 3× Blood → clean with Mop
- 1× Box → push to target

Total tasks: **5**

---

## 11. Gameplay Flow & Mechanics

### Core Loop
1. Player spawns at (149, 86), timer starts (120s default)
2. Walk near objects — interaction prompt appears at bottom of screen
3. Complete all 5 tasks before timer hits 0
4. `level_complete` signal fires when done; `level_failed` fires on timeout

### Input

| Input | Action |
|---|---|
| WASD / Arrow keys | Move |
| E (tap) | Interact / pick up / drop / deposit |
| E (hold) | Clean blood (while carrying mop) |

### Mop Workflow (full loop)
1. Pick up mop (CARRYING, speed ×0.8)
2. Walk to blood stain, hold E for 2 seconds → blood cleaned, mop dirty
3. Walk to cleaning station, press E → mop clean again
4. Repeat for remaining blood stains

### Bone Workflow
1. Pick up bone (CARRYING, speed ×0.7)
2. Walk to trashcan, press E → bone deposited, task completed

### Box Workflow
1. Press E near box → enter PUSHING, axis locked
2. Move in allowed direction to push box toward ghost target
3. Box snaps to target when close enough, task completed

---

## 12. Signals Reference

| Signal | Emitter | Receiver | Payload |
|---|---|---|---|
| `task_completed(interactable)` | Any Interactable | LevelManager | interactable node |
| `player_nearby(is_near)` | Any Interactable | LevelManager | bool |
| `task_updated(key, label, done)` | LevelManager | HUD | string, string, bool |
| `timer_tick(seconds_left)` | LevelManager | HUD | float |
| `level_complete` | LevelManager | (unhandled — future GameManager) | — |
| `level_failed` | LevelManager | (unhandled — future GameManager) | — |
| `interaction_prompt_changed(text, show)` | LevelManager | HUD | string, bool |

---

## 13. Physics Layers

| Layer | Name | Used by |
|---|---|---|
| 1 | Player | player.tscn |
| 2 | Environment | Walls TileMapLayer, Box (StaticBody2D) |
| 3 | Interactables | InteractionArea (Area2D) on all interactables |

Player `collision_mask` includes Environment (layer 2) to collide with walls and box.
InteractionArea `collision_mask` includes Player (layer 1) to detect player proximity.

---

## 14. What's Not Yet Implemented

From [TASKS.md](TASKS.md) — Phase 5 and beyond:

- `GameManager.gd` autoload — persistent state (gold, current_level)
- Level transition system
- Shop / upgrade system
- Sound effects and music
- Additional tools (broom, etc.)
- Multiple level scenes

---

*Last updated: 2026-03-15*
