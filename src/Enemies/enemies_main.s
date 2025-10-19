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

# Include constants
.include "../../src/constants.s"

# %rdi = pointer to centipede
# %rsi = pointer to spider (for testing)
# %rdx = pointer to flea (for testing)
# %rcx = level
init_enemies:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12

    movq %rsi, %rbx             # spider pointer in rbx
    movq %rdx, %r12             # flea pointer in r12

    # Initialize centipede
    movq $0, %rsi               # x position
    call init_centipede

    # Initialize spider
    //movq %rbx, %rdi
    // movq $200, %rsi               # x position
    // movq $900, %rdx               # y position
    // call init_spider

    # Initialize flea
    //movq %r12, %rdi
    // movq $320, %rsi               # x position
    // movq $0, %rdx                 # y position
    // call init_flea

    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

# %rdi = pointer to centipede
# %rsi = pointer to spider
# %rdx = pointer to flea
# %rcx = pointer to grid
# %r8  = pointer to bullets
# --------------------------------------
# %rax = score
update_enemies:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq %rsi, %rbx             # spider pointer in %rbx
    movq %rdx, %r12             # flea pointer in %r12
    movq %rcx, %r13             # grid pointer in %r13
    movq %rdi, %r14             # centipede pointer in %r14
    movq %r8,  %r15             # bullets pointer in %r15


    movb 8(%r12), %al           # load flea state
    cmpb $1, %al
    je .spider_check            # if alive skip

    # Random chance to spawn flea if none exists
    movq $1, %rdi
    movq $FLEA_SPAWN_CHANCE, %rsi
    call GetRandomValue
    cmpq $1, %rax
    jne .spider_check

    # spawn flea at random x position at top of screen
    movq $0, %rdi
    movq $29, %rsi
    call GetRandomValue
    shll $5, %eax                # multiply by 32 for grid
    movl %eax, %esi              # x position
    movq $0, %rdx                # y position
    movq %r12, %rdi              # flea pointer
    call init_flea

.spider_check:
    movb 9(%rbx), %al            # load spider state
    cmpb $1, %al
    je .update_enemies_logic     # if alive skip

    # Random chance to spawn spider if none exists
    movq $1, %rdi
    movq $SPIDER_SPAWN_CHANCE, %rsi
    call GetRandomValue
    cmpq $1, %rax
    jne .update_enemies_logic

    # spawn spider at random y position at left of screen
    movq $800, %rdi
    movq $SCREEN_HEIGHT - 33, %rsi
    call GetRandomValue          # random y position
    pushq %rax
    
    movq $0, %rdi
    movq $1, %rsi
    call GetRandomValue          # random x position side
    imulq $SCREEN_WIDTH - 34, %rax
    addq $1, %rax                

    movq %rax, %rsi              # x position
    popq %rdx                    # y position
    movq %rbx, %rdi              # spider pointer
    call init_spider

.update_enemies_logic:
    xorq %rax, %rax              # clear score
    pushq %rax
    # Update centipede
    movq %r14, %rdi
    movq %r13, %rsi
    movq %r15, %rdx
    call update_centipede
    addl %eax, (%rsp)            # add score from centipede
    
    # Update spider
    movq %rbx, %rdi
    movq %r13, %rsi
    movq %r15, %rdx
    call update_spider
    addl %eax, (%rsp)          # add score from spider

    # Update flea
    movq %r12, %rdi
    movq %r13, %rsi
    movq %r15, %rdx
    call update_flea
    addl %eax, (%rsp)          # add score from flea

# Check if centipede is alive
    xorq %rdx, %rdx            # any_segment_alive boolean in %rdx
    movq $0, %r10              # index %r10
.update_centipede_alive_loop:
    # Calculate segment pointer
    movq %r10, %rax
    imulq $12, %rax            # segment size is 12 bytes
    leaq (%r14, %rax), %rax    # current segment pointer

    orb 11(%rax), %dl          # if segment alive -> true
    incq %r10
    cmpq $30, %r10             # repeat for all segments
    jl .update_centipede_alive_loop

    xorq %rdi, %rdi
    movb %dl, %dil             # move boolean to %rdi (second output)

    # Update total score
    popq %rax

.update_enemies_end:
    popq %r15
    popq %r14
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
