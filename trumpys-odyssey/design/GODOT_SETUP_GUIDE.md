# Trumpy's Odyssey — Godot 4 Setup Guide

Original setup notes from the project's Drive folder, kept for reference. The
actual project structure in this repo has since been built out — see the
root `README.md` for current status.

## 1. Install & Project Creation

1. Download **Godot 4.3+** (stable) from https://godotengine.org/download
2. Create a **new project** → name it `Trumpy_Odyssey`
3. Folder layout: `scenes/`, `scripts/`, `assets/tiles/`, `assets/sprites/`, `assets/sounds/`, `assets/icons/`

## 2. Recommended Project Settings

- Display → Window → Size: 640x480 (or 800x600 for prototype feel)
- Rendering → Quality → Use TAA = Off (for crisp pixel art)
- Physics → Common → Physics Ticks per Second = 60

## 3. Core TileMap Setup (parallax depth)

Godot 4 TileMap + multiple layers + ParallaxBackground gives SNES-style depth:

- `ParallaxBackground`
  - `ParallaxLayer` (Background — far mountains/sky) → `TileMap` child, Motion Scale (0.3, 0.3)
  - `ParallaxLayer` (Mid — trees/ground) → `TileMap` child, Motion Scale (0.6, 0.6)
  - `ParallaxLayer` (Foreground — details) → `TileMap` child, Motion Scale (1.0, 1.0)
- `TileMap` (main collision layer)
- `Player` (CharacterBody2D)
- `Camera2D` (follow player, limited to world bounds)
- `UI` (CanvasLayer for inventory, health, etc.)

## 4. Original core scripts

The original hand-off included `player.gd` and `trumpy.gd` starter scripts,
plus six standalone systems built afterward:

- `Player_Damage_System.gd` — health, damage types, secret mitigation, tunic color
- `Player_Knockback.gd` — player knockback state
- `Enemy_Knockback.gd` — enemy knockback state
- `EnemyBase_Confused.gd` — patrol/chase/confused AI, "WTF + run away" reaction
- `CombatSystem.gd` — centralized damage application, over-mitigation healing, impact effects
- `ImpactDustEffect.gd` / `FloatingHealText.gd` — visual feedback

These have all been merged into the real project under `scripts/` — see
`scripts/entities/player.gd` and `scripts/autoload/combat_system.gd`.

## 5. How to run

1. Install Godot 4.3+.
2. Open `project.godot` at the repo root in the Godot editor.
3. Run `scenes/world1/World1_Screen1.tscn` (or press F5 to run the project's
   main scene).
