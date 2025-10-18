.section .text
.global draw_centipede

.include "../../src/constants.s"

.section .data
radius_14: .float 14.0
float_4: .float 4.0

.section .text
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

    # Check if head segment
    xorq %rsi, %rsi
    movq %rdi, %rdx
    subq $12, %rdx
    cmpb $0, 11(%rdx)
    jne .not_head_segment
    movq $1, %rsi

.not_head_segment:
    # Update segment
    call draw_segment

    incq %r12
    cmpq $30, %r12     # repeat for all segments
    jl .draw_centipede_loop
    
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

# %rdi = pointer to segment
# %rsi = isHead
draw_segment:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12

    movq %rdi, %rbx             # segment pointer in rbx
    movq %rsi, %r12             # isHead in r12

    movb 11(%rbx), %al          # load alive state to rax
    cmpb $0, %al
    je .draw_segment_end        # if dead, skip update

    movl (%rbx), %edi           # load x position to rdi
    addl $6 , %edi              # small offset for centipede body
    movl 4(%rbx), %esi          # load y position to rsi
    movl $20, %edx              # load width to rdx
    movl $32, %ecx              # load height to rcx (square)
    movl $PURPLE, %r8d          # color
    call DrawRectangle

    movl (%rbx), %edi           # load x position to rdi
    addl $16, %edi              # center x
    movl 4(%rbx), %esi          # load y position to rsi
    addl $16, %esi              # center y
    movss radius_14(%rip), %xmm0 # load radius
    movl $GREEN, %edx          # color
    call DrawCircle

    # Eyes if head
    cmpq $1, %r12
    jne .draw_segment_end

    movl (%rbx), %edi           # load x position to rdi
    addl $16, %edi              # left eye x
    movl 4(%rbx), %esi          # load y position to rsi
    addl $10, %esi              # left eye y
    movss float_4(%rip), %xmm0  # eye radius
    movl $RED, %edx           # color
    call DrawCircle

    movl (%rbx), %edi           # load x position to rdi
    addl $16, %edi              # right eye x
    movl 4(%rbx), %esi          # load y position to rsi
    addl $22, %esi              # right eye y
    movss float_4(%rip), %xmm0  # eye radius
    movl $RED, %edx           # color
    call DrawCircle

.draw_segment_end:
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
