.data
.LC1:
.string "Array Operations Demo\n"
.LC2:
.string "=====================\n\n"
.LC3:
.string "Array: ["
.LC4:
.string ", "
.LC5:
.string "]\n\n"
.LC6:
.string "Maximum: "
.LC7:
.string "Sum: "
.LC8:
.string "Average: "
.LC0:
.word 10
.word 25
.word 7
.word 42
.word 15

.text
.globl main
main:
	addi x2, x2, -48
	sw x1, 44(x2)
	sw x8, 40(x2)
	addi x8, x2, 48
	la x15, .LC0
	lw x11, 0(x15)
	lw x12, 4(x15)
	lw x13, 8(x15)
	lw x14, 12(x15)
	sw x11, -40(x8)
	sw x12, -36(x8)
	sw x13, -32(x8)
	sw x14, -28(x8)
	lw x15, 16(x15)
	sw x15, -24(x8)
	la x10, .LC1
	call print_string
	la x10, .LC2
	call print_string
	la x10, .LC3
	call print_string
	sw x0, -20(x8)
	j .L14

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
.globl find_max
find_max:
	addi x2, x2, -48
	sw x1, 44(x2)
	sw x8, 40(x2)
	addi x8, x2, 48
	sw x10, -36(x8)
	sw x11, -40(x8)
	lw x15, -36(x8)
	lw x15, 0(x15)
	sw x15, -20(x8)
	li x15, 1
	sw x15, -24(x8)
	j .L5
.L7:
	lw x15, -24(x8)
	slli x15, x15, 2
	lw x14, -36(x8)
	add x15, x14, x15
	lw x15, 0(x15)
	lw x14, -20(x8)
	bge x14, x15, .L6
	lw x15, -24(x8)
	slli x15, x15, 2
	lw x14, -36(x8)
	add x15, x14, x15
	lw x15, 0(x15)
	sw x15, -20(x8)
.L6:
	lw x15, -24(x8)
	addi x15, x15, 1
	sw x15, -24(x8)
.L5:
	lw x14, -24(x8)
	lw x15, -40(x8)
	blt x14, x15, .L7
	lw x15, -20(x8)
	mv x10, x15
	lw x1, 44(x2)
	lw x8, 40(x2)
	addi x2, x2, 48
	jr x1
.globl array_sum
array_sum:
	addi x2, x2, -48
	sw x1, 44(x2)
	sw x8, 40(x2)
	addi x8, x2, 48
	sw x10, -36(x8)
	sw x11, -40(x8)
	sw x0, -20(x8)
	sw x0, -24(x8)
	j .L10
.L11:
	lw x15, -24(x8)
	slli x15, x15, 2
	lw x14, -36(x8)
	add x15, x14, x15
	lw x15, 0(x15)
	lw x14, -20(x8)
	add x15, x14, x15
	sw x15, -20(x8)
	lw x15, -24(x8)
	addi x15, x15, 1
	sw x15, -24(x8)
.L10:
	lw x14, -24(x8)
	lw x15, -40(x8)
	blt x14, x15, .L11
	lw x15, -20(x8)
	mv x10, x15
	lw x1, 44(x2)
	lw x8, 40(x2)
	addi x2, x2, 48
	jr x1
.L16:
	lw x14, -20(x8)
	addi x15, x8, -40
	slli x14, x14, 2
	add x15, x14, x15
	lw x15, 0(x15)
	mv x10, x15
	call print_int
	lw x14, -20(x8)
	li x15, 3
	bgt x14, x15, .L15
	la x10, .LC4
	call print_string
.L15:
	lw x15, -20(x8)
	addi x15, x15, 1
	sw x15, -20(x8)
.L14:
	lw x14, -20(x8)
	li x15, 4
	ble x14, x15, .L16
	la x10, .LC5
	call print_string
	la x10, .LC6
	call print_string
	addi x15, x8, -40
	li x11, 5
	mv x10, x15
	call find_max
	mv x15, x10
	mv x10, x15
	call print_int
	li x10, 10
	call print_char
	la x10, .LC7
	call print_string
	addi x15, x8, -40
	li x11, 5
	mv x10, x15
	call array_sum
	mv x15, x10
	mv x10, x15
	call print_int
	li x10, 10
	call print_char
	la x10, .LC8
	call print_string
	addi x15, x8, -40
	li x11, 5
	mv x10, x15
	call array_sum
	mv x15, x10
	li x14, 1717985280
	addi x14, x14, 1639
	mulh x14, x15, x14
	srai x14, x14, 1
	srai x15, x15, 31
	sub x15, x14, x15
	mv x10, x15
	call print_int
	li x10, 10
	call print_char
	li x15, 0
	mv x10, x15
	lw x1, 44(x2)
	lw x8, 40(x2)
	addi x2, x2, 48
	li x17, 10
	ecall
