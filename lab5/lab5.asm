.386
clr		equ		110b

DATA	SEGMENT USE16 
dvalue		db	30 dup('0',0Fh)
len		dw	20				
row		dw	10				
col		dw	30				
valadd		db	8				
cont		db	0ffh				
DATA	ENDS


ASSUME	CS: CODE, DS: DATA
CODE	SEGMENT USE16 
@@entry:
mov		ax, data
mov		ds, ax
mov		ax, 0b800h
mov		es, ax
call	mouse_init
mov 	al, 02h
mov 	ah, 00h
int 	10h
mov 	ax, 1
int 	33h		

@write:								
cli						
lea		si, dvalue

mov		al, byte ptr row		
mov		ah, 0
imul	ax, (80*2)
add		ax, col
add		ax, col				
mov		di, ax
mov		cx, len
	
@l_write:
mov 	bx, cx
shl 	bx, 1
mov 	ah, ds:[si+bx]	
mov 	es:[di+bx], ah
loop	@l_write
sti	

@9: 								
mov		si, len
shl		si, 1
sub		si, 2				
mov		ah ,0				
												
mov		al, dvalue[si]
add		al, [valadd]
aaa						
												
or		al, 30h				
mov		dvalue[si], al

@10:
dec		si
dec		si
mov		al, ah
mov		ah, 0
add		al, dvalue[si]			
aaa
or		al, 30h
mov		dvalue[si], al
						
cmp		si, 0
jg		@10

mov		al, [cont]			
cmp		al, 0ffh
je		@write
jmp		exit

exit:		
call	mouse_deinit
mov		ax, 4c00h
int		21h

mouse_init	proc
push	ax
push	cx
push	dx
						
xor		ax, ax
int		33h
test	ax, ax
jz		@mi_endp
						
mov		ax, 0ch								
mov		cx, 1010b			
													
push	es					
push	cs
pop		es					
													
lea 	dx, prmaus									
int		33h		
							
pop		es

@mi_endp:		
pop		dx
pop		cx
pop		ax
ret
mouse_init	endp

mouse_deinit proc
push	ax
push	cx
push	dx
					
xor		cx, cx				
mov		ax, 0ch						
int		33h	

pop		dx
pop		cx
pop		ax
ret
mouse_deinit endp
													
prmaus 	proc 	far
												
push	ds    
push	es
pusha
												
push	0b800h 				
pop		es
push 	data
pop		ds
											
test	bx, 01b
jz		@exit_r

mov 	ax,3
int 	33h
shr 	cx,3
shr 	dx,3
mov 	si, dx
imul	si, 80
add 	si, cx
shl		si, 1
mov 	byte ptr es:[si+1], clr


@exit_r:
test	ax, 1000b
jz		@l

mov		byte ptr[cont], 0
@l:	
popa
pop		es
pop		ds
ret
prmaus	endp
CODE	ENDS
END @@entry
