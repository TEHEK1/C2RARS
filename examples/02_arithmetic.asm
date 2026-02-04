.data
.LC0:
.string "a = "
.LC1:
.string ", b = "
.LC2:
.string "a + b = "
.LC3:
.string "a - b = "
.LC4:
.string "a * b = "

.text
.globl main
main:
	addi x2, x2, -32
	sw x1, 28(x2)
	sw x8, 24(x2)
	addi x8, x2, 32
	li x15, 15
	sw x15, -20(x8)
	li x15, 27
	sw x15, -24(x8)
	la x10, .LC0
	call print_string
	lw x10, -20(x8)
	call print_int
	la x10, .LC1
	call print_string
	lw x10, -24(x8)
	call print_int
	li x10, 10
	call print_char
	la x10, .LC2
	call print_string
	lw x14, -20(x8)
	lw x15, -24(x8)
	add x15, x14, x15
	mv x10, x15
	call print_int
	li x10, 10
	call print_char
	la x10, .LC3
	call print_string
	lw x14, -20(x8)
	lw x15, -24(x8)
	sub x15, x14, x15
	mv x10, x15
	call print_int
	li x10, 10
	call print_char
	la x10, .LC4
	call print_string
	lw x14, -20(x8)
	lw x15, -24(x8)
	mul x15, x14, x15
	mv x10, x15
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

print_int:
	addi x2, x2, -32
	sw x1, 28(x2)
	sw x8, 24(x2)
	addi x8, x2, 32
	sw x10, -20(x8)
	lw x10, -20(x8)
	li x17, 1
	ecall
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
	lw x1, 28(x2)
	lw x8, 24(x2)
	addi x2, x2, 32
	jr x1
