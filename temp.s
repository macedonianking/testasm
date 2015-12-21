	.file "boot.s"
	.code16

.text
.globl main
.org 0x0000
.equ SCREEN_W, 80
.equ SCRENE_H, 25
main:
	movw $0x07c0, %ax
	movw %ax, %ds
	movw $0x9000, %ax
	movw %ax, %es
	xorw %si, %si
	xorw %di, %di
	movw $256, %cx
	rep
	movsw
	ljmp $0x9000, $L1
L1:
	movw $0x9000, %ax
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %ss
	movw %ax, %fs
	movw %ax, %gs
	movw $0xff00, %ax
	movw %ax, %sp
	movw %ax, %bp

# read four sector to 0x92000
	movw $0x0204, %ax
	movw $0x0200, %bx
	movw $0x0002, %cx
	movw $0x0080, %dx
	int  $0x13
	jc   HALT

# read setup susscessful
	movb $0x08, %ah
	movb $0x80, %dh
	int  $0x13
	jc   HALT

	movb $0x00, %ch
	movw %cx, SECTORS
	movb %dh, %dl
	movb $0x00, %dh
	movw %dx, HEADERS

	movw $0x0000, %ax
	movw %ax, CURR_HEADER
	movw $0x0000, %ax
	movw %ax, CURR_TRACKER
	movw $0x0005, %ax
	movw %ax, READ_SECTORS
	movw $0x1000, %ax
	movw %ax, DEST_SEGMENT
	movw $0x0000, %ax
	movw %ax, DEST_OFFSET

	movw $0x0000, %dx
	call clear_screen

HALT:
	hlt
	jmp HALT

read_it:
	push %bp
	movw %bp, %sp

# set ax
	movw SECTORS, %ax
	subw READ_SECTORS, %ax
	movw %ax, EXEC_SECTORS

	movw DEST_OFFSET, %bx
	shrw $9, %bx
	movw $0x80, %ax
	subw %bx, %ax
	cmpw EXEC_SECTORS, %ax
	ja read_it_L1
	movw %ax, EXEC_SECTORS

read_it_L1:
	movw $0x0200, %bx
	movw EXEC_SECTORS, %ax
	movb %al, %bl
	movw %bx, READ_AX

# set bx
	movw DEST_OFFSET, %ax
	movw %ax, READ_BX

# set cx
	movw CURR_TRACKER, %ax
	movb %al, %ch
	movw READ_SECTORS, %ax
	inc  %ax
	movb %al, %cl
	movw %cx, READ_CX
	jmp read_it_end

# set dx
	movw $0x0007, %dx
	movw CURR_HEADER, %ax
	movb %al, %dh
	movw %dx, READ_DX

# adjust READ SECTORS
	movw EXEC_SECTORS, %ax
	addw READ_SECTORS, %ax
	movw %ax, READ_SECTORS
	cmpw SECTORS, %ax
	jb  read_it_L2
	movw $0x0000, %ax
	movw %ax, READ_SECTORS

# adust current header
	movw CURR_HEADER, %ax
	inc  %ax
	movw %ax, CURR_HEADER
	cmpw HEADERS, %ax
	jbe  read_it_L2
	movw $0x0000, %ax
	movw %ax, CURR_HEADER

# adjust current tracker.
	movw CURR_TRACKER, %ax
	inc  %ax
	movw %ax, CURR_TRACKER

read_it_L2:
	movw EXEC_SECTORS, %ax
	shlw $9, %ax
	addw DEST_OFFSET, %ax
	jnc read_it_L3
	movw DEST_SEGMENT, %ax
	addw $0x1000, %ax
	movw %ax, DEST_SEGMENT

	movw $0x0000, %ax
read_it_L3:
	movw %ax, DEST_OFFSET

#output
read_it_end:
	movw $0x0001, %dx
	push $0x0000
	call PUTINT
	addw $2, %sp

	movw %bp, %sp
	pop  %bp
	ret
# end read it

PUTMSG:
	push %bp
	movw %sp, %bp

	push %bp
	movw $LC0, %ax
	movw %ax, %bp
	mov  $0x1301, %ax
	mov  $0x0007, %bx
	mov  $16, %cx
	int  $0x10
	pop  %bp

	mov  %bp, %sp
	pop  %bp
	ret

clear_screen:
	push %bp
	movw %sp, %bp

	push $0x0000
	push $0x0000
	call SetCursorPosition
	addw $4, %sp

	movw $(SCREEN_W * SCRENE_H), %cx
	movw $0x0007, %bx

clear_screen_L1:
	push %cx
	movw $0x0e00, %ax
	movb $' ', %al
	int $0x10
	popw %cx
	loop clear_screen_L1

	push $0x0000
	push $0x0000
	call SetCursorPosition
	addw $4, %sp
	movw $0x0000, CURSOR_X
	movw $0x0000, CURSOR_Y

clear_screen_end:
	movw %bp, %sp
	popw %bp
	ret

SetCursorPosition:
	push %bp
	movw %sp, %bp

	movw 4(%bp), %ax
	movb %al, %dh
	movw 6(%bp), %ax
	movb %al, %dl
	movw $0x0200, %ax
	movw $0x0001, %bx
	int  $0x10

	movw %bp, %sp
	popw %bp
	ret

PUTINT:
	push %bp
	movw %sp, %bp

# read the cursor position
	movw CURSOR_X, %ax
	movb %al, %dl
	movw CURSOR_Y, %ax
	movb %al, %dh

	movw $4, %cx
	movw $(LC1 + 2), %ax
	movw %ax, %di

PUTINT_L1:
	movw $LC0, %ax
	movw %ax, %si

	movw 4(%bp), %ax
	rolw $4, %ax
	movw %ax, 4(%bp)
	andw $0x000F, %ax
	addw %si, %ax
	movw %ax, %si
	movb (%si), %al
	movb %al, (%di)
	incw %di
	loop PUTINT_L1

# output message
	push %bp
	movw $LC1, %ax
	movw %ax, %bp
	movw $0x1301, %ax
	movw $0x0007, %bx
	movw $07, %cx
	int  $0x10
	popw %bp

	movw %bp, %sp
	popw %bp
	ret

LC0:
	.ascii "0123456789ABCDEF"
LC1:
	.ascii "0xAAAA "
CURR_TRACKER:
	.short 0x0000
CURR_HEADER:
	.short 0x0000
READ_SECTORS:
	.short 0x0000
EXEC_SECTORS:
	.short 0x0000

HEADERS:
	.short 0x0000
SECTORS:
	.short 0x0000

READ_AX:
	.short 0x0000
READ_BX:
	.short 0x0000
READ_CX:
	.short 0x0000
READ_DX:
	.short 0x000

DEST_SEGMENT:
	.short 0x0000
DEST_OFFSET:
	.short 0x0000
CURSOR_X:
	.short 0x0000
CURSOR_Y:
	.short 0x0000
.org 0x1fe
.short 0xaa55
