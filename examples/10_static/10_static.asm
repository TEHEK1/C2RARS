.data
.align 2
g_initialized:
.word 1
.align 2
g_zero:
.space 4
.align 2
.LC0:
.string "Globals before:\n"
.align 2
.LC1:
.string "\n"
.align 2
.LC2:
.string "Globals after:\n"
.align 2
.LC3:
.string "First 10 Fibonacci numbers:\n"
.align 2
first.1:
.space 4
.align 2
second.0:
.word 1

.text
.globl main
main:
	addi x2, x2, -32
	sw x1, 28(x2)
	sw x8, 24(x2)
	addi x8, x2, 32
	la x10, .LC0
	call print_string
	la x15, g_initialized
	lw x15, 0(x15)
	mv x10, x15
	call print_int
	la x10, .LC1
	call print_string
	la x15, g_zero
	lw x15, 0(x15)
	mv x10, x15
	call print_int
	la x10, .LC1
	call print_string
	la x15, g_initialized
	lw x15, 0(x15)
	addi x14, x15, 41
	la x15, g_zero
	sw x14, 0(x15)
	la x10, .LC2
	call print_string
	la x15, g_initialized
	lw x15, 0(x15)
	mv x10, x15
	call print_int
	la x10, .LC1
	call print_string
	la x15, g_zero
	lw x15, 0(x15)
	mv x10, x15
	call print_int
	la x10, .LC1
	call print_string
	la x10, .LC3
	call print_string
	sw x0, -20(x8)
	j .L6

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
.globl g_initialized
.globl g_zero
.globl fibonacci
fibonacci:
	addi x2, x2, -32
	sw x1, 28(x2)
	sw x8, 24(x2)
	addi x8, x2, 32
	la x15, first.1
	lw x14, 0(x15)
	la x15, second.0
	lw x15, 0(x15)
	add x15, x14, x15
	sw x15, -20(x8)
	la x15, second.0
	lw x14, 0(x15)
	la x15, first.1
	sw x14, 0(x15)
	la x15, second.0
	lw x14, -20(x8)
	sw x14, 0(x15)
	lw x15, -20(x8)
	mv x10, x15
	lw x1, 28(x2)
	lw x8, 24(x2)
	addi x2, x2, 32
	jr x1
.L7:
	call fibonacci
	mv x15, x10
	mv x10, x15
	call print_int
	la x10, .LC1
	call print_string
	lw x15, -20(x8)
	addi x15, x15, 1
	sw x15, -20(x8)
.L6:
	lw x14, -20(x8)
	li x15, 9
	ble x14, x15, .L7
	li x15, 0
	mv x10, x15
	lw x1, 28(x2)
	lw x8, 24(x2)
	addi x2, x2, 32
	li x17, 10
	ecall
