.section .text

# Include constants
.include "../../src/constants.s"

# Bullet structure
# .quad x
# .quad y
# .quad active (0 or 1)
.global bullet_update
.global bullet_shoot

bullet_update:
    pushq %rbp
    movq %rsp, %rbp

    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq %rdi, %r15  # bullets base address in %r15
    movq %rsi, %r14  # bullet width in %r14
    movq %rdx, %r13  # bullet height in %r13
    movq %rcx, %r12  # bullet_speed in %r12
    
.bullet1:
    cmpq $0, 16(%r15)
    je .bullet2
    subq %r12, 8(%r15)

    cmpq $0, 8(%r15)
    jge .bullet2
    movq $0, 16(%r15)
.bullet2:
    cmpq $0, 40(%r15)
    je .bullet3
    subq %r12, 32(%r15)

    cmpq $0, 32(%r15)
    jge .bullet3
    movq $0, 40(%r15)
.bullet3:
    cmpq $0, 64(%r15)
    je .bullet4
    subq %r12, 56(%r15)

    cmpq $0, 56(%r15)
    jge .bullet4
    movq $0, 64(%r15)
.bullet4:
    cmpq $0, 88(%r15)
    je .bullet5
    subq %r12, 80(%r15)

    cmpq $0, 80(%r15)
    jge .bullet5
    movq $0, 88(%r15)
.bullet5:
    cmpq $0, 112(%r15)
    je .bullet_update_done
    subq %r12, 104(%r15)

    cmpq $0, 104(%r15)
    jge .bullet_update_done
    movq $0, 112(%r15)

.bullet_update_done:
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbp
    ret



bullet_shoot:
    pushq %rbp
    movq %rsp, %rbp

    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq %rdi, %r15  # bullets base address in %r15
    movq %rsi, %r14  # x in %r14
    movq %rdx, %r13  # y in %r13

    movq $0, %rcx    # bullet index i = 0

    # Check if space is pressed
    movl $KEY_SPACE, %edi
    call IsKeyDown
    testl %eax, %eax
    jz .bullet_shoot_done


    # Check if bullet is active and shoot if inactive
bullet1_shoot:
    cmpq $1, 16(%r15)
    je .bullet2_shoot
    movq %r14, 0(%r15)  
    movq %r13, 8(%r15)
    movq $1, 16(%r15)
    jmp .bullet_shoot_done
    
.bullet2_shoot:
    cmpq $1, 40(%r15)
    je .bullet3_shoot
    movq %r14, 24(%r15)  
    movq %r13, 32(%r15)
    movq $1, 40(%r15)
    jmp .bullet_shoot_done

.bullet3_shoot:
    cmpq $1, 64(%r15)
    je .bullet4_shoot
    movq %r14, 48(%r15)  
    movq %r13, 56(%r15)
    movq $1, 64(%r15)
    jmp .bullet_shoot_done

.bullet4_shoot:
    cmpq $1, 88(%r15)
    je .bullet5_shoot
    movq %r14, 72(%r15)  
    movq %r13, 80(%r15)
    movq $1, 88(%r15)
    jmp .bullet_shoot_done

.bullet5_shoot:
    cmpq $1, 112(%r15)
    je .bullet_shoot_done
    movq %r14, 96(%r15)  
    movq %r13, 104(%r15)
    movq $1, 112(%r15)
    jmp .bullet_shoot_done

.bullet_shoot_done:
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbp
    ret

