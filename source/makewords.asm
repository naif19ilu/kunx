# kunx - Kernighan using unix
# 30 Jun 2025
# 'makewords' command - word per line

.section .rodata
	.usage_msg: .string "makewords-command: makewords <filename>\n"
	.usage_len: .quad   41

	.unable_msg: .string "makewords-command: unable to open/read file\n"
	.unable_len: .quad   44

	.words_cap: .quad 2048

.section .bss
        .buffer: .zero 8
	.words:  .zero 2048

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
	# r9 : 'words' buffer
	# r10: number of bytes written in 'words' buffer
        movq    (.buffer), %r8
	leaq	.words(%rip), %r9
	movq	$0, %r10
.loop:
        movzbl  (%r8), %edi
        cmpb	$0, %dil
	je	.leave
	cmpq	.words_cap(%rip), %r10
	je	.words_full
	call	.Wordable
	cmpq	$0, %rax
	je	.wordend
	movb	%dil, (%r9)
	incq	%r9
	incq	%r10
	jmp	.resume
.wordend:
	movb	$'\n', (%r9)
	incq	%r9
	incq	%r10
	jmp	.resume
.words_full:
	movq	$1, %rax
	movq	$1, %rdi
	leaq	.words(%rip), %rsi
	movq	%r10, %rdx
	syscall
	leaq	.words(%rip), %r9
	xorq	%r10, %r10
	jmp	.loop
.resume:
	incq	%r8
	jmp	.loop
.leave:
	movq	$1, %rax
	movq	$1, %rdi
	leaq	.words(%rip), %rsi
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

.Wordable:
	cmpb	$'0', %dil
	jl	.wa_no
	cmpb	$'9', %dil
	jle	.wa_yes
	cmpb	$'A', %dil
	jl	.wa_no
	cmpb	$'Z', %dil
	jle	.wa_yes
	cmpb	$'a', %dil
	jl	.wa_no
	cmpb	$'z', %dil
	jle	.wa_yes
.wa_no:
	movq	$0, %rax
	ret
.wa_yes:
	movq	$1, %rax
	ret
