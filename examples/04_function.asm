.data
.LC0:
.string "Function Examples\n"
.LC1:
.string "=================\n\n"
.LC2:
.string "Factorial(5) = "
.LC3:
.string "Fibonacci(7) = "
.LC4:
.string "Power(2, 8) = "

.text
.globl main
main:
	addi x2, x2, -16
	sw x1, 12(x2)
	sw x8, 8(x2)
	addi x8, x2, 16
	la x10, .LC0
	call print_string
	la x10, .LC1
	call print_string
	la x10, .LC2
	call print_string
	li x10, 5
	call factorial
	mv x15, x10
	mv x10, x15
	call print_int
	li x10, 10
	call print_char
	la x10, .LC3
	call print_string
	li x10, 7
	call fibonacci
	mv x15, x10
	mv x10, x15
	call print_int
	li x10, 10
	call print_char
	la x10, .LC4
	call print_string
	li x11, 8
	li x10, 2
	call power
	mv x15, x10
	mv x10, x15
	call print_int
	li x10, 10
	call print_char
	li x15, 0
	mv x10, x15
	lw x1, 12(x2)
	lw x8, 8(x2)
	addi x2, x2, 16
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
.globl factorial
factorial:
	addi x2, x2, -32
	sw x1, 28(x2)
	sw x8, 24(x2)
	addi x8, x2, 32
	sw x10, -20(x8)
	lw x14, -20(x8)
	li x15, 1
	li x15, 1
.L5:
	lw x15, -20(x8)
	addi x15, x15, -1
	mv x10, x15
	call factorial
	mv x14, x10
	lw x15, -20(x8)
	mul x15, x14, x15
.L6:
	mv x10, x15
	lw x1, 28(x2)
	lw x8, 24(x2)
	addi x2, x2, 32
	jr x1
.globl fibonacci
fibonacci:
	addi x2, x2, -32
	sw x1, 28(x2)
	sw x8, 24(x2)
	sw x9, 20(x2)
	addi x8, x2, 32
	sw x10, -20(x8)
	lw x14, -20(x8)
	li x15, 1
	lw x15, -20(x8)
.L8:
	lw x15, -20(x8)
	addi x15, x15, -1
	mv x10, x15
	call fibonacci
	mv x9, x10
	lw x15, -20(x8)
	addi x15, x15, -2
	mv x10, x15
	call fibonacci
	mv x15, x10
	add x15, x9, x15
.L9:
	mv x10, x15
	lw x1, 28(x2)
	lw x8, 24(x2)
	lw x9, 20(x2)
	addi x2, x2, 32
	jr x1
.globl power
power:
	addi x2, x2, -48
	sw x1, 44(x2)
	sw x8, 40(x2)
	addi x8, x2, 48
	sw x10, -36(x8)
	sw x11, -40(x8)
	li x15, 1
	sw x15, -20(x8)
	sw x0, -24(x8)
.L12:
	lw x14, -20(x8)
	lw x15, -36(x8)
	mul x15, x14, x15
	sw x15, -20(x8)
	lw x15, -24(x8)
	addi x15, x15, 1
	sw x15, -24(x8)
.L11:
	lw x14, -24(x8)
	lw x15, -40(x8)
	blt x14, x15, .L12
	lw x15, -20(x8)
	mv x10, x15
	lw x1, 44(x2)
	lw x8, 40(x2)
	addi x2, x2, 48
	jr x1
