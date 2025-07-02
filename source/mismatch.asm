# kunx - Kernighan using unix
# 2 Jul 2025
# 'mismatch' command - spot spelling errors agains a given dict

.section .rodata
	.usage_msg: .string "mismatch-command: mismatch <filename> <dict>\n"
	.usage_len: .quad   46

	.unable_msg: .string "mismatch-command: unable to open/read file\n"
	.unable_len: .quad   43

.section .bss
        .buffer: .zero 8

.section .text

.include "macro.inc"

.globl _start

_start:
	popq	%rax
	cmpq	$3, %rax
	jne	.usage
	popq	%rax
	popq	%rdi
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$12, %rsp
	RDFILE	.buffer(%rip), -4(%rbp), -12(%rbp)
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
