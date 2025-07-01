
# kunx - Kernighan using unix
# 1 Jul 2025
# 'sort' command - sort lines by ascii order

.section .rodata
	.usage_msg: .string "sort-command: sort <filename>\n"
	.usage_len: .quad   32

	.unable_msg: .string "sort-command: unable to open/read file\n"
	.unable_len: .quad   39

.section .data
	.lines:  .quad 0
	.lgtwrd: .quad 0

.section .bss
        .buffer: .zero 8

.section .text

.include "macro.inc"

.globl _start

_start:
	popq	%rax
	cmpq	$2, %rax
	jne	.usage
	popq	%rax
	popq	%rdi
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$12, %rsp
	RDFILE	.buffer(%rip)
	# first thing we want to do is to know
	# how many words there are
	# r8: source
	# r9: no of bytes of current word
	movq	(.buffer), %r8
	movq	$0, %r9
.loop_1:
	movzbl	(%r8), %edi
	cmpb	$0, %dil
	je	.stage_2
	cmpb	$'\n', %dil
	je	.neword
	incq	%r8
	incq	%r9
	jmp	.loop_1
.neword:
	cmpq	.lgtwrd(%rip), %r9
	jle	.resume_1
	movq	%r9, (.lgtwrd)
.resume_1:
	incq	%r8
	xorq	%r9, %r9
	jmp	.loop_1
.stage_2:


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
