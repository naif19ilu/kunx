# kunx - Kernighan using unix
# 3 Jul 2025
# 'mismatch' command - compare file's words against a provided dictionary

.section .bss
	.filesrc: .zero 8
	.dictsrc: .zero 8

.section .rodata
	.usage_msg: .string "mismatch-command: mismatch <file> <dict>\n"
	.usage_len: .quad   41

	.unable_msg: .string "mismatch-command: unable to open/read file\n"
	.unable_len: .quad   44

.section .data
	.fileoff: .quad 0
	.dictoff: .quad 0

.section .text

.include "macro.inc"

.globl _start

_start:
	popq	%rax
	cmpq	$3, %rax
	jne	.usage
	popq	%rax
	# rdi: file's name
	# r15: dict's name (temporary storage)
	popq	%rdi
	popq	%r15
	pushq	%rbp
	movq	%rsp, %rbp
	# -4 : file's fd
	# -12: file's content size
	# -16: dict's fd
	# -24: dict's content size
	# -32: number of lines in 'file'
	# -40: number of lines visited in 'file'
	# -48: current word's length
	subq	$48, %rsp
	RDFILE	.filesrc(%rip), -4(%rbp), -12(%rbp)
	movq	%r15, %rdi
	RDFILE	.dictsrc(%rip), -16(%rbp), -24(%rbp)
	# getting number of lines in the file
	movq	.filesrc(%rip), %rdi
	call	.NLines
	movq	%rax, -32(%rbp)
	movq	$0, -40(%rbp)
	# Setting up buffers
	movq	.filesrc(%rip), %rax
	movq	%rax, (.fileoff)
.loop:
	movq	-40(%rbp), %rax
	cmpq	-32(%rbp), %rax
	je	.leave

	movq	.fileoff(%rip), %rdi
	leaq	.fileoff(%rip), %rsi
	call	.GetWord
	movq	%rcx, -48(%rbp)

	incq	-40(%rbp)
	jmp	.loop
.leave:
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

# args:
# rdi : source
# rets:
# rax : number of lines
.NLines:
	xorq	%rcx, %rcx
.nl_loop:
	movzbl	(%rdi), %eax
	cmpb	$0, %al
	je	.nl_return
	cmpb	$'\n', %al
	jne	.nl_resume
	incq	%rcx
.nl_resume:
	incq	%rdi
	jmp	.nl_loop
.nl_return:
	movq	%rcx, %rax
	ret

# args:
# rdi : buffer
# rsi : pointer to place the new offset
# rets:
# rax : pointer to the beg of new word
# rcx : word's length
.GetWord:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$8, %rsp
	# -8: stores the current position
	movq	%rdi, -8(%rbp)
	xorq	%rcx, %rcx
.gw_loop:
	movzbl	(%rdi), %eax
	cmpb	$0, %al
	je	.gw_return
	cmpb	$10, %al
	je	.gw_return
	incq	%rdi
	incq	%rcx
	incq	(%rsi)
	jmp	.gw_loop
.gw_return:
	incq	(%rsi)
	movq	-8(%rbp), %rax
	leave
	ret
