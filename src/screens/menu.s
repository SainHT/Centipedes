.section .data
menu_title: .asciz "Centipedes Reimagined"
credits: .asciz "Developed by K. Zivcic & T. Kovac"
instructions: .asciz "Press SPACE to Start"
how_to_play_line1: .asciz "Centipedes have gone rogue!"
how_to_play_line2: .asciz "You have to eliminate each and every one"
how_to_play_line3: .asciz "shooting anything other than its head/tail will split it into two"
how_to_play: .asciz "Use Arrow Keys to move and SPACE to shoot"
hi_score_text: .asciz "High Score: %8i"

.section .text
.global main_menu

.extern init_centipede
.extern update_centipede
.extern draw_centipede

# Include constants
.include "../../src/constants.s"

# %rdi = hi_score
# %rsi = pointer to grid
# %rdx = pointer to centipede
# %rcx = pointer to bullets
main_menu:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14

    movl %edi, %ebx               # hi_score in rbx
    movq %rsi, %r12               # grid pointer in r12
    movq %rdx, %r13               # centipede pointer in r13
    movq %rcx, %r14               # bullets pointer in r14

    movq %r12, %rdi
    call generate_grid

    movq %r13, %rdi
    movq $0, %rsi               
    movq $0, %rcx
    call init_centipede            

.menu_load_loop:
    # Check if window should close
    call WindowShouldClose
    testl %eax, %eax
    jnz .menu_exit

    #update animated background
    movq %r13, %rdi
    movq %r12, %rsi
    movq %r14, %rdx
    call update_centipede

    call BeginDrawing

    movl $BLACK, %edi
    call ClearBackground

    # Draw animated background
    movq %r12, %rdi
    call draw_grid

    movq %r13, %rdi
    call draw_centipede

    # Draw transparent overlay
    movl $0, %edi                 # x position
    movl $0, %esi                 # y position
    movl $SCREEN_WIDTH, %edx      # width
    movl $SCREEN_HEIGHT, %ecx     # height
    movl $TRANSPBLACK, %r8d       # color
    call DrawRectangle 

    # Title
    leaq menu_title(%rip), %rdi
    movl $250, %esi               # x position
    movl $10, %edx                # y position
    movl $40, %ecx                # font size
    movl $RED, %r8d               # color
    call DrawText

    # How to Play
    leaq how_to_play_line1(%rip), %rdi
    movl $320, %esi               # x position
    movl $200, %edx               # y position
    movl $20, %ecx                # font size
    movl $WHITE, %r8d             # color
    call DrawText

    leaq how_to_play_line2(%rip), %rdi
    movl $280, %esi               # x position
    movl $230, %edx               # y position
    movl $20, %ecx                # font size
    movl $WHITE, %r8d             # color
    call DrawText

    leaq how_to_play_line3(%rip), %rdi
    movl $180, %esi                # x position
    movl $260, %edx               # y position
    movl $20, %ecx                # font size
    movl $WHITE, %r8d             # color
    call DrawText

    leaq how_to_play(%rip), %rdi
    movl $250, %esi               # x position
    movl $320, %edx               # y position
    movl $20, %ecx                # font size
    movl $WHITE, %r8d             # color
    call DrawText

    # High Score
    leaq hi_score_text(%rip), %rdi
    movl %ebx, %esi               # hi score
    call TextFormat

    movq %rax, %rdi
    movl $380, %esi               # x position
    movl $400, %edx               # y position
    movl $20, %ecx                # font size
    movl $YELLOW, %r8d            # color
    call DrawText

    # Instructions
    leaq instructions(%rip), %rdi
    movl $350, %esi              # x position
    movl $600, %edx              # y position
    movl $20, %ecx               # font size
    movl $WHITE, %r8d            # color
    call DrawText

    # Credits
    leaq credits(%rip), %rdi
    movl $280, %esi              # x position
    movl $950, %edx              # y position
    movl $20, %ecx               # font size
    movl $WHITE, %r8d            # color
    call DrawText

    call EndDrawing

    # Wait for SPACE key to start
    movl $KEY_SPACE, %edi
    call IsKeyDown
    testl %eax, %eax            # Check if key is pressed

    jz .menu_load_loop

    # grid reset
    movq %r12, %rdi
    movq $960, %rcx             # size of grid (iteration)
    xorq %rax, %rax             # zero value
    rep stosb                   # store to pointer from register

.menu_exit:
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
