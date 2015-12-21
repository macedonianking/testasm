	.file "boot.s"
	.code16
.text
.globl main
main:
	movw $0x07c0, %ax
	movw %ax, %ds
	movw $0x9000, %ax
	movw %ax, %es
	movw $256, %cx
	xorw %si, %si
	xorw %di, %di
	rep  movsw
	ljmp $0x9000, $go

go:
	movw $0x9000, %ax
	movw %ax, %ds
	movw %ax, %es
	movw $0xFF00, %ax
	movw %ax, %sp

# read 4 sectors to 0x90200 location.
load_setup:
	movw $0x0080, %dx
	movw $0x0002, %cx
	movw $0x0200, %bx
	movw $0x0204, %ax
	int  $0x13
	jnc  ok_load_setup
	movw $0x0080, %dx
	movw $0x0000, %ax
	int  $0x13
	jmp load_setup

ok_load_setup:
	
	xorw %bx, %bx
	movb $0x03, %ah
	int  $0x10

	movw $20, %cx
	movw $0x0007, %bx
	movw $MSG, %bp
	movw $0x1301, %ax
	int  $0x10

	ljmp $0x9020, $0x0000
HALT:
	hlt
	jmp HALT
MSG:
	.ascii "Loading system ...\r\n"
.org 0x1fe
.short 0xaa55