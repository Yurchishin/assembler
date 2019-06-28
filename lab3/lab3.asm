.386
data1 segment   use16
i1      db      0
i2      db      0
i3      db      0
i4      db      0
a1      dw      3 dup(4 dup(2 dup (5 dup(?))))
adres   dw      begin2, code2
data1 ends

data2 segment   use16
a2      dd      3 dup(4 dup(2 dup (5 dup(?))))
data2 ends

code1 segment use16
        assume  ds:data1, es:data2, cs:code1
begin:
    mov     ax, data1
    mov     ds, ax
    mov     ax, data2
    mov     es, ax

    mov     dx, offset a2

    xor     eax, eax

    mov     i1, 0
@i1:
    mov     i2, 0
@i2:
    mov     i3, 0
@i3:
    mov     i4, 0
@i4:
    movzx   ax, byte ptr i1
    shl     ax, 2
    movzx   dx, byte ptr i2
    add     ax, dx
    shl     ax, 1
    movzx   dx, byte ptr i3
    add     ax, dx
    imul    ax, 5
    movzx   dx, byte ptr i4
    add     al, dx

    lea     dx, [offset a2 + eax * 4 + 2]
    mov     word ptr a1[eax * 2], dx

    inc     i4
    cmp     i4, 5
    jne     @i4

    inc     i3
    cmp     i3, 2
    jne     @i3

    inc     i2
    cmp     i2, 4
    jne     @i2

    inc     i1
    cmp     i1, 03h         
    jne     @i1

    jmp     dword ptr adres
@endprog:
    mov     ax, data1
    mov     es, ax
    mov     ax, data2
    mov     ds, ax

    mov     ax, 4c00h
    int     21h

code1   ends

code2   segment use16
        assume es:data2, ds:data1, cs:code2
begin2:
        mov     ax, data1
        mov     ds, ax
        mov     ax, data2
        mov     es, ax

		; load adress of element A1[2, 1, 1, 3]
        mov     eax, 62h       ; 98
        lea     eax, [offset a1 + eax * 2]

        mov     di, offset a2
        mov     cx, 78h        ; 120
        repnz   stosd

        nop
        nop

        jmp     far ptr @endprog

code2   ends
        end     begin
        end     begin2
