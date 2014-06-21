	.section .rodata
.LC0:
	.string	"%s\n"
	.text
	.globl	STRING_LENGTH
	.globl	MOVE_STRING
	.globl	TO_UPPER
	.globl	TO_LOWER
	.globl	PRINT_ENVIRONMENTS
	.type	PRINT_ENVIRONMENTS, @function
.equ	LOWER_TO_UPPER, 'A' - 'a'
.equ	UPPER_TO_LOWER, 'a' - 'A'
STRING_LENGTH:
	push	%ebp
	mov		%esp, %ebp

	xor		%eax, %eax
	mov		8(%ebp), %ebx
L1:
	cmpb	$0, (%ebx)
	jz		L2
	inc		%eax
	inc		%ebx
	jmp		L1

L2:
	mov		%ebp, %esp
	pop		%ebp
	ret

MOVE_STRING:
	push	%ebp
	mov		%esp, %ebp

	mov		8(%ebp), %edi
	mov		12(%ebp), %esi
	mov		16(%ebp), %ecx
	shr		$2, %ecx
	cld
	rep		movsl
	mov		16(%ebp), %ecx
	and		$3, %ecx
	rep		movsb

	mov		%ebp, %esp
	pop		%ebp
	ret

TO_UPPER:
	push	%ebp
	mov		%esp, %ebp

	mov		12(%ebp), %edi
	mov		8(%ebp), %esi
	cld
TO_UPPER_L1:
	lodsb
	cmpb	$0, %al
	jz		TO_UPPER_L2
	cmpb	$'a', %al
	jl		TO_UPPER_L3
	cmpb	$'z', %al
	jg		TO_UPPER_L3
	addb	$LOWER_TO_UPPER, %al
TO_UPPER_L3:
	stosb
	jmp		TO_UPPER_L1
TO_UPPER_L2:

	mov		%ebp, %esp
	pop		%ebp
	ret

TO_LOWER:
	push	%ebp
	mov		%esp, %ebp

	mov		8(%ebp), %edi
	mov		12(%ebp), %esi
	cld
TO_LOWER_L1:
	lodsb
	cmp		$0, %al
	jz		TO_LOWER_L3	
	cmp		$'A', %al
	jl		TO_LOWER_L2	
	cmp		$'Z', %al
	jg		TO_LOWER_L2
	add		$UPPER_TO_LOWER, %al
TO_LOWER_L2:
	stosb
	jmp		TO_LOWER_L1	
TO_LOWER_L3:

	mov		%ebp, %esp
	pop		%ebp
	ret

PRINT_ENVIRONMENTS:
	mov		16(%ebp), %edi
PRINT_ENV_L1:
	mov		(%edi), %eax
	cmp		$0, %eax
	jz		PRINT_ENV_L2
	push	%edi
	push	%eax
	push	$.LC0
	call	printf
	addl	$8, %esp
	pop		%edi
	addl	$4, %edi
	jmp		PRINT_ENV_L1

PRINT_ENV_L2:
	ret
