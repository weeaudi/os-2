org 0x0
bits 16


%define ENDL 0x0D, 0x0A


start:

    mov si, msg_hello
    call puts

    cli
    hlt

;
; Prints a string to the screen
; Params:
;   - ds:si points to a string
;
puts:
    ; save registers we will modify
    push si
    push ax

.loop:
    lodsb ; loads next character in al
    or al, al ; verify is next character is null
    jz .done

    mov ah, 0x0e
    mov bh, 0
    int 0x10


    jmp .loop

.done:
    pop ax
    pop si
    ret

msg_hello: db 'Hello World From Kernel!', ENDL, 0
