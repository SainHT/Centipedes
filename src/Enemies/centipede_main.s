.section .text
.global init_centipede
.global update_centipede

# Include constants
.include "../../src/constants.s"

# %rdi = pointer to centipede structure
# %rsi = x_coord
init_centipede:
    pushq %rbp
    movq %rsp, %rbp
    push %rbx
    push %r12

    movq %rdi, %rbx             # centipede pointer in %rbx
    movq %rsi, %r12             # x position in %r12

    # Initialize centipede segments and positions
    movq $11, %rdi
    movq $MAX_SEGMENTS, %rsi
    call GetRandomValue         # random starting number of segments

    # First segment is always dead (other values are ignored)
    movb $0, 11(%rbx)          # state (1 = alive)

    # Initialize each segment
    movq %rax, %rcx            # number of segments in %rcx
    movq $1, %r8               # index in %r8
.init_segment_loop:
    # Calculate segment pointer
    movq %r8, %rax
    imulq $12, %rax            # segment = 12 bytes
    leaq (%rbx,%rax), %rdi     # current segment pointer in %rdi

    # move X position based on index
    movl $32, %eax
    imull %r8d, %eax           # %rax = 32 * index
    addl %r12d, %eax            # starting X position offset

    # Set initial position and state
    movl %eax, (%rdi)          # set x position
    movl $0,  4(%rdi)          # y position
    movb $32, 8(%rdi)          # size
    movb $1,  9(%rdi)          # direction (1 = right)
    movb $1, 10(%rdi)          # absolute direction (1 = down)
    movb $1, 11(%rdi)          # state (1 = alive)

    incq %r8
    cmpq %rcx, %r8
    jl .init_segment_loop      # loop intil all segments

    # Last segment is always dead (other values are ignored)
    movq %r8, %rax
    imulq $12, %rax            # segment = 12 bytes
    leaq (%rbx,%rax), %rdi     # current segment pointer in %rdi
    movb $0, 11(%rdi)          # state (1 = alive)

    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

# %rdi = pointer to centipede structure
# %rsi = pointer to grid
update_centipede:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    
    movq %rdi, %rbx              # centipede pointer in %rbx
    movq $0, %r12                # index %r12
.update_centipede_loop:
    # Calculate segment pointer
    movq %r12, %rax
    imulq $12, %rax              # segment = 12 bytes
    leaq (%rbx,%rax), %rdi       # current segment pointer in %rdi

    
    # Update segment
    call update_segment

    incq %r12
    cmpq $MAX_SEGMENTS, %r12     # repeat for all segments
    jl .update_centipede_loop

    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

# %rdi = pointer to segment
# %rsi = pointer to grid
update_segment:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx

    movb 11(%rdi), %al          # load alive state to %rax
    cmpb $0, %al
    je .update_segment_end      # if dead, skip update

    # Load segment state
    movl (%rdi), %edx           # load x position to %rdx
    movl 4(%rdi), %ecx          # load y position to %rcx
    movsbl 9(%rdi), %r8d        # load direction to %r8 (sign-extended)
    movsbl 10(%rdi), %r9d       # load absolute direction to %r9 (sign-extended)

.change_col:
    # Check if y-coordinate is divisible by 32 (every 4th movement)
    movl %ecx, %eax
    andl $31, %eax              # y % 32
    cmpl $0, %eax
    jne .update_position_y      # if not divisible by 32, skip obstacle check

    # Check if position is divisible by 32 (every 4th movement)
    movl %edx, %eax
    andl $31, %eax              # x % 32
    cmpl $0, %eax
    jne .update_position_x      # if not divisible by 32, skip obstacle check

.check_obstacle:
    # test tile in front
    movl $32, %eax
    imull %r8d, %eax            # %eax = 32 * direction [-1; 1]
    addl %eax, %edx             # test x position in front
    
    # Check for screen bounds
    cmpl $0, %edx               # x < 0 
    jl .change_row
    cmpl $SCREEN_WIDTH, %edx    # x >= SCREEN_WIDTH
    jge .change_row

    # Check for mushroom collision
    xor %rax, %rax
    movl %ecx, %eax             
    shr $5, %eax                # y / 32 -> row index
    
    xor %rbx, %rbx
    movl %edx, %ebx             
    shr $5, %ebx                # x / 32 -> col index

    imull $GRID_COLS, %eax      # row * GRID_COLS
    addl %ebx, %eax             # index = row * GRID_COLS + col

    # checking if there's a mushroom
    movb (%rsi,%rax), %al
    cmpb $0, %al
    je .update_position_x         # if no mushroom, continue moving

.change_row:
    # when we hit an obstacle or edge, move by row and reverse direction
    movl $32, %eax              
    imull %r9d, %eax            # %eax = 32 * absolute direction [-1; 1]
    addl %eax, %ecx             # move by row
    negl %r8d                   # reverse horizontal direction
    
    # check whether we hit bottom / top of screen
    cmpl $0, %ecx                # y >= 0
    jl .switch_abs_direction
    cmpl $SCREEN_HEIGHT, %ecx    # y < SCREEN_HEIGHT
    jge .switch_abs_direction
    movl (%rdi), %edx           # load x position to %rdx
    jmp .update_position_y

.switch_abs_direction:
    negl %r9d                   # reverse absolute direction
    movl $64, %eax              
    imull %r9d, %eax            # %eax = 64 * absolute direction [-1; 1]
    addl %eax, %ecx             # move by 2 rows (64 since we moved 32 already and we want to go opposite direction)
    movl (%rdi), %edx           # load x position to %rdx
    jmp .update_position_y

.update_position_y:
    # Update based on absolute direction (SPEED pixel movement speed)
    movl 4(%rdi), %ecx          # load y position to %rcx
    movl $SPEED, %eax              
    imull %r9d, %eax            # %eax = SPEED * absolute direction [-1; 1]
    addl %eax, %ecx             # move by row
    jmp .store_position

.update_position_x:
    # Update based on direction (SPEED pixel movement speed)
    movl (%rdi), %edx           # load x position to %rdx
    movl $SPEED, %eax              
    imull %r8d, %eax            # %eax = SPEED * direction [-1; 1]
    addl %eax, %edx             # update x position

.store_position:
    # Store updated state back
    movl %edx,  (%rdi)          # store updated x position
    movl %ecx, 4(%rdi)          # store updated y position
    movb %r8b, 9(%rdi)          # store updated direction
    movb %r9b, 10(%rdi)         # store updated absolute direction

.update_segment_end:
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret



# %rdi = pointer to segment
# %rsi = pointer to grid
destroy_segment:
    pushq %rbp
    movq %rsp, %rbp

    movb $0, 11(%rdi)           # set state to dead

    xor %rax, %rax
    movl 8(%rdi), %eax          # get y position
    shr $5, %eax                # y / 32 -> row index

    movl 0(%rdi), %edx          # get x position
    shr $5, %edx                # x / 32 -> col index

    imull $GRID_COLS, %eax      # row * GRID_COLS
    addl %edx, %eax             # index = row * GRID_COLS + col

    movb $3, (%rsi,%rax)        # set grid cell to 3 (mushroom)

    # //TODO: move all segments behind to last true grid position (not sure if needed)


    # //TODO: if all segments are dead, respawn centipede 
    # (each successive centipede is one segment shorter and accompanied by one detached head)

    movq %rbp, %rsp
    popq %rbp
    ret
