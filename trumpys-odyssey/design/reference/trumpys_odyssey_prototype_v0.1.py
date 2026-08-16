#!/usr/bin/env python3
"""
Trumpy's Odyssey - Prototype v0.1
Single-file Pygame prototype for Lobster
Core features: Player, Trumpy AI (chase + "Trumpy!" + sparkles + orbit on collide),
cracked secret walls, bomb to open, secret pickup, basic inventory, safe pixel-style graphics.
Run with: python trumpys_odyssey_prototype.py
Requires: pygame (pip install pygame)
"""

import pygame
import random
import math
from collections import deque

pygame.init()
WIDTH, HEIGHT = 800, 600
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Trumpy's Odyssey - Prototype v0.1 (for Lobster)")
clock = pygame.time.Clock()
font = pygame.font.SysFont("Arial", 18)
big_font = pygame.font.SysFont("Arial", 28)
small_font = pygame.font.SysFont("Arial", 14)

# Colors
GREEN = (34, 139, 34)
DARK_GREEN = (0, 100, 0)
BROWN = (139, 69, 19)
CRACKED = (160, 82, 45)
GOLD = (255, 215, 0)
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RED = (220, 20, 60)
BLUE = (30, 144, 255)
PURPLE = (128, 0, 128)
CYAN = (0, 255, 255)
YELLOW = (255, 255, 0)
ORANGE = (255, 165, 0)

# Game state
player_x, player_y = 400, 300
player_speed = 3.5
player_health = 6
bombs = 5
secrets_collected = []
inventory_open = False
game_message = ""
message_timer = 0

# Simple particle system for sparkles
particles = []

class Particle:
    def __init__(self, x, y, color=YELLOW):
        self.x = x
        self.y = y
        self.vx = random.uniform(-2, 2)
        self.vy = random.uniform(-2, 2)
        self.life = random.randint(20, 40)
        self.color = color
        self.size = random.randint(2, 4)

    def update(self):
        self.x += self.vx
        self.y += self.vy
        self.vy += 0.05  # gravity
        self.life -= 1
        self.size = max(1, self.size - 0.1)

    def draw(self, surf):
        if self.life > 0:
            alpha = max(0, int(255 * (self.life / 40)))
            s = pygame.Surface((self.size*2, self.size*2), pygame.SRCALPHA)
            pygame.draw.circle(s, (*self.color, alpha), (self.size, self.size), self.size)
            surf.blit(s, (self.x - self.size, self.y - self.size))

# Trumpy class - rainbow alien Alf-like with long snout behavior
class Trumpy:
    def __init__(self, x, y, color):
        self.x = x
        self.y = y
        self.color = color
        self.size = 18
        self.speed = 1.8
        self.state = "idle"  # idle, chase, orbiting
        self.orbit_timer = 0
        self.orbit_angle = 0
        self.target_x = x
        self.target_y = y

    def update(self, px, py):
        dist = math.hypot(px - self.x, py - self.y)
        
        if self.state == "orbiting":
            self.orbit_timer -= 1
            self.orbit_angle += 0.15
            self.x = px + math.cos(self.orbit_angle) * 45
            self.y = py + math.sin(self.orbit_angle) * 45
            if self.orbit_timer <= 0:
                self.state = "idle"
                # fly away
                self.vx = random.uniform(-3, 3)
                self.vy = random.uniform(-3, 3)
        else:
            if dist < 140:  # detection range
                self.state = "chase"
                # move toward player
                dx = px - self.x
                dy = py - self.y
                dist = max(1, dist)
                self.x += (dx / dist) * self.speed
                self.y += (dy / dist) * self.speed
            else:
                self.state = "idle"
                # gentle wander
                self.x += random.uniform(-0.8, 0.8)
                self.y += random.uniform(-0.8, 0.8)

            # Collide with player
            if dist < 22:
                self.state = "orbiting"
                self.orbit_timer = 90  # ~1.5 seconds
                global game_message, message_timer, particles
                game_message = "Trumpy!"
                message_timer = 45
                # Add sparkles
                for _ in range(12):
                    particles.append(Particle(self.x, self.y, random.choice([YELLOW, CYAN, GOLD])))

    def draw(self, surf):
        # Body - oval alien shape with longer snout
        pygame.draw.ellipse(surf, self.color, (self.x - self.size, self.y - self.size//2, self.size*2, self.size))
        # Snout (longer, harder look)
        snout_color = tuple(max(0, c-40) for c in self.color)
        pygame.draw.ellipse(surf, snout_color, (self.x + 8, self.y - 6, 16, 10))
        # Eyes
        pygame.draw.circle(surf, WHITE, (int(self.x - 5), int(self.y - 4)), 4)
        pygame.draw.circle(surf, WHITE, (int(self.x + 5), int(self.y - 4)), 4)
        pygame.draw.circle(surf, BLACK, (int(self.x - 5), int(self.y - 4)), 2)
        pygame.draw.circle(surf, BLACK, (int(self.x + 5), int(self.y - 4)), 2)
        # Simple legs
        pygame.draw.line(surf, DARK_GREEN, (self.x - 6, self.y + 8), (self.x - 8, self.y + 14), 2)
        pygame.draw.line(surf, DARK_GREEN, (self.x + 6, self.y + 8), (self.x + 8, self.y + 14), 2)

# Create rainbow Trumpys
trumpy_colors = [RED, ORANGE, YELLOW, GREEN, CYAN, BLUE, PURPLE]
trumpys = [Trumpy(random.randint(100, 700), random.randint(100, 500), random.choice(trumpy_colors)) for _ in range(6)]

# Simple map - walls and cracked secrets
walls = []  # (x, y, w, h, is_cracked)
for _ in range(12):
    x = random.randint(50, 650)
    y = random.randint(50, 500)
    walls.append((x, y, 40, 40, False))  # normal trees

# Add some cracked secret walls
cracked_positions = [(150, 150), (550, 200), (300, 450), (650, 350)]
for cx, cy in cracked_positions:
    walls.append((cx, cy, 36, 36, True))

def draw_map(surf):
    # Grass background
    surf.fill((34, 139, 34))
    # Simple grid lines for depth
    for x in range(0, WIDTH, 40):
        pygame.draw.line(surf, (30, 120, 30), (x, 0), (x, HEIGHT), 1)
    for y in range(0, HEIGHT, 40):
        pygame.draw.line(surf, (30, 120, 30), (0, y), (WIDTH, y), 1)

    for wx, wy, ww, wh, cracked in walls:
        if cracked:
            pygame.draw.rect(surf, CRACKED, (wx, wy, ww, wh))
            # Cracks
            pygame.draw.line(surf, (80, 40, 20), (wx+5, wy+5), (wx+ww-5, wy+wh-5), 2)
            pygame.draw.line(surf, (80, 40, 20), (wx+ww-5, wy+5), (wx+5, wy+wh-5), 2)
            pygame.draw.circle(surf, GOLD, (wx + ww//2, wy + wh//2), 4)  # secret glow hint
        else:
            # Tree / obstacle
            pygame.draw.rect(surf, BROWN, (wx, wy, ww, wh))
            pygame.draw.polygon(surf, DARK_GREEN, [(wx-5, wy), (wx+ww//2, wy-15), (wx+ww+5, wy)])

def check_collision(x, y, size=20):
    for wx, wy, ww, wh, _ in walls:
        if (x < wx + ww and x + size > wx and y < wy + wh and y + size > wy):
            return True
    return False

def explode_bomb(bx, by):
    global walls, game_message, message_timer, particles, secrets_collected
    radius = 50
    destroyed = 0
    new_walls = []
    for w in walls:
        wx, wy, ww, wh, cracked = w
        dist = math.hypot(bx - (wx + ww/2), by - (wy + wh/2))
        if cracked and dist < radius:
            destroyed += 1
            # Reveal secret!
            game_message = "Secret found! +1"
            message_timer = 60
            secrets_collected.append(f"Secret #{len(secrets_collected)+1} - {random.choice(['Rare', 'Epic'])} item")
            for _ in range(20):
                particles.append(Particle(wx + ww/2, wy + wh/2, GOLD))
        else:
            new_walls.append(w)
    walls = new_walls
    if destroyed == 0:
        game_message = "No cracked wall hit"
        message_timer = 30
    # Explosion particles
    for _ in range(15):
        p = Particle(bx, by, ORANGE)
        p.vx *= 1.5
        p.vy *= 1.5
        particles.append(p)

# Main loop
running = True
bomb_placed = None
bomb_timer = 0

while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False
            if event.key == pygame.K_i:
                inventory_open = not inventory_open
            if event.key == pygame.K_SPACE and bombs > 0:
                # Place bomb at player
                bomb_placed = (player_x + 10, player_y + 10)
                bomb_timer = 45  # 0.75 sec fuse
                bombs -= 1
                game_message = "Bomb placed!"
                message_timer = 20

    keys = pygame.key.get_pressed()
    dx = dy = 0
    if keys[pygame.K_LEFT] or keys[pygame.K_a]: dx = -player_speed
    if keys[pygame.K_RIGHT] or keys[pygame.K_d]: dx = player_speed
    if keys[pygame.K_UP] or keys[pygame.K_w]: dy = -player_speed
    if keys[pygame.K_DOWN] or keys[pygame.K_s]: dy = player_speed

    new_x = player_x + dx
    new_y = player_y + dy
    if not check_collision(new_x, new_y):
        player_x = max(20, min(WIDTH-40, new_x))
        player_y = max(20, min(HEIGHT-40, new_y))

    # Update Trumpys
    for t in trumpys:
        t.update(player_x, player_y)

    # Update particles
    particles = [p for p in particles if p.life > 0]
    for p in particles:
        p.update()

    # Bomb logic
    if bomb_placed and bomb_timer > 0:
        bomb_timer -= 1
        if bomb_timer == 0:
            explode_bomb(*bomb_placed)
            bomb_placed = None

    # Draw
    draw_map(screen)

    # Draw walls (already in map)
    # Draw Trumpys
    for t in trumpys:
        t.draw(screen)

    # Draw player (simple green tunic guy)
    # Tunic
    pygame.draw.rect(screen, GREEN, (player_x, player_y, 22, 26))
    # Head
    pygame.draw.ellipse(screen, (255, 218, 185), (player_x + 3, player_y - 8, 16, 14))
    # Cap
    pygame.draw.rect(screen, DARK_GREEN, (player_x + 2, player_y - 10, 18, 6))
    # Eyes
    pygame.draw.circle(screen, WHITE, (player_x + 7, player_y - 3), 3)
    pygame.draw.circle(screen, WHITE, (player_x + 15, player_y - 3), 3)
    pygame.draw.circle(screen, BLACK, (player_x + 7, player_y - 3), 1)
    pygame.draw.circle(screen, BLACK, (player_x + 15, player_y - 3), 1)

    # Draw particles
    for p in particles:
        p.draw(screen)

    # Draw bomb if active
    if bomb_placed:
        bx, by = bomb_placed
        pygame.draw.circle(screen, ORANGE, (int(bx), int(by)), 8)
        pygame.draw.circle(screen, RED, (int(bx), int(by)), 4)

    # UI
    screen.blit(font.render(f"Health: {player_health}   Bombs: {bombs}   Secrets: {len(secrets_collected)}/101", True, WHITE), (10, 10))
    screen.blit(small_font.render("Arrows/WASD: Move  |  SPACE: Bomb  |  I: Inventory  |  ESC: Quit", True, (200,200,200)), (10, HEIGHT - 25))

    if game_message and message_timer > 0:
        msg_surf = big_font.render(game_message, True, GOLD)
        screen.blit(msg_surf, (WIDTH//2 - msg_surf.get_width()//2, 50))
        message_timer -= 1
    else:
        game_message = ""

    # Inventory
    if inventory_open:
        inv_surf = pygame.Surface((400, 300), pygame.SRCALPHA)
        inv_surf.fill((0, 0, 0, 200))
        screen.blit(inv_surf, (200, 150))
        screen.blit(big_font.render("SECRET INVENTORY", True, GOLD), (220, 160))
        y_off = 200
        if secrets_collected:
            for s in secrets_collected[-8:]:  # show last 8
                screen.blit(small_font.render(s, True, WHITE), (220, y_off))
                y_off += 22
        else:
            screen.blit(small_font.render("No secrets yet. Find cracked walls and bomb them!", True, WHITE), (220, 220))
        screen.blit(small_font.render("Press I to close", True, (180,180,180)), (220, 420))

    pygame.display.flip()
    clock.tick(60)

pygame.quit()
print("Thanks for playing the prototype, Lobster! More coming soon.")