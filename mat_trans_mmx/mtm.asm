;; Emit 16 bit architecture instructions
bits 16

	;; Include _start symbol in the object code file (though here not required)
    global _start

	;; Constant macros
    %define BOOT_SECTOR_BASE    0x07C0
    %define BOOT_SECTOR_SIZE    0x0200
    %define STACK_SEGMENT_SIZE  4096
    %define CGA_BASE            0xB800
    %define VIDEO_COLOR_MODE    0x00
    %define SET_VIDEO_MODE      0x00
    %define CHAR_ATTR           0x2B
    %define BOOT_SIGNATURE      0xAA55
    %define HIDE_CURSOR_ATTR    0x2607
    %define SET_CURSOR_MODE     0x01
    %define NEWLINE             0x0D

	;; Initializes stack segment to the start of boot sector in ram
    %macro INIT_STACK_SEGMENT 0
	    mov ax, BOOT_SECTOR_BASE    ; Init ax to the boot sector load addr
        shl ax, 0x4                 ; Shift the contents to left by four
	    add ax, BOOT_SECTOR_SIZE    ; Add 512 to the boot sector load addr
        shr ax, 0x4
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

    ;; Print newline on the CGA display (from the)
    %macro PRINT_NEWLINE 0
	    mov ax, di
        mov bl, 80
        div bl
        mov ah, 0x0
        inc ax
        mul bl
        mov di, ax
    %endmacro

    ;; Print space on the CGA display (from the)
    %macro PRINT_SPACE 0
	    mov ax, 0x2B20
        stosw
    %endmacro

	;; Text section
    section .text

_start:

	;; Initialize the stack segment
	INIT_STACK_SEGMENT

		;; Initialize the data segment
	INIT_DATA_SEGMENT

	;; Initialize the extra segment
    INIT_EXTRA_SEGMENT

	;; Set the color video mode
    INIT_VIDEO_MODE

    ;; Hide cursor
    HIDE_CURSOR

	;; Set the index to CGA
    xor di, di

	;; Print the input matrix message
    push msg_input
    call display_string

    PRINT_NEWLINE

	;; Print the input matrix (from 0-31 index)
    push 0x8
    push 0x4
    push mat_input
    call display_matrix
    pop cx
    pop cx
    pop cx

    PRINT_NEWLINE
    PRINT_NEWLINE

    ;; Initialize the 4 rows in the mmx regs
    movq mm0, [mat_input]
    movq mm1, [mat_input + 0x8]
    movq mm2, [mat_input + 0x10]
    movq mm3, [mat_input + 0x18]

    movq mm4, mm0
    punpcklbw mm4, mm1

    movq mm5, mm2
    punpcklbw mm5, mm3

    movq mm6, mm4
    punpcklwd mm6, mm5

    movq mm7, mm4
    punpckhwd mm7, mm5

	movq [mat_output], mm6
    movq [mat_output + 0x8], mm7

    movq mm4, mm0
    punpckhbw mm4, mm1

    movq mm5, mm2
    punpckhbw mm5, mm3

    movq mm6, mm4
    punpcklwd mm6, mm5

    movq mm7, mm4
    punpckhwd mm7, mm5

	movq [mat_output + 0x10], mm6
    movq [mat_output + 0x18], mm7


	;; Print the output matrix message
    push msg_output
    call display_string

    PRINT_NEWLINE

	;; Print the output matrix
	push 0x4
    push 0x8
    push mat_output
    call display_matrix

	jmp $

display_string:

    push bp
    mov bp, sp

    ;; Set index to the message address
    mov si, [bp + 0x04]

.loop:

	;; Get the string character
    lodsb

    ;; If the character is 0 then quit the loop
    cmp al, 0x0
    je .end

	;; Store the character in al to the cga address
    stosb

	;; Load the attribute in al
	mov al, CHAR_ATTR

	;; Store the attribute to the cga address
    stosb

    ;; Loop again
    jmp .loop

.end:

    ;; Get the old stack registers again
    pop bp

    ;; Return from the function
    ret

display_matrix:

    push bp
    mov bp, sp

	;; Get the cols counts
    mov dx, [bp + 8]

	;; Get the rows count
    mov bx, [bp + 6]

    ;; Get the base address
    mov si, [bp + 4]

	;; Initialize the count (ch-total count, cl-row count)
    mov cx, 0x0

_loop:

	;; Get the string character and store at the video ram
    movsb

	;; Load the attribute in al
	mov al, CHAR_ATTR

	;; Store the attribute to the cga address
    stosb

    PRINT_SPACE

	;; Increment the number of characters printed in a single row
	inc cl
	inc ch

	;; Check if a row is printed
    cmp cl, dl
    jnz skip_newline
    mov cl, 0x0
    PRINT_NEWLINE

skip_newline:

    cmp ch, 32
    jnz _loop

    ;; Get the old stack registers again
    pop bp

    ;; Return from the function
    ret

	;; Initialize the messages
    msg_input db "The input matrix is:", 0
    msg_output db "The output matrix is:", 0

	;; Initialize the input matrix
	mat_input_nb_rows db 4
    mat_input_nb_cols db 8
	mat_input db "01234567012345670123456701234567"

	;; Initialize the output matrix
    mat_output times 32 db (0)

    ;; Pad all but the last word with zero
	times 510-($-$$) db (0)

    ;; Insert the boot signature as the last word
	dw BOOT_SIGNATURE
