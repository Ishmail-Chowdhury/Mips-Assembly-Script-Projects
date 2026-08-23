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

division: add $v0, $zero, $a0       #v0 = quotient = a0
addi $v1, $zero, 0                  #v1 = remainder = 0
addi $t6, $a0, 0                    #t6 = prevremainder = dividend
add $t1, $zero, $a1                 #t1 = divisor = a1

lui $t8, 32768                      #load 1 into bit 31 
and $t5, $t8, $v0                   #check if a0 is neg
srl $t5, $t5, 31                    #1 or 0

and $t4, $t8, $a1                   #check if a1 is negative 
srl $t4, $t4, 31                    #1 or 0

beq $t5, $t4, postive               #11 or 00, postive 
beq $t5, $zero, negdivisor          #if t5 (v0) is postive, divisor is negative 
bne $t5, $zero, negdividend            

negdivisor: nor $t1, $t1, $zero
addi $t1, $t1, 1
addi $t5, $zero, 1
j skip

postive: beq $t5, $zero, skip
nor $t1, $t1, $zero
addi $t1, $t1, 1
nor $v0, $v0, $zero
addi $v0, $v0, 1
addi $t5, $zero, 0
j skip

negdividend: nor $v0, $v0, $zero                 #if negative make pos
addi $v0, $v0, 1

skip: addi $t9, $t9, 33                   #iteration counter

loop: beq $t9, $zero, lastop        #i<30, then j to lastop


sub $v1, $v1, $t1                #Rem = Rem - Div
slt $t2, $v1, $zero              #if Rem < 0
bne $t2, $zero, lt0
beq $t2, $zero, gte0

gte0: and $t7, $v0, $t8              #t7 = find the highest bit value of v0  (1 or 0)
srl $t7, $t7, 31                #shift 31 bits
sll $v0, $v0, 1                 # shift left quotient
addi $v0, $v0, 1
beq $t7, $zero, shift0          # t7 = 0 shift 0 in remainder
bne $t7, $zero, shift1          # t7 = 0 shift 1 in remainder 



lt0: add $v1, $v1, $t1          #restore v1
and $t7, $v0, $t8               #t7 = find the highest bit value of v0  (1 or 0)
srl $t7, $t7, 31                #shift 31 bits
sll $v0, $v0, 1                 # shift left quotient
beq $t7, $zero, shift0          # t7 = 0 shift 0 in remainder
bne $t7, $zero, shift1          # t7 = 0 shift 1 in remainder 

shift0: addi $t6, $v1, 0
sll $v1, $v1, 1
addi $t9, $t9, -1
j loop

shift1: addi $t6, $v1, 0
sll $v1, $v1, 1
addi $v1, $v1, 1
addi $t9, $t9, -1
j loop

lastop: addi $v1, $t6, 0
beq $t5, $zero, exit
bne $t5, $zero, flip+1

flip+1: nor $v0, $v0, $zero
addi $v0, $v0, 1
and $s0, $t8, $a1                   #check if a1 is negative 
srl $s0, $s0, 31                    #1 or 0

bne $s0, $zero, exit

nor $v1, $v1, $zero
addi $v1, $v1, 1
j exit

exit: jr $ra