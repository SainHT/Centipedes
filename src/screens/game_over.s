.section .data
    game_over_text: .asciz "Game Over!"
    centipede_text: .asciz "The centipedes wreak havoc once more..."
    score_text: .asciz "Final Score: %8i"
    hi_score_text: .asciz "High Score: %8i"
    congrats_text: .asciz "Congratulations! You've achieved a new high score!"
    continue_text: .asciz "Press ENTER to continue..."

.section .text
.global game_over

# Include constants
.include "../../src/constants.s"

# %rdi = hi_score
# %rsi = score
game_over:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12

    movl %edi, %ebx               # hi_score in rbx
    movl %esi, %r12d              # score in r12

    call BeginDrawing

    // movl $BLACK, %edi
    // call ClearBackground

    # Draw "Game Over" text
    leaq game_over_text(%rip), %rdi
    movl $350, %esi               # x position
    movl $100, %edx               # y position
    movl $40, %ecx                # font size
    movl $RED, %r8d               # color
    call DrawText

    # Draw centipede message
    leaq centipede_text(%rip), %rdi
    movl $240, %esi               # x position
    movl $150, %edx               # y position
    movl $20, %ecx                # font size
    movl $WHITE, %r8d             # color
    call DrawText

    # Draw continue prompt
    leaq continue_text(%rip), %rdi
    movl $280, %esi               # x position
    movl $500, %edx               # y position
    movl $20, %ecx                # font size
    movl $WHITE, %r8d             # color
    call DrawText

    # Draw final score
    leaq score_text(%rip), %rdi
    movl %r12d, %esi              # score
    call TextFormat

    movq %rax, %rdi
    movl $350, %esi               # x position
    movl $300, %edx               # y position
    movl $20, %ecx                # font size
    movl $YELLOW, %r8d            # color
    call DrawText

    # new high score?
    cmpl %ebx, %r12d
    jle .draw_hi_score

    movl %r12d, %ebx               # update hi_score

    # Draw congratulations message
    leaq congrats_text(%rip), %rdi
    movl $250, %esi               # x position
    movl $350, %edx               # y position
    movl $20, %ecx                # font size
    movl $GREEN, %r8d             # color
    call DrawText
    jmp .end_draw

.draw_hi_score:
    # Draw high score
    leaq hi_score_text(%rip), %rdi
    movl %ebx, %esi               # hi_score
    call TextFormat

    movq %rax, %rdi
    movl $350, %esi               # x position
    movl $400, %edx               # y position
    movl $20, %ecx                # font size
    movl $CYAN, %r8d              # color
    call DrawText

.end_draw:
    call EndDrawing

.game_over_loop:
    # Check if window should close
    call WindowShouldClose
    testl %eax, %eax
    jnz .game_over_exit

    call BeginDrawing

    call EndDrawing

    # Wait for ENTER key to start
    movl $KEY_ENTER, %edi
    call IsKeyDown
    testl %eax, %eax            # Check if key is pressed

    jz .game_over_loop

.game_over_exit:
    movl %ebx, %eax               # return hi_score

    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
