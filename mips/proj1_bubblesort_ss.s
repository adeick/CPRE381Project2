  #bubblesort tests for proc
  #$a0 = a[]
  #$a1 = n
.data
arr:
        .word   5 #0 
        .word   4 #1
        .word   3 #2
        .word   2 #3
        .word	1 #4
.text
main:
  lui 	$at, 0x00001001
  nop
  nop
  nop
  ori 	$sp, $at, 0x1000
  nop
  nop
  nop
  addiu	$sp, $sp, -32
  nop
  nop
  nop
  addi	$a0, $sp, 8
  addi	$a1, $zero, 20
  nop
  nop
  nop
  sw	$a1, 4($sp)
  nop
  nop
  nop
  addi	$t1, $zero, 5
  nop
  nop
  nop
  sw	$t1, 0($a0)
  addi	$t1, $zero, 4
  nop
  nop
  nop
  sw	$t1, 4($a0)
  nop
  nop
  nop
  addi	$t1, $zero, 3
  nop
  nop
  nop
  sw	$t1, 8($a0)
  nop
  nop
  nop
  addi	$t1, $zero, 2
  nop
  nop
  nop
  sw	$t1, 12($a0)
  nop
  nop
  nop
  addi	$t1, $zero, 1
  nop
  nop
  nop
  sw	$t1, 16($a0)
  nop
  nop
  nop
  addi	$t1, $zero, 0
bubble:
  nop
  nop
  nop
  nop
  addiu  $t8, $sp, 8     #ptr:     original pointer to a[]
  addiu  $t7, $zero, 0   #bool:    swapped
  addiu  $t6, $zero, 4   #int:     i

whileloop:
  nop
  nop
  nop
  nop
  slt   $t9, $t6, $a1
  nop
  nop
  nop
  bne   $t9, 1, isswapped
  nop
  nop
  nop
  lw	$t0, 0($t8)             #load a = a[i]
  nop
  nop
  nop
  lw	$t1, 4($t8)             #load b = a[i+1]
  nop
  nop
  nop
  slt	$t2, $t1, $t0           #if a[i+1] < a[i]
  nop
  nop
  nop
  bne	$t2, 1, preloop        	#if a[i+1] > a[i], go to else
  sw	$t1, 0($t8)             #a[i]   = a[i+1]
  sw	$t0, 4($t8)             #a[i+1] = a[i]
  addi	$t7, $zero, 1           #set swapped to true
  j	preloop                 #go to preloop

preloop:
  nop
  nop
  nop
  nop
  addi    $t6, $t6, 4           #i++
  addi    $t8, $t8, 4           #a[]++
  j       whileloop             #go back to loop
isswapped:
  nop
  nop
  nop
  nop
  beq	$t7, 1, bubble

whiledone:
  nop
  nop
  nop
  nop
  lw	$t0, 0($a0)
  lw	$t1, 4($a0)
  lw	$t2, 8($a0)
  lw	$t3, 12($a0)
  lw	$t4, 16($a0)
  nop
  nop
  nop
  nop
  halt
