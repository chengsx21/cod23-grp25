addi t0, x0, 0x0
lui t0, 0x40000
addi t1, x0, 0x300
lui t1, 0x40075
loop:
    sb t0, 0(t0)
    addi t0, t0, 1
    beq t0, t1, over
over:
    j over