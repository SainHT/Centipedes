.section .text

.global player_enemy_collision

# Include constants
.include "../../src/constants.s"


# %rdi = pointer to player
# %rsi = pointer to centipede
# %rdx = pointer to spider
# %rcx = pointer to flea
# --------------------------------------
# %rax = 1 if collision detected, 0 otherwise
player_enemy_collision:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq %rdi, %rbx             # player pointer in %rbx
    movq %rsi, %r12             # centipede pointer in %r12
    movq %rdx, %r13             # spider pointer in %r13
    movq %rcx, %r14             # flea pointer in %r14
    xorq %r15, %r15             # no collision

    # Centipede collision
    xorq %rsi, %rsi
    xorq %r9, %r9               # index
.check_centipede_loop:
    movq %r9, %rax
    imulq $12, %rax              # segment = 12 bytes
    leaq (%r12,%rax), %r8       # current segment pointer in %r8

    movq %rbx, %rdi             # player pointer
    xorq %rsi, %rsi
    movl 0(%r8), %esi           # segment x position
    xorq %rdx, %rdx
    movl 4(%r8), %edx           # segment y position
    movq $RESOLUTION, %rcx      # segment width
    call check_player_at_pos
    orl %eax, %r15d              # collision status

    incq %r9
    cmpq $30, %r9               # repeat for all segments
    jl .check_centipede_loop


    # Spider collision
    movq %rbx, %rdi             # player pointer
    xorq %rsi, %rsi
    movl 0(%r13), %esi          # spider x position
    xorq %rdx, %rdx
    movl 4(%r13), %edx          # spider y position
    movq $RESOLUTION, %rcx      # spider width
    call check_player_at_pos
    orl %eax, %r15d              # collision status


    # Flea collision
    movq %rbx, %rdi             # player pointer
    xorq %rsi, %rsi
    movl 0(%r14), %esi          # flea x position
    xorq %rdx, %rdx
    movl 4(%r14), %edx          # flea y position
    movq $RESOLUTION, %rcx      # flea width
    call check_player_at_pos
    orl %eax, %r15d              # collision status

    movl %r15d, %eax             # return collision status

    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
