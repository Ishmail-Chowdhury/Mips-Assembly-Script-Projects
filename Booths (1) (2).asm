## Implement the Booth's algorithm for multiplication
lui $a0, 32768 # load 250 into $a0 as the multiplicand
ori $a0, $a0, 0
lui $a1, 65532 # load 400 into $a1 as the multiplier
ori $a1, $a1, 0
jal booth # call your Booth procedure
add $v0, $v0, $zero # copy the upper 32-bit of the product to itself
add $v1, $v1, $zero # copy the lower 32-bit of the product to itself
finish: j finish # infinite loop after displaying the product

#####################
### Booth's procedure for you to implement
#####################
### input: a0 - multiplicand
### input: a1 - multiplier
### output: v0 - high 32bit of the product
### output: v1 - low 32bit of the product

booth: addi $v0, $zero, 0     # A = 0
addi $v1, $a1, 0              # Q = multiplier
addi $t2, $zero, 0            # Q-1 = 0
addi $t9, $zero, 32           # loop counter
lui  $t8, 32768               # 0x80000000 mask

loop: beq $t9, $zero, exit

andi $t3, $v1, 1              # Q0
beq  $t3, $t2, doShift        # 00 or 11 -> no add/sub
bne  $t3, $zero, doSub        # 10 -> A = A - M

doAdd: add $v0, $v0, $a0      # 01 -> A = A + M
j doShift

doSub: sub $v0, $v0, $a0

doShift: andi $t5, $v0, 1      # old A0 for Q31 after shift
sra  $v0, $v0, 1              # arithmetic shift A
srl  $v1, $v1, 1              # logical shift Q
beq  $t5, $zero, noQSignIn
or   $v1, $v1, $t8
noQSignIn: addi $t2, $t3, 0   # Q-1 = old Q0
addi $t9, $t9, -1
j loop

exit: jr $ra
