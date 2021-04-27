.data

.text
main:
	addi 	$sp, $zero, 0x10011000
	addi	$a0, $zero, 0x0
	addi	$a1, $zero, 0x1
	addi	$a2, $zero, 0x2
	jal	stackframetst
	nop
	nop
	nop
	nop
	addi	$s0, $v0, 0
	j	finish

stackframetst:
	nop
	nop
	nop
	nop
	addi	$sp, $sp, -16
	slti	$t4, $a2, 0xF00
	nop
	nop
	nop
	beq	$t4, 0, tstdone
	sw	$ra, 0($sp)
	sw	$a0, 4($sp)
	sw	$a1, 8($sp)
	sw	$a2, 12($sp)
	addi	$v0, $v0, 1
	j	stcktstloop
	
stcktstloop:
	nop
	nop
	nop
	nop
	lw	$t0, 4($sp)
	lw	$t1, 8($sp)
	lw	$t2, 12($sp)
	add	$t1, $t1, $t0
	nop
	nop
	add	$t2, $t2, $t1
	addi	$t0, $t0, 1
	nop
	addi	$a2, $t2, 0
	addi	$a1, $t1, 0
	addi	$a0, $t0, 0
	j	stackframetst
tstdone:
	addi	$sp, $sp, 16
	nop
	nop
	nop
	lw	$t0, 4($sp)
	lw	$t1, 8($sp)
	lw	$t2, 12($sp)
	nop
	add	$t1, $t1, $t0
	nop
	nop
	add	$t2, $t2, $t1
	nop
	nop
	add	$v1, $v1, $t2
	bne	$t0, 1, tstdone
	lw	$ra, 0($sp)
	jr	$ra
	
finish:
	nop
	nop
	nop
	nop
	halt
