.data
.LC0:
.string "Countdown from 10:\n"
.LC1:
.string "... "
.LC2:
.string "\nLiftoff!\n"
.LC3:
.string "\nSum from 1 to 10:\n"
.LC4:
.string "Result: "

.text
.globl main
main:
	addi x2, x2, -32
	sw x1, 28(x2)
	sw x8, 24(x2)
	addi x8, x2, 32
	la x10, .LC0
	call print_string
	li x15, 10
	sw x15, -20(x8)
	j .L5

print_int:
	addi x2, x2, -32
	sw x1, 28(x2)
	sw x8, 24(x2)
	addi x8, x2, 32
	sw x10, -20(x8)
	lw x10, -20(x8)
	li x17, 1
	ecall
	nop
	lw x1, 28(x2)
	lw x8, 24(x2)
	addi x2, x2, 32
	jr x1
print_string:
	addi x2, x2, -32
	sw x1, 28(x2)
	sw x8, 24(x2)
	addi x8, x2, 32
	sw x10, -20(x8)
	lw x10, -20(x8)
	li x17, 4
	ecall
	nop
	lw x1, 28(x2)
	lw x8, 24(x2)
	addi x2, x2, 32
	jr x1
print_char:
	addi x2, x2, -32
	sw x1, 28(x2)
	sw x8, 24(x2)
	addi x8, x2, 32
	mv x15, x10
	sb x15, -17(x8)
	lbu x15, -17(x8)
	mv x10, x15
	li x17, 11
	ecall
	nop
	lw x1, 28(x2)
	lw x8, 24(x2)
	addi x2, x2, 32
	jr x1
.L6:
	lw x10, -20(x8)
	call print_int
	la x10, .LC1
	call print_string
	lw x15, -20(x8)
	addi x15, x15, -1
	sw x15, -20(x8)
.L5:
	lw x15, -20(x8)
	bgt x15, x0, .L6
	la x10, .LC2
	call print_string
	la x10, .LC3
	call print_string
	sw x0, -24(x8)
	li x15, 1
	sw x15, -28(x8)
	j .L7
.L8:
	lw x14, -24(x8)
	lw x15, -28(x8)
	add x15, x14, x15
	sw x15, -24(x8)
	lw x15, -28(x8)
	addi x15, x15, 1
	sw x15, -28(x8)
.L7:
	lw x14, -28(x8)
	li x15, 10
	ble x14, x15, .L8
	la x10, .LC4
	call print_string
	lw x10, -24(x8)
	call print_int
	li x10, 10
	call print_char
	li x15, 0
	mv x10, x15
	lw x1, 28(x2)
	lw x8, 24(x2)
	addi x2, x2, 32
	li x17, 10
	ecall
