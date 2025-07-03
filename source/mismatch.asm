# kunx - Kernighan using unix
# 3 Jul 2025
# 'mismatch' command - compare file's words against a provided dictionary

.section .bss
	.filesrc: .zero 8
	.dictsrc: .zero 8

	# This is map table to access in a quick way
	# the families, for example if we need familia
	# 'a' we access this map at position 0, if we
	# need familia 'z' then use 25
	# [a:z] -> first word -> family size
	.abcmap: .zero 26 * 64

.section .rodata
	.usage_msg: .string "mismatch-command: mismatch <file> <dict>\n"
	.usage_len: .quad   41

	.unable_msg: .string "mismatch-command: unable to open/read file\n"
	.unable_len: .quad   44

.section .data
	.fileoff: .quad 0
	.dictoff: .quad 0

	.faminfo: .quad 0

.section .text

.macro GETFAM no, put_at, famsz
	movq	\no, %rax
	movq	$16, %rbx
	mulq	%rbx
	movq	%rax, %rbx
	leaq	.abcmap(%rip), %rax
	addq	%rbx, %rax
	movq	(%rax), %r15
	movq	%r15, \put_at
	movq	8(%rax), %r15
	movq	%r15, \famsz
.endm

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
	# -56: current word
	# -64: current family size
	# -72: counter for -64
	subq	$72, %rsp
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
	call	.FindFamilas
.loop:
	movq	-40(%rbp), %rax
	cmpq	-32(%rbp), %rax
	je	.leave
	# Gets words
	movq	.fileoff(%rip), %rdi
	leaq	.fileoff(%rip), %rsi
	call	.GetWord
	movq	%rcx, -48(%rbp)
	movq	%rax, -56(%rbp)
	# Gets word's family
	movzbl	(%rax), %edi
	subl	$'a', %edi
	GETFAM	%rdi, (.faminfo), -64(%rbp)
	movq	$0, -72(%rbp)
.check:
	movq	-72(%rbp), %rax
	cmpq	-64(%rbp), %rax
	je	.not_found
	movq	.faminfo(%rip), %rdi
	leaq	.faminfo(%rip), %rsi
	call	.GetWord
	movq	%rax, %rsi
	movq	-56(%rbp), %rdi
	call	.CmpStr
	cmpq	$1, %rax
	je	.resume_main
	incq	-72(%rbp)
	jmp	.check
.not_found:
	movq	$1, %rax
	movq	$1, %rdi
	movq	-56(%rbp), %rsi
	movq	-48(%rbp), %rdx
	incq	%rdx
	syscall
.resume_main:
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

# args: None
# rets: None
.FindFamilas:
	pushq	%rbp
	movq	%rsp, %rbp
	# -8 : dict's number lines
	# -16: current number line
	# -24: current family
	# -32: dict's offset
	# -40: family size
	# -48: previous element in abcmap
	subq	$48, %rsp
	movq	(.dictsrc), %rdi
	call	.NLines
	movq	%rax, -8(%rbp)
	movq	$0, -16(%rbp)
	movq	$96, -24(%rbp)
	movq	(.dictsrc), %rax
	movq	%rax, -32(%rbp)
	movq	$0, -40(%rbp)
.ff_loop:
	movq	-16(%rbp), %rax
	cmpq	-8(%rbp), %rax
	je	.ff_return
	movq	-32(%rbp), %rdi
	leaq	-32(%rbp), %rsi
	call	.GetWord
	movzbl	(%rax), %edi
	movq	%rax, %r15					# beginning of new word
	cmpq	-24(%rbp), %rdi
	je	.ff_resume
	incq	-40(%rbp)					# count this word as well
	movq	%rdi, -24(%rbp)
	subq	$'a', %rdi
	movq	%rdi, %rax
	movq	$16, %rbx
	mulq	%rbx
	movq	%rax, %rbx
	leaq	.abcmap(%rip), %rax
	addq	%rbx, %rax
	movq	%r15, (%rax)
	cmpq	$0, -48(%rbp)
	je	.ff_setnewfam
	movq	-48(%rbp), %r15
	movq	-40(%rbp), %r14
	movq	%r14, 8(%r15)
.ff_setnewfam:
	movq	%rax, -48(%rbp)
	movq	$-1, -40(%rbp)
.ff_resume:
	incq	-40(%rbp)
	incq	-16(%rbp)
	jmp	.ff_loop
.ff_return:
	incq	-40(%rbp)					# count this word as well
	movq	-48(%rbp), %r15
	movq	-40(%rbp), %r14
	movq	%r14, 8(%r15)
	leave
	ret

# args:
# rdi : main word
# rsi : compare against
.CmpStr:
	pushq	%rbp
	movq	%rsp, %rbp
.cs_loop:
	movzbl	(%rdi), %r8d
	movzbl	(%rsi), %r9d
	cmpb	%r8b, %r9b
	jne	.cs_no
	cmpb	$10, %r8b
	je	.cs_si
	cmpb	$0, %r8b
	je	.cs_si
	incq	%rdi
	incq	%rsi
	jmp	.cs_loop
.cs_si:
	movq	$1, %rax
	jmp	.cs_return
.cs_no:
	movq	$0, %rax
.cs_return:
	leave
	ret
