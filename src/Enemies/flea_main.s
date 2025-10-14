.section .text
.global init_flea
.global update_flea
.global draw_flea


# Constants
.equ SCREEN_WIDTH, 480
.equ SCREEN_HEIGHT, 512
.equ GRID_COLS, 30
.equ SPEED, 4                   # has to be a factor of 16
.equ FLEA_SIZE, 16              # size of flea

.equ CYAN, 0xFF00FFFF

# Fleas drop vertically and disappear upon touching the bottom of the screen, 
# occasionally leaving a trail of mushrooms in their path 
# when only a few mushrooms are in the player movement area; 
# they are worth 200 points each and take two shots to destroy.

# %rdi = pointer to flea structure
init_flea:
    pushq %rbp
    movq %rsp, %rbp


    # Initialize flea position and state
    movl $0, %eax                # x position
    movl $0, %ecx                # y position

    # store in structure
    movl %eax, (%rdi)            # set x position
    movl %ecx, 4(%rdi)           # set y position

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

    # Load flea
    movl  (%rbx), %edi          # load x position to rdi
    movl 4(%rbx), %esi          # load y position to rsi
    movl $FLEA_SIZE, %edx       # load width to rdx
    movl %edx, %ecx             # load height to rcx (square)
    movl $CYAN, %r8d            # color
    call DrawRectangle

    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
