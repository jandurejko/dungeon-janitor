# Dungeon Janitor — Implementation Task List

Track progress here. Mark tasks `[x]` when done, `[~]` when skipped, `[-]` when in-progress.

---

## Phase 1: Foundation

### Task 1.1 — InteractableData Resources
**Status:** `[x]`
**Goal:** Create the resource system all interactable objects will use.
**Files to create:**
- `Scripts/Resources/InteractableData.gd` — base Resource class
- `Scripts/Resources/BoneData.gd` — extends InteractableData
- `Scripts/Resources/BloodData.gd` — extends InteractableData
- `Scripts/Resources/BoxData.gd` — extends InteractableData

**Notes:**
- Base class holds: `display_name`, `interaction_prompt` (String)
- BoneData adds: `carry_speed_multiplier` (float, default 0.7), `is_weapon` (bool)
- BloodData adds: `clean_time` (float, seconds to hold E)
- BoxData adds: `push_speed` (float), `target_position` (Vector2)

---

### Task 1.2 — Interactable Base Scene
**Status:** `[x]`
**Goal:** One base scene/script all interactables extend from.
**Files to create:**
- `Scripts/Interactables/Interactable.gd`
- `Scenes/Interactables/interactable_base.tscn`

**Node structure:**
```
Interactable (Node2D)
├── Sprite2D
├── CollisionShape2D (for physics body if needed)
└── InteractionArea (Area2D)
    └── CollisionShape2D  ← detection radius
```

**Script responsibilities:**
- `@export var data: InteractableData`
- Signal `task_completed(interactable: Node)`
- Signal `player_nearby(is_near: bool)`
- Virtual `func interact(player: Node) -> void` (override in children)
- Tracks if player is in range

---

### Task 1.3 — Player State Machine
**Status:** `[x]`
**Goal:** Refactor `player.gd` to use a state machine.
**File to modify:** `Scripts/Charecters/Player/player.gd`

**States:**
```
enum State { IDLE, MOVING, CARRYING, CLEANING, PUSHING }
```

**Behavior per state:**
- `IDLE` / `MOVING` — current movement logic (no change)
- `CARRYING` — speed multiplied by item's carry_speed_multiplier, `E` drops item
- `CLEANING` — player stops, holds `E`, emits cleaning progress
- `PUSHING` — player movement pushes nearby box

**New additions:**
- `@export var interact_key = "interact"` (map E key in Input Map)
- `var current_state: State`
- `var nearby_interactable: Node` (set by Interactable when player enters range)
- `var carried_item: Node`
- `func change_state(new_state: State) -> void`
- `func _handle_interact() -> void` — called on E press

---

## Phase 2: Interactable Objects

### Task 2.1 — Bone Interactable
**Status:** `[x]`
**Files to create:**
- `Scripts/Interactables/Bone.gd`
- `Scenes/Interactables/bone.tscn`
- `Resources/bone_default.tres` (BoneData resource, editable in inspector)

**Behavior:**
- Player walks near → prompt shows "Pick up [E]"
- `E` pressed → bone reparents to player, follows at offset, player enters CARRYING
- `E` again → bone dropped at player position, player returns to IDLE/MOVING
- Future: deposit zone triggers `task_completed`

---

### Task 2.2 — Blood Interactable
**Status:** `[x]`
**Files to create:**
- `Scripts/Interactables/Blood.gd`
- `Scenes/Interactables/blood.tscn`
- `Resources/blood_default.tres` (BloodData resource)

**Behavior:**
- Player walks near → prompt shows "Clean [Hold E]"
- Hold `E` → player enters CLEANING, ProgressBar fills over `clean_time` seconds
- Release `E` → progress resets (or pauses — your choice, adjust in BloodData)
- On complete → blood sprite hides, `task_completed` emitted

---

### Task 2.3 — Box Interactable
**Status:** `[x]`
**Files to create:**
- `Scripts/Interactables/Box.gd`
- `Scenes/Interactables/box.tscn`
- `Resources/box_default.tres` (BoxData resource)
- `Scenes/Interactables/box_target_ghost.tscn` (visual ghost at target position)

**Behavior:**
- Ghost sprite at `BoxData.target_position` shows where box should go
- Player walks into box and presses movement direction → box moves at `push_speed`
- On reaching target (within threshold) → `task_completed` emitted, ghost disappears

---

## Phase 3: UI

### Task 3.1 — HUD Scene
**Status:** `[x]`
**Files to create:**
- `Scenes/Ui/hud.tscn`
- `Scripts/Ui/hud.gd`

**Node structure:**
```
HUD (CanvasLayer)
├── TimerLabel (Label)              ← top-left
├── TasksPanel (PanelContainer)     ← top-right
│   └── TaskList (VBoxContainer)    ← populated at runtime
├── InteractionPrompt (Label)       ← bottom-center, hidden by default
└── CarryingIndicator (HBoxContainer) ← bottom-left, hidden by default
    ├── Icon (TextureRect)
    └── ItemName (Label)
```

**Script responsibilities:**
- `func update_timer(seconds_left: float) -> void`
- `func add_task(task_name: String) -> void`
- `func complete_task(task_name: String) -> void`
- `func show_prompt(text: String) -> void` / `hide_prompt()`
- `func show_carrying(item_name: String) -> void` / `hide_carrying()`

---

### Task 3.2 — LevelManager
**Status:** `[x]`
**Files to create:**
- `Scripts/Managers/LevelManager.gd`

**Responsibilities:**
- `@export var time_limit: float = 120.0`
- Holds references to all interactables (via group "interactables" or NodePaths)
- Countdown timer in `_process`
- Connects to `task_completed` signal of each interactable in `_ready`
- Emits signals to HUD: `task_updated`, `timer_tick`, `level_complete`, `level_failed`
- Placed as a node in `main.tscn`

---

### Task 3.3 — Wire HUD + LevelManager
**Status:** `[x]`
**Goal:** Connect LevelManager signals to HUD functions.
**Files to modify:**
- `Scenes/General/main.tscn` — add HUD (CanvasLayer) and LevelManager nodes
- `Scripts/Ui/hud.gd` — connect LevelManager signals in `_ready`

**Also:** Add `"interact"` action to Input Map in `project.godot` (key E).

---

## Phase 4: Gameplay Systems

### Task 4.1 — Task System Foundation
**Status:** `[x]`
**Files to modify:**
- `Scripts/Interactables/Interactable.gd` — add `counts_as_task: bool`, `takes_priority_over_carry()` virtual
- `Scripts/Managers/LevelManager.gd` — filter by `counts_as_task`, use node name as task key
- `Scripts/Ui/hud.gd` — `add_task(key, label)` / `complete_task(key)` with unique keys
- `Scripts/Charecters/Player/player.gd` — check `takes_priority_over_carry()` before routing E to carried item

---

### Task 4.2 — Box Axis-Locking
**Status:** `[x]`
**Files to modify:**
- `Scripts/Interactables/Box.gd` — lock push axis on grab based on approach side; filter input in `_physics_process`

**Behaviour:** Approaching from left/right locks horizontal push only. From above/below locks vertical push only.

---

### Task 4.3 — Trashcan Deposit Zone
**Status:** `[x]`
**Files to create:**
- `Scripts/Resources/TrashcanData.gd`
- `Scripts/Interactables/Trashcan.gd`
- `Scenes/Interactables/trashcan.tscn`

**Behaviour:** Player carries a bone to the trashcan and presses E. Bone is hidden and its `task_completed` is emitted. Trashcan itself does not count as a task (`counts_as_task = false`).

---

### Task 4.4 — Mop Tool + Cleaning Station
**Status:** `[x]`
**Files to create:**
- `Scripts/Resources/MopData.gd` — `carry_speed_multiplier: float = 0.8`
- `Scripts/Interactables/Mop.gd` — pickup/drop tool with `is_dirty` state; `make_dirty()` / `make_clean()` tint sprite
- `Scenes/Interactables/mop.tscn`
- `Scripts/Resources/CleaningStationData.gd`
- `Scripts/Interactables/CleaningStation.gd` — press E with dirty mop → mop becomes clean
- `Scenes/Interactables/cleaning_station.tscn`

Both are `counts_as_task = false`.

---

### Task 4.5 — Blood Requires Mop
**Status:** `[x]`
**Files to modify:**
- `Scripts/Interactables/Blood.gd` — player must carry a clean mop to start cleaning; mop becomes dirty on completion; player returns to CARRYING (not IDLE) after cleaning

---

## Phase 5: Game Management

### Task 5.1 — GameManager Autoload (stub)
**Status:** `[ ]`
**Files to create:**
- `Scripts/Managers/GameManager.gd`

**Minimal stub:**
```gdscript
extends Node
var gold: int = 0
var current_level: int = 1
```
Register as Autoload in `project.godot` with name `GameManager`.

---

## Skipped / Future Tasks

Use this section to park tasks you're tackling yourself or deferring:

| Task | Reason | Notes |
|------|--------|-------|
| Shop/Upgrade system | Post-MVP | Needs GameManager to be fleshed out |
| Multiple level scenes | Post-MVP | One level for now |
| Tool system (broom etc.) | Post-MVP | Mop is in; other tools (broom, etc.) are future |
| Sound effects | Post-MVP | — |

---

## Paper Trail

| Date | Task | Outcome |
|------|------|---------|
| 2026-03-15 | Tasks 1.1–1.3 | Completed |
| 2026-03-15 | Tasks 2.1–2.3 | Completed |
| 2026-03-15 | Tasks 3.1–3.3 | Completed |
| 2026-03-15 | Tasks 4.1–4.5 | Completed |
