.section .text
.global init_spider
.global update_spider
.global draw_spider


# Constants
.equ SCREEN_WIDTH, 480
.equ SCREEN_HEIGHT, 512
.equ SPEED, 4                    # has to be a factor of 16
.equ SPIDER_SIZE, 16             # size of spider

.equ PINK, 0xFFFFC0CB


# Spiders move across the player area in a zig-zag pattern and (eat some of the mushrooms); 
# they are worth 300, 600, or 900 points depending on the range they are shot from.

# %rdi = pointer to spider structure
init_spider:
    pushq %rbp
    movq %rsp, %rbp


    # Initialize spider position and state
    movl $0, %eax               # x position
    movl $0, %ecx               # y position

    # store in structure
    movl %eax,  (%rdi)          # set x position
    movl %ecx, 4(%rdi)          # set y position
    movb $0,   8(%rdi)          # direction (00 for leftdown, 01 for rightdown, 10 for leftup, 11 for rightup)

    movq %rbp, %rsp
    popq %rbp
    ret

# %rdi = pointer to spider structure
# %rsi = pointer to grid
update_spider:
    pushq %rbp
    movq %rsp, %rbp

    # add logic to move spider in zig-zag

    movq %rbp, %rsp
    popq %rbp
    ret

# rdi = pointer to spider structure
draw_spider:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx

    movq %rdi, %rbx             # spider pointer in %rbx

    # Load spider
    movl  (%rbx), %edi          # load x position to edi
    movl 4(%rbx), %esi          # load y position to esi
    movl $SPIDER_SIZE, %edx     # load width to edx
    movl $SPIDER_SIZE, %ecx     # load height to ecx (square)
    movl $PINK, %r8d            # color
    call DrawRectangle

    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
