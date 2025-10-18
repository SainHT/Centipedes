.section .text
.global generate_grid
.global draw_grid
.global bullet_mushroom_collision

# Include constants
.include "../../src/constants.s"

.section .data
radius_1: .float 12.0
radius_2: .float 16.0

.section .text
# %rdi - grid pointer
generate_grid:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12

    movq %rdi, %rbx              # grid pointer in rbx

    # generate MUSHROOMS random values for the grid
    movq $MUSHROOMS, %r12        # number of mushrooms to generate
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
    cmpb $4, %al
    je .generate_mushrooms_loop # if already a mushroom, try again
    movb $4, (%rbx,%rcx)

    decq %r12
    jnz .generate_mushrooms_loop

    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret


# %rdi - pointer to bullets
# %rsi - pointer to grid
bullet_mushroom_collision:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13

     movq %rdi, %rbx             # bullets pointer in %rbx
     movq %rsi, %r12             # grid pointer in %r12
     xorq %r13, %r13             # score

     movq $0, %rdi               # bullet index
.bullet_collision_loop:
    movq %rdi, %rax
    imulq $24, %rax             # each bullet is 24 byte
    cmpq $0, 16(%rbx, %rax)     # check if active
    je .next_bullet

    movq (%rbx, %rax), %rsi       # bullet x position
    shrq $5, %rsi                 # divide by 32 to get grid col


    movq 8(%rbx, %rax), %rdx      # bullet y position
    shrq $5, %rdx                 # divide by 32 to get grid row

    movq %rdx, %rax
    imulq $GRID_COLS, %rax
    addq %rsi, %rax               # index = row * GRID_COLS + col

    movb (%r12, %rax), %cl        # load grid cell
    cmpb $0, %cl                  # check if mushroom
    je .next_bullet               # if not, skip

    # decrease mushroom health
    decb (%r12, %rax)            # decrease mushroom health
    addq %rax, %r12

    # deactivate bullet
    movq %rdi, %rax
    imulq $24, %rax
    movq $0, 16(%rbx, %rax)      # set active to 0

    cmpb $0, (%r12)              # check if mushroom is dead
    jne .next_bullet             # if not dead, skip score
    addq $10, %r13               # increase score by 10

.next_bullet:
    incq %rdi
    cmpq $MAX_BULLETS, %rdi
    jl .bullet_collision_loop

    xorq %rax, %rax
    movq %r13, %rax             # return score in %rax

    popq %r13
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
    pushq %r14
    pushq %r15

    movq %rdi, %rbx              # grid pointer in rbx
    movq $GRID_ROWS + 4, %r14

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
    movzbq %al, %r15
    je .no_mushroom

    # draw mushroom cap
    movq %r13, %rax
    imulq $32, %rax             # x = col * 32
    addq $16, %rax              # center x
    movl %eax, %edi             # x in rdi
    movq %r12, %rax
    imulq $32, %rax             # y = row * 32
    addq $16, %rax              # center y
    movl %eax, %esi             # y in rsi
    movss radius_2(%rip), %xmm0 # radius = 16.0 (float in xmm0)
    movl $SHROOM_OUTLINE, %edx           # color in edx
    //movl $WHITE, %ecx         # color2 in ecx
    call DrawCircle
    

    movq %r13, %rax
    imulq $32, %rax             # x = col * 32
    addq $16, %rax              # center x
    movl %eax, %edi             # x in rdi
    movq %r12, %rax
    imulq $32, %rax             # y = row * 32
    addq $16, %rax              # center y
    movl %eax, %esi             # y in rsi
    movss radius_1(%rip), %xmm0 # radius = 14.0 (float in xmm0)
    movl $SHROOM_FILL, %edx           # color in edx
    call DrawCircle

    # Wipe second half of circles
    movq %r13, %rax
    shl $5, %rax                # x = col * 32
    movl %eax, %edi             # x in rdi
    movq %r12, %rax             # y = row * 32
    shl $5, %rax
    addq $16, %rax              # center y
    movl %eax, %esi             # y in rsi
    movl $32, %edx              # width = 32
    movl $16, %ecx              # height = 16
    movl $BLACK, %r8d
    call DrawRectangle
    
    # Draw bottom of mushroom cap
    movq %r13, %rax
    shl $5, %rax                # x = col * 32
    movl %eax, %edi             # x in rdi
    movq %r12, %rax             # y = row * 32
    shl $5, %rax
    addq $16, %rax              # center y
    movl %eax, %esi             # y in rsi
    movl $32, %edx              # width = 32
    movl $4, %ecx              # height = 4
    movl $SHROOM_OUTLINE, %r8d
    call DrawRectangle

    # Draw mushroom stem
    movq %r13, %rax
    shl $5, %rax                # x = col * 32
    addq $9, %rax
    movl %eax, %edi             # x in rdi
    movq %r12, %rax             # y = row * 32
    shl $5, %rax
    addq $16, %rax              # center y
    movl %eax, %esi             # y in rsi
    movl $14, %edx              # width = 10
    movl $16, %ecx              # height = 12
    movl $SHROOM_OUTLINE, %r8d
    call DrawRectangle

    movq %r13, %rax
    shl $5, %rax                # x = col * 32
    addq $13, %rax
    movl %eax, %edi             # x in rdi
    movq %r12, %rax             # y = row * 32
    shl $5, %rax
    addq $20, %rax              # center y
    movl %eax, %esi             # y in rsi
    movl $6, %edx              # width = 10
    movl $8, %ecx              # height = 12
    movl $SHROOM_FILL, %r8d
    call DrawRectangle

    cmpq $4, %r15
    je .no_mushroom

    movq %r13, %rax
    shl $5, %rax                # x = col * 32
    movl %eax, %edi             # x in rdi
    movq %r12, %rax             # y = row * 32
    shl $5, %rax
    addq $24, %rax              # center y
    movl %eax, %esi             # y in rsi
    movl $32, %edx              # width = 32
    movl $8, %ecx               # height = 8
    movl $BLACK, %r8d
    call DrawRectangle
    cmpq $3, %r15
    je .no_mushroom

    movq %r13, %rax
    shl $5, %rax                # x = col * 32
    movl %eax, %edi             # x in rdi
    movq %r12, %rax             # y = row * 32
    shl $5, %rax
    addq $16, %rax              # center y
    movl %eax, %esi             # y in rsi
    movl $32, %edx              # width = 32
    movl $8, %ecx               # height = 8
    movl $BLACK, %r8d
    call DrawRectangle
    cmpq $2, %r15
    je .no_mushroom

    movq %r13, %rax
    shl $5, %rax                # x = col * 32
    movl %eax, %edi             # x in rdi
    movq %r12, %rax             # y = row * 32
    shl $5, %rax
    addq $8, %rax              # center y
    movl %eax, %esi             # y in rsi
    movl $32, %edx              # width = 32
    movl $8, %ecx               # height = 8
    movl $BLACK, %r8d
    call DrawRectangle

.no_mushroom:
    incq %r13
    cmpq $GRID_COLS, %r13
    jl .draw_grid_col_loop

    incq %r12
    cmpq %r14, %r12
    jl .draw_grid_row_loop

    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
