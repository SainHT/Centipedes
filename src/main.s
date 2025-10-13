.section .text
.global main

# External raylib functions (System V x86-64 calling convention)
.extern InitWindow
.extern WindowShouldClose
.extern BeginDrawing
.extern EndDrawing
.extern ClearBackground
.extern DrawRectangle
.extern DrawText
.extern CloseWindow
.extern SetTargetFPS
.extern IsKeyDown

# Constants
.equ SCREEN_WIDTH, 480
.equ SCREEN_HEIGHT, 512
.equ KEY_UP, 265
.equ KEY_DOWN, 264
.equ KEY_LEFT, 263
.equ KEY_RIGHT, 262

# Color constants (RGBA format)
.equ BLACK, 0xFF000000
.equ WHITE, 0xFFFFFFFF
.equ GREEN, 0xFF00FF00
.equ RED, 0xFFFF0000

.section .data
window_title: .asciz "Centipedes"
score_text: .asciz "Score: %d"
instructions: .asciz "Use arrow keys to move"

# Game state variables
player_x: .long 400
player_y: .long 550
player_width: .long 20
player_height: .long 20

enemy_x: .long 100
enemy_y: .long 100
enemy_width: .long 15
enemy_height: .long 15

score: .long 0
speed: .long 3

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

game_loop:
    # Check if window should close
    call WindowShouldClose
    testl %eax, %eax
    jnz game_exit
    
    # Handle input
    call handle_input
    
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

# Handle player input
handle_input:
    pushq %rbp
    movq %rsp, %rbp
    
    # Check UP key
    movl $KEY_UP, %edi
    call IsKeyDown
    testl %eax, %eax
    jz .check_down
    
    # Move up
    movl speed(%rip), %eax
    subl %eax, player_y(%rip)
    
.check_down:
    movl $KEY_DOWN, %edi
    call IsKeyDown
    testl %eax, %eax
    jz .check_left
    
    # Move down
    movl speed(%rip), %eax
    addl %eax, player_y(%rip)
    
.check_left:
    movl $KEY_LEFT, %edi
    call IsKeyDown
    testl %eax, %eax
    jz .check_right
    
    # Move left
    movl speed(%rip), %eax
    subl %eax, player_x(%rip)
    
.check_right:
    movl $KEY_RIGHT, %edi
    call IsKeyDown
    testl %eax, %eax
    jz .input_done
    
    # Move right
    movl speed(%rip), %eax
    addl %eax, player_x(%rip)

.input_done:
    # Boundary checking
    call check_boundaries
    
    popq %rbp
    ret

# Check player boundaries
check_boundaries:
    # Check left boundary
    movl player_x(%rip), %eax
    testl %eax, %eax
    jns .check_right_boundary
    movl $0, player_x(%rip)
    
.check_right_boundary:
    movl player_x(%rip), %eax
    addl player_width(%rip), %eax
    cmpl $SCREEN_WIDTH, %eax
    jle .check_top_boundary
    movl $SCREEN_WIDTH, %eax
    subl player_width(%rip), %eax
    movl %eax, player_x(%rip)
    
.check_top_boundary:
    movl player_y(%rip), %eax
    testl %eax, %eax
    jns .check_bottom_boundary
    movl $0, player_y(%rip)
    
.check_bottom_boundary:
    movl player_y(%rip), %eax
    addl player_height(%rip), %eax
    cmpl $SCREEN_HEIGHT, %eax
    jle .boundaries_done
    movl $SCREEN_HEIGHT, %eax
    subl player_height(%rip), %eax
    movl %eax, player_y(%rip)
    
.boundaries_done:
    ret

# Update game logic
update_game:
    pushq %rbp
    movq %rsp, %rbp
    
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
    movl player_x(%rip), %eax
    addl player_width(%rip), %eax
    cmpl enemy_x(%rip), %eax
    jl .no_collision
    
    # Check if player_x > enemy_x + enemy_width
    movl enemy_x(%rip), %eax
    addl enemy_width(%rip), %eax
    cmpl player_x(%rip), %eax
    jl .no_collision
    
    # Check Y axis
    movl player_y(%rip), %eax
    addl player_height(%rip), %eax
    cmpl enemy_y(%rip), %eax
    jl .no_collision
    
    movl enemy_y(%rip), %eax
    addl enemy_height(%rip), %eax
    cmpl player_y(%rip), %eax
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
    
    # Draw player (using System V x86-64 ABI)
    movl player_x(%rip), %edi
    movl player_y(%rip), %esi
    movl player_width(%rip), %edx
    movl player_height(%rip), %ecx
    movl $GREEN, %r8d
    call DrawRectangle
    
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
