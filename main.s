	.file	"main.s"
	.data
.LC0:
	.string	"This value is %d\n"
.LC1:
	.string	"%s\n"
	.bss
	.lcomm	buf, 100

	.text
	.globl	main
	.type	main, @function
main:
	pushl	%ebp
	mov		%esp, %ebp

	mov		16(%ebp), %edi
L2:
	push	%edi
	mov		(%edi), %eax
	cmp		$0, %eax
	jz		L1
	push	%eax
	push	$.LC1
	call	printf
	addl	$8, %esp
	pop		%edi
	addl	$4, %edi
	jmp		L2
L1:
	push	$0
	call	exit
