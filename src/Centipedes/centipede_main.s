.section .text
.global init_centipede
.global update_centipede
.global update_segment          # temporary for testing

.equ SCREEN_WIDTH, 480
.equ SCREEN_HEIGHT, 512
.equ GRID_COLS, 30


# rdi = pointer to centipede structure
init_centipede:
    pushq %rbp
    movq %rsp, %rbp

    # Initialize centipede segments and positions

    movq %rbp, %rsp
    popq %rbp
    ret

# rdi = pointer to centipede structure
# rsi = pointer to grid
update_centipede:
    pushq %rbp
    movq %rsp, %rbp

    # Update logic for the entire centipede
    call update_segment

    movq %rbp, %rsp
    popq %rbp
    ret

# rdi = pointer to segment
# rsi = pointer to grid
update_segment:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx

    movb 11(%rdi), %al          # load alive state to rax
    cmpb $0, %al
    je .update_segment_end      # if dead, skip update

    # Load segment state
    movl (%rdi), %edx           # load x position to rdx
    movl 4(%rdi), %ecx          # load y position to rcx
    movsbl 9(%rdi), %r8d        # load direction to r8 (sign-extended)
    movsbl 10(%rdi), %r9d       # load absolute direction to r9 (sign-extended)

.change_col:
    # Update based on direction (move to next grid cell)
    movl $16, %eax              
    imull %r8d, %eax              # %rax = 16 * direction [-1; 1]
    addl %eax, %edx             # move by col

.check_obstacle:
    # Check for screen bounds
    cmpl $0, %edx                # x < 0 
    jl .change_row
    cmpl $SCREEN_WIDTH, %edx     # x >= SCREEN_WIDTH
    jge .change_row

    # Check for mushroom collision
    xor %rax, %rax
    movl %ecx, %eax             
    shr $4, %eax                # x / 16 -> row index
    
    xor %rbx, %rbx
    movl %edx, %ebx             
    shr $4, %ebx                # y / 16 -> col index

    imull $GRID_COLS, %eax       # row * GRID_COLS
    addl %ebx, %eax               # index = row * GRID_COLS + col

    # checking if there's a mushroom
    movb (%rsi,%rax), %al
    cmpb $0, %al
    je .update_position          # if no mushroom, continue moving

.change_row:
    movl (%rdi), %edx           # reload x position to rdx
    # when we hit an obstacle or edge, move by row and reverse direction
    movl $16, %eax              
    imull %r9d, %eax              # %rax = 16 * absolute direction [-1; 1]
    addl %eax, %ecx             # move by row
    negl %r8d                   # reverse horizontal direction
    
    # check whether we hit bottom / top of screen
    cmpl $0, %ecx                # y >= 0
    jl .switch_abs_direction
    cmpl $SCREEN_HEIGHT, %ecx    # y < SCREEN_HEIGHT
    jge .switch_abs_direction
    jmp .update_position

.switch_abs_direction:
    negl %r9d                   # reverse absolute direction
    movl $32, %eax              
    imull %r9d, %eax            # %rax = 32 * absolute direction [-1; 1]
    addl %eax, %ecx             # move by 2 rows (32 since we moved 16 already and we want to go opposite direction)

.update_position:
    movl %edx,  (%rdi)          # store updated x position
    movl %ecx, 4(%rdi)          # store updated y position
    movb %r8b, 9(%rdi)          # store updated direction
    movb %r9b, 10(%rdi)         # store updated absolute direction

.update_segment_end:
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
