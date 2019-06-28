
 
.186

code SEGMENT          ;7 6 5 4 3 2 1 0      11110011b     243d
     ASSUME cs:code   ;4 1 6 0 3 6 2 1      11110101b       

begin:
        mov al, 11110011b   
        mov dh,0  

        	; 0-ий розряд
        	mov ah, al     		     
        	and ah, 00000001b 
		mov cl, 4  			
		shl ah, cl			
		or dh, ah	

		; 1-ий розряд
        	mov ah, al     		     
        	and ah, 00000010b 			
		shr ah, 1			
		or dh, ah
		mov cl, 6
		shl ah, cl
		or dh, ah		
       
		
        	; 2-ий розряд
        	mov ah, al          
	       	and ah, 00000100b			
		shr ah, 1
		or dh, ah

		;3-ий розряд
		mov ah, al
		and ah, 00001000b
		or dh, ah

		; 4-ий розряд
        	mov ah, al     		     
        	and ah, 00010000b 
		mov cl, 3  			
		shl ah, cl			
		or dh, ah
		
		; 6-ий розряд
		mov ah, al          
		and ah, 01000000b
		shr ah, 1
		or dh, ah
		mov cl, 3
		shr ah, cl
		or dh, ah
	
        mov ax, 4c00h    ;  4c00h – код для операційної системи
        int 21h          ;  виклик функції операційної системи
code ENDS
    end begin
