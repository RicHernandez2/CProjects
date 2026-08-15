#!/usr/bin/env python3
"""
generate_screens.py

Procedurally scaffolds every overworld screen and dungeon room for all 8
worlds of Trumpy's Odyssey: 8 worlds x 8 screens each (grid-connected, NES
Zelda style) + 2 dungeon rooms per world, wired together with ScreenExit
transitions, and every one of the 101 secrets placed in a cracked wall
somewhere in the overworld.

This is a *layout* generator, not an art generator: every screen uses the
same placeholder-geometry entities (Wall, CrackedWall, Trumpy, Enemy) the
rest of the project uses, tinted per-world via each screen's Ground/Mid
parallax colors. Re-run this any time the world/screen topology needs to
change instead of hand-editing 80 .tscn files.

Usage: python3 tools/generate_screens.py
(run from the trumpys-odyssey/ project root, or anywhere -- paths below
are relative to this file's parent directory)
"""

import json
import os
import random

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
SCENES_DIR = os.path.join(ROOT, "scenes")
DATA_PATH = os.path.join(ROOT, "data", "secrets_101.json")

SCREEN_W, SCREEN_H = 640, 480

# --- Grid layout shared by every world -------------------------------
# 3x3 grid minus the (2,2) corner, which is reserved as the world-gate
# side of screen 8 (the "deepest" screen, where the dungeon entrance and
# the gate to the next world both live).
GRID = {
    1: (0, 0), 2: (0, 1), 3: (0, 2),
    4: (1, 0), 5: (1, 1), 6: (1, 2),
    7: (2, 0), 8: (2, 1),
}
POS_TO_SCREEN = {v: k for k, v in GRID.items()}


def neighbors(screen_id):
    r, c = GRID[screen_id]
    out = {}
    deltas = {"north": (-1, 0), "south": (1, 0), "west": (0, -1), "east": (0, 1)}
    for direction, (dr, dc) in deltas.items():
        pos = (r + dr, c + dc)
        if pos in POS_TO_SCREEN:
            out[direction] = POS_TO_SCREEN[pos]
    return out


# Where the player spawns on the *new* screen, keyed by which edge they
# exited through (i.e. they arrive at the opposite edge).
SPAWN_FOR_EXIT_DIRECTION = {
    "north": (SCREEN_W / 2, SCREEN_H - 40),
    "south": (SCREEN_W / 2, 40),
    "east": (40, SCREEN_H / 2),
    "west": (SCREEN_W - 40, SCREEN_H / 2),
}

EDGE_TRIGGER_POS = {
    "north": (SCREEN_W / 2, 20),
    "south": (SCREEN_W / 2, SCREEN_H - 20),
    "east": (SCREEN_W - 20, SCREEN_H / 2),
    "west": (20, SCREEN_H / 2),
}

DUNGEON_ENTRANCE_POS = (SCREEN_W / 2, SCREEN_H - 80)

# --- World themes ------------------------------------------------------
WORLDS = [
    {"id": 1, "name": "Verdant Hollow", "ground": (0.13, 0.55, 0.13), "mid": (0.10, 0.35, 0.10, 0.45),
     "wall": (0.0, 0.39, 0.0), "boss": "Grovewarden", "drop": "fire_stick"},
    {"id": 2, "name": "Sundered Dunes", "ground": (0.82, 0.70, 0.42), "mid": (0.55, 0.42, 0.20, 0.4),
     "wall": (0.60, 0.46, 0.20), "boss": "Duneleviathan", "drop": "magic_lamp"},
    {"id": 3, "name": "Frostspire Reaches", "ground": (0.78, 0.88, 0.95), "mid": (0.55, 0.70, 0.85, 0.4),
     "wall": (0.55, 0.70, 0.85), "boss": "Rimefang", "drop": "hookshot"},
    {"id": 4, "name": "Emberdeep Caverns", "ground": (0.25, 0.08, 0.05), "mid": (0.45, 0.15, 0.05, 0.5),
     "wall": (0.45, 0.15, 0.05), "boss": "Cinderjaw", "drop": "flippers"},
    {"id": 5, "name": "Cragstone Pass", "ground": (0.55, 0.52, 0.48), "mid": (0.35, 0.33, 0.30, 0.45),
     "wall": (0.35, 0.33, 0.30), "boss": "Gorgonhide", "drop": "ice_boots"},
    {"id": 6, "name": "Skyfallen Ruins", "ground": (0.75, 0.80, 0.92), "mid": (0.55, 0.55, 0.75, 0.4),
     "wall": (0.55, 0.55, 0.75), "boss": "Aetherwing", "drop": "wing_charm"},
    {"id": 7, "name": "Marrow Fen", "ground": (0.25, 0.42, 0.38), "mid": (0.15, 0.28, 0.25, 0.5),
     "wall": (0.15, 0.28, 0.25), "boss": "Bogmother", "drop": "storm_horn"},
    {"id": 8, "name": "Duskbloom Meadow", "ground": (0.75, 0.55, 0.70), "mid": (0.55, 0.35, 0.55, 0.4),
     "wall": (0.55, 0.35, 0.55), "boss": "Nightpetal", "drop": "aegis_of_zeus"},
]


def world_screen_path(world_id, screen_id):
    return f"res://scenes/world{world_id}/World{world_id}_Screen{screen_id}.tscn"


def world_dungeon_path(world_id, room):
    return f"res://scenes/world{world_id}/World{world_id}_Dungeon_Room{room}.tscn"


# --- Secret distribution ------------------------------------------------
def load_secrets():
    with open(DATA_PATH, encoding="utf-8") as f:
        return json.load(f)


def build_secret_assignment(secrets):
    """64 overworld screens (world,screen) in generation order each get 1
    secret; the first 37 of those (in the same order) get a 2nd. Uses ids
    1..101 sequentially so every secret is placed exactly once."""
    pairs = [(w["id"], s) for w in WORLDS for s in range(1, 9)]
    assert len(pairs) == 64

    ids = sorted(s["id"] for s in secrets)
    assert len(ids) == 101

    primary = ids[:64]
    secondary = ids[64:]  # 37 ids

    assignment = {pair: [primary[i]] for i, pair in enumerate(pairs)}
    for i, sid in enumerate(secondary):
        assignment[pairs[i]].append(sid)
    return assignment


# --- .tscn builders ------------------------------------------------------
class SceneBuilder:
    """Accumulates ext_resource declarations (deduped, stable order) and
    node blocks, then renders a complete .tscn file."""

    EXT_TYPES = {
        "Player": ("PackedScene", "res://scenes/entities/Player.tscn"),
        "Wall": ("PackedScene", "res://scenes/entities/Wall.tscn"),
        "CrackedWall": ("PackedScene", "res://scenes/entities/CrackedWall.tscn"),
        "Trumpy": ("PackedScene", "res://scenes/entities/Trumpy.tscn"),
        "Enemy": ("PackedScene", "res://scenes/entities/Enemy.tscn"),
        "Boss": ("PackedScene", "res://scenes/entities/Boss.tscn"),
        "ScreenExit": ("PackedScene", "res://scenes/entities/ScreenExit.tscn"),
        "HUD": ("PackedScene", "res://scenes/ui/HUD.tscn"),
        "InventoryUI": ("PackedScene", "res://scenes/ui/InventoryUI.tscn"),
        "ScreenRootScript": ("Script", "res://scripts/world/screen_root.gd"),
    }

    def __init__(self):
        self._used = {}  # key -> id string
        self._order = []
        self.nodes = []

    def use(self, key):
        if key not in self._used:
            self._used[key] = str(len(self._order) + 1)
            self._order.append(key)
        return self._used[key]

    def render(self):
        header_lines = []
        for key in self._order:
            res_type, path = self.EXT_TYPES[key]
            header_lines.append(f'[ext_resource type="{res_type}" path="{path}" id="{self._used[key]}"]')

        load_steps = len(self._order) + 1
        out = [f"[gd_scene load_steps={load_steps} format=3]", ""]
        out.extend(header_lines)
        out.append("")
        out.extend(self.nodes)
        return "\n".join(out) + "\n"


def color_str(c, default_alpha=1.0):
    if len(c) == 4:
        return f"Color({c[0]}, {c[1]}, {c[2]}, {c[3]})"
    return f"Color({c[0]}, {c[1]}, {c[2]}, {default_alpha})"


def add_root(sb, name, world_id, screen_label):
    script_id = sb.use("ScreenRootScript")
    sb.nodes.append(f'[node name="{name}" type="Node2D"]')
    sb.nodes.append(f'script = ExtResource("{script_id}")')
    sb.nodes.append(f"world_id = {world_id}")
    sb.nodes.append(f'screen_label = "{screen_label}"')
    sb.nodes.append("")


def add_background(sb, ground_rgb, mid_rgba):
    sb.nodes.append('[node name="ParallaxBackground" type="ParallaxBackground" parent="."]')
    sb.nodes.append("")
    sb.nodes.append('[node name="SkyLayer" type="ParallaxLayer" parent="ParallaxBackground"]')
    sb.nodes.append("motion_scale = Vector2(0.3, 0.3)")
    sb.nodes.append("")
    sb.nodes.append('[node name="SkyRect" type="ColorRect" parent="ParallaxBackground/SkyLayer"]')
    sb.nodes.append("offset_left = -400.0")
    sb.nodes.append("offset_top = -400.0")
    sb.nodes.append("offset_right = 1200.0")
    sb.nodes.append("offset_bottom = 900.0")
    sb.nodes.append(f"color = {color_str(ground_rgb, 0.6)}")
    sb.nodes.append("")
    sb.nodes.append('[node name="MidLayer" type="ParallaxLayer" parent="ParallaxBackground"]')
    sb.nodes.append("motion_scale = Vector2(0.6, 0.6)")
    sb.nodes.append("")
    sb.nodes.append('[node name="MidRect" type="ColorRect" parent="ParallaxBackground/MidLayer"]')
    sb.nodes.append("offset_left = -200.0")
    sb.nodes.append("offset_top = 200.0")
    sb.nodes.append("offset_right = 1000.0")
    sb.nodes.append("offset_bottom = 700.0")
    sb.nodes.append(f"color = {color_str(mid_rgba)}")
    sb.nodes.append("")
    sb.nodes.append('[node name="Ground" type="ColorRect" parent="."]')
    sb.nodes.append("offset_left = 0.0")
    sb.nodes.append("offset_top = 0.0")
    sb.nodes.append(f"offset_right = {SCREEN_W}.0")
    sb.nodes.append(f"offset_bottom = {SCREEN_H}.0")
    sb.nodes.append(f"color = {color_str(ground_rgb)}")
    sb.nodes.append("")


def add_player(sb, name, position):
    ext_id = sb.use("Player")
    sb.nodes.append(f'[node name="{name}" parent="." instance=ExtResource("{ext_id}")]')
    sb.nodes.append(f"position = Vector2({position[0]}, {position[1]})")
    sb.nodes.append("")


def add_wall(sb, name, position):
    ext_id = sb.use("Wall")
    sb.nodes.append(f'[node name="{name}" parent="." instance=ExtResource("{ext_id}")]')
    sb.nodes.append(f"position = Vector2({position[0]}, {position[1]})")
    sb.nodes.append("")


def add_cracked_wall(sb, name, position, secret_id):
    ext_id = sb.use("CrackedWall")
    sb.nodes.append(f'[node name="{name}" parent="." instance=ExtResource("{ext_id}")]')
    sb.nodes.append(f"position = Vector2({position[0]}, {position[1]})")
    sb.nodes.append(f"secret_id = {secret_id}")
    sb.nodes.append("")

    for suffix, dx in ((0, -20), (1, 20)):
        sb.nodes.append(f'[node name="{name}Torch{suffix}" type="ColorRect" parent="."]')
        tx = position[0] + dx
        ty = position[1] - 10
        sb.nodes.append(f"offset_left = {tx - 5}.0")
        sb.nodes.append(f"offset_top = {ty - 10}.0")
        sb.nodes.append(f"offset_right = {tx + 5}.0")
        sb.nodes.append(f"offset_bottom = {ty + 10}.0")
        sb.nodes.append("color = Color(1, 0.55, 0, 1)")
        sb.nodes.append("")


def add_trumpy(sb, name, position, color):
    ext_id = sb.use("Trumpy")
    sb.nodes.append(f'[node name="{name}" parent="." instance=ExtResource("{ext_id}")]')
    sb.nodes.append(f"position = Vector2({position[0]}, {position[1]})")
    sb.nodes.append(f"trumpy_color = {color_str(color)}")
    sb.nodes.append("")


def add_enemy(sb, name, position):
    ext_id = sb.use("Enemy")
    sb.nodes.append(f'[node name="{name}" parent="." instance=ExtResource("{ext_id}")]')
    sb.nodes.append(f"position = Vector2({position[0]}, {position[1]})")
    sb.nodes.append("")


def add_boss(sb, name, position, boss_name, drop_item):
    ext_id = sb.use("Boss")
    sb.nodes.append(f'[node name="{name}" parent="." instance=ExtResource("{ext_id}")]')
    sb.nodes.append(f"position = Vector2({position[0]}, {position[1]})")
    sb.nodes.append(f'boss_name = "{boss_name}"')
    sb.nodes.append(f'drop_item_key = "{drop_item}"')
    sb.nodes.append("")


def add_screen_exit(sb, name, position, target_scene, spawn, required_item="", locked_hint=""):
    ext_id = sb.use("ScreenExit")
    sb.nodes.append(f'[node name="{name}" parent="." instance=ExtResource("{ext_id}")]')
    sb.nodes.append(f"position = Vector2({position[0]}, {position[1]})")
    sb.nodes.append(f'target_scene = "{target_scene}"')
    sb.nodes.append(f"spawn_position = Vector2({spawn[0]}, {spawn[1]})")
    if required_item:
        sb.nodes.append(f'required_item = "{required_item}"')
    if locked_hint:
        sb.nodes.append(f'locked_hint = "{locked_hint}"')
    sb.nodes.append("")


def add_boundary_wall(sb, name, direction):
    # Decorative-only closed edge (no neighbor / gate here): a row of Wall
    # instances blocking that side so the player can't walk off into
    # nothing.
    ext_id = sb.use("Wall")
    if direction in ("north", "south"):
        y = 0 if direction == "north" else SCREEN_H
        xs = range(20, SCREEN_W, 60)
        for i, x in enumerate(xs):
            sb.nodes.append(f'[node name="{name}{i}" parent="." instance=ExtResource("{ext_id}")]')
            sb.nodes.append(f"position = Vector2({x}, {y})")
            sb.nodes.append("")
    else:
        x = 0 if direction == "west" else SCREEN_W
        ys = range(20, SCREEN_H, 60)
        for i, y in enumerate(ys):
            sb.nodes.append(f'[node name="{name}{i}" parent="." instance=ExtResource("{ext_id}")]')
            sb.nodes.append(f"position = Vector2({x}, {y})")
            sb.nodes.append("")


def add_ui(sb):
    hud_id = sb.use("HUD")
    sb.nodes.append(f'[node name="HUD" parent="." instance=ExtResource("{hud_id}")]')
    sb.nodes.append("")
    inv_id = sb.use("InventoryUI")
    sb.nodes.append(f'[node name="InventoryUI" parent="." instance=ExtResource("{inv_id}")]')
    sb.nodes.append("")


SAFE_ZONE = (110, 110, SCREEN_W - 110, SCREEN_H - 110)  # left, top, right, bottom


def scattered_points(rng, count, taken, min_dist=70):
    points = []
    attempts = 0
    while len(points) < count and attempts < count * 40:
        attempts += 1
        x = rng.randint(int(SAFE_ZONE[0]), int(SAFE_ZONE[2]))
        y = rng.randint(int(SAFE_ZONE[1]), int(SAFE_ZONE[3]))
        ok = True
        for (px, py) in points + taken:
            if (x - px) ** 2 + (y - py) ** 2 < min_dist ** 2:
                ok = False
                break
        if ok:
            points.append((x, y))
    return points


def build_overworld_screen(world, screen_id, secret_ids, secrets_by_id):
    sb = SceneBuilder()
    rng = random.Random(world["id"] * 100 + screen_id)

    add_root(sb, f"World{world['id']}Screen{screen_id}", world["id"],
              f"{world['name']} - Screen {screen_id}")
    add_background(sb, world["ground"], world["mid"])

    start_pos = (SCREEN_W / 2, SCREEN_H / 2)
    add_player(sb, "Player", start_pos)

    taken_points = [start_pos]

    # Cracked walls (secrets)
    cracked_points = scattered_points(rng, len(secret_ids), taken_points)
    taken_points.extend(cracked_points)
    for i, (sid, pos) in enumerate(zip(secret_ids, cracked_points)):
        add_cracked_wall(sb, f"CrackedWall{i}", pos, sid)

    # Plain obstacles
    wall_count = rng.randint(3, 5)
    wall_points = scattered_points(rng, wall_count, taken_points)
    taken_points.extend(wall_points)
    for i, pos in enumerate(wall_points):
        add_wall(sb, f"Wall{i}", pos)

    # Trumpys
    trumpy_colors = [(1, 0, 0), (1, 0.5, 0), (1, 1, 0), (0, 0.8, 0.2),
                      (0, 0.8, 1), (0.2, 0.3, 1), (0.6, 0, 1)]
    trumpy_count = rng.randint(2, 3)
    trumpy_points = scattered_points(rng, trumpy_count, taken_points)
    taken_points.extend(trumpy_points)
    for i, pos in enumerate(trumpy_points):
        add_trumpy(sb, f"Trumpy{i}", pos, rng.choice(trumpy_colors))

    # Enemies
    enemy_count = rng.randint(1, 2)
    enemy_points = scattered_points(rng, enemy_count, taken_points)
    taken_points.extend(enemy_points)
    for i, pos in enumerate(enemy_points):
        add_enemy(sb, f"Enemy{i}", pos)

    # Screen exits / boundaries
    conns = neighbors(screen_id)
    for direction, pos in EDGE_TRIGGER_POS.items():
        if direction in conns:
            target_screen = conns[direction]
            spawn = SPAWN_FOR_EXIT_DIRECTION[direction]
            add_screen_exit(sb, f"Exit_{direction}", pos,
                              world_screen_path(world["id"], target_screen), spawn)
        elif screen_id == 8 and direction == "east":
            # World gate: needs this world's boss-dropped item.
            next_world = world["id"] + 1
            if next_world <= 8:
                add_screen_exit(sb, "Exit_east_worldgate", pos,
                                  world_screen_path(next_world, 1),
                                  SPAWN_FOR_EXIT_DIRECTION["east"],
                                  required_item=world["drop"],
                                  locked_hint=f"The way is blocked. Defeat {world['boss']} in this world's dungeon first.")
            else:
                add_boundary_wall(sb, "Boundary_east", "east")
        elif screen_id == 1 and direction == "west" and world["id"] > 1:
            prev_world = world["id"] - 1
            add_screen_exit(sb, "Exit_west_prevworld", pos,
                              world_screen_path(prev_world, 8),
                              SPAWN_FOR_EXIT_DIRECTION["west"])
        else:
            add_boundary_wall(sb, f"Boundary_{direction}", direction)

    if screen_id == 8:
        add_screen_exit(sb, "Exit_dungeon", DUNGEON_ENTRANCE_POS,
                          world_dungeon_path(world["id"], 1),
                          SPAWN_FOR_EXIT_DIRECTION["north"])

    add_ui(sb)
    return sb.render()


def build_dungeon_room1(world):
    sb = SceneBuilder()
    rng = random.Random(world["id"] * 1000 + 1)
    dark_ground = tuple(c * 0.5 for c in world["ground"])
    dark_mid = tuple(c * 0.4 for c in world["ground"]) + (0.5,)

    add_root(sb, f"World{world['id']}DungeonRoom1", world["id"], f"{world['name']} - Dungeon Entrance")
    add_background(sb, dark_ground, dark_mid)

    start_pos = SPAWN_FOR_EXIT_DIRECTION["north"]  # arriving from the cave mouth (south side)
    add_player(sb, "Player", start_pos)

    taken = [start_pos]
    wall_points = scattered_points(rng, rng.randint(3, 4), taken)
    taken.extend(wall_points)
    for i, pos in enumerate(wall_points):
        add_wall(sb, f"Wall{i}", pos)

    enemy_points = scattered_points(rng, rng.randint(2, 3), taken)
    taken.extend(enemy_points)
    for i, pos in enumerate(enemy_points):
        add_enemy(sb, f"Enemy{i}", pos)

    add_screen_exit(sb, "Exit_south", EDGE_TRIGGER_POS["south"],
                      world_screen_path(world["id"], 8), (SCREEN_W / 2, 350))
    add_screen_exit(sb, "Exit_north", EDGE_TRIGGER_POS["north"],
                      world_dungeon_path(world["id"], 2), SPAWN_FOR_EXIT_DIRECTION["north"])
    add_boundary_wall(sb, "Boundary_east", "east")
    add_boundary_wall(sb, "Boundary_west", "west")

    add_ui(sb)
    return sb.render()


def build_dungeon_room2(world):
    sb = SceneBuilder()
    dark_ground = tuple(c * 0.35 for c in world["ground"])
    dark_mid = tuple(c * 0.3 for c in world["ground"]) + (0.5,)

    add_root(sb, f"World{world['id']}DungeonRoom2", world["id"], f"{world['name']} - {world['boss']}'s Lair")
    add_background(sb, dark_ground, dark_mid)

    start_pos = SPAWN_FOR_EXIT_DIRECTION["north"]
    add_player(sb, "Player", start_pos)

    add_boss(sb, "Boss", (SCREEN_W / 2, SCREEN_H / 2 - 40), world["boss"], world["drop"])

    add_screen_exit(sb, "Exit_south", EDGE_TRIGGER_POS["south"],
                      world_dungeon_path(world["id"], 1), (SCREEN_W / 2, 60))
    add_boundary_wall(sb, "Boundary_east", "east")
    add_boundary_wall(sb, "Boundary_west", "west")
    add_boundary_wall(sb, "Boundary_north", "north")

    add_ui(sb)
    return sb.render()


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def main():
    secrets = load_secrets()
    secrets_by_id = {s["id"]: s for s in secrets}
    assignment = build_secret_assignment(secrets)

    total_screens = 0
    total_secrets_placed = 0

    for world in WORLDS:
        world_dir = os.path.join(SCENES_DIR, f"world{world['id']}")

        for screen_id in range(1, 9):
            secret_ids = assignment[(world["id"], screen_id)]
            total_secrets_placed += len(secret_ids)
            text = build_overworld_screen(world, screen_id, secret_ids, secrets_by_id)
            write(os.path.join(world_dir, f"World{world['id']}_Screen{screen_id}.tscn"), text)
            total_screens += 1

        write(os.path.join(world_dir, f"World{world['id']}_Dungeon_Room1.tscn"), build_dungeon_room1(world))
        write(os.path.join(world_dir, f"World{world['id']}_Dungeon_Room2.tscn"), build_dungeon_room2(world))
        total_screens += 2

    print(f"Generated {total_screens} scene files across {len(WORLDS)} worlds.")
    print(f"Placed {total_secrets_placed} secrets (expected 101).")
    assert total_secrets_placed == 101


if __name__ == "__main__":
    main()
