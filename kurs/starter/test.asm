.386

Data SEGMENT
  Str1   DB  'Rybak'
  Int2   DB  01010101b
  Int10  DW  523
  Int16  DD  0F856Ah
Data ENDS

Code SEGMENT
  ASSUME DS:Data, CS:Code
  NUMBER EQU 1
  Int0  DB  00001101b
start:
  IF NUMBER
  Jbe endl
  je endl
  Cli
  Jbe endl
  Mov dl, 00111100b
  Mov al, 00001111b
  Inc esi
  Dec Int0[eax+edx]
  Add al, dl
  Cmp dl, Str1[ecx + edx]
  And Int0[eax+edx], dl
  Or  Int0[eax+edx], NUMBER

  ELSE
  mov al, 33

  ENDIF
  Jbe start
  Cli

endl:
Code ends
END start
