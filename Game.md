# Project: Dungeon Janitor (LM.md)

## 1. Elevator Pitch
A cozy top-down 2D simulation where you play as a Dungeon Janitor. Adventurers leave messes; you clean them up before the next raid party arrives. 
**Focus:** Code Architecture, Signal Flow, and Game Feel over Art or Complex Mechanics.

## 2. Core Loop
1. **Enter Level:** Dungeon is messy (bones, stains, broken pots).
2. **Clean:** Use tools to clean objects (Interact → Clean → Deposit).
3. **Complete:** Reach 100% Cleanliness before Timer ends.
4. **Upgrade:** Spend gold on permanent tool upgrades.
5. **Repeat:** Next level with more mess.

## 3. Technical Learning Goals
*   **Decoupling:** Objects never talk to UI directly. Use **Signals**.
*   **State Machines:** Player movement and interaction states (Idle, Cleaning, Carrying).
*   **Resources:** Use Godot `.tres` files for Upgrades and Item Data (no hardcoding).
*   **Scene Flow:** Proper transition between Menu → Level → Shop → Level.
*   **Input Handling:** Context-sensitive interaction (closest object priority).

## 4. Architecture Rules
*   **UI:** All HUD elements live in a `CanvasLayer`. Never put UI nodes inside Game Objects.
*   **Interaction:** 
    *   `Player` detects nearby objects via `Area2D`.
    *   `Player` calculates closest object.
    *   `Player` tells `HUD` to show prompt ("Press E").
    *   `Player` tells `Object` to show highlight (Sprite).
*   **Game State:** 
    *   `LevelManager` (Scene Root) tracks level progress.
    *   `GameManager` (Autoload) tracks persistent data (Gold, Upgrades).
*   **Objects:** All cleanable items inherit from `Cleanable.gd` (polymorphism).

## 5. Asset Strategy
*   **NO CUSTOM ART.** Do not draw anything.
*   **Source:** Kenney Assets, itch.io free packs, or simple geometric shapes.
*   **Style:** Top-down Pixel Art (16x16 or 32x32).
*   **Placeholder:** Use colored squares if assets aren't ready. Code first, art second.

## 6. Scope (MVP - Minimum Viable Product)
*   **Levels:** 1 Complete Level (plus a Main Menu).
*   **Tools:** 1 Tool (Broom/Hands).
*   **Mess Types:** 1 Type (Debris/Bones).
*   **Upgrades:** 1 Upgrade (Clean Speed).
*   **UI:** Cleanliness Bar, Timer, Interaction Prompt, Shop Menu.

## 7. Signal Flow Map
```text
[Cleanable Object] --(fully_cleaned)--> [LevelManager]
                                             |
                                             +--(update_score)--> [HUD]
                                             |
                                             +--(check_win)-----> [GameManager]