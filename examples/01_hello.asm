.data
.LC0:
.string "Hello, world!\n"

.text
.globl main
main:
	addi x2, x2, -16
	sw x1, 12(x2)
	sw x8, 8(x2)
	addi x8, x2, 16
	la x10, .LC0
	call print_string
	li x15, 0
	mv x10, x15
	lw x1, 12(x2)
	lw x8, 8(x2)
	addi x2, x2, 16
	li x17, 10
	ecall

print_string:
	addi x2, x2, -32
	sw x1, 28(x2)
	sw x8, 24(x2)
	addi x8, x2, 32
	sw x10, -20(x8)
	lw x10, -20(x8)
	li x17, 4
	ecall
	lw x1, 28(x2)
	lw x8, 24(x2)
	addi x2, x2, 32
	jr x1
