; boot.asm: print "Hello World!" on screen
; 
; INT 10h --  BIOS interrupt call 10hex, the 17th interrupt vector in an x86-based computer system
; function code: AH=13h -- write string
; parameters:
;     AL = write mode:
;       bit 0: update cursor after writing;
;       bit 1: string contains attributes.
;     BH = page number.
;     BL = attribute if string contains only characters (bit 1 of AL is zero).
;     CX = number of characters in string (attributes are not counted).
;     DL,DH = column, row at which to start writing.
;     ES:BP points to string to be printed.

	org 07c00h   ; "0x7C00" is the memory address which BIOS loads 
	             ; MBR(Master Boot Record, a first sector in hdd/fdd) into.
	mov ax, cs
	mov es, ax          ; set es
	mov ax, Message
	mov bp, ax          ; set bp, es:bp = Hello World!
	mov cx, Fill - Message  ; length
	mov ah, 13h         ; function : write string
	mov al, 01h         ; write mode = update cursor, attribute in BL
	mov bh, 0           ; page number
	mov bl, 0ah         ; background color=black, foreground color=light green
	mov dh,	0           ; row 0
	mov dl, 0           ; column 0
	int 10h             ; BIOS interrupt call
	jmp $               ; jump to current address (= infinite loop)
Message:    db "Hello, World!"       ; string data
Fill:       times 510-($-$$)  db 0   ; first sector (512 bytes) 
                                     ; |program data| ....any data ...|0xaa, 0x55|
                                     ;0         ($-$$)             509 510   511 512
                                     ; $$ is the address of the beginning of the current section
            dw 0xaa55      ; boot signature = end of the first sector