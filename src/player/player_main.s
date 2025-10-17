
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
    // pushq %r13
    // pushq %r12

    movq %rdi, %r15  # Save player pointer in %r15 for later use
    movq %rsi, %r14  # Save speed in %r14 for later use
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
    // movq $SCREEN_WIDTH, %rsi
    // movq $SCREEN_HEIGHT, %rdx
    call check_boundaries


    # Restore registers and return
    // popq %r12
    // popq %r13
    popq %r14
    popq %r15
    popq %rbp
    ret

# Check player boundaries
check_boundaries:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r15

    movq %rdi, %r15  # Player pointer in %r15

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
    cmpq $800, %rax
    jge .check_bottom_boundary
    movq $800, %rax
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
    popq %r15
    popq %rbp
    ret


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
    popq %rbp
    ret
