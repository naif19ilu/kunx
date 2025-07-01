
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

.section .data
	.nolines: .quad 0
	.lgtwrd:  .quad 0

.section .bss
        .buffer: .zero 8
	.heapsc: .zero 8

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
	cmpq	.lgtwrd(%rip), %r9
	jle	.resume_1
	movq	%r9, (.lgtwrd)
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
	cmpq	.lgtwrd(%rip), %r9
	jle	.stage_2
	movq	%r9, (.lgtwrd)
.stage_2:
	# Now we need to make room for the array
	# of strings which is going to be (lgtwrd + 1) * nolines
	# (The +1 is due to null-terminator byte)
	movq	(.lgtwrd), %rbx
	incq	%rbx
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
	movq	(.lgtwrd), %rax
	subq	%r10, %rax
	# Add the missing bytes
	addq	%rax, %r9
	xorq	%r10, %r10
.resume_2:
	incq	%r8
	incq	%r9
	jmp	.loop_2
.stage_3:

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
