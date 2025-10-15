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
    //movb $1,   8(%rdi)             # state (1 = alive)

    movq %rbp, %rsp
    popq %rbp
    ret

# %rdi = pointer to flea structure
# %rsi = pointer to grid
update_flea:
    pushq %rbp
    movq %rsp, %rbp
    
    # add logic to move flee down the screen & spawn mushrooms
    
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
    movl  (%rbx), %edi          # load x position to rdi
    movl 4(%rbx), %esi          # load y position to rsi
    movl $FLEA_SIZE, %edx       # load width to rdx
    movl %edx, %ecx             # load height to rcx (square)
    movl $CYAN, %r8d            # color
    call DrawRectangle

.draw_flea_end:
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
