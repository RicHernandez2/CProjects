# Trumpy's Odyssey

An SNES-style metroidvania collectathon, in the spirit of NES Zelda: 8 themed
worlds, 101 stacking secrets with Greek-mythology names, and rainbow-colored
alien creatures called **Trumpys** that orbit the player yelling "Trumpy!"
when caught. Full design brief in [`design/GAME_BIBLE.md`](design/GAME_BIBLE.md).

> **"Trumpy" is a fictional creature** — a rainbow, Alf-like alien with a
> longer/harder snout — invented for this game. Not based on any real person.

## Status

This is a **playable vertical slice**, not a finished game. It picks up
directly from six standalone GDScript systems that had already been
designed (combat, knockback, over-mitigation healing, confused-enemy AI,
tunic-color shifts) and wires them into an actual runnable Godot 4 project.

### What's implemented

- **Full 101-secret dataset** (`data/secrets_101.json`) — every name, rarity
  (Rare/Epic/Legendary/Mythic), effect type, and stacking percentage from the
  original spreadsheet, parsed into a format the game reads directly.
- **`SecretsDatabase` autoload** — tracks collected secrets, sums stacking
  bonuses per effect type, and flips on **Zeus Mode** (invulnerability,
  unlimited bombs, double speed) the instant all 101 are found.
- **Player** — 4-directional movement, bombs, melee attack, health/damage
  with per-damage-type mitigation read live from `SecretsDatabase`, and the
  green → blue → purple tunic color shift at 100% fire/ice mitigation.
- **Combat system** (`CombatSystem` autoload) — damage application,
  knockback, over-mitigation healing (with the "enemy gets confused and
  runs away" reaction), and impact dust effects.
- **Enemies** — patrol → chase → attack → confused state machine, with
  knockback.
- **Trumpys** — proximity-based behavior (gets excited as you approach),
  chase/orbit state machine, sparkle trail, "Trumpy!" popup.
- **Bombs + cracked walls** — place a bomb, it detonates on a fuse, cracks
  open any `CrackedWall` in the blast radius, which reveals a `SecretPickup`
  tied to a real secret ID.
- **Secret inventory UI** — toggle with the `inventory` action, browse every
  collected secret grouped by rarity (color-coded, since there's no icon art
  yet — see below).
- **HUD** — hearts, bombs, secret progress (`x/101`), gems, Zeus Mode flag.
- **One playable room** (`scenes/world1/World1_Screen1.tscn`) demonstrating
  all of the above together: 3 cracked walls (each tied to a real secret),
  3 Trumpys, an enemy, parallax background layers.

### How to run

1. Install [Godot 4.3+](https://godotengine.org/download).
2. Open `project.godot` in the editor.
3. Press F5 (or open and run `scenes/world1/World1_Screen1.tscn`).
4. Controls: arrow keys/WASD or gamepad stick to move, Space/gamepad A to
   bomb, Enter/gamepad B to attack, I/gamepad X to open the secret inventory.

No PNG/audio assets are required to run — every visual is a placeholder
`ColorRect`/primitive shape, the same trick the original Pygame prototype
(`design/reference/trumpys_odyssey_prototype_v0.1.py`) used. Real pixel art
and sound drop in later without touching the underlying systems.

## Roadmap — what's still ahead

This is one room out of a full game. Left to build, roughly in priority
order:

1. **Real art** — the 32x32 SNES-style icons described per-secret in
   `data/secrets_101.json` (`icon_prompt` field), tile sets per world,
   character/enemy sprite sheets with directional walk animations, the
   Trumpy sprite itself (Alf-like, longer snout). Swap into the `Sprite`
   `ColorRect` nodes / add `AnimatedSprite2D`s once art exists.
2. **7 more worlds** — each with its own tile theme, 8 screens, 1-3 secrets
   per screen, a dungeon with a boss, and a progression item gate (bombs are
   the only unlocked item right now; `fire_stick`, `magic_lamp`, `hookshot`,
   `flippers` are stubbed in `GameState.unlocked_items` but nothing grants
   or uses them yet).
3. **Discrete screen transitions** — right now the camera free-follows the
   player around one room. The Bible calls for NES-Zelda-style fixed
   single-screen rooms with hard cuts between them; that's not built yet.
4. **Sound & music** — `Trumpy.gd` already has a proximity-based
   `AudioStreamPlayer2D` hook (`ProximitySound`) ready for a stream, just
   needs actual audio files.
5. **Economy** — gem pickups currently apply instantly on enemy death with
   no physical pickup/animation; potions, arrows, fire sticks, and the
   cave/store system from the Bible aren't built.
6. **Unused secret effect types** — `magic_power`, `magic_cost`,
   `max_mana`, `potion_potency` are collected and summed in
   `SecretsDatabase.stat_totals` but nothing reads them yet since there's no
   magic-casting or potion system to hook them into.
7. **Directional player facing** — attacks currently hit in a radius
   around the player rather than in the direction they're facing.
8. **Playtest recording hook** — the Bible asks for a built-in
   play-test capture to MP4; not implemented.
9. **Joystick calibration** — movement and the `bomb`/`inventory`/`attack`
   actions are wired for gamepad, but the exact button mapping in
   `project.godot` was hand-authored outside the Godot editor and hasn't
   been verified on real hardware — check Project Settings → Input Map if a
   binding doesn't respond correctly.

## Project layout

```
project.godot
data/secrets_101.json          # all 101 secrets, structured
design/                        # original Game Bible, setup guide, Pygame prototype
scripts/autoload/              # GameState, SecretsDatabase, CombatSystem
scripts/entities/               # Player, EnemyBase, Trumpy, Bomb, CrackedWall, SecretPickup
scripts/effects/                 # dust, floating heal text, sparkles
scripts/ui/                     # HUD, secret inventory UI
scenes/entities/                # matching .tscn scenes (placeholder ColorRect art)
scenes/effects/, scenes/ui/
scenes/world1/                  # the one playable room so far
assets/                         # empty — tiles/sprites/sounds/icons land here
```
