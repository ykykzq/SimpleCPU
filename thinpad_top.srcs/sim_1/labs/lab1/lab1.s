    .org 0x0
    .text
    .global _start
_start:
    addi.w      $t0,$zero,0x1   # t0 = 1
    addi.w      $t1,$zero,0x1   # t1 = 1
    lu12i.w     $a0,-0x7fc00    # a0 = 0x80400000
    addi.w      $a1,$a0,0x100   # a1 = 0x80400100
loop:
    add.w       $t2,$t0,$t1     # t2 = t0+t1
    addi.w      $t0,$t1,0x0     # t0 = t1
    addi.w      $t1,$t2,0x0     # t1 = t2
    st.w        $t2,$a0,0x0
    ld.w        $t3,$a0,0x0
    bne         $t2,$t3,end
    addi.w      $a0,$a0,0x4     # a0 += 4
    bne         $a0,$a1,loop
end:
    bne         $a0,$zero,end