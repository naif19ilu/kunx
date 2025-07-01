# kunx - Kernighan using unix
# 30 Jun 2025
# Useful macros

.macro RDFILE buffer
        # opens the file for reading only
        xorq    %rax, %rax
	movl	$2, %eax
	xorq	%rsi, %rsi
	xorq	%rdx, %rdx
	syscall
        cmpl    $0, %eax
        jl      .unable
        # getting file size in bytes
	movl	%eax, -4(%rbp)
	movq	$8, %rax
	movl	-4(%rbp), %edi
	xorq	%rsi, %rsi
	movq	$2, %rdx
	syscall
        # setting pointer to the first byte in file
	movq	%rax, -12(%rbp)
	movq	$8, %rax
	movl	-4(%rbp), %edi
	xorq	%rsi, %rsi
	xorq	%rdx, %rdx
	syscall
        # allocating memory
        xorq    %rdi, %rdi
        movq    -12(%rbp), %rsi
        movq    $1, %rdx
        movq    $2, %r10
        movl    -4(%rbp), %r8d
        xorq    %r9, %r9
        movq    $9, %rax
        syscall
        cmpq    $-1, %rax
        je      .unable
        movq    %rax, \buffer
.endm

.macro CLSFILE
        movq    $3, %rax
        xorq    %rdi, %rdi
        movl    -4(%rbp), %edi
        syscall
.endm

.macro UNMAP buffer, len
        movq    $11, %rax
        movq    \buffer, %rdi
        movq    \len, %rdx
        syscall
.endm

