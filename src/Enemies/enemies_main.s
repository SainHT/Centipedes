.section .text
.global init_enemies
.global update_enemies
.global draw_enemies

.extern init_centipede
.extern update_centipede
.extern draw_centipede

.extern init_spider
.extern update_spider
.extern draw_spider

.extern init_flea
.extern update_flea
.extern draw_flea

# %rdi = pointer to centipede
# %rsi = pointer to spider
# %rdx = pointer to flea
init_enemies:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12

    movq %rsi, %rbx             # spider pointer in rbx
    movq %rdx, %r12             # flea pointer in r12

    # Initialize centipede
    call init_centipede

    # Initialize spider
    movq %rbx, %rdi
    call init_spider

    # Initialize flea
    movq %r12, %rdi
    call init_flea

    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

# %rdi = pointer to centipede
# %rsi = pointer to spider
# %rdx = pointer to flea
# %rcx = pointer to grid
update_enemies:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13

    movq %rsi, %rbx             # spider pointer in rbx
    movq %rdx, %r12             # flea pointer in r12
    movq %rcx, %r13             # grid pointer in r13

    # Update centipede
    movq %r13, %rsi
    call update_centipede

    # Update spider
    movq %rbx, %rdi
    movq %r13, %rsi
    call update_spider

    # Update flea
    movq %r12, %rdi
    movq %r13, %rsi
    call update_flea

    popq %r13
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

# %rdi = pointer to centipede
# %rsi = pointer to spider
# %rdx = pointer to flea
draw_enemies:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12

    movq %rsi, %rbx             # spider pointer in rbx
    movq %rdx, %r12             # flea pointer in r12

    # Draw centipede
    call draw_centipede

    # Draw spider
    movq %rbx, %rdi
    call draw_spider

    # Draw flea
    movq %r12, %rdi
    call draw_flea

    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
