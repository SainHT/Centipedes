
.section .text
.global handle_input

.equ KEY_UP, 265
.equ KEY_DOWN, 264
.equ KEY_LEFT, 263
.equ KEY_RIGHT, 262


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
    pushq %r12

    movq %rdi, %r15  # Save player pointer in %r15 for later use
    movq %rsi, %r14  # Save speed in %r14 for later use
    movq %rdx, %r13  # Save screen width in %r13
    movq %rcx, %r12  # Save screen height in %r12

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
    movq %r12, %rdx
    call check_boundaries


    # Restore registers and return
    popq %r12
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
    pushq %r13

    movq %rdi, %r15  # Player pointer in %r15
    movq %rsi, %r14  # Screen width in %r14
    movq %rdx, %r13  # Screen height in %r13

    # Check left boundary
    movq (%r15), %rax
    cmpq $0, %rax
    jge .check_right_boundary
    movq $0, %rax
    movq %rax, (%r15)


.check_right_boundary:
    movq (%r15), %rax
    addq 16(%r15), %rax
    cmpq %r14, %rax
    jle .check_top_boundary
    movq %r14, %rax
    subq 16(%r15), %rax
    movq %rax, (%r15)

.check_top_boundary:
    movq 8(%r15), %rax
    cmpq $0, %rax
    jge .check_bottom_boundary
    movq $0, %rax
    movq %rax, 8(%r15)

.check_bottom_boundary:
    movq 8(%r15), %rax
    addq 16(%r15), %rax
    cmpq %r13, %rax
    jle .boundaries_done
    movq %r13, %rax
    subq 16(%r15), %rax
    movq %rax, 8(%r15)

.boundaries_done:
    popq %r13
    popq %r14
    popq %r15
    popq %rbp
    ret
