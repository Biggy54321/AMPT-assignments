;; Emit 16 bit architecture instructions
bits 16

	;; Include _start symbol in the object code file (though here not required)
    global _start

	;; Constant macros
    %define BOOT_SECTOR_BASE    0x07C0
    %define BOOT_SECTOR_SIZE    0x0200
    %define STACK_SEGMENT_SIZE  4096
    %define CGA_BASE            0xB800
    %define VIDEO_COLOR_MODE    0x3
    %define SET_VIDEO_MODE      0x00
    %define CHAR_ATTR           0x2B
    %define BOOT_SIGNATURE      0xAA55
    %define HIDE_CURSOR_ATTR    0x2607
    %define SET_CURSOR_MODE     0x01
    %define NEWLINE             0x0D
    %define BACKSPACE           0x08

	;; Initializes stack segment to the start of boot sector in ram
    %macro INIT_STACK_SEGMENT 0
	    mov ax, BOOT_SECTOR_BASE    ; Init ax to the boot sector load addr
        shl ax, 0x4                 ; Shift the contents to left by four
	    add ax, BOOT_SECTOR_SIZE    ; Add 512 to the boot sector load addr
	    mov ss, ax                  ; Init stack segment base at the end of it
	    mov sp, STACK_SEGMENT_SIZE  ; Initialize a stack of 4K size
    %endmacro

	;; Initializes data segment to the start of boot sector in ram
    %macro INIT_DATA_SEGMENT 0
		mov ax, BOOT_SECTOR_BASE    ; Init ax to the boot sector load addr
	    mov ds, ax                  ; Init data segment base to it
    %endmacro

	;; Initializes extra segment to the start of cga
	%macro INIT_EXTRA_SEGMENT 0
	    mov ax, CGA_BASE            ; Set ax to the cga address
        mov es, ax                  ; Inint extra segment to it
    %endmacro

	;; Sets the 80 X 25 coloured video mode
	%macro INIT_VIDEO_MODE 0
		mov al, VIDEO_COLOR_MODE    ; Coloured mode
        mov ah, SET_VIDEO_MODE      ; Set video mode
        int 0x10                    ; Bios interrupt call
    %endmacro

    ;; Hide cursor
    %macro HIDE_CURSOR 0
        mov ah, SET_CURSOR_MODE     ; Select the cursor mode option for bios
        mov cx, HIDE_CURSOR_ATTR    ; Set the attribute for hiding the cursor
        int 0x10                    ; Bios interrupt call
    %endmacro

	;; Get a keystroke
    %macro GET_KBD_CHAR 0
        mov ah, 0x00            ; Set the read kbd character
        int 0x16                ; Call the interrupt
    %endmacro

	;; Text section
    section .text

_start:

	;; Initialize the stack segment
	INIT_STACK_SEGMENT

	;; Write the message to the cga
    call write_kbd_to_cga

    ;; Jump infinitely
    jmp $

	;; Procedure to write message to the cga memory
write_kbd_to_cga:

    ;; Save the stack pointers
	push bp
    mov bp, sp

	;; Initialize the data segment
	INIT_DATA_SEGMENT

	;; Initialize the extra segment
    INIT_EXTRA_SEGMENT

	;; Set the color video mode
    INIT_VIDEO_MODE

    ;; Hide cursor
    HIDE_CURSOR

    ;; Set index to cga
    xor di, di

get_char_again:

    ;; Get the character from kbd
    GET_KBD_CHAR

    ;; If the entered character is newline
    cmp al, NEWLINE

    ;; Jump if the entered character is newline
    jz get_char_done

	;; If the entered character is backspace
    cmp al, BACKSPACE

	;; If the entered character is not backspace
    jnz get_char_write

    ;; If the index is already zero
	cmp di, 0x00
    jz get_char_again

    ;; Decrement the index to cga by a word
    sub di, 0x02

    ;; Load ax with null word
    xor ax, ax

    ;; Store null byte at the current index
    stosw

    ;; Decrement the index to cga by a word again
    sub di, 0x02

	;; Get the next character
    jmp get_char_again

get_char_write:

    ;; Set the attribute byte in ah
    mov ah, CHAR_ATTR

    ;; Store the entire character attribute word in the cga
    stosw

    ;; Jump to get the kbd char again
    jmp get_char_again

get_char_done:

    ;; Get the old stack registers again
    pop bp

    ;; Return from the function
    ret

    ;; Pad all but the last word with zero
	times 510-($-$$) db 0

    ;; Insert the boot signature as the last word
	dw BOOT_SIGNATURE
