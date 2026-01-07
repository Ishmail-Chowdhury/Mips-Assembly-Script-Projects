# Hamming Decoding
# Note that 5 parity bits can only protect 26 data bits. The total number of bits in a codeword is 31. 
# We store the 31-bit codeword in a 32-bit register and the storage is left aligned:
# Example:
#   Hamming bit positions:  hamming-b1  hamming-b2  hamming-b3  hamming-b4 ...  hamming-b31  
#    position in register:  reg-bit31   reg-bit30   reg-bit29   reg-bit28  ...  reg-bit1      reg-bit0(unused)

main: j start
.word 1407014220 # hex 0xAB68FFA8
start: lw $a0, 4($zero) # load the codeword
j Hamming

end: addi $v0, $v0, 0 # corrected codeword
addi $v1, $v1, 0 # corrected data

stop: j stop

############## Hamming decoding procedure ##############
## Input: $a0 - input codeword
## Output: $v0 - corrected codeword (still left aligned but with 1-bit error corrected if there is any)
## Output: $v1 - corrected data (
Hamming: lui $t0, 32768
and $s1, $a0, $t0   #p1
lui $t1, 43690      #p1 pattern
ori $t1, $t1, 43690

lui $t0, 16384
and $s2, $a0, $t0   #p2
lui $t2, 26214      #p2 pattern
ori $t2, $t2,  26214

lui $t0, 4096
and $s3, $a0, $t0   #p4
lui $t3, 7710       #p4 pattern
ori $t3, $t3, 7710

lui $t0, 256
and $s4, $a0, $t0   #p8
lui $t4, 510        #p8 pattern
ori $t4, $t4, 510

lui $t0, 1
and $s5, $a0, $t0   #p16
lui $t5, 1          #p16 pattern
ori $t5, $t5, 65534

addi $t7, $zero, 0
lui $t6, 32768

and $t0, $a0, $t1
jal cal_parity
addi $t1, $s6, 0    #move xor value to t1(done with pattern)

and $t0, $a0, $t2    #initialize p2 pattern to loop var
jal cal_parity
addi $t2, $s6, 0    #move xor value to t2(done with pattern)

and $t0, $a0, $t3    #initialize p4 pattern to loop var
jal cal_parity
addi $t3, $s6, 0    #move xor value to t3(done with pattern)

and $t0, $a0, $t4    #initialize p8 pattern to loop var
jal cal_parity
addi $t4, $s6, 0    #move xor value to t4(done with pattern)

and $t0, $a0, $t5   #initialize p16 pattern to loop var
jal cal_parity
addi $t5, $s6, 0    #move xor value to t5(done with pattern)


bne $t1, $zero, correct1

bne $t2, $zero, correct2

bne $t3, $zero, correct3

bne $t4, $zero, correct4

bne $t5, $zero, correct5

addi $v0, $a0, 0
addi $s0, $v0, 0
j predw

cal_parity: addi $s6, $zero, 0
lui $t9, 32768
loop:  beq  $t0, $zero, done  # when pattern is zero, return
    and $t8, $t9, $t0
    srl  $t8, $t8, 31       # Shift the bit to LSB
    xor  $s6, $s6, $t8      # Accumulate parity using XOR
    sll  $t0, $t0, 1        # Shift mask left to check the next bit
    j    loop
done: jr $ra

correct1: bne $t1, $zero, add1
j correct2
add1: addi $t7, $t7, 1
j correct2

correct2: bne $t2, $zero, add2
j correct3
add2: addi $t7, $t7, 2
j correct3

correct3: bne $t3, $zero, add3
j correct4
add3: addi $t7, $t7, 4
j correct4

correct4: bne $t4, $zero, add4
j correct5
add4: addi $t7, $t7, 8
j correct5

correct5: bne $t5, $zero, add5
j correctcw
add5: addi $t7, $t7, 16
j correctcw

correctcw: addi $t7, $t7, -1
srlv $t6, $t6, $t7
xor $v0, $a0, $t6
addi $s0, $v0, 0

predw: addi $t9, $zero, 32    #n =32
addi $s7, $zero, 1              #i = 1
addi $t1, $zero, 1              #p1 position
addi $t2, $zero, 2              #p2 position
addi $t3, $zero, 4              #p4 position
addi $t4, $zero, 8              #p8 position
addi $t5, $zero, 16             #p16 position
addi $v1, $zero, 0              # inital v1 = 0
lui $t6, 32768

dw: slt $t8, $s7, $t9     #i<n
beq $t8, $zero, orientright
beq $s7, $t1, shifts0           #if p1 postion, sll 0 to delete
beq $s7, $t2, shifts0           #if p2 postion, sll 0 to delete
beq $s7, $t3, shifts0           #if p3 postion, sll 0 to delete
beq $s7, $t4, shifts0           #if p4 postion, sll 0 to delete
beq $s7, $t5, shifts0           #if p5 postion, sll 0 to delete

and $t7, $s0, $t6
srl $t7, $t7, 31

beq $t7, $zero, add0v1          #if s0_31 is 0, sll v1 by 1 to add 0
bne $t7, $zero, add1v1          #if s0_31 is 0, sll v1 by 1 to add 0, then +1               

shifts0: sll $s0, $s0, 1
addi $s7, $s7, 1
j dw

add0v1: sll $v1, $v1, 1
sll $s0, $s0, 1
addi $s7, $s7, 1
j dw

add1v1: sll $v1, $v1, 1
addi $v1, $v1, 1
sll $s0, $s0, 1
addi $s7, $s7, 1
j dw

orientright: addi $v1, $v1, 0
j end


