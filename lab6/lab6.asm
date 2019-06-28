.386
;======================================================
; МОДЕЛЬ МУЛЬТИПРОГРАМНОЇ СИСТЕМИ
;======================================================
max_prg equ 10 ;максимальна кількість "одночасно" виконуваних задач 
time_slice equ 65535; кількість мікросекунд, виділених на один квант часу (максимальне значення 65535)

_ST SEGMENT WORD STACK 'stack' use16
	dw 32000 dup (?)
	top label word
	dw 100 dup (?) ;резерв для помилок анти переповнення стека
_ST ENDS

_DATA SEGMENT WORD PUBLIC 'DATA' use16
	@ms_dos_busy dd (?) ; логічна адреса ознаки зайнятості MS-DOS

	int8set db 0 ;ознака перехоплення переривання від таймера
	int9set db 0 ;ознака перехоплення переривання від клавіатури

	fon equ max_prg ; ознака фонової задачі;
	fonsp label word ;адреса збереження SP фонової задачі
	sssp dd top ;логічна адреса стека фонової задачі

; масив значень SP для задач, (для стека кожної задачі відведено 1000 слів)
;задані початкові значення 
	stp dw 1000,2000,3000,4000
		dw 5000,6000,7000,8000
		dw 9000,10000,11000,12000
		dw 13000,14000,15000,16000


	nprg dw 0 ;номер активної задачі (від 0 до 
	;max_prg-1)
	; або ознака фонової задачі (fon)

	; масив стану задач
	init db 16 dup (0)

	; масив дозволеного числа квантів задач
	clock db 16 dup (1)

	; масив лічильників квантів задач 
	clockt db 16 dup (0)

	screen_addr dw 16 dup (0) ; адреса (зміщення від початку відеосторінки)
	; області введення на екран значень задачі

	; масив імен задач
	names label word
	db '0T1T2T3T4T5T6T7T8T9TATBTCTDTETFT'
	clk dw 0 ;лічильник переривань від таймера 

	mouse_state dw 0
	cursor_pos dw 0
_DATA ENDS

_TEXT SEGMENT BYTE PUBLIC 'CODE' use16
	ASSUME CS:_TEXT,DS:_DATA

;------------------------------------------------------------
; процедура "перехоплення" переривання від таймера (int8)
;------------------------------------------------------------
setint8 PROC
;------------------------------------------------------------
	mov al,int8set
	or al,al ; контроль "перехоплення" перехоплень
	jnz zero_8 ;
	MOV AH,35H ; отримати вектор переривання
	MOV AL,8 ; переривання від таймера (8)
	INT 21H ; значення що повертається:
	 ; es:bx - логічна адреса системної процедури
	 ; обробки переривання від таймера

	mov cs:int8ptr,bx ; зберегти логічну адресу системної
	mov cs:int8ptr+2,es ; процедури в сегменті кодів

	mov dx,offset userint8 ;формування в ds:dx логічної
	push ds ; адреси процедури користувача
	push cs ; для обробки переривань від таймера
	pop ds

	MOV AH,25H ; встановити вектор
	MOV AL,8 ; переривання від таймера
	INT 21H ; ds:dx - покажчик на користувацьку
	; процедуру оброб. переривання від ;таймера


	mov ax,time_slice ; встановити задану величину кванту часу
	out 40h,al ; 40h - адреса 8-розрядного порта таймера, 
	; через який задають період таймера 
	; спочатку молодший байт,
	; а потім старший

	jmp $+2 ; стандартний метод узгодження швидкісного
	 ; процесора з більш повільним зовнішнім
	 ; пристроєм. Припускаємо, що
	 ; "безглузда" команда jmp очищує буфер
	 ; попередньої вибірки команд і, тим самим,
	 ; уповільнює роботу процесора. Тим часом
	 ; зовнішній пристрій буде готовий 
	;прийняти наступний байт
	nop

	mov al,ah ; (старший байт)
	out 40h,al

	pop ds

	mov int8set,0ffh ; заборона повторних входжень
zero_8:
	ret
	
	int8ptr dw 2 dup (?)
setint8 ENDP


;--------------------------------------------------------------------------
; Процедура відновлення вектора переривання від таймера
;--------------------------------------------------------------------------
retint8 PROC
;--------------------------------------------------------------------------
	push ds
	push dx

	mov al,0ffh ; відновити нормальну роботу
	out 40h,al ; системного таймера
	jmp $+2
	nop
	out 40h,al
	mov dx,cs:int8ptr
	mov ds,cs:int8ptr+2

	MOV AH,25H ; відновити початковий вектор
	MOV AL,8 ; переривання від таймера
	INT 21H ; ds:dx - вказівник (логічна адреса) 
	;на початкову (системну) процедуру
	 ; оброб. переривання від таймера
	pop dx
	pop ds
	mov int8set,0h ; дозвіл наступних "перехоплень"
	ret
retint8 ENDP



;------------------------------------------------------------
setint9 PROC
;-----------------------------------------------------------
; процедура "перехоплення" переривання від клавіатури (int9)
;------------------------------------------------------------
	mov al,int9set
	or al,al
	jnz zero_9
	MOV AH,35H ; отримати вектор переривання
	MOV AL,9 ; переривання від клавіатури (9)
	INT 21H ;значення що повертається:
	 ; es:bx - вказівник на системну процедуру
	 ; обробки переривання від клавіатури

	mov cs:int9ptr,bx ; зберегти в сегменті кодів вказівник 
	mov cs:int9ptr+2,es ; на системну процедуру

	mov dx,offset userint9
	push ds
	push cs ; ds:dx - вказівник на процедуру користувача
	pop ds ; оброб. переривання від клавіатури

	MOV AH,25H ; встановити вектор "перехоплення"
	MOV AL,9 ; переривання від клавіатури (9)
	INT 21H ; 
	pop ds

	mov int9set,0ffh ; заборона повторних входжень

zero_9:
	ret
	int9ptr dw 2 dup (?)
setint9 ENDP


;--------------------------------------------------------------------------
; Процедура відновлення попереднього (системного)
; вектора переривання від клавіатури
;--------------------------------------------------------------------------
retint9 PROC
	push ds
	push dx
	mov dx,cs:int9ptr ; ds:dx - покажчик на початкову (системну)
	mov ds,cs:int9ptr+2 ; процедуру обробки переривання від
	; клавіатури

	MOV AH,25H ; встановити вектор системної процедури
	MOV AL,9 ; обробки переривання від клавіатури
	INT 21H ; 
	 ; 
	pop dx
	pop ds
	mov int9set,0h ; дозвіл наступних "перехоплень"
	ret
retint9 ENDP


;-----------------------------------------------------------------------------------------------
; Процедура обробки переривань від клавіатури,
; викликається при любому натисканні або відтисканні клавіш клавіатури,
; здійснює повернення в MS-DOS після відтискання клавіші Esc
;------------------------------------------------------------------------------------------------
userint9 proc far
;----------------------------------------------------------------------------
esc_key equ 01h ; скан-код клавіші esc
	pusha
	push es
	in al,60h ; ввести скан-код - розряди 0-6
	mov ah,al ; 7-ий розряд дорівнює 0 при натисканні
	and al,7fh ;клавіші, 1- при відтисканні

	; cmp al,esc_key
	; je ui9010
	
	; ; (варіант 2)
	; pop es
	; popa
	; jmp dword ptr cs:int9ptr ; перехід на системну
	; ;процедуру обробки
	; ;переривань від клавіатури, яка
	; ;виконає всі необхідні дії, включаючи
	; ;повернення в перервану програму

	call checkKeys

	ui9010:
	mov bx,ax
	in al,61h ;біт 7 порта 61h призначений для введення
	; ; підтверджуючого імпульсу в клавіатуру ПЕОМ.
	 ; Клавіатура блокується поки не надійде
	 ; підтверджуючий імпульс
	 ;
	mov ah,al
	or al,80h ; |
	out 61h,al ; виведення на клавіатуру └───┐ 
	jmp $+2
	mov al,ah
	out 61h,al ; підтверджуючого імпульсу ┌───┘

	mov al,20h ; розблокувати в контролері переривання
	 ; проходження запитів на переривання 
	;поточного та меншого рівнів пріоритету,
	out 20h,al ; що забезпечить можливість наступного 
	;переривання від клавіатури

	mov ax,bx
	cmp ah,al ; перевірка події переривання - від натискання
	 ; чи від відтискання клавіші клавіатури
	je ui9040
	 ;відтискання клавіші

	ui9020:
	
	cmp al, esc_key
	jne ui9040

	push es
	les bx, @ms_dos_busy ; es:bx - адреса ознаки 
	;зайнятості MS-DOS
	mov al,es:[bx] ; ax - ознака зайнятості MS-DOS
	pop es
	or al,al ; перевірка
	; якщо була перервана робота MS-DOS
	;в "невдалий" момент
	jnz ui9040 ; то не можна від неї вимагати
	 ; виконання ряду функцій
	; (в загальному випадку MS-DOS 
	; не забезпечує повторне входження)

	call retint8
	call retint9

	mov ax,4c00h
	int 21h ; ЗАКІНЧИТИ РОБОТУ
	; БАГАТОПРОГРАМНОЇ МОДЕЛІ
ui9040:
	pop es ; відновити стек перерваної програми
	popa
	iret ; закінчити обробку переривання
userint9 endp
;------------------------------------------------------------
; процедура обробки переривання від таймера
; (менеджер квантів)
; коди стану задач (використовуються в масиві init)
ready equ 0 ; задача завантажена в пам’ять і
 ; готова до початкового запуску
 ; статус встановлюється поза менеджером квантів
execute equ 1 ; задача виконується
hesitation equ 2 ; задача призупинена і чекає своєї черги
close equ 4 ; виконання задачі завершено
stop equ 8 ; задача зупинена 
 ; статус встановлюється і змінюється
 ; поза менеджера квантів
absent equ 16 ; задача відсутня 

;------------------------------------------------------------
; процедура обробки переривання від таймера
;  (менеджер квантів)
; коди стану задач (використовуються в масиві init)
ready equ 0 ; задача завантажена в пам’ять і
     ; готова до початкового запуску
     ; статус встановлюється поза менеджером квантів
execute equ 1 ; задача виконується
hesitation equ 2 ; задача призупинена і чекає своєї черги
close  equ 4 ; виконання задачі завершено
stop  equ 8 ; задача зупинена 
     ; статус встановлюється і змінюється
      ; поза менеджера квантів
absent equ 16 ; задача відсутня 


	;------------------------------------------------------------
userint8 PROC far
	;------------------------------------------------------------
	pushad   ;збереження РОН в стеку перерваної задачі
	push ds

	; (варіант 3)
	pushf   ;програмна імітація апаратного переривання
	;ВІДМІТИМО - ознака дозволу на переривання (if) апаратурою скинута в 0.

	call cs:dword ptr int8ptr
	;виклик системної процедури обробки переривання int8,
	;яка, між іншим, розблокує 8-ме переривання в контролері переривань 
	;але апаратні переривання не можливі, оскільки if=0


	mov ax,_data ;в перерваній програмі вміст сегментного регістра
	mov ds,ax		;ds в загальному випадку може бути любим

	inc clk  ; програмний лічильник переривань від таймера
	push clk  ; може бути корисним при вивченні моделі
	push 2440
	call show		; виведення на екран значення лічильника

	xor esi,esi
	mov si,nprg
	cmp si,fon  ; перервана задача фонова ?
	je disp005

	; перервана задача не фонова
	cmp clockt[si],1 ; є ще не використані кванти ?
	jc disp010

	dec clockt[si] ; зменшити лічильник квантів
	pop ds
	popad  ; продовжити виконання перерваної задачі
	iret

disp005:    ; перервана задача фонова
	mov fonsp,sp
	mov nprg,max_prg-1 ; забезпечити перегляд задач з 0-вої
	mov cx,max_prg  ; max_prg - max кількість задач
	jmp disp015

disp010:      ; перервана задача не фонова
	mov stp[esi*2],sp 
	mov init[si],hesitation ; призупинити поточну задачу
	mov cx,max_prg


disp015:
	; визначення задачі, якій необхідно передати управління
	mov di,max_prg+1
	sub di,cx
	add di,nprg
	cmp di,max_prg
	jc disp018
	sub di,max_prg
disp018:
	xor ebx,ebx
	mov bx,di
	;push bx
	;push 3220
	;call show

	; сх пробігає значення max_prg,max_prg-1,...,2,1
	; bx пробігає значення nprg+1,nprg+2,...,max_prg- 
	;1,0,...,nprg
	;
	cmp init[bx],ready
	je disp100   ; перехід на початковий запуск задачі

	cmp init[bx],hesitation
	je  disp020   ; перехід на відновлення роботи
	; наступної задачі
	loop disp015

	; відсутні задачі, які можна запустить
	; (перезапустити), тому 
	; 
	mov sp,fonsp			; установлюємо стек фонової задачі
	mov nprg,fon
	pop ds			; із стека фонової задачі відновлюємо
	popad					; вміст регістрів
	iret    ; повернення в фонову задачу


disp020:
	; відновлення роботи наступної задачі
	;push bx
	;push 2480
	;call show
	mov nprg,bx
	mov sp,stp[ebx*2]
	mov al,clock[bx]
	mov clockt[bx],al ; встановити дозволену
	; кількість квантів
	mov init[bx],execute		; стан задачі - задача виконується

	pop ds
	popad
	iret

disp100:
	; першопочатковий запуск задачі
	mov nprg,bx
	mov sp,stp[ebx*2]
	mov al,clock[bx]
	mov clockt[bx],al  ; встановити дозволену
	; кількість квантів
	mov init[bx],execute

	push	names[ebx*2]		; ім'я задачі
	push screen_addr[ebx*2] ; адреса "вікна" для задачі на екрані 
	push 22    ; розрядність лічильника
	call Vcount   ; запуск


	xor esi,esi
	mov si,nprg   ; на ax - номер задачі, яка
	; завершила свою роботу в межах
	; чергового кванту часу
	mov init[si],close
	mov sp,fonsp
	mov nprg,fon
	pop ds
	popad
	iret     ; повернення в фонову задачу

	userint8 ENDP


checkKeys proc
	pusha
	push es
	push ds

	cmp al, 3Dh
	jne checkKeysEnd

	mov bx, _DATA
	mov ds, bx

	mov di, 0

	cmp ah, 3Dh
	je label101
	inc di
	label101:

	tasksLoop:

	cmp BYTE PTR init[di], absent
	jne nextElement

	mov BYTE PTR init[di], ready

	nextElement:

	inc di
	inc di
	cmp di, max_prg
	jl tasksLoop

	checkKeysEnd:

	pop ds
	pop es
	popa

	ret
checkKeys endp



;-
; Vcount - процедура для моделювання незалежних задач 
; вхідні параметри:
; 1-й - ім'я задачі (два символа) [bp+8]
; 2-й - зміщення в відеосторінці "вікна" задачі [bp+6]
; 3-й - кількість двійкових розрядів лічильника [bp+4]
; Виконувані дії:
; при запуску:
; - дозволяє переривання
; - створює в стеку 10-байтну область для локальних даних
; - розміщує в цю область по адресі [bp-2] статок від ділення
; 3-го параметра на 32 (фактична розрядність лічильника -
; перестраховка від помилок в завданні розрядності)
; - записує в цю область по адресу [bp-6] маску з числом
; одиниць в молодших розрядів рівним фактичній 
; розрядності лічильника
; - записує в нуль в 4-х байт ний лічильник по адресу [bp-10]

; в подальшому в циклі:
; - виводить показники лічильника на екран
; - збільшує значення лічильника на 1
; завершення задачі після переходу лічильника 
; з стану "всі одиниці" в стан всі 0

Vcount proc near
	
	push bp
	mov bp,sp
	sub sp,10 ;формування в стеку області для
	 ;збереження даних
	sti

	push es
	mov ax,0b800h
	mov es,ax

	mov ax,[bp+4] ;ax = кількість розрядів лічильника
	and ax,31 ;ax=ax mod 32 (для перестраховки)
	mov [bp-2],ax ;по [bp-2] кількість розр. лічильника 
	 ;<32
	mov cx,ax
	mov eax,001b
	shl eax,cl
	dec eax ; eax - маска с числом 1 рівним
	 ; кількості розрядів лічильника
	mov [bp-6],eax

	mov dword ptr [bp-10],0 ; скидання лічильника

	mov di,[bp+6] ; вивід імені задачі
	mov dx,[bp+8]

	mov al, dh
	cld
	stosb
	inc di
	mov al,dl
	stosb
	inc di

	std ;підготовка до виводу лічильника
	add di,cx ;починаючи с молодших розрядів
	add di,cx
	mov bx,di
	xor edx,edx

l20: ;вивід показників лічильника в двоїчному 
	 ;форматі
	mov di,bx
	mov cx,[bp-2]

l40:
	mov al, '0'
	shr edx, 1
	jnc l60
		inc al
	l60:
	stosb
	dec di
	loop l40

	inc dword ptr [bp-10] ; +1 в лічильник
	mov edx,dword ptr [bp-10]
	and edx,[bp-6] ; перевірка на 0
	jnz l20

	pop es
	add sp,10
	mov ax,[bp+8]
	and ax,0fh
	cli
	pop bp
	ret 6
Vcount endp

;=====
show proc near
	push bp
	mov bp,sp
	pusha
	push es
	mov ax,0b800h
	mov es,ax

	std
ls20:
	mov di,[bp+4]
	mov bx,[bp+6]
	mov cx,4
ls40:
	mov al,bl
	and al,00001111b
	cmp al,10
	jl ls100
	add al,7
ls100:
	add al,30h
	stosb
	dec di
	shr bx,4
	loop ls40

	pop es
	popa
	pop bp
	ret 4
show endp

;------------------------------------------------------------
;------------------------------------------------------------
;------------------------------------------------------------
begin:
	mov ax,_data
	mov ds,ax

	mov ax,3 ; задати текстовий режим 80 на 25
	int 10h

	; Clear screen
	mov ax, 0b800h
	mov es, ax
	mov di, 0
	mov ah, 1010b
	mov al, ' '
	mov cx, 2000
	rep stosw

	mov ah,10h ; відключити режим миготіння
	mov al,3
	mov bl,0
	int 10h
	
	mov cx,max_prg
	xor esi, esi
	mov bx, 4

b10:
	mov screen_addr[esi*2],bx ; заповнення таблиці
	 ; адрес виводу для задач
	mov init[esi],absent ; першопочаткове заповнення
	 ; таблиці стану задач
	
	add bx, 80
	inc esi

	loop b10
	;SETINT
	cli ; заборона переривань

	mov ah,34h
	int 21h ;es:bx - адреса ознаки зайнятості MS-DOS
	mov word ptr @ms_dos_busy,bx
	mov word ptr @ms_dos_busy+2,es

	call setint8 ;"перехоплення" int8
	call setint9 ;"перехоплення" int9

	lss sp,sssp ; стек фонової задачі
	mov nprg,fon
	push 'FN'
	push 1800
	push 30
	call Vcount ; запуск фонової задачі
	; в процедурі Vcount установлюється дозвіл
	;на переривання і при чергових перериваннях
	; від таймера менеджер квантів (userint8) 
	; буде запускать інші задачі
	;
	; управління в цю точку буде передано по команді RET по завершені фонової ; задачі, а це можливо лише після завершення інших задач

	call retint8 ; відновлення системних векторів 
	call retint9
	sti

	; Clear screen
	mov ax, 0b800h
	mov es, ax
	mov di, 0
	mov ah, 0Fh
	mov al, ' '
	mov cx, 2000
	rep stosw

	mov ax,4c00h
	int 21h
_TEXT ENDS

end begin