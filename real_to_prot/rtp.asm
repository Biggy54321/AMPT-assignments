org 0x7c00

	;; Formatting for a single character and its background
    %define CHAR_ATTR           0x2B
    %define CONSOLE_SIZE        80*24
    %define BOOT_SIGNATURE      0xAA55

    ;; GDT descriptors
    %define NULL_DESCR          0x0000, 0x0000, 0x0000, 0x0000
    %define CODE_DESCR          0xFFFF, 0x0000, 0x9A00, 0x00CF
    %define DATA_DESCR          0xFFFF, 0x0000, 0x9200, 0x00CF
    %define CGA_DESCR           0xFFFF, 0x8000, 0x920B, 0x00CF

	;; Macro to initialize a blank screen
	%macro INIT_SCREEN 0
        xor ax, ax
        int 0x16
        xor ax, ax
	    xor di,di
	    mov cx, CONSOLE_SIZE
	    repnz stosw
    %endmacro

bits 16
real_mode_text:

	;; Initialize the extra segment
	mov ax, 0xB800
	mov es, ax

	;; Initialize the screen
	INIT_SCREEN

	;; Initialize the message
	mov si, msg_real_mode
    xor di, di

    ;; Write the characters to the CGA
.loop:

	;; Get the string character
    lodsb

    ;; If the character is 0 then quit the loop
    cmp al, 00h
    je .end

	;; Store the character in al to the cga address
    stosb

	;; Store the attribute to the cga address
    mov al, CHAR_ATTR
    stosb

    ;; Loop again
    jmp .loop

.end:

	;; Reinitialize the screen
	INIT_SCREEN

	;; Load the GDTR register
	lgdt [gdtr_val_addr]

	;; Enter PVAM mode
    mov eax, cr0
	or eax, 0x1
	mov cr0, eax

	;; Jump so that code descriptor is fetched
	jmp CODE_SELECTOR:pvam_mode_text

	;; Define the GDT table
gdt_start:
    dw NULL_DESCR
gdt_code_descr:
    dw CODE_DESCR
gdt_data_descr:
    dw DATA_DESCR
gdt_cga_descr:
    dw CGA_DESCR
gdt_end:

	;; Define the GDTR value container address
gdtr_val_addr:
    dw gdt_end - gdt_start
    dd gdt_start

	;; Define the selectors
    CODE_SELECTOR equ gdt_code_descr - gdt_start
    DATA_SELECTOR equ gdt_data_descr - gdt_start
    CGA_SELECTOR equ gdt_cga_descr - gdt_start

bits 32
pvam_mode_text:

	;; Initialize the data segment
    mov ax, DATA_SELECTOR
    mov ds, ax

	;; Initialize the extra segment
    mov ax, CGA_SELECTOR
    mov es, ax

	;; Initialize the indices
    mov esi, msg_pvam_mode
    xor di, di

    ;; Write the characters to the CGA
.loop:

	;; Get the string character
    lodsb

    ;; If the character is 0 then quit the loop
    cmp al, 00h
    je .end

	;; Store the character in al to the cga address
    stosb

	;; Store the attribute to the cga address
    mov al, CHAR_ATTR
    stosb

    ;; Loop again
    jmp .loop

.end:

	;; Clear interrupts and enter a halt state
    cli
    hlt

	;; Dummy rejumping
    jmp $

    ;; Initialize the messages
    msg_real_mode db "In real mode", 0
    msg_pvam_mode db "In protected virtual address mode", 0

    ;; Pad all but the last word with zero
	times 510-($-$$) db 0

    ;; Insert the boot signature as the last word
	dw BOOT_SIGNATURE
