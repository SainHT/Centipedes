.section .text
.global draw_centipede

.equ PURPLE, 0xFFA020F0
.equ MAX_SEGMENTS, 13           # maximum segments in a centipede

# rdi = pointer to centipede structure
draw_centipede:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12

    movq %rdi, %rbx              # centipede pointer in %rbx
    movq $0, %r12                # index %r12
.draw_centipede_loop:
    # Calculate segment pointer
    movq %r12, %rax
    imulq $12, %rax              # segment = 12 bytes
    leaq (%rbx,%rax), %rdi       # current segment pointer in %rdi

    # Update segment
    call draw_segment

    incq %r12
    cmpq $MAX_SEGMENTS, %r12     # repeat for all segments
    jl .draw_centipede_loop
    
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

# rdi = pointer to segment
draw_segment:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    
    movq %rdi, %rbx              # segment pointer in rbx

    movb 11(%rbx), %al          # load alive state to rax
    cmpb $0, %al
    je .draw_segment_end      # if dead, skip update

    # Load segment state
    movl (%rbx), %edi           # load x position to rdi
    movl 4(%rbx), %esi          # load y position to rsi
    movl $32, %edx        # load width to rdx
    movl %edx, %ecx             # load height to rcx (square)
    movl $PURPLE, %r8d          # color
    call DrawRectangle

.draw_segment_end:
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
