.section .text
.global init_flea
.global update_flea
.global draw_flea

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
update_flea:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx

    # add logic to move flee down the screen & spawn mushrooms
    movq %rdi, %rbx             # flea pointer in %rbx
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
    movl (%rbx), %edx        # get x position
    shr $5, %edx             # x / 32 -> col index

    shr $5, %edi             # y / 32 -> row index

    xor %rax, %rax
    movl %edi, %eax
    imull $GRID_COLS, %eax
    addl %edx, %eax          # index = row * GRID_COLS + col

    movb (%rsi, %rax), %cl   # load grid cell
    cmpb $0, %cl             # check if empty
    jne .update_flea_end     # if not empty, skip

    pushq %rsi
    pushq %rax

    movq $0, %rdi
    movq $50, %rsi
    call GetRandomValue     # 1 in 50 chance
    cmpq $0, %rax
    jne .update_flea_end

    popq %rax
    popq %rsi
    movb $3, (%rsi, %rax)  # set grid cell to mushroom (3)

.update_flea_end:
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
    jne .draw_flea_end        # if not alive, skip update

    # Load flea
    movl  (%rbx), %edi          # load x position to %rdi
    movl 4(%rbx), %esi          # load y position to %rsi
    movl $FLEA_SIZE, %edx       # load width to %rdx
    movl %edx, %ecx             # load height to %rcx (square)
    movl $CYAN, %r8d            # color
    call DrawRectangle

.draw_flea_end:
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
