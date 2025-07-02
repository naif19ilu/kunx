# kunx - Kernighan using unix
# 2 Jul 2025
# 'mismatch' command - spot spelling errors agains a given dict

.section .rodata
	.usage_msg: .string "mismatch-command: mismatch <filename> <dict>\n"
	.usage_len: .quad   46

	.unable_msg: .string "mismatch-command: unable to open/read file\n"
	.unable_len: .quad   43

.section .bss
        .source: .zero 8
	.dict: .zero 8

.section .text

.include "macro.inc"

.globl _start

_start:
	popq	%rax
	cmpq	$3, %rax
	jne	.usage
	popq	%rax
	popq	%rdi
	popq	%r15
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$24, %rsp
	RDFILE	.source(%rip), -4(%rbp), -12(%rbp)
	movq	%r15, %rdi
	RDFILE	.dict(%rip), -16(%rbp), -24(%rbp)
	# r8: handles source
	# r9: handles dictionary
	movq	.source(%rip), %r8
	movq	.dict(%rip), %r9
.loop:
	movzbl	(%r8), %edi
	cmpb	$0, %dil
	je	.leave

	call	.FindFamily

	movq	$1, %rax
	movq	$1, %rdi
	movq	%r9, %rsi
	movq	$5, %rdx
	syscall

	#jmp	.loop

.leave:
	UNMAP	.source(%rip), -12(%rbp)
	UNMAP	.dict(%rip), -24(%rbp)
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

.FindFamily:
.ff_loop:
	movzbl	(%r9), %esi
	cmpb	$0, %sil
	je	.ff_no_fam
	cmpb	%sil, %dil
	jne	.ff_skip_word
	movq	$0, %rax
	ret
.ff_skip_word:	
	movzbl	(%r9), %esi
	cmpb	$10, %sil
	je	.ff_skiped
	incq	%r9
	jmp	.ff_skip_word
.ff_skiped:
	incq	%r9
	jmp	.ff_loop
.ff_no_fam:
	movq	$-1, %rax
	ret


