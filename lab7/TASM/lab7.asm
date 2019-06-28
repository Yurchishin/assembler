.386

DATA SEGMENT use16
	temporally	dq ?

	min_x		dq -4.0
	max_x		dq 4.0	 
	max_crt_x	dw 320
	crt_x		dw ?
	scale_x		dq ?

	min_y		dq -4.0
	max_y		dq 4.0
	max_crt_y	dw 200
	crt_y 		dw ?
	scale_y		dq ?
DATA ENDS

CODE SEGMENT use16
ASSUME CS:CODE,DS:DATA

scale macro p1
	fld max_&p1
	fsub min_&p1
	fild max_crt_&p1
	fdivp st (1), st (0)
	fstp scale_&p1 ; top=0
endm

start:
	mov ax, DATA
	mov ds, ax

	finit
	scale x
	scale y

	mov ax, 13h
	int 10h
	
	mov ax, 0A000h
	mov es, ax

	mov di, 0
	mov cx, 320*200
	mov ax, 2Ch
	rep stosb

	mov cx, 320
	line1:
		dec cx
		mov di, 320*100
		add di, cx
		mov al, 32
		stosb
		cmp cx, 0
	jne line1


	mov cx, 200
	line2:
		dec cx
		mov di, 160

		mov ax, cx
		imul ax, 320

		add di, ax
		mov al, 32
		stosb
		cmp cx, 0
	jne line2

	mov dx, max_crt_x
	mov crt_x, dx

	draw:
		dec crt_x
		
		; перетворення екранної координати в дійсну.
		; top=0
		fld scale_x
		; st0 - масштаб
		fild crt_x
		; st0=crt_x, st1-масштаб

		;top = 6
		fmulp st(1), st(0)		; top=7
		fadd min_x		; st0 - реальне зн. Х; top=7

		fst temporally
		fsin
		fld temporally
		fcos
		fdiv
		fld temporally
		fsin
		fadd

		; контроль діапазону (top не змінюється)
		; порівняння ST (0) та min_y
		fcom min_y
		; результат порівняння в ax 
		fstsw ax
		; результат порівняння
		sahf
		;ST (0) та min_y в регістр Flags

		; st0 < min_y
		jc minus
		; поза видимим діапазоном
		; по @minus забезпечити top=0 і
		; crt_y=max_crt_y

		; порівняння ST (0) та max_y
		fcom max_y		
		fstsw ax
		sahf
		ja plus		; st0 > max_y (zf=cf=0)
		; поза видимим діапазоном
		; по @plus - забезпечити top=0
		; і встановити crt_y=0
		fsub min_y;
		fdiv scale_y
		; округлення до цілого
		frndint
		; TOP=0!!!
		fistp crt_y

		; дзеркальне відображення
		mov ax, max_crt_y
		sub ax, crt_y
		mov crt_y, ax

		imul ax, 320

		add ax, WORD PTR crt_x
		mov di, ax
		mov al, 32
		stosb

		minus:
		plus:
		
		fstp temporally
		
	cmp crt_x, 0
	jne draw

	mov		ah, 4ch
	int		21h

CODE ENDS
end start