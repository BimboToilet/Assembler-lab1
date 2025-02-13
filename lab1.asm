;--------------------------------------------------------------------------
code_seg segment
        ASSUME  CS:CODE_SEG,DS:code_seg,ES:code_seg
	org 100h
;
CR		EQU		13
LF		EQU		10
Space	EQU		20h
;--------------------------------------------------------------------------
print_letter	macro	letter
	push	AX
	push	DX
	mov	DL, letter
	mov	AH,	02
	int	21h
	pop	DX
	pop	AX
endm

;--------------------------------------------------------------------------
print_mes	macro	message
	local	msg, nxt
	push	AX
	push	DX
	mov	DX, offset msg
	mov	AH,	09h
	int	21h
	pop	DX
	pop	AX
	jmp nxt
	msg	DB message,'$'
	nxt:
	endm
;--------------------------------------------------------------------------
start:
	mov 	AH,	02	
	mov 	CX,16
;--------check string of parameters ---------------------------------------
    mov 	si,		80h      		; address of length parameter in psp
    mov 	al,		byte ptr[si] 	; is it 0 in buffer?
    cmp 	AL,		0
    jne 	cont4        			; yes
;--------------------------------------------------------------------------
    print_mes 'Input File Name > '
	mov		AH,	0Ah
	mov		DX,	offset	FileName
	int		21h
	xor	BH,	BH
	mov	BL,  FileName[1]
	mov	FileName[BX+2],	0
	mov	AX,	3D02h		; Open file for read/write
	mov	DX, offset FileName+2
	int	21h
	jnc	openOK
print_letter	CR
print_letter	LF
print_mes	'openERR'
	int	20h
;--------------------------------------------------------------------------
cont4:
	xor	BH,	BH
	mov	BL, ES:[80h]		
	mov	byte ptr [BX+81h],	0
	mov	AX,	3D02h		; Open file for read/write
	mov	DX, 82h
	int	21h
	jnc	openOKbuf
print_mes	'openERR'
	int	20h
;--------------------------------------------------------------------------
openOK:
print_letter	CR
print_letter	LF
openOKbuf:
print_mes	'openOK'
mov Handle1, AX
mov AH, 3Ch
mov CX,0
mov DX, offset FileNameResult
int 21h
mov AX, 3D01h
mov DX, offset FileNameResult
int 21h
mov Handle2, AX
mov bx,Handle1
write:
mov SI,0
xor AX,AX
mov ah,03fh
mov cx, 250
mov dx, offset Buf
int 21h
mov CX,AX
run:
cmp byte ptr [offset Buf+SI], ' '
jne next
cmp WordLen,0
jne next1
call PrintSpc
jmp ending
next1:
call WorkWithWord
call PrintSpc
jmp ending
next:
cmp byte ptr [offset Buf+SI], LF
jne next2
cmp WordLen,0
je next3
call WorkWithWord
next3:
mov SymbLen,1
mov byte ptr [offset Symb], LF
call PrintSymb
jmp ending
next2:
mov DI, WordLen
push BX
mov BL, byte ptr [offset Buf + SI]
mov byte ptr [offset WordBuf + DI], BL
pop BX
inc DI
mov WordLen, DI
ending:
inc SI
loop run
cmp AX, 250
je write
cmp WordLen,0
je last
call WorkWithWord
last:
mov		AX,	4C00h
int 	21h

WorkWithWord proc near
push AX
push SI
push DI
push CX
mov CX, WordLen
checking:
mov SI, WordLen
sub SI, CX
call CompareL
call CompareR
loop checking
mov SI, FlagL
and SI, FlagR
cmp SI, 0
je noway
mov CX, WordLen
working:
mov SI, WordLen
sub SI, CX
cmp byte ptr [offset WordBuf + SI], 'ÿ'
ja isit
cmp byte ptr [offset WordBuf + SI], 'À'
jb isit
call RusToLat
jmp ready
isit:
cmp byte ptr [offset WordBuf + SI], '¸'
jne YO
mov SymbLen,2
mov byte ptr [offset Symb], 'y'
mov byte ptr [offset Symb+1], 'o'
jmp ready
YO:
cmp byte ptr [offset WordBuf + SI], '¨'
jne other
mov SymbLen,2
mov byte ptr [offset Symb], 'y'
mov byte ptr [offset Symb+1], 'o'
jmp ready
other:
mov SymbLen,1
push BX
mov BL, byte ptr [offset WordBuf + SI]
mov byte ptr [offset Symb], BL
pop BX
ready:
call PrintSymb
loop working
jmp finish
noway:
call PrintWord
finish:
pop CX
pop DI
pop SI
pop AX
mov FlagL,0
mov FlagR,0
mov WordLen,0
ret
WorkWithWord endp

CompareL proc near
cmp byte ptr [offset WordBuf + SI], 'z'
ja markLA
cmp byte ptr [offset WordBuf + SI], 'a'
jb markLA
mov FlagL, 1
jmp markL
markLA:
cmp byte ptr [offset WordBuf + SI], 'Z'
ja markL
cmp byte ptr [offset WordBuf + SI], 'A'
jb markL
mov FlagL, 1
markL:
ret
CompareL endp
CompareR proc near
cmp byte ptr [offset WordBuf + SI], 'ÿ'
ja markR
cmp byte ptr [offset WordBuf + SI], 'À'
jb markR
mov FlagR, 1
jmp markRA
markR:
cmp byte ptr [offset WordBuf + SI], '¸'
jne markRB
mov FlagR, 1
markRB:
cmp byte ptr [offset WordBuf + SI], '¨'
jne markRA
mov FlagR, 1
markRA:
ret
CompareR endp

PrintSpc proc near
push AX
push BX
push DX
push CX
mov AH, 40h
mov CX, 1
mov BX, Handle2
mov DX, offset Spc
int 21h
pop CX
pop DX
pop BX
pop AX
ret
PrintSpc endp

RusToLat proc near
mov SymbLen,0
push DI
push AX
push DX
push BX
xor DX, DX
xor BX, BX
xor AX,AX
mov DI, SymbLen
mov AL, 3
mov DL, byte ptr [offset WordBuf+SI]
cmp DL, 224
jb Zagl
sub DL, 224
mul DL
mov BX, AX
jmp adds
Zagl:
sub DL, 192
mul DL
mov BX, AX
adds:
mov DL, byte ptr [offset Alphabet+BX]
mov byte ptr [offset Symb+DI], DL
inc DI
inc BX
mov SymbLen, DI
cmp byte ptr [offset Alphabet+BX], '$'
jne adds
pop BX
pop DX
pop AX
pop DI
ret
RusToLat endp

PrintWord proc near
push AX
push BX
push DX
push CX
mov AH, 40h
mov CX, WordLen
mov BX, Handle2
mov DX, offset WordBuf
int 21h
pop CX
pop DX
pop BX
pop AX
ret
PrintWord endp

PrintSymb proc near
push AX
push BX
push DX
push CX
mov AH, 40h
mov CX, SymbLen
mov BX, Handle2
mov DX, offset Symb
int 21h
pop CX
pop DX
pop BX
pop AX
ret
PrintSymb endp

Spc DB ' '
FileName	DB		14,0,14 dup (0)
WordLen DW 0
WordBuf DB 250 dup(?)
Handle1 DW ?
FlagR DW 0
FlagL DW 0
FlagB DW 0
Symb DB 3 dup(?)
SymbLen DW 0
FileNameResult DB 'Result.txt', 0
Handle2 DW ?
Alphabet DB 'a$$b$$v$$g$$d$$e$$zh$z$$i$$i$$k$$l$$m$$n$$o$$p$$r$$s$$t$$u$$f$$h$$ts$ch$sh$sh$$$$i$$$$$e$$yu$ya$'
Buf DB 250 dup(?)
	code_seg ends
         end start
	
	