.section .text
.global draw_centipede
.global draw_segment

.equ PURPLE, 0xFFA020F0

# rdi = pointer to centipede structure
draw_centipede:
    pushq %rbp
    movq %rsp, %rbp

    # Draw each segment of the centipede

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
    movzbl 8(%rbx), %edx        # load width to rdx
    movl %edx, %ecx             # load height to rcx (square)
    movl $PURPLE, %r8d          # color
    call DrawRectangle

.draw_segment_end:
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
