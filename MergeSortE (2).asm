# merge-sort starter code

main: j start # skip the .word region to start execution
# .word region to store a sequence of unsorted values
.word 9 # each .worcod store a signed integer value into a 4-byte word
.word 6
.word 10
.word 7
.word 4
.word 3
.word 5
.word 8

start: addi $a0, $zero, 4 #entry address of the unsorted sequence in $a0
addi $a1, $zero, 8 #number of elements

jal mergeSort #use jal to call a procedure. Must return using "jr $ra"

lw $t0, 0($v0) # a sequence of lw to load the sorted values
lw $t0, 4($v0)
lw $t0, 8($v0)
lw $t0, 12($v0)
lw $t0, 16($v0)
lw $t0, 20($v0)
lw $t0, 24($v0)
lw $t0, 28($v0)

stop: j stop # infinite loop after displaying results

################# MergeSort procedure #####################
## input: $a0 -> start address of the unsorted sequence
## input: $a1 -> count of elements in the unsorted sequence
## output: $v0 -> start address of the sorted sequence

mergeSort:  sll $t0, $a1, 2 # a1*4 = number of bytes needed in the stack to store combined sequence
sub $sp, $sp, $t0 # reserve space for combined sequence in the stack
addi $sp, $sp, -12     
sw   $ra, 8($sp)       # Save ra
sw   $a0, 4($sp)        # Save a0
sw   $a1, 0($sp)        # Save a1





# Base Case
addi $t0, $zero, 1      # Set t0 = 1
beq $a1, $t0, copy

# Compute mid = $a1 / 2
sra  $t1, $a1, 1        # t1 = $a1 / 2

# Sort the left half
addi $a1, $t1, 0        # a1 = mid
jal  mergeSort          # Recursive left call


# move sorted left into the upperhalf of the combined sequence
lw $a0, 4($sp)
lw $a1, 0($sp)
addi $a3, $sp, 12
srl $t0, $a1, 1
sll $t0, $t0, 2 # t0 contains number of bytes for sorted left
sll $t1, $a1, 2 # total bytes for combined
sub $t1, $t1, $t0
add $a3, $a3, $t1 # upper half of the combine sorted is at $a3
# left sorted is at $v0

srl $t0, $a1, 1
cpyLoop: beq $t0, $zero, sortRight
lw $t1, 0($v0) #load 1 element from left sorted
sw $t1, 0($a3) #move into combined
addi $v0, $v0, 4
addi $a3, $a3, 4
addi $t0, $t0, -1
j cpyLoop



# Sort the right half
sortRight: lw   $a0, 4($sp)        # Restore original a0
lw   $a1, 0($sp)        # Restore original a1
srl  $t0, $a1, 1
sub $a1, $a1, $t0
sll $t0, $t0, 2
add $a0, $a0, $t0
jal  mergeSort          # Recursively sort the right half
addi $t3, $v0, 0        # Save right sorted address in $t3 

# Merge
#addi   $a0, $t2, 0      # a0 = start of left half 
#lw   $a1, 0($sp)        # a1 = length of left half 
#addi $a2, $t3, 0        # a2 = start of right half 
#lw   $a3, 4($sp)        # a3 = length of right half

lw $a0, 4($sp)
lw $a1, 0($sp)
addi $a3, $sp, 12
srl $t0, $a1, 1
sll $t0, $t0, 2 # t0 contains number of bytes for sorted left
sll $t1, $a1, 2 # total bytes for combined
sub $t1, $t1, $t0
add $a0, $a3, $t1 # start of the left sorted half in the stack
addi $a2, $t3, 0 # start of the right sorted half
srl $a3, $a1, 1 
sub $a3, $a1, $a3 # length of right half
srl $a1, $a1, 1 #length of left half
addi $v0, $sp, 12 # start of the combined sequence in the stack





jal  merge              # Merge the two halves
addi $v0, $sp, 12 # make sure the start of the combined sequence is in v0 before jr $ra
lw $ra, 8($sp) # restore return address
lw $a1, 0($sp)
sll $a1, $a1, 2
addi $a1, $a1, 12 # total number of bytes in the current stack
add $sp, $sp, $a1 # restore stack pointer
jr $ra




#Copy:    addi $t0, $a2, 0       # i = start
#addi $t1, $a1, 1        #end+1
#slt $t2, $t0, $t1       #i<end+1
#sll $t0, $t0, 2         #i*4
#add $a0, $a0, $t0       #base + offset
#lw $t4, 0($a0)          
#sw $t4, 0($v0)
#lw $t5, 0($v0)

copy: addi $v0, $a0, 0
addi $sp, $sp, 16
jr $ra

################# Merge procedure #####################
## input: $a0 -> start of left sorted half
## input: $a1 -> length of left half
## input: $a2 -> start of right sorted half
## input: $a3 -> length of right half
## output: $v0 -> start of the merged sorted sequence

merge:  addi $t0, $zero, 0      # t0 = i = 0
addi $t1, $zero, 0      # t1 = j = 0
add  $t2, $a1, $a3      # t2 = total length
sll  $t3, $t2, 2        # t3 = total_length * 4

mergeLoop:   beq  $t0, $a1, copyRight
beq  $t1, $a3, copyLeft

# Load current elements from left and right halves
sll  $t4, $t0, 2        # t4 = offset left half
add  $t4, $a0, $t4      # t4 = address of a0(i)
lw   $t5, 0($t4)        # t5 = a0[i]

sll  $t6, $t1, 2        # t6 = offset right half
add  $t6, $a2, $t6      # t6 = address of a2(j)
lw   $t7, 0($t6)        # t7 = a2[j]

# Compare left and right elements
slt  $t8, $t5, $t7      # a0[i] < a2[j]
beq  $t8, $zero, StoreRight # if a0[i] >= a2[j], then copy a2[j]

sw   $t5, 0($v0)        # Store a0[i] in v0
addi $v0, $v0, 4        # Increment pointer
addi $t0, $t0, 1        # Increment index
j    mergeLoop

StoreRight:   sw   $t7, 0($v0)        # Store a2[j] 
addi $v0, $v0, 4        # Increment pointer
addi $t1, $t1, 1        # Increment index
j    mergeLoop

copyLeft:    beq  $t0, $a1, endMerge  
sll  $t4, $t0, 2        # $t4 = offset
add  $t4, $a0, $t4      # $t4 = address of a0(i)
lw   $t5, 0($t4)        # $t5 = a0[i]
sw   $t5, 0($v0)        # Store a0[i] 
addi $v0, $v0, 4        # Increment pointer
addi $t0, $t0, 1        # Increment index
j    copyLeft

copyRight:    beq  $t1, $a3, endMerge  
    sll  $t6, $t1, 2        # $t6 = offset 
    add  $t6, $a2, $t6      # $t6 = address of a2(j)
    lw   $t7, 0($t6)        # $t7 = a2[j]
    sw   $t7, 0($v0)        # Store a2[j] 
    addi $v0, $v0, 4        # Increment pointer
    addi $t1, $t1, 1        # Increment index
    j    copyRight

endMerge:  jr $ra                # Return