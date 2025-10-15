.section .text
.global generate_grid
.global draw_grid

# Include constants
.include "../../src/constants.s"

.section .data
radius_16: .float 16.0

.section .text
# %rdi - grid pointer
generate_grid:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12

    movq %rdi, %rbx              # grid pointer in rbx

    # generate MUSHROOMS random values for the grid
    movq $MUSHROOMS, %r12              # number of mushrooms to generate
.generate_mushrooms_loop:
    # random index in the grid
    movq $GRID_COLS, %rax
    movq $GRID_ROWS, %rdi
    mulq %rdi                    # rax = GRID_COLS * GRID_ROWS
    decq %rax                    # max index is size-1

    movq $30, %rdi
    movq %rax, %rsi
    call GetRandomValue

    xorq %rcx, %rcx
    movl %eax, %ecx          # random index in rcx
    
    # set grid cell to 1 (mushroom)
    movb (%rbx,%rcx), %al
    cmpb $3, %al
    je .generate_mushrooms_loop # if already a mushroom, try again
    movb $3, (%rbx,%rcx)

    decq %r12
    jnz .generate_mushrooms_loop

    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret


# %rdi - grid pointer
draw_grid:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13

    movq %rdi, %rbx              # grid pointer in rbx

    xorq %r12, %r12              # row index
.draw_grid_row_loop:
    xorq %r13, %r13              # col index
.draw_grid_col_loop:
    movq %r12, %rax
    imulq $GRID_COLS, %rax
    addq %r13, %rax              # index = row * GRID_COLS + col
    
    # checking if there's a mushroom
    movb (%rbx,%rax), %al
    cmpb $0, %al
    je .no_mushroom

    # draw mushroom (circle)
    movq %r13, %rax
    imulq $32, %rax             # x = col * 32
    addq $16, %rax              # center x
    movl %eax, %edi             # x in rdi

    movq %r12, %rax
    imulq $32, %rax             # y = row * 32
    addq $16, %rax              # center y
    movl %eax, %esi             # y in rsi

    movss radius_16(%rip), %xmm0 # radius = 16.0 (float in xmm0)
    movl $BROWN, %edx           # color in edx

    call DrawCircle

.no_mushroom:
    incq %r13
    cmpq $GRID_COLS, %r13
    jl .draw_grid_col_loop

    incq %r12
    cmpq $GRID_ROWS, %r12
    jl .draw_grid_row_loop

    popq %r13
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
