.data
arr:
	.word	2
	.word	5
	.word	8
.text
main:
	lui 	$at, 0x00001001
        nop
        nop
        nop
    	ori 	$sp, $at, 0x1000
    	la	$t7, arr
    	nop
    	nop
    	nop
    	lw	$t0, 0($t7)
    	lw	$t1, 4($t7)
    	lw	$t2, 8($t7)
    	addi	$t0, $t0, 0x10		#0x12
    	addi	$t1, $t1, 0x15		#0x1a
    	addi	$t2, $t2, 0x20		#0x28
    	sw	$t0, 0($t7)
    	sw	$t1, 4($t7)
    	sw	$t2, 8($t7)
    	j	end
    	nop
    	nop
    	nop
    	nop
end:
	halt
	nop
	nop
	nop
	nop