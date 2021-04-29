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
  addi	$sp, $sp, -32
  la	$a0, arr
  li	$a1, 20
bubble:
  addi  $t6, $zero, 4   #int:     i
  la	$t8, arr        #ptr:     original pointer to a[]
  addi  $t7, $zero, 0   #bool:    swapped
whileloop:
  addi 	$at, $zero, 1
  slt 	$t9, $t6, $a1
      nop
      nop
      nop
  bne  	$t9, $at, isswapped
      nop
      nop
      nop
      nop
  lw	$t0, 0($t8)             #load a = a[i]
  lw	$t1, 4($t8)             #load b = a[i+1]
      nop
      nop
  addi 	$at, $zero, 1
  slt	$t2, $t1, $t0           #if a[i+1] < a[i]
      nop
      nop
      nop
  bne	$t2, $at, preloop        	#if a[i+1] > a[i], go to else
      nop
      nop
      nop
      nop
  sw	$t1, 0($t8)             #a[i]   = a[i+1]
  sw	$t0, 4($t8)             #a[i+1] = a[i]
  addi	$t7, $zero, 1           #set swapped to true
preloop:
  addi    $t6, $t6, 4           #i++
  addi    $t8, $t8, 4           #a[]++
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
  lw	$t1, 4($a0)
  lw	$t2, 8($a0)
  lw	$t3, 12($a0)
  lw	$t4, 16($a0)
  halt
      nop
      nop
      nop
      nop