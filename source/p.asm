# kunx - Kernighan using unix
# 30 Jun 2025
# 'p' command - print file

.section .rodata
	.usage_msg: .string "p-command: p <filename>\n"
	.usage_len: .quad   24

	.unable_msg: .string "p-command: unable to open/read file\n"
	.unable_len: .quad   31

.section .bss
	.buffer: .zero 8

.section .text

.globl _start

.include "macro.inc"

_start:
	popq	%rax
	cmpq	$2, %rax
	jne	.usage
	popq	%rax
	popq	%rdi
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$12, %rsp
	RDFILE	%rdi, .unable, .buffer(%rip)	
	movq	$1, %rax
	movq	$1, %rdi
	movq	.buffer(%rip), %rsi
	movq	-12(%rbp), %rdx
	syscall
	jmp	.leave	
.leave:
	UNMAP	.buffer(%rip)
	CLSFILE
	movq	$60, %rax
	movq	$0, %rdi
	syscall
.usage:
	movq	$1, %rax
	movq	$1, %rdi
	leaq	.usage_msg(%rip), %rsi
	movq	.usage_len(%rip), %rdx
	syscall
	movq	$60, %rax
	movq	$0, %rdi
	syscall
.unable:
	movq	$1, %rax
	movq	$1, %rdi
	leaq	.unable_msg(%rip), %rsi
	movq	.unable_len(%rip), %rdx
	syscall
	movq	$60, %rax
	movq	$1, %rdi
	syscall
