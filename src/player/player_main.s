
.section .text
.global handle_input
.global check_player_at_pos

# Include constants
.include "../../src/constants.s"

#.global handle_input
# Handle player input
# param rdi - player pointer
# param rsi - speed
handle_input:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r15
    pushq %r14
    pushq %r13
    // pushq %r12

    movq %rdi, %r15  # Save player pointer in %r15 for later use
    movq %rsi, %r14  # Save speed in %r14 for later use
    movq %rdx, %r13  # Save grid pointer in %r13
    // movq %rdx, %r13  # Save screen width in %r13
    // movq %rcx, %r12  # Save screen height in %r12

    # Check UP key
    movl $KEY_UP, %edi
    call IsKeyDown
    testl %eax, %eax
    jz .check_down
    
    # Move up
    movq %r14, %rax
    subq %rax, 8(%r15)

.check_down:
    movl $KEY_DOWN, %edi
    call IsKeyDown
    testl %eax, %eax
    jz .check_left
    
    # Move down
    movq %r14, %rax
    addq %rax, 8(%r15)

.check_left:
    movl $KEY_LEFT, %edi
    call IsKeyDown
    testl %eax, %eax
    jz .check_right
    
    # Move left
    movq %r14, %rax
    subq %rax, (%r15)

.check_right:
    movl $KEY_RIGHT, %edi
    call IsKeyDown
    testl %eax, %eax
    jz .input_done
    
    # Move right
    movq %r14, %rax
    addq %rax, (%r15)

.input_done:
    # Boundary checking
    movq %r15, %rdi
    movq %r13, %rsi
    // movq $SCREEN_HEIGHT, %rdx
    call check_boundaries


    # Restore registers and return
    // popq %r12
    popq %r13
    popq %r14
    popq %r15
    popq %rbp
    ret

# Check player boundaries
check_boundaries:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r15
    pushq %r14

    movq %rdi, %r15  # Player pointer in %r15
    movq %rsi, %r14  # Grid pointer in %r14

    # Check left boundary
    movq (%r15), %rax
    cmpq $0, %rax
    jge .check_right_boundary
    movq $0, %rax
    movq %rax, (%r15)


.check_right_boundary:
    movq (%r15), %rax
    addq 16(%r15), %rax
    cmpq $SCREEN_WIDTH, %rax
    jle .check_top_boundary
    movq $SCREEN_WIDTH, %rax
    subq 16(%r15), %rax
    movq %rax, (%r15)

.check_top_boundary:
    movq 8(%r15), %rax
    cmpq $PLAYER_UPPER_BOUNDARY, %rax
    jge .check_bottom_boundary
    movq $PLAYER_UPPER_BOUNDARY, %rax
    movq %rax, 8(%r15)

.check_bottom_boundary:
    movq 8(%r15), %rax
    addq 16(%r15), %rax
    cmpq $SCREEN_HEIGHT, %rax
    jle .boundaries_done
    movq $SCREEN_HEIGHT, %rax
    subq 16(%r15), %rax
    movq %rax, 8(%r15)

.boundaries_done:
.lucorner_check:
#check if player collides with any mushrooms
    #Look up if shroom at position left corner of player
    movq %r14, %rdi      #grid pointer
    movq (%r15), %rsi    #player x
    movq 8(%r15), %rdx  #player y
    call mushroom_at_pos
   
    cmpq $0, %rax
    je .rucorner_check
    #Handle x/y capping
    #calculate distance x from grid cell left corner
    movq (%r15), %rdi
    movq (%r15), %rax
    shrq $5, %rax
    shlq $5, %rax
    subq %rax, %rdi
    #calculate distance y from grid cell left corner
    movq 8(%r15), %rsi
    movq 8(%r15), %rax
    shrq $5, %rax
    shlq $5, %rax
    subq %rax, %rsi

    cmpq %rdi, %rsi
    jg .lucorner_cap_y
    #cap x
    movq $RESOLUTION, %rax
    subq %rdi, %rax
    addq %rax, (%r15)
    jmp .rucorner_check

.lucorner_cap_y:
    #cap y
    movq $RESOLUTION, %rax
    subq %rsi, %rax
    addq %rax, 8(%r15)

.rucorner_check:
    #Look up if shroom at position right corner of player
    movq %r14, %rdi      #grid pointer
    movq (%r15), %rsi    #player x
    addq 16(%r15), %rsi  
    movq 8(%r15), %rdx  #player y
    call mushroom_at_pos

    cmpq $0, %rax
    je .ldcorner_check
    #Handle x/y capping
    #calculate distance x from grid cell left corner
    movq (%r15), %rdi
    addq 16(%r15), %rdi
    movq %rdi, %rax
    shrq $5, %rax
    shlq $5, %rax
    addq $RESOLUTION, %rax
    subq %rdi, %rax
    movq %rax, %rdi
    #calculate distance y from grid cell left corner
    movq 8(%r15), %rsi
    movq 8(%r15), %rax
    shrq $5, %rax
    shlq $5, %rax
    subq %rax, %rsi

    cmpq %rdi, %rsi
    jg .rucorner_cap_y
    #cap x
    movq $RESOLUTION, %rax
    subq %rdi, %rax
    subq %rax, (%r15)
    jmp .ldcorner_check
.rucorner_cap_y:
    #cap y
    movq $RESOLUTION, %rax
    subq %rsi, %rax
    addq %rax, 8(%r15)

.ldcorner_check:
#check if player collides with any mushrooms
    #Look up if shroom at position left corner of player
    movq %r14, %rdi      #grid pointer
    movq (%r15), %rsi    #player x
    movq 8(%r15), %rdx  #player y
    addq 16(%r15), %rdx
    call mushroom_at_pos
   
    cmpq $0, %rax
    je .rdcorner_check
    #Handle x/y capping
    #calculate distance x from grid cell left corner
    movq (%r15), %rdi
    movq (%r15), %rax
    shrq $5, %rax
    shlq $5, %rax
    subq %rax, %rdi
    #calculate distance y from grid cell left corner
    movq 8(%r15), %rsi
    addq 16(%r15), %rsi
    movq %rsi, %rax
    shrq $5, %rax
    shlq $5, %rax
    addq $RESOLUTION, %rax
    subq %rsi, %rax
    movq %rax, %rsi

    cmpq %rdi, %rsi
    jg .ldcorner_cap_y
    #cap x
    movq $RESOLUTION, %rax
    subq %rdi, %rax
    addq %rax, (%r15)
    jmp .rdcorner_check

.ldcorner_cap_y:
    #cap y
    movq $RESOLUTION, %rax
    subq %rsi, %rax
    subq %rax, 8(%r15)

.rdcorner_check:
    #Look up if shroom at position right corner of player
    movq %r14, %rdi      #grid pointer
    movq (%r15), %rsi    #player x
    addq 16(%r15), %rsi  
    movq 8(%r15), %rdx  
    addq 16(%r15), %rdx
    call mushroom_at_pos

    cmpq $0, %rax
    je .shroom_checks_done
    #Handle x/y capping
    #calculate distance x from grid cell left corner
    movq (%r15), %rdi
    addq 16(%r15), %rdi
    movq %rdi, %rax
    shrq $5, %rax
    shlq $5, %rax
    addq $RESOLUTION, %rax
    subq %rdi, %rax
    movq %rax, %rdi
    #calculate distance y from grid cell left corner
    movq 8(%r15), %rsi
    addq 16(%r15), %rsi
    movq %rsi, %rax
    shrq $5, %rax
    shlq $5, %rax
    addq $RESOLUTION, %rax
    subq %rsi, %rax
    movq %rax, %rsi

    cmpq %rdi, %rsi
    jg .rdcorner_cap_y
    #cap x
    movq $RESOLUTION, %rax
    subq %rdi, %rax
    subq %rax, (%r15)
    jmp .shroom_checks_done
.rdcorner_cap_y:
    #cap y
    movq $RESOLUTION, %rax
    subq %rsi, %rax
    subq %rax, 8(%r15)

.shroom_checks_done:
    popq %r14
    popq %r15
    popq %rbp
    ret


# %rdi = pointer to player
# %rsi = x position to check
# %rdx = y position to check
# %rcx = width of target area
# --------------------------------------
# %rax = 0 if no hit, 1 if hit
check_player_at_pos:
    pushq %rbp
    movq %rsp, %rbp

    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq %rdi, %r15  # player base address in %r15
    movq %rsi, %r14  # x in %r14
    movq %rdx, %r13  # y in %r13
    movq %rcx, %r12  # width in %r12

    movq $0, %rax    # No hit by default

    # Check if player_x + player_width < bullet_x
    movq (%rdi), %rax
    addq 16(%rdi), %rax
    cmpq %r14, %rax
    movq $0, %rax
    jl .no_player_hit

    # Check if player_x > target_x + target_width
    movq %r14, %rax
    addq %r12, %rax
    cmpq (%rdi), %rax
    movq $0, %rax
    jl .no_player_hit

    # Check if player_y + player_height < bullet_y
    movq 8(%rdi), %rax
    addq 16(%rdi), %rax
    cmpq %r13, %rax
    movq $0, %rax
    jl .no_player_hit

    # Check if bullet_y > target_y + target_height
    movq %r13, %rax
    addq %r12, %rax
    cmpq 8(%rdi), %rax
    movq $0, %rax
    jl .no_player_hit

    movl $1, %eax  # Hit detected
.no_player_hit:
    # Restore registers and return
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    
    movq %rbp, %rsp
    popq %rbp
    ret


# %rdi = pointer to mushroom array
# %rsi = x position to check
# %rdx = y position to check
mushroom_at_pos:
    pushq %rbp
    movq %rsp, %rbp

    pushq %r15
    pushq %r14
    pushq %r13

    movq %rdi, %r15  # Mushroom array pointer in %r15
    movq %rsi, %r14  # X position in %r14
    movq %rdx, %r13  # Y position in %r13

    shrq $5, %r14   # Divide x by 32 to get grid index
    shrq $5, %r13   # Divide y by 32 to get grid index

    movq %r13, %rax
    imulq $GRID_COLS, %rax
    addq %r14, %rax  # rax = row * cols + col = index

    movq %rax, %rdi  # Move index to rdi for array access
    movb (%r15, %rdi), %al  # Load mushroom at index
    cmpb $0, %al
    movq $0, %rax    # No mushroom by default
    je .no_mushroom

    # Mushroom found
    movq $1, %rax    # Mushroom exists

.no_mushroom:
    popq %r13
    popq %r14
    popq %r15
    popq %rbp
    ret
