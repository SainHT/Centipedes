.section .text
.global init_centipede
.global update_centipede

# Include constants
.include "../../src/constants.s"

# %rdi = pointer to centipede structure
# %rsi = x_coord
# %rcx= level
init_centipede:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13

    movq %rdi, %rbx             # centipede pointer in %rbx
    movq %rsi, %r12             # x position in %r12
   
    xorq %r13, %r13
    movl %ecx, %r13d             # level in %r13

    # random direction
    movq $0, %rdi
    movq $1, %rsi
    call GetRandomValue
    andq $1, %rax               # direction 0 or 1
    cmpq $0, %rax
    jne .init_centipede_loop
    movq $-1, %rax              # direction -1 (left)
    
.init_centipede_loop:
    movq %rax, %r9               # direction in %r9
    # Initialize centipede segments and positions
    xorq %rax, %rax             
    movq $11, %rdi
    movq $MAX_SEGMENTS, %rsi
    call GetRandomValue         # random starting number of segments

    # First segment is always dead (other values are ignored)
    movb $0, 11(%rbx)          # state (1 = alive)

    # Initialize each segment
    movq %rax, %rcx            # number of segments in %rcx
    subq %r13, %rcx            # reduce by level
    movq $1, %r8               # index in %r8
.init_segment_loop:
    # Calculate segment pointer
    movq %r8, %rax
    imulq $12, %rax            # segment = 12 bytes
    leaq (%rbx,%rax), %rdi     # current segment pointer in %rdi

    # move y position based on index
    movl $-32, %eax
    imull %r8d, %eax           # %rax = -32 * index
    addl %r12d, %eax           # starting y position

    # Set initial position and state
    movl $480,  (%rdi)         # set x position
    movl %eax, 4(%rdi)         # y position
    movb $8,   8(%rdi)          # speed
    movb %r9b, 9(%rdi)         # direction
    movb $1,  10(%rdi)         # absolute direction
    movb $1,  11(%rdi)         # state

    incq %r8
    cmpq %rcx, %r8
    jl .init_segment_loop      # loop intil all segments

    # Last segment is always dead (other values are ignored)
    movq %r8, %rax
    imulq $12, %rax            # segment = 12 bytes
    leaq (%rbx,%rax), %rdi     # current segment pointer in %rdi
    movb $0, 11(%rdi)          # state (1 = alive)

    # Detached heads (amount = level)
    addq %r8, %r13
.detached_loop:
    cmpq %r13, %r8
    jge .init_centipede_end    # loop all detached heads

    # random direction
    movq $0, %rdi
    movq $1, %rsi
    call GetRandomValue
    andq $1, %rax               # direction 0 or 1
    cmpq $0, %rax
    jne .random_x
    movq $-1, %rax              # direction -1 (left)

.random_x:
    movq %rax, %r9              # direction in %r9
    # Random x position
    movq $0, %rdi
    movq $29, %rsi
    call GetRandomValue
    imulq $32, %rax             # x = random * 32
    cmpq $480, %rax
    je .random_x               # x != 480 (big centipede starting position)
    movq %rax, %r12             # x position in %r12

    # Calculate segment pointer
    movq %r8, %rax
    imulq $12, %rax            # segment = 12 bytes
    leaq (%rbx,%rax), %rdi     # current segment pointer in %rdi

    # Set initial position and state
    movl %r12d,  (%rdi)        # set x position
    movl $-32,  4(%rdi)        # y position
    movb $8,    8(%rdi)        # speed
    movb %r9b,  9(%rdi)        # direction
    movb $1,    10(%rdi)       # absolute direction
    movb $1,    11(%rdi)       # state

    movb $0, 23(%rdi)          # state of next segment (dead)

    incq %r8
    jmp .detached_loop

.init_centipede_end:
    popq %r13
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

# %rdi = pointer to centipede structure
# %rsi = pointer to grid
# %rdx = pointer to bullets
# --------------------------------------
# %rax = score
update_centipede:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    
    xorq %r13, %r13              # score in %r13
    movq %rdi, %rbx              # centipede pointer in %rbx
    movq $0, %r12                # index %r12
.update_centipede_loop:
    # Calculate segment pointer
    movq %r12, %rax
    imulq $12, %rax              # segment = 12 bytes
    leaq (%rbx,%rax), %rdi       # current segment pointer in %rdi

    
    # Update segment
    call update_segment
    addq %rax, %r13              # add score from segment

    incq %r12
    cmpq $30, %r12               # repeat for all segments
    jl .update_centipede_loop

    movq %r13, %rax              # return total score in %rax

    popq %r13
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

# %rdi = pointer to segment
# %rsi = pointer to grid
# %rdx = pointer to bullets
# --------------------------------------
# %rax = score
update_segment:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13

    movq %rdi, %rbx             # segment pointer in %rbx
    movq %rsi, %r12             # grid pointer in %r12
    movq %rdx, %r13             # bullets pointer in %r13

    xorq %rax, %rax            # clear score
    pushq %rax

    movb 11(%rbx), %al          # load alive state to %rax
    cmpb $0, %al
    je .update_segment_end      # if dead, skip update

    # Load segment state
    movl     (%rbx), %edx       # load x position to %rdx
    movl    4(%rbx), %ecx       # load y position to %rcx
    movsbl  9(%rbx), %r8d       # load direction to %r8 (sign-extended)
    movsbl 10(%rbx), %r9d       # load absolute direction to %r9 (sign-extended)

.change_col:
    # Check if y-coordinate is divisible by 32 (every 4th movement)
    movl %ecx, %eax
    andl $31, %eax              # y % 32
    cmpl $0, %eax
    jne .update_position_y      # if not divisible by 32, skip obstacle check

    # Check if y-coordinate is less than 0 (startup case)
    cmpl $0, %ecx
    jl .update_position_y

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
    
    xor %esi, %esi
    movl %edx, %esi             
    shr $5, %esi                # x / 32 -> col index

    imull $GRID_COLS, %eax      # row * GRID_COLS
    addl %esi, %eax             # index = row * GRID_COLS + col

    # checking if there's a mushroom
    movb (%r12,%rax), %al
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
    movl (%rbx), %edx           # load x position to %rdx
    jmp .update_position_y

.switch_abs_direction:
    negl %r9d                   # reverse absolute direction
    movl $64, %eax              
    imull %r9d, %eax            # %eax = 64 * absolute direction [-1; 1]
    addl %eax, %ecx             # move by 2 rows (64 since we moved 32 already and we want to go opposite direction)
    movl (%rbx), %edx           # load x position to %rdx
    jmp .update_position_y

.update_position_y:
    # Update based on absolute direction (SPEED pixel movement speed)
    movl 4(%rbx), %ecx          # load y position to %rcx
    movzbl 8(%rbx), %eax          # speed to %eax
    imull %r9d, %eax            # %eax = SPEED * absolute direction [-1; 1]
    addl %eax, %ecx             # move by row
    jmp .store_position

.update_position_x:
    # Update based on direction (SPEED pixel movement speed)
    movl (%rbx), %edx           # load x position to %rdx
    movzbl 8(%rbx), %eax          # speed to %eax
    imull %r8d, %eax            # %eax = SPEED * direction [-1; 1]
    addl %eax, %edx             # update x position

.store_position:
    # Store updated state back
    movl %edx,   (%rbx)         # store updated x position
    movl %ecx,  4(%rbx)         # store updated y position
    movb %r8b,  9(%rbx)         # store updated direction
    movb %r9b, 10(%rbx)         # store updated absolute direction

.bullet_collision:
    # Check for bullet collision
    movq %r13, %rdi             # bullets pointer in %rdi
    xorq %rsi, %rsi
    movl (%rbx), %esi           # get x position from segment
    xorq %rdx, %rdx
    movl 4(%rbx), %edx          # get y position from segment
    movq $32, %rcx              # size in %rcx

    call check_bullet_at_pos
    cmpq $1, %rax
    jne .update_segment_end     # if no collision, skip destroy
    
    # If collision, destroy segment
    movq %rbx, %rdi             # segment pointer in %rdi
    movq %r12, %rsi             # grid pointer in %rsi
    call destroy_segment
    # score higher for head (100 - head; 1 - segment)
    call isHead
    addq %rax, (%rsp)           # score for segment destroyed 

.update_segment_end:
    popq %rax
    movq %rbx, %rdi
    movq %r12, %rsi
    movq %r13, %rdx

    popq %r13
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

# %rdi = pointer to segment
# --------------------------------------
# %rax = 100 if head, 10 otherwise
isHead:
    pushq %rbp
    movq %rsp, %rbp

    subq $12, %rdi               # segment before current
    movb 11(%rdi), %al           # check if alive
    cmpb $1, %al
    je .notHead
    movq $100, %rax
    jmp .isHead_end

.notHead:
    movq $10, %rax

.isHead_end:
    movq %rbp, %rsp
    popq %rbp
    ret


# %rdi = pointer to segment
# %rsi = pointer to grid
destroy_segment:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx

    movb $0, 11(%rdi)           # set state to dead

    xor %rax, %rax
    movl 4(%rdi), %eax          # get y position
    //addl $16, %eax              # center of segment
    shr $5, %eax                # y / 32 -> row index

    movl  (%rdi), %edx          # get x position
    //addl $16, %edx              # center of segment
    shr $5, %edx                # x / 32 -> col index

    imull $GRID_COLS, %eax      # row * GRID_COLS
    addl %edx, %eax             # index = row * GRID_COLS + col

    movb $4, (%rsi,%rax)        # set grid cell to 4 (mushroom)

    # Return all prev segments to last %32 position
    movq %rdi, %rbx

# //TODO: fix segment disalignment issue
.move_segments_loop:
    subq $12, %rbx               # previous segment
    
    cmpb $0, 11(%rbx)           # check if segment is alive
    je .destroy_segments_end    # if dead, stop moving segments

    movl (%rbx), %eax           # get x position
    shr $5, %eax                # align to 32
    shl $5, %eax                # align to 32
    cmpl %eax, (%rbx)
    je .y_adjust
    movl %eax, (%rbx)           # set x position

    cmpb $-1, 9(%rbx)          # check direction
    jne .y_adjust
    movl (%rbx), %eax          # get x position
    addl $32, %eax              # move right
    movl %eax, (%rbx)          # set x position
    
.y_adjust:
    movl 4(%rbx), %eax          # get y position
    shr $5, %eax                # align to 32
    shl $5, %eax                # align to 32
    cmpl %eax, 4(%rbx)
    je .move_segments_loop
    movl %eax, 4(%rbx)          # set y position

    cmpb $1, 9(%rbx)            # check direction
    jne .move_segments_loop
    movl 4(%rbx), %eax          # get y position
    addl $32, %eax              # move down
    movl %eax, 4(%rbx)          # set y position

    jmp .move_segments_loop

.destroy_segments_end:
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
