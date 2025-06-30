# kunx - Kernighan using unix
# 23 Jun 2025
# 'p' command - print file

.section .rodata
	.usage_msg: .string "p-command: p <filename>\n"
	.usage_len: .quad   24

	.unable_msg: .string "p-command: unable to open file\n"
	.unable_len: .quad   31

.section .bss
	.buffer: .zero 2048

.section .text

.globl _start

_start:
	popq	%rax
	cmpq	$2, %rax
	jne	.usage
	popq	%rax
	movq	$2, %rax
	popq	%rdi
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$12, %rsp
	xorq	%rsi, %rsi
	xorq	%rdx, %rdx
	syscall
	cmpq	$-1, %rax
	je	.unable
	movl	%eax, -4(%rbp)			# file descriptor
	movq	$8, %rax
	movl	-4(%rbp), %edi
	xorq	%rsi, %rsi
	movq	$2, %rdx
	syscall

	movq	%rax, %rdi
	movq	$60, %rax
	syscall

.leave:
	xorq	%rdi, %rdi
	movl	-4(%rbp), %edi
	movq	$3, %rax
	syscall
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

