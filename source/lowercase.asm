# kunx - Kernighan using unix
# 30 Jun 2025
# 'lowercase' command - makes all lowercase

.section .rodata
	.usage_msg: .string "lowercase-command: lowercase <filename>\n"
	.usage_len: .quad   41

	.unable_msg: .string "lowercase-command: unable to open/read file\n"
	.unable_len: .quad   44

	.lower_cap: .quad 2048

.section .bss
        .buffer: .zero 8
	.lower:  .zero 2048

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
	# r8 : file content
	# r9 : 'lower' buffer
	# r10: number of bytes written in 'lower' buffer
	movq	(.buffer), %r8
	leaq	.lower(%rip), %r9
	movq	$0, %r10
.loop:
	movzbl	(%r8), %edi
	cmpb	$0, %dil
	je	.leave
	cmpq	.lower_cap(%rip), %r10
	je	.dump
	cmpb	$'A', %dil
	jl	.ignore
	cmpb	$'Z', %dil
	jg	.ignore
	addb	$32, %dil
	movb	%dil, (%r9)
	incq	%r9
	incq	%r10
	jmp	.resume
.ignore:
	movb	%dil, (%r9)
	incq	%r9
	incq	%r10
	jmp	.resume
.resume:
	incq	%r8
	jmp	.loop
.dump:
	movq	$1, %rax
	movq	$1, %rdi
	leaq	.lower(%rip), %rsi
	movq	%r10, %rdx
	syscall
	leaq	.lower(%rip), %r9
	xorq	%r10, %r10
	jmp	.loop
.leave:
	movq	$1, %rax
	movq	$1, %rdi
	leaq	.lower(%rip), %rsi
	movq	%r10, %rdx
	syscall
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
