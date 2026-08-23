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

booth: addi $v0, $v0, 0     #v0 = 0
addi $v1, $a1, 0            #v1 = multiplier

lui $t8, 32768              # check for negative

#check if inputs are negative
and $t7, $t8, $a0           # check multiplicand is neg
srl $t7, $t7, 31            # 1 or 0

and $t6, $t8, $a1           #check if multiplier is neg
srl $t6, $t8, 31            # 1 or 0

beq $t6, $t7, postive       # check if 11 , 00

bne $t6, $zero, pass        #if multiplier is negative, pass
addi $t7, $zero, 1          #otherwise, multicand is negative, set t7 to 1 to flip +1 in end 
j pass

postive: addi $t7, $zero, 0 #set t7 to 0 to pass flip+1

beq $t6, $zero, pass        #if multipicand is postive, pass
nor $v1, $v1, $zero         #neg to postive 
addi $v1, $v1, 1


pass: addi $t4, $zero, 0  # A_31 bit

addi $t9, $zero, 32 #iteration counter

addi $t2, $zero, 0  #Q_-1 = 0 


loop: beq $t9, $zero, lastop

andi $t3, $v1, 1    #Gets Q_0
andi $t5, $v0, 1    #gets A_0

beq $t3, $t2, shift # if 11 or 00, shift 
bne $t3, $zero, sub #if t3 = 1, subtract 
bne $t2, $zero, add #if t2 = 0, add

add: add $v0, $v0, $a0   # A = A+M
j shift0A

sub: sub $v0, $v0, $a0  # A= A-M
j shift1A

shift0A: srl $v0, $v0, 1         #shift in 0 by 1 bit  
addi $t4, $zero, 0               #shifted in a 0, so A_31 is 0
beq $t5, zero, shift0Q           #shift 0 if A_0 is 0
bne $t5, zero, shift1Q           #shfit 1 if A_0 is 1

shift0Q: srl $v1, $v1, 1         #shift in 0 by 1 bit 
addi $t2, $t3, 0                 # add prev Q_0 is t2 = Q_-1
addi $t9, $t9, -1                # decrement counter
j loop

shift1A: sra $v0, $v0, 1        #shift upper by 1 bit
or $v0, $t8, $v0                #check highest bit for 1 or 0
addi $t4, $zero, 1              #shifted in a 1, so A_31 is 1
beq $t5, zero, shift0Q          #shift 0 if A_0 is 0
bne $t5, zero, shift1Q          #shfit 1 if A_0 is 1

shift1Q: sra $v1, $v1, 1        #shift in 0 by 1 bit 
or $v1, $t8, $v1                #check highest bit for 1 or 0
addi $t2, $t3, 0                # add prev Q_0 is t2 = Q_-1
addi $t9, $t9, -1               #decrement counter
j loop


shift: bne $t4, $zero, shift1A  # if A_31 is 1, jump to continue to shift 1
beq $t4, $zero, shift0A         # if A_31 is 0, jump to continue to shift 0

lastop: beq $t7, $zero, exit    # if multicand is not negative only, otherwise pass
bne $t7, $zero, flip+1          # if multipicand is negative only, jump flip+1

flip+1: nor $v1, $v1, $zero      #flip bottom
nor $v0, $v0, $zero              #flip top
addi $v1, $v1, 1                 # add 1 to bottom
bne $v1, $zero, skip             #if bottom become is not 0, skip
addi $v0, $v0, 1                 # if bootom is 0 , add 1 to top
skip: j exit

exit: jr $ra
