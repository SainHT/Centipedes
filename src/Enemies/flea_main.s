.section .text
.global init_flea
.global update_flea
.global draw_flea

.section .data
flea_radius_x: .float 10.0
flea_radius_y: .float 16.0
float_6: .float 6.0
float_10: .float 10.0

.section .text
# Include constants
.include "../../src/constants.s"

# Fleas drop vertically and disappear upon touching the bottom of the screen, 
# occasionally leaving a trail of mushrooms in their path 
# when only a few mushrooms are in the player movement area; 
# they are worth 200 points each and take two shots to destroy.

# %rdi = pointer to flea structure
# %rsi = x_coord
# %rdx = y_coord
init_flea:
    pushq %rbp
    movq %rsp, %rbp


    # Initialize flea position and state
    movl %esi, %eax                # x position
    movl %edx, %ecx                # y position

    # store in structure
    movl %eax,  (%rdi)             # set x position
    movl %ecx, 4(%rdi)             # set y position
    movb $1,   8(%rdi)           # state (1 = alive)

    movq %rbp, %rsp
    popq %rbp
    ret

# %rdi = pointer to flea structure
# %rsi = pointer to grid
# %rdx = pointer to bullets
# --------------------------------------
# %rax = score
update_flea:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13

    # add logic to move flee down the screen & spawn mushrooms
    movq %rdi, %rbx             # flea pointer in %rbx
    movq %rdx, %r12             # grid pointer in %r12

    xor %r13, %r13              # score in %r13

    # check state
    movb 8(%rbx), %al           # load state
    cmpb $1, %al
    jne .update_flea_end        # if not alive, skip update

    # Load flea
    movl   4(%rbx), %edi        # load y position to %rdi
    addl $FLEA_SPEED, %edi      # move down

    # check if we hit bottom of screen
    cmpl $SCREEN_HEIGHT, %edi   # y < SCREEN_HEIGHT
    jl .update_flea_location
    movb $0, 8(%rbx)            # set state to dead
    jmp .update_flea_end

.update_flea_location:
    # Store updated state back
    movl %edi, 4(%rbx)          # store updated y position

# 1/5 chance to spawn mushroom
.spawn_mushroom:
    movl (%rbx), %edx           # get x position
    shr $5, %edx                # x / 32 -> col index

    shr $5, %edi                # y / 32 -> row index

    xor %rax, %rax
    movl %edi, %eax
    imull $GRID_COLS, %eax
    addl %edx, %eax             # index = row * GRID_COLS + col

    movb (%rsi, %rax), %cl      # load grid cell
    cmpb $0, %cl                # check if empty
    jne .check_flea_bullet_collision     # if not empty, skip

    pushq %rsi
    pushq %rax

    movq $0, %rdi
    movq $50, %rsi
    call GetRandomValue         # 1 in 50 chance
    cmpq $0, %rax
    jne .check_flea_bullet_collision

    popq %rax
    popq %rsi
    movb $4, (%rsi, %rax)       # set grid cell to mushroom (4)

.check_flea_bullet_collision:
    xorq %rax, %rax             # return score value
    # Check for bullet collision
    movq %r12, %rdi             # bullets pointer in %rdi
    xor %rsi, %rsi
    movl  (%rbx), %esi          # get x position from segment
    xor %rdx, %rdx
    movl 4(%rbx), %edx          # get y position from segment   
    movq $32, %rcx              # size in %rcx

    call check_bullet_at_pos
    cmpq $1, %rax
    jne .update_flea_end        # if no collision, skip destroy

    # Set flea state to dead
    movb $0, 8(%rbx)            # set state to dead
    movq $200, %r13             # score for flea

.update_flea_end:
    movq %r13, %rax             # return score in %rax
    
    popq %r13
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

# rdi = pointer to flea structure   
draw_flea:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx

    movq %rdi, %rbx             # flea pointer in %rbx
    # check state
    movb 8(%rbx), %al           # load state
    cmpb $1, %al
    jne .draw_flea_end          # if not alive, skip update

    # Load flea
    movl  (%rbx), %edi          # load x position to %rdi
    add $16, %edi               # center x
    movl 4(%rbx), %esi          # load y position to %rsi
    add $16, %esi               # center y
    movss flea_radius_x(%rip), %xmm0  # flea radius x
    movss flea_radius_y(%rip), %xmm1  # flea radius y
    movl $YELLOW, %edx          # color
    call DrawEllipse

    # Wings
    movl  (%rbx), %edi          # load x position to %rdi
    addl $4, %edi               # wing x
    movl 4(%rbx), %esi          # load y position to %rsi
    addl $10, %esi              # wing y
    movss float_6(%rip), %xmm0  # wing radius x
    movss float_10(%rip), %xmm1 # wing radius y
    movl $CYAN, %edx            # color
    call DrawEllipse

    movl (%rbx), %edi           # load x position to %rdi
    addl $28, %edi              # wing x
    movl 4(%rbx), %esi          # load y position to %rsi
    addl $10, %esi              # wing y
    movss float_6(%rip), %xmm0  # wing radius x
    movss float_10(%rip), %xmm1 # wing radius y
    movl $CYAN, %edx            # color
    call DrawEllipse

    # Eyes
    movl  (%rbx), %edi          # load x position to %rdi
    addl $8, %edi               # eye x
    movl 4(%rbx), %esi          # load y position to %rsi
    addl $20, %esi              # eye y
    movss float_6(%rip), %xmm0  # eye radius
    movl $RED, %edx             # color
    call DrawCircle

    movl  (%rbx), %edi          # load x position to %rdi
    addl $24, %edi              # eye x
    movl 4(%rbx), %esi          # load y position to %rsi
    addl $20, %esi              # eye y
    movss float_6(%rip), %xmm0  # eye radius
    movl $RED, %edx             # color
    call DrawCircle



.draw_flea_end:
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
