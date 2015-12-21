	.file "head.s"
	.code16
.text
.globl main
.org 0x0000
main:
# initialize segment registers.
	movw %cs, %ax
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %ss
	movw %ax, %fs
	movw %ax, %gs

# set stack pointer
	movw $0xfd00, %ax
	movw %ax, %sp
	movw %ax, %bp

	movw $0x0000, CURSOR_X
	movw $0x0000, CURSOR_Y
	call SetCursor

	call LoadDiskParameters
	call ReadSystem

# halt command
HALT:
	hlt
	jmp  HALT

PutMsg:
	push %bp
	movw %sp, %bp

# set position
	movw CURSOR_Y, %ax
	movb %al, %dh
	movw CURSOR_X, %ax
	movb %al, %dl

	push %bp
	movw $LC0, %ax
	movw %ax, %bp
	mov  $0x1301, %ax
	mov  $0x0007, %bx
	mov  $(LC1 - LC0), %cx
	int  $0x10
	pop  %bp

	mov  %bp, %sp
	pop  %bp
	ret

SetCursor:
	push %bp
	movw %sp, %bp

	movw CURSOR_X, %ax
	movb %al, %dl
	movw CURSOR_Y, %ax
	movb %al, %dh

	movw $0x0200, %ax
	movw $0x0001, %bx
	int  $0x10

	movw %bp, %sp
	popw %bp
	ret

LoadDiskParameters:
	movb $0x80, %dl
	movw $0x0800, %ax
	int $0x13

	xorw %ax, %ax
	movb %cl, %al
	movw %ax, SECTORS

	xorw %ax, %ax
	movb %ch, %al
	movw %ax, TRACKERS

	xorw %ax, %ax
	movb %dh, %al
	movw %ax, HEADERS
	ret

PUTINT:
	push %bp
	movw %sp, %bp

	push %ax
	push %bx
	push %cx
	push %dx
	push %si
	push %di
	push %ds
	push %es

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

	pop %es
	pop %ds
	pop %di
	pop %si
	pop %dx
	pop %cx
	pop %bx
	pop %ax

	movw %bp, %sp
	popw %bp
	ret

PrintIntAndAdvance:
	push %bp
	movw %sp, %bp

	push 4(%bp)
	call PUTINT
	addw $2, %sp
	addw $7, CURSOR_X

	movw %bp, %sp
	pop  %bp
	ret

# read the system into 0x10000
ReadSystem:
	call SetInitParams
CheckReadSections:
	cmpw $0X9000, DEST_SEGMENT
	jb   rp_read
	ret

rp_read:
	call GetReadSections
	call DoReadSections
	call DumpReadState
	call ReadSectionAdvance
	jmp  CheckReadSections

SetInitParams:
	movw $0x0005, READ_SECTORS
	movw $0x0000, CURR_TRACKER
	movw $0x0000, CURR_HEADER
	movw $0x1000, DEST_SEGMENT
	movw $0x0000, DEST_OFFSET
	ret

GetReadSections:
	movw SECTORS, %ax
	subw READ_SECTORS, %ax
	movw %ax, %cx
	shlw $9, %cx
	movw DEST_OFFSET, %bx
	addw %cx, %bx
	jnc  ok2_read
	je   ok2_read
	xorw %ax, %ax
	subw DEST_OFFSET, %ax
	shrw $9, %ax
ok2_read:
	movw %ax, EXEC_SECTORS
	ret

DoReadSections:
	movw EXEC_SECTORS, %ax
	movb $0x02, %ah
	movw %ax, READ_AX
	movw DEST_OFFSET, %bx
	movw %bx, READ_BX
	movb CURR_TRACKER, %ch
	movw READ_SECTORS, %ax
	inc %ax
	movb %al, %cl
	movw %cx, READ_CX
	movb CURR_HEADER, %dh
	movb $0x80, %dl
	movw %dx, READ_DX

	push %es
	movw DEST_SEGMENT, %ax
	movw %ax, %es
	movw READ_AX, %ax
	movw READ_BX, %bx
	movw READ_CX, %cx
	movw READ_DX, %dx
	int  $0x13
	jc   HALT
	pop  %es
	ret

DumpReadState:
	movw $0X0000, CURSOR_X
# print ax
	push READ_AX
	call PrintIntAndAdvance
	addw $2, %sp
# print bx
	push READ_BX
	call PrintIntAndAdvance
	addw $2, %sp
# print cx
	push READ_CX
	call PrintIntAndAdvance
	addw $2, %sp
# print dx
	push READ_DX
	call PrintIntAndAdvance
	addw $2, %sp
# print segment
	push DEST_SEGMENT
	call PrintIntAndAdvance
	addw $2, %sp
# print offset
	push DEST_OFFSET
	call PrintIntAndAdvance
	addw $2, %sp
# print exec sectors
	push EXEC_SECTORS
	call PrintIntAndAdvance
	addw $2, %sp
# print read sectors
	push READ_SECTORS
	call PrintIntAndAdvance
	addw $2, %sp

	incw CURSOR_Y
	ret

ReadSectionAdvance:
	movw EXEC_SECTORS, %ax
	shlw $9, %ax
	addw DEST_OFFSET, %ax
	jnc  ok_advance0
	movw DEST_SEGMENT, %ax
	addw $0x1000, %ax
	movw %ax, DEST_SEGMENT
	movw $0x0000, %ax
ok_advance0:
	movw %ax, DEST_OFFSET

	movw READ_SECTORS, %ax
	addw EXEC_SECTORS, %ax
	movw %ax, READ_SECTORS
	cmpw SECTORS, %ax
	jb   ok_advance1
	movw $0x0000, %ax
	movw %ax, READ_SECTORS
	incw CURR_HEADER
	movw CURR_HEADER, %ax
	cmpw HEADERS, %ax
	jbe  ok_advance1
	movw $0x0000, CURR_HEADER
	incw CURR_TRACKER
ok_advance1:
	incw READ_COUNT
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
TRACKERS:
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
READ_COUNT:
	.short 0x0000
.org 0x07fe
.short 0xaa55
