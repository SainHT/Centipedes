.section .text

# Include constants
.include "../../src/constants.s"

# Bullet structure
# .quad x
# .quad y
# .quad active (0 or 1)
.global bullet_update
.global bullet_shoot
.global check_bullet_at_pos

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
    movq %rbp, %rsp
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
    movq %rbp, %rsp
    popq %rbp
    ret


# %rdi = pointer to bullet
# %rsi = x position to check
# %rdx = y position to check
# %rcx = width of enemy
check_bullet_at_pos:
    pushq %rbp
    movq %rsp, %rbp

    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq %rdi, %r15  # bullets base address in %r15
    movq %rsi, %r14  # x in %r14
    movq %rdx, %r13  # y in %r13
    movq %rcx, %r12  # width in %r12

    movq $0, %rax    # No hit by default

    # Check each bullet for collision
.check_bullet1:
    cmpq $1, 16(%r15)
    jne .check_bullet2
    movq %r15, %rdi
    call check_single_bullet_collision
    testl %eax, %eax
    jnz .hit_detected

.check_bullet2:
    cmpq $1, 40(%r15)
    jne .check_bullet3
    movq %r15, %rdi
    addq $24, %rdi
    call check_single_bullet_collision
    testl %eax, %eax
    jnz .hit_detected

.check_bullet3:
    cmpq $1, 64(%r15)
    jne .check_bullet4
    movq %r15, %rdi
    addq $48, %rdi
    call check_single_bullet_collision
    testl %eax, %eax
    jnz .hit_detected

.check_bullet4:
    cmpq $1, 88(%r15)
    jne .check_bullet5
    movq %r15, %rdi
    addq $72, %rdi
    call check_single_bullet_collision
    testl %eax, %eax
    jnz .hit_detected

.check_bullet5:
    cmpq $1, 112(%r15)
    jne .done
    movq %r15, %rdi
    addq $96, %rdi
    call check_single_bullet_collision
    testl %eax, %eax
    jnz .hit_detected
    jmp .done

.hit_detected:
    movq $0, 16(%rdi)
    movq $1, %rax
    jmp .done

.done:
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    movq %rbp, %rsp
    popq %rbp
    ret

#The bullet knows where it is at all times by knowing where it is not
#Basically check if the bullet is within the bounds of the target
check_single_bullet_collision:
    #TODO: change literal values to constants

    # Check if bullet_x + bullet_width < target_x
    movq (%rdi), %rax
    addq $2, %rax 
    cmpq %r14, %rax
    movq $0, %rax
    jl .no_hit

    # Check if bullet_x > target_x + target_width
    movq %r14, %rax
    addq %r12, %rax
    cmpq (%rdi), %rax
    movq $0, %rax
    jl .no_hit

    # Check if bullet_y + bullet_height < target_y
    movq 8(%rdi), %rax
    addq $14, %rax
    cmpq %r13, %rax
    movq $0, %rax
    jl .no_hit

    # Check if bullet_y > target_y + target_height
    movq %r13, %rax
    addq %r12, %rax
    cmpq 8(%rdi), %rax
    movq $0, %rax
    jl .no_hit

    movl $1, %eax  # Hit detected
.no_hit:
    ret

