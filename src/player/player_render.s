.section .data
PLAYER_ELLIPSE_RADIUS_X: .float 10.0
PLAYER_ELLIPSE_RADIUS_Y: .float 7.0
PLAYER_COLOR: .byte 255, 255, 255, 255   # White color (RGBA)

EYES_DIAMETER: .float 3.5

.section .text
.global draw_player

# Include constants
.include "../../src/constants.s"


draw_player:
    pushq %rbp
    movq %rsp, %rbp

    pushq %r15
    pushq %r14
    pushq %r13
    //pushq %r12

    movq %rdi, %r15  # x
    movq %rsi, %r14  # y
    movq %rdx, %r13  # size - hihihi dont care 

    // movl %r15d, %edi
    // movl %r14d, %esi
    // movl %r13d, %edx
    // movl %r13d, %ecx
    // movl $PLAYER_FILL, %r8d
    // call DrawRectangle

    #Draw elipse AHHHHAHHDBNJFASAHJHBFBHFBIBIFBIBIUFBIU
    movl %r15d, %edi
    addl $10, %edi          # center x
    movl %r14d, %esi
    addl $15, %esi          # center y
    leaq PLAYER_ELLIPSE_RADIUS_X(%rip), %rdx
    movsd (%rdx), %xmm0
    leaq PLAYER_ELLIPSE_RADIUS_Y(%rip), %rcx
    movsd (%rcx), %xmm1
    movq $0xFFFFFFF0, %rdx
    call DrawEllipse

    #Draw small triangle on top
    movl %r15d, %edi
    addl $9, %edi           # top x
    movl %r14d, %esi
    movl $2, %edx
    movl $20, %ecx
    movl $PLAYER_FILL, %r8d
    call DrawRectangle
    
    movl %r15d, %edi
    addl $8, %edi           # top x
    movl %r14d, %esi
    addl $3, %esi           # top y
    movl $4, %edx
    movl $20, %ecx
    movl $PLAYER_FILL, %r8d
    call DrawRectangle

    movl %r15d, %edi
    addl $6, %edi           # top x
    movl %r14d, %esi
    addl $5, %esi           # top y
    movl $8, %edx
    movl $20, %ecx
    movl $PLAYER_FILL, %r8d
    call DrawRectangle

    movl %r15d, %edi
    addl $4, %edi           # top x
    movl %r14d, %esi
    addl $7, %esi           # top y
    movl $12, %edx
    movl $10, %ecx
    movl $PLAYER_FILL, %r8d
    call DrawRectangle

    movl %r15d, %edi
    addl $2, %edi           # top x
    movl %r14d, %esi
    addl $9, %esi           # top y
    movl $16, %edx
    movl $10, %ecx
    movl $PLAYER_FILL, %r8d
    call DrawRectangle

    #Draw eyes
    movl %r15d, %edi
    addl $6, %edi           # eye1 x
    movl %r14d, %esi
    addl $10, %esi          # eye1 y
    leaq EYES_DIAMETER(%rip), %rdx
    movss (%rdx), %xmm0
    movq $PLAYER_EYES, %rdx
    call DrawCircle

    movl %r15d, %edi
    addl $14, %edi           # eye2 x
    movl %r14d, %esi
    addl $10, %esi          # eye2 y
    leaq EYES_DIAMETER(%rip), %rdx
    movss (%rdx), %xmm0
    movq $PLAYER_EYES, %rdx
    call DrawCircle

    //popq %r12
    popq %r13
    popq %r14
    popq %r15
    popq %rbp
    ret
