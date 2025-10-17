.section .text
.global main

# Screens
.extern main_menu
.extern game_over

# Grid generation
.extern generate_grid
.extern draw_grid

# Input handling
.extern bullet_update
.extern bullet_shoot
.extern handle_input

# Collisions
.extern check_bullet_at_pos
.extern bullet_mushroom_collision
.extern player_enemy_collision

# Enemy
.extern init_enemies
.extern update_enemies
.extern draw_enemies

# External raylib
.extern InitWindow
.extern WindowShouldClose
.extern BeginDrawing
.extern EndDrawing
.extern ClearBackground
.extern DrawCircle
.extern DrawRectangle
.extern TextFormat
.extern DrawText
.extern CloseWindow
.extern SetTargetFPS
.extern IsKeyDown

.extern GetRandomValue

# Include constants
.include "../../src/constants.s"

.section .data
window_title: .asciz "Centipedes"
score_text: .asciz "Score: %8i"

# Game state variables
grid: .zero 32 * 30     # 32x30 grid for mushrooms (value represents Health of mushroom)
player:
    .quad 400 # x
    .quad 800 # y
    .quad 20  # size
    .byte 3   # lives

score: .long 0
hi_score: .long 0

bullets:
    #bullet 1
    .quad 100 #x
    .quad 300 #y
    .quad 0 #active (0 or 1)
    #bullet 2
    .quad 200 #x
    .quad 300 #y
    .quad 0 #active (0 or 1)
    #bullet 3
    .quad 300 #x
    .quad 300 #y
    .quad 0 #active (0 or 1)
    #bullet 4
    .quad 400 #x
    .quad 300 #y
    .quad 0 #active (0 or 1)
    #bullet 5
    .quad 450 #x
    .quad 300 #y
    .quad 0 #active (0 or 1)

bullet_index: .quad 0
bullet_cooldown: .quad 0


level: .quad 0           # current level (centipede splitting based on level)
# centipede always has the first and last segment dead (in order to simplify split logic)
centipede: .zero 360    # memory placeholder for centipede segments

# Structure for a centipede segment
# Segment is 12 bytes:
#  .long 480           x position (4 bytes)
#  .long 0             y position (4 bytes)
#  .byte 32            speed (max 127) (1 byte)
#  .byte 1             direction (1 for right, -1 for left) (1 byte)
#  .byte 1             absolute direction (1 for down, -1 for up) (1 byte)
#  .byte 1             state (1 for alive, 0 for dead) (1 byte)

# flea
flea:
    .long 0              # x position
    .long 0              # y position
    .byte 0              # state (0 for dead, 1 for alive)

# spider
spider:
    .long 0              # x position
    .long 0              # y position
    .byte 0              # direction (00 for leftdown, 01 for rightdown, 11 for rightup, 10 for leftup)
    .byte 0              # state (0 for dead, 1 for alive)

.section .text
main:
    pushq %rbp
    movq %rsp, %rbp
    
    # Initialize window (rescale based in choice)
    movq $SCREEN_WIDTH, %rdi
    movq $SCREEN_HEIGHT, %rsi
    leaq window_title(%rip), %rdx
    call InitWindow
    
    # Set target FPS
    movl $60, %edi
    call SetTargetFPS

.main_menu:

    movl hi_score(%rip), %edi
    leaq grid(%rip), %rsi
    leaq centipede(%rip), %rdx
    leaq bullets(%rip), %rcx
    call main_menu

.main_menu_skip:
    # Generate the grid with mushrooms
    leaq grid(%rip), %rdi
    call generate_grid

    # Initialize centipede
    leaq centipede(%rip), %rdi
    leaq spider(%rip), %rsi
    leaq flea(%rip), %rdx
    movl level(%rip), %ecx
    call init_enemies

game_loop:
    # Check if window should close
    call WindowShouldClose
    testl %eax, %eax
    jnz game_exit
    
    # Handle input
    leaq player(%rip), %rdi
    movq $PLAYER_SPEED, %rsi
    leaq grid(%rip), %rdx
    call handle_input

    # Update bullets
    leaq bullets(%rip), %rdi
    call bullet_update

    # Shoot a bullet every BULLET_COOLDOWN frames
    # If player waits for signed quad frames without shooting he will be locked out of shooting :)
    cmpq $BULLET_COOLDOWN, bullet_cooldown(%rip)
    jl .skip_shoot

    leaq bullets(%rip), %rdi
    movq player+16(%rip), %rsi  # Player size
    shrq $1, %rsi
    addq player(%rip), %rsi  # Player X position
    movq player+8(%rip), %rdx  # Player Y position
    subq $BULLET_HEIGHT, %rdx  # Bullet appears above the player
    call bullet_shoot
    cmpq $0, %rax
    je .skip_shoot
    movq $0, bullet_cooldown(%rip)
.skip_shoot:
    addq $1, bullet_cooldown(%rip)

    # Update game logic
    call update_game
    
    # Render frame
    call render_frame
    
    jmp game_loop

game_exit:
    call CloseWindow
    
    # Return 0
    movl $0, %eax
    popq %rbp
    ret

# Update game logic
update_game:
    pushq %rbp
    movq %rsp, %rbp

    # Check player collision
    leaq player(%rip), %rdi
    leaq centipede(%rip), %rsi
    leaq spider(%rip), %rdx
    leaq flea(%rip), %rcx
    call player_enemy_collision
    cmpl $0, %eax
    je .bullet_collision

    # Player hit
    leaq player(%rip), %rdi
    movq $400, (%rdi)
    movq $800, 8(%rdi)
    decb 24(%rdi)               # decrease lives

    movb $0, flea+8(%rip)       # destroy flea
    movb $0, spider+9(%rip)     # destroy spider

    # Game over (0 lives)
    cmpb $0, 24(%rdi)
    jne .skip_level_reset

    # game over
    movl hi_score(%rip), %edi
    movl score(%rip), %esi
    call game_over              # show game over screen
    movl %eax, hi_score(%rip)   # update hi_score

    # grid reset
    leaq grid(%rip), %rdi
    movq $960, %rcx             # size of grid (iteration)
    xorq %rax, %rax             # zero value
    rep stosb                   # store to pointer from register

    # game state reset
    movl $0,   score(%rip)      # score
    movl $0,   level(%rip)      # level
    movq $400, player(%rip)     # player x
    movq $800, player+8(%rip)   # player y
    movb $3,   player+24(%rip)  # player lives
    # bullet reset
    movq $0, bullets+16(%rip)   # bullet 1 inactive
    movq $0, bullets+40(%rip)   # bullet 2 inactive
    movq $0, bullets+64(%rip)   # bullet 3 inactive
    movq $0, bullets+88(%rip)   # bullet 4 inactive
    movq $0, bullets+112(%rip)  # bullet 5 inactive

    jmp .main_menu         # restart game

.bullet_collision:
    # Bullet-Mushroom collision
    leaq bullets(%rip), %rdi
    leaq grid(%rip), %rsi
    call bullet_mushroom_collision
    addl %eax, score(%rip)      # add score from mushroom collisions

    # Update enemies
    leaq centipede(%rip), %rdi
    leaq spider(%rip), %rsi
    leaq flea(%rip), %rdx
    leaq grid(%rip), %rcx
    leaq bullets(%rip), %r8
    call update_enemies
    addl %eax, score(%rip)      # add score from enemies


    # Check if level complete
    cmpb $1, %dl
    je .update_done             # centipede alive, continue

    # Level Complete
    addl $1, level(%rip)        # increase level
    cmpl $MAX_SEGMENTS, level(%rip)
    jl .skip_level_reset
    movl $0, level(%rip)        # reset level after all segments are as heads

.skip_level_reset:
    # Clear player area
    leaq grid(%rip), %rdi
    addq $840, %rdi             # offset to clear player area
    movq $120, %rcx             # size of grid (iteration)
    xorq %rax, %rax             # zero value
    rep stosb                   # store to pointer from register

    # Respawn centipede
    leaq centipede(%rip), %rdi
    leaq spider(%rip), %rsi
    leaq flea(%rip), %rdx
    movl level(%rip), %ecx
    call init_enemies

    
    #Check bullet-enemy collision(pos left corner and width)
    // leaq bullets(%rip), %rdi
    // movq $200, %rsi # enemy_x
    // movq $300, %rdx # enemy_y
    // movq $100, %rcx # enemy_width
    // call check_bullet_at_pos
    #rax if there is a hit, increase score and reset enemy

    // leaq player(%rip), %rdi
    // movq $100, %rsi  # enemy x
    // movq $900, %rdx      # enemy y
    // movq $50, %rcx    # enemy size
    // call check_player_at_pos
    // cmpq $0, %rax
    // je .update_done
    // # Player hit, reset position and decrease score
    // movq $800, player(%rip)
    // movq $900, player+8(%rip)

.update_done:
    popq %rbp
    ret

# Render the frame
render_frame:
    pushq %rbp
    movq %rsp, %rbp
    
    call BeginDrawing
    
    # Clear background
    movl $BLACK, %edi
    call ClearBackground

    # Draw grid (mushrooms)
    leaq grid(%rip), %rdi
    call draw_grid

    # Draw centipede (temporary - draw single segment for now)
    leaq centipede(%rip), %rdi
    leaq spider(%rip), %rsi
    leaq flea(%rip), %rdx
    call draw_enemies

    # Draw player (using System V x86-64 ABI)
    movl player(%rip), %edi
    movl player+8(%rip), %esi
    movl player+16(%rip), %edx
    movl player+16(%rip), %ecx
    movl $GREEN, %r8d
    call DrawRectangle
    
    # Draw bullets
    # TODO: Loop through bullets and draw active ones
    movq $0,  bullet_index(%rip)
.render_bullets_loop:
    leaq bullets+16(%rip), %rax
    addq bullet_index(%rip), %rax
    cmpq $0, (%rax)
    je .render_bullets_loop_end
    
    leaq bullets(%rip), %rax
    addq bullet_index(%rip), %rax
    movq (%rax), %rdi

    leaq bullets+8(%rip), %rax
    addq bullet_index(%rip), %rax
    movq (%rax), %rsi

    movl $BULLET_WIDTH, %edx
    movl $BULLET_HEIGHT, %ecx
    movl $BULLET_COLOR, %r8d
    call DrawRectangle

.render_bullets_loop_end:
    addq $24, bullet_index(%rip)
    cmpq $120, bullet_index(%rip) # 24*5=120
    jl .render_bullets_loop

    # Draw score
    leaq score_text(%rip), %rdi
    movl score(%rip), %esi
    call TextFormat

    movq %rax, %rdi              # formatted score string
    movl $10, %esi               # x position
    movl $10, %edx               # y position
    movl $20, %ecx               # font size
    movl $WHITE, %r8d            # color
    call DrawText

    call EndDrawing
    
    popq %rbp
    ret
