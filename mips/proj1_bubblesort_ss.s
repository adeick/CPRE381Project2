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
  nop
  nop
  nop
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
  nop
  nop
  nop
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
  nop
  nop
  nop
bubble:
  addi  $t8, $sp, 8     #ptr:     original pointer to a[]
  nop
  nop
  nop
  addi  $t7, $zero, 0   #bool:    swapped
  nop
  nop
  nop
  addi  $t6, $zero, 4   #int:     i
  nop
  nop
  nop

whileloop:
  slt   $t9, $t6, $a1
  nop
  nop
  nop
  bne   $t9, 1, isswapped
  nop
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
  nop
  nop
  nop
  nop
  sw	$t1, 0($t8)             #a[i]   = a[i+1]
  nop
  nop
  nop
  sw	$t0, 4($t8)             #a[i+1] = a[i]
  nop
  nop
  nop
  addi	$t7, $zero, 1           #set swapped to true
  nop
  nop
  nop
  j	preloop                 #go to preloop
  nop
  nop
  nop
  nop

preloop:
  addi    $t6, $t6, 4           #i++
  nop
  nop
  nop
  addi    $t8, $t8, 4           #a[]++
  nop
  nop
  nop
  j       whileloop             #go back to loop
  nop
  nop
  nop
  nop
isswapped:
  beq	$t7, 1, bubble
  nop
  nop
  nop
  nop

whiledone:
  lw	$t0, 0($a0)
  nop
  nop
  nop
  lw	$t1, 4($a0)
  nop
  nop
  nop
  lw	$t2, 8($a0)
  nop
  nop
  nop
  lw	$t3, 12($a0)
  nop
  nop
  nop
  lw	$t4, 16($a0)
  nop
  nop
  nop
  halt
