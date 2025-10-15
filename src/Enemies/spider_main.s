.section .text
.global init_spider
.global update_spider
.global draw_spider


# Constants
.equ SCREEN_WIDTH, 480
.equ SCREEN_HEIGHT, 512
.equ X_SPEED, 1                    # has to be a factor of 16
.equ Y_SPEED, 2                  # has to be a factor of 16
.equ SPIDER_SIZE, 16             # size of spider

.equ PINK, 0xFFFFC0CB


# Spiders move across the player area in a zig-zag pattern and (eat some of the mushrooms); 
# they are worth 300, 600, or 900 points depending on the range they are shot from.

# %rdi = pointer to spider structure
init_spider:
    pushq %rbp
    movq %rsp, %rbp


    # Initialize spider position and state
    movl $100, %eax               # x position
    movl $450, %ecx               # y position

    # store in structure
    movl %eax,  (%rdi)          # set x position
    movl %ecx, 4(%rdi)          # set y position
    movb $0,   8(%rdi)          # direction (00 for leftdown, 01 for rightdown, 10 for leftup, 11 for rightup)
    movb $1,   9(%rdi)          # state (1 = alive)

    movq %rbp, %rsp
    popq %rbp
    ret

# %rdi = pointer to spider structure
# %rsi = pointer to grid
update_spider:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx

    # add logic to move spider in zig-zag
    movq %rdi, %rbx             # spider pointer in %rbx

    # check state
    movb 9(%rbx), %al           # load state
    cmpb $1, %al
    jne .update_spider_end      # if not alive, skip update

    # Load spider
    movl    (%rbx), %eax        # load x position to %rax
    movl   4(%rbx), %edi        # load y position to %rdi
    movzbl 8(%rbx), %edx        # load direction to %rdx

    # Zig-zag pattern movement
    testb $1, %dl               # check right/left bit
    jz .move_left
.move_right:
    addl $X_SPEED, %eax           # move right
    testb $2, %dl               # check up/down bit
    jz .move_down
    jmp .move_up

.move_left:
    subl $X_SPEED, %eax           # move left
    testb $2, %dl               # check up/down bit
    jz .move_down
    jmp .move_up

.move_down:
    addl $Y_SPEED, %edi           # move down
    jmp .vertical_bounds

.move_up:
    subl $Y_SPEED, %edi            # move up

# Check vertical bounds & reverse direction (up <-> down)
.vertical_bounds:
    cmpl $0, %eax                # x >= 0
    jle .reverse_vertical
    movl $SCREEN_WIDTH - SPIDER_SIZE, %esi
    cmpl %esi, %eax             # x < SCREEN_WIDTH
    jge .reverse_vertical
    jmp .horizontal_bounds

# Reverse vertical direction
.reverse_vertical:
    xorb $1, %dl                # toggle right/left bit

# Check horizontal bounds & reverse direction (up <-> down)
.horizontal_bounds:
    cmpl $432, %edi                # y >= 0
    jle .reverse_horizontal
    movl $SCREEN_HEIGHT - SPIDER_SIZE, %esi
    cmpl %esi, %edi              # y < SCREEN_HEIGHT
    jge .reverse_horizontal
    jmp .update_location

# Reverse horizontal direction
.reverse_horizontal:
    xorb $2, %dl                # toggle right/left bit

.update_location:
    # Store updated positions
    movl %eax,  (%rbx)          # store updated x position
    movl %edi, 4(%rbx)          # store updated y position
    movb %dl,  8(%rbx)          # store updated direction
    
.update_spider_end:
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

# rdi = pointer to spider structure
draw_spider:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx

    movq %rdi, %rbx             # spider pointer in %rbx
    
    # check state
    movb 9(%rbx), %al           # load state
    cmpb $1, %al
    jne .draw_spider_end      # if not alive, skip update

    # Load spider
    movl  (%rbx), %edi          # load x position to edi
    movl 4(%rbx), %esi          # load y position to esi
    movl $SPIDER_SIZE, %edx     # load width to edx
    movl $SPIDER_SIZE, %ecx     # load height to ecx (square)
    movl $PINK, %r8d            # color
    call DrawRectangle

.draw_spider_end:
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
