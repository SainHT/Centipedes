# ==============================================================================
# CONSTANTS FILE
# This file contains all shared constants used throughout the Centipedes game
# ==============================================================================

.section .text

# ==============================================================================
# SCREEN AND DISPLAY CONSTANTS
# ==============================================================================
.equ SCREEN_WIDTH, 960
.equ SCREEN_HEIGHT, 1024
.equ PLAYER_UPPER_BOUNDARY, 800
.equ RESOLUTION, 32

# ==============================================================================
# GRID CONSTANTS
# ==============================================================================
.equ GRID_ROWS, 28
.equ GRID_COLS, 30
.equ MUSHROOMS, 50

# ==============================================================================
# COLOR CONSTANTS (RGBA format)
# ==============================================================================
.equ BLACK, 0xFF000000
.equ WHITE, 0xFFFFFFFF
.equ GREEN, 0xFF00FF00
.equ RED, 0xFFFF0000
.equ BROWN, 0x8B4513FF
.equ CYAN, 0xFF00FFFF
.equ PINK, 0xFFFFC0CB
.equ BULLET_COLOR, 0xFFFFFF00

# ==============================================================================
# BULLET CONSTANTS
# ==============================================================================
.equ BULLET_WIDTH, 4
.equ BULLET_HEIGHT, 28
.equ BULLET_SPEED, 20
.equ BULLET_COOLDOWN, 13
.equ MAX_BULLETS, 5

# ==============================================================================
# PLAYER CONSTANTS
# ==============================================================================
.equ PLAYER_SPEED, 6

.equ KEY_UP, 265
.equ KEY_DOWN, 264
.equ KEY_LEFT, 263
.equ KEY_RIGHT, 262
.equ KEY_SPACE, 32

# ==============================================================================
# ENEMY CONSTANTS
# ==============================================================================
# Centipede specific
.equ MAX_SEGMENTS, 13           # Maximum segments in a centipede

# Spider specific
.equ X_SPEED, 1                 # Spider X movement speed (must be factor of 32)
.equ Y_SPEED, 2                 # Spider Y movement speed (must be factor of 32)
.equ SPIDER_SIZE, 32            # Size of spider

# Flea specific
.equ FLEA_SPEED, 4              # Flea Y movement speed (must be factor of 32)
.equ FLEA_SIZE, 32              # Size of flea

# Spawn chance
.equ FLEA_SPAWN_CHANCE, 2000    # 1 in 2000 chance each frame to spawn flea
.equ SPIDER_SPAWN_CHANCE, 50    # 1 in 50 chance each frame to spawn spider
