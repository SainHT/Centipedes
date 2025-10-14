.section .text
.global main

# Grid generation function
.extern generate_grid
.extern draw_grid
.extern bullet_update
.extern bullet_shoot
.extern handle_input


#centipede functions
.extern init_centipede
.extern update_centipede

.extern draw_centipede

# External raylib functions (System V x86-64 calling convention)
.extern InitWindow
.extern WindowShouldClose
.extern BeginDrawing
.extern EndDrawing
.extern ClearBackground
.extern DrawCircle
.extern DrawRectangle
.extern DrawText
.extern CloseWindow
.extern SetTargetFPS
.extern IsKeyDown

.extern GetRandomValue

# Constants
.equ SCREEN_WIDTH, 480
.equ SCREEN_HEIGHT, 512


.equ BULLET_WIDTH, 2
.equ BULLET_HEIGHT, 14
.equ BULLET_SPEED, 10
.equ BULLET_COOLDOWN, 13

# Color constants (RGBA format)
.equ BLACK, 0xFF000000
.equ WHITE, 0xFFFFFFFF
.equ GREEN, 0xFF00FF00
.equ RED, 0xFFFF0000
.equ BULLET_COLOR, 0xFFFFFF00

.section .data
window_title: .asciz "Centipedes"
score_text: .asciz "Score: %d"
instructions: .asciz "Use arrow keys to move"

# Game state variables
grid: .zero 32 * 30     # 32x30 grid for mushrooms (value represents Health of mushroom)
player:
    .quad 200 #x
    .quad 200 #y
    .quad 20 #size

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

enemy_x: .long 100
enemy_y: .long 100
enemy_width: .long 15
enemy_height: .long 15

# centipede always has the first and last segment dead (in order to simplify split logic)
centipede: .zero 240    # memory placeholder for centipede segments

# Structure for a centipede segment
# Segment is 12 bytes:
#  .long 240           x position (4 bytes)
#  .long 0             y position (4 bytes)
#  .byte 16            size (max 127) (1 byte)
#  .byte 1             direction (1 for right, -1 for left) (1 byte)
#  .byte 1             absolute direction (1 for down, -1 for up) (1 byte)
#  .byte 1             state (1 for alive, 0 for dead) (1 byte)


score: .long 0
speed: .long 3

.section .text
// .include "../../src/player/player_main.s"
// .include "../../src/bullet/bullet_main.s"

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

    # Generate the grid with mushrooms
    leaq grid(%rip), %rdi
    call generate_grid

    # Initialize centipede
    leaq centipede(%rip), %rdi
    call init_centipede

game_loop:
    # Check if window should close
    call WindowShouldClose
    testl %eax, %eax
    jnz game_exit
    
    # Handle input
    leaq player(%rip), %rdi
    movq speed(%rip), %rsi
    movq $SCREEN_WIDTH, %rdx
    movq $SCREEN_HEIGHT, %rcx
    call handle_input

    # Update bullets
    leaq bullets(%rip), %rdi
    movq $BULLET_WIDTH, %rsi
    movq $BULLET_HEIGHT, %rdx
    movq $BULLET_SPEED, %rcx
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

    # Update centipede
    leaq centipede(%rip), %rdi
    leaq grid(%rip), %rsi
    call update_centipede
    
    # Move enemy
    addl $2, enemy_x(%rip)
    
    # Check if enemy is off screen
    movl enemy_x(%rip), %eax
    cmpl $SCREEN_WIDTH, %eax
    jle .check_collision
    
    # Reset enemy position
    movl enemy_width(%rip), %eax
    negl %eax
    movl %eax, enemy_x(%rip)
    
    # Random Y position (simplified)
    movl $100, enemy_y(%rip)
    
.check_collision:
    call check_player_enemy_collision
    testl %eax, %eax
    jz .update_done
    
    # Collision detected - update score
    addl $10, score(%rip)
    
    # Reset enemy
    movl enemy_width(%rip), %eax
    negl %eax
    movl %eax, enemy_x(%rip)

.update_done:
    popq %rbp
    ret

# Check collision between player and enemy
# Returns: 1 if collision, 0 if no collision
check_player_enemy_collision:
    # Check if player_x + player_width < enemy_x
    movl player(%rip), %eax
    addl player+16(%rip), %eax
    cmpl enemy_x(%rip), %eax
    jl .no_collision
    
    # Check if player_x > enemy_x + enemy_width
    movl enemy_x(%rip), %eax
    addl enemy_width(%rip), %eax
    cmpl player(%rip), %eax
    jl .no_collision
    
    # Check Y axis
    movl player+8(%rip), %eax
    addl player+16(%rip), %eax
    cmpl enemy_y(%rip), %eax
    jl .no_collision
    
    movl enemy_y(%rip), %eax
    addl enemy_height(%rip), %eax
    cmpl player+8(%rip), %eax
    jl .no_collision
    
    # Collision detected
    movl $1, %eax
    ret
    
.no_collision:
    movl $0, %eax
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
    call draw_centipede

    
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

    # Draw enemy
    movl enemy_x(%rip), %edi
    movl enemy_y(%rip), %esi
    movl enemy_width(%rip), %edx
    movl enemy_height(%rip), %ecx
    movl $RED, %r8d
    call DrawRectangle
    
    # Draw text (simplified - you'd need proper text rendering)
    # This requires more complex string formatting in assembly
    
    call EndDrawing
    
    popq %rbp
    ret
