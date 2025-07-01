
# kunx - Kernighan using unix
# 1 Jul 2025
# 'sort' command - sort lines by ascii order

.section .rodata
	.usage_msg: .string "sort-command: sort <filename>\n"
	.usage_len: .quad   32

	.unable_msg: .string "sort-command: unable to open/read file\n"
	.unable_len: .quad   39

	.badheap_msg: .string "sort-command: unable to allocate space\n"
	.badheap_len: .quad 39

	.n: .string "\n"

.section .data
	# Number of lines the raw file has
	.nolines: .quad 0
	# Longest word within the file (do not include newline byte)
	.longestw: .quad 0
	# Longest word within the file (does include newline byte)
	.longswp1: .quad 0

.section .bss
	# The raw file, for example
	# abc
	# drjfgh
	# something
        .buffer: .zero 8
	# The file content but all lines share wdith
	# abc      .
	# drjfgh   .
	# something.
	.heapsc: .zero 8

.section .text

.macro GETWRD i, store
	movq	\i, %rax
	movq	(.longswp1), %rbx
	mulq	%rbx
	movq	(.heapsc), %r15
	movq	%r15, \store
	addq	%rax, \store
.endm

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
	# -20: number of bytes used in 'heapsc'
	subq	$20, %rsp
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
	je	.check_final
	cmpb	$'\n', %dil
	je	.neword
	incq	%r8
	incq	%r9
	jmp	.loop_1
.neword:
	cmpq	.longestw(%rip), %r9
	jle	.resume_1
	movq	%r9, (.longestw)
.resume_1:
	incq	(.nolines)
	incq	%r8
	xorq	%r9, %r9
	jmp	.loop_1
.check_final:
	# since some editors do not add a newline at the end
	# of the file we need to make sure the last line was
	# counted
	decq	%r8
	movzbl	(%r8), %edi
	cmpb	$'\n', %dil
	je	.stage_2
	incq	(.nolines)
	cmpq	.longestw(%rip), %r9
	jle	.stage_2
	movq	%r9, (.longestw)
.stage_2:
	# Now we need to make room for the array
	# of strings which is going to be (longestw + 1) * nolines
	# (The +1 is due to null-terminator byte)
	movq	(.longestw), %rbx
	incq	%rbx
	movq	%rbx, (.longswp1)
	movq	(.nolines), %rax
	mulq	%rbx
	movq	%rax, -20(%rbp)
	# allocating memory
        xorq    %rdi, %rdi
        movq    %rax, %rsi
        movq    $3, %rdx		# READ | WRITE
        movq    $34, %r10		# MAP_PRIVATE | MAP_ANONYMOUS
	movq	$-1, %r8
        xorq    %r9, %r9
        movq    $9, %rax
        syscall
	cmpq	$-1, %rax
	je	.badheap
	movq	%rax, (.heapsc)
	# Now we need to fill the second buffer as it was
	# the first one but now all words have a same length
	# r8 : original buffer
	# r9 : second buffer
	# r10: current word's length
	movq	(.buffer), %r8
	movq	(.heapsc), %r9
	xorq	%r10, %r10
.loop_2:
	movzbl	(%r8), %edi
	cmpb	$0, %dil
	je	.stage_3
	cmpb	$'\n', %dil
	je	.newline
	movb	%dil, (%r9)
	incq	%r10
	jmp	.resume_2
.newline:
	movq	(.longestw), %rax
	subq	%r10, %rax
	movq	%rax, %r15
	xorq	%rcx, %rcx
.newline_loop:
	cmpq	%rcx, %r15
	je	.newline_ok
	movb	$0, (%r9)
	incq	%r9
	incq	%rcx
	jmp	.newline_loop
.newline_ok:
	movb	$'\n', (%r9)
	xorq	%r10, %r10
.resume_2:
	incq	%r8
	incq	%r9
	jmp	.loop_2
.stage_3:
	# At this point .heapsc has a word each
	# .longestw bytes, it's time to sort them
	movq	$0, %rdi
	movq	(.nolines), %rsi
	decq	%rsi
	call	.Quick
	movq	$1, %rax
	movq	$1, %rdi
	movq	(.heapsc), %rsi
	movq	-20(%rbp), %rdx
	syscall
.leave:
	UNMAP	.heapsc(%rip), -20(%rbp)
	UNMAP	.buffer(%rip), -12(%rbp)
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
.badheap:
	movq	$1, %rax
	movq	$1, %rdi
	leaq	.badheap_msg(%rip), %rsi
	movq	.badheap_len(%rip), %rdx
	syscall
	movq	$60, %rax
	movq	$1, %rdi
	syscall

# arguments: rdi (low), rsi (high)
.Quick:
	pushq	%rbp
	movq	%rsp, %rbp
	# -8: low
	# -16: high
	# -24: parition value
	subq	$24, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	cmpq	%rsi, %rdi		# rdi < rsi
	jg	.qk_return
	call	.Partition
	movq	%rax, -24(%rbp)
	movq	-8(%rbp), %rdi
	movq	-24(%rbp), %rsi
	decq	%rsi
	call	.Quick
	movq	-24(%rbp), %rdi
	incq	%rdi
	movq	-16(%rbp), %rsi
	call	.Quick
.qk_return:
	leave
	ret

# arguments: rdi (low), rsi (high)
.Partition:
	pushq	%rbp
	movq	%rsp, %rbp
	# -8 : low
	# -16: high
	# -24: pivot
	# -32: pointer
	# -40: loop iter
	subq	$40, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	# Getting high offset within heapsc
	# (longestw + 1) * high
	GETWRD	%rsi, -24(%rbp)
	# pointer is low - 1
	decq	%rdi
	movq	%rdi, -32(%rbp)
	# j = low; j < high; j++ type shit
	movq	-8(%rbp), %rax
	movq	%rax, -40(%rbp)
.pt_loop:
	movq	-40(%rbp), %rax
	cmpq	-16(%rbp), %rax
	je	.pt_return
	# cmp(words[j], pivot)
	GETWRD	-40(%rbp), %rdi
	movq	-24(%rbp), %rsi
	call	.Cmp
	cmpq	$2, %rax
	je	.pt_resume
	incq	-32(%rbp)
	movq	-32(%rbp), %rdi
	movq	-40(%rbp), %rsi
	call	.Swap
.pt_resume:
	incq	-40(%rbp)
	jmp	.pt_loop
.pt_return:
	incq	-32(%rbp)
	movq	-32(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	.Swap
	movq	-32(%rbp), %rax
	leave
	ret

# rdi: string 1
# rsi: string 2
# ret: { 0:rdi < rsi, 1:rdi = rsi, 2:rdi > rsi }
.Cmp:
	pushq	%rbp
	movq	%rsp, %rbp
.cmp_loop:
	movzbl	(%rdi), %eax
	cmpb	(%rsi), %al
	je	.cmp_eqch
	cmpb	$'\n', %al
	je	.cmp_ret0
	movzbl	(%rsi), %ebx
	cmpb	$'\n', %bl
	je	.cmp_ret2
	subb	%bl, %al
	js	.cmp_ret0
	jmp	.cmp_ret2
.cmp_eqch:
	cmpb	$'\n', %al
	je	.cmp_ret1
	incq	%rdi
	incq	%rsi
	jmp	.cmp_loop
.cmp_ret2:
	movq	$2, %rax
	leave
	ret
.cmp_ret1:
	movq	$1, %rax
	leave
	ret
.cmp_ret0:
	movq	$0, %rax
	leave
	ret

# arguments: rdi (first pos) rsi (second pos)
.Swap:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$24, %rsp
	GETWRD	%rdi, -8(%rbp)
	GETWRD	%rsi, -16(%rbp)
	xorq	%rcx, %rcx
.sw_loop:
	cmpq	.longestw(%rip), %rcx
	je	.sw_return

	movq	-8(%rbp), %rax
	movq	-16(%rbp), %rbx

	movzbl	(%rax), %edi
	movzbl	(%rbx), %esi

	movb	%sil, (%rax)
	movb	%dil, (%rbx)

	incq	%rcx
	incq	-8(%rbp)
	incq	-16(%rbp)
	jmp	.sw_loop
.sw_return:
	leave
	ret


