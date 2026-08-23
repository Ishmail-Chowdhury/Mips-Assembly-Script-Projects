## Implement the Restoring Division Algorithm
## Assume that dividend cannot -2^31, divisor will not be 0
## Remember to handle the signs of the quotient and the remainder in separate steps

main: lui $a0, 1 # load 65537 into $a0 as the dividend
ori $a0, $a0, 1
lui $a1, 0 # load 128 into $a1 as the divisor
ori $a1, $a1, 128
jal division # call the division procedure

addi $v0, $v0, 0 # copy the quotient (must be in $v0) to itself
addi $v1, $v1, 0 # copy the remainder (must be in $v1) to itself

finish: j finish # infinite loop after displaying the results

########### Division Procedure for you to implement ############
## Input: $a0 - the dividend
##        #a1 - the divisor
## Output: $v0 - the quotient
##         $v1 - the remainder

division: addi $v0, $a0, 0          # Q = dividend
addi $v1, $zero, 0                  # A = remainder = 0
addi $t1, $a1, 0                    # M = divisor

lui  $t8, 32768                      # 0x80000000 mask
and  $t5, $a0, $t8                   # dividend sign
srl  $t5, $t5, 31                    # 1 if negative
and  $t4, $a1, $t8                   # divisor sign
srl  $t4, $t4, 31                    # 1 if negative
xor  $t7, $t5, $t4                   # quotient sign
addi $t6, $t5, 0                     # remainder sign (same as dividend)

beq  $t5, $zero, absDivisor
nor  $v0, $v0, $zero                 # abs(dividend)
addi $v0, $v0, 1

absDivisor: beq  $t4, $zero, prepLoop
nor  $t1, $t1, $zero                 # abs(divisor)
addi $t1, $t1, 1

prepLoop: addi $t9, $zero, 32        # iteration counter

loop: beq  $t9, $zero, applySigns
and  $t2, $v0, $t8                   # capture Q31
srl  $t2, $t2, 31
sll  $v1, $v1, 1                     # A <<= 1
or   $v1, $v1, $t2                   # A[0] = old Q31
sll  $v0, $v0, 1                     # Q <<= 1
sub  $v1, $v1, $t1                   # A = A - M
slt  $t3, $v1, $zero
bne  $t3, $zero, restore
ori  $v0, $v0, 1                     # Q0 = 1
addi $t9, $t9, -1
j loop

restore: add  $v1, $v1, $t1          # restore A, Q0 remains 0
addi $t9, $t9, -1
j loop

applySigns: beq  $t7, $zero, remSign
nor  $v0, $v0, $zero                 # apply quotient sign
addi $v0, $v0, 1

remSign: beq  $t6, $zero, exit
nor  $v1, $v1, $zero                 # apply remainder sign
addi $v1, $v1, 1

exit: jr $ra