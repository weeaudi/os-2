org 0x7C00
bits 16



entry:
    ; setup stack
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 7C00h

    ; switch to protected mode
    cli ; 1 - disable inturupts
    call EnableA20 ; 2 - Enable A20 gate
    call LoadGDT ; 3 - Load GDT

    ; 4 - set protection enable flag in CR0
    mov eax, cr0
    or al, 1
    mov cr0, eax

    ; 5 - far jump into protected mode
    jmp dword 08h:.pmode

.pmode:
    [bits 32]
    ; we are now in 32-bit protected mode!

    ; 6 - setup segments
    mov ax, 0x10
    mov ds, ax
    mov ss, ax

    mov esi, g_Hello
    mov edi, ScreenBuffer
    cld

    mov bl, 1

.loop:
    lodsb
    or al, al
    jz .done

    mov [edi], al
    inc edi

    mov [edi], bl
    inc edi
    inc bl

    jmp .loop

.done:

    jmp word 18h:.pmode16

.pmode16:
    [bits 16]
    ; 2 - disable protected mode bit in CR0
    mov eax, cr0
    and al, ~1
    mov cr0, eax

    ; 3 - jump to real mode
    jmp word 00h:.rmode

.rmode:
    ; 4 - setup segments
    mov ax, 0
    mov ds, ax
    mov ss, ax

    ; 5 - enable interupts
    sti

    ; print hello world using int10h
    mov si, g_Hello

.rloop:
    lodsb
    or al, al
    jz .rdone
    mov ah, 0eh
    int 10h
    jmp .rloop
.rdone

.halt:
    jmp .halt

EnableA20:
    [bits 16]
    ; disable keyboard
    call A20WaitInput
    mov al, KbdControllerDisableKeyboard
    out KbdControllerCommandPort, al

    ; read control output port ( i.e. flush output buffer)
    call A20WaitInput
    mov al, KbdControllerReadCtrlOutputPort
    out KbdControllerCommandPort, al

    call A20WaitOutput
    in al, KbdControllerDataPort
    push eax

    ; write control output port
    call A20WaitInput
    mov al, KbdControllerWriteCtrlOutputPort
    out KbdControllerDataPort, al

    call A20WaitInput
    pop eax
    or al, 2 ; bit 2 = A20 bit
    out KbdControllerDataPort, al

    ; enable keyboard
    call A20WaitInput
    mov al, KbdControllerEnableKeyboard
    out KbdControllerCommandPort, al

    call A20WaitInput
    ret

A20WaitInput:
    [bits 16]
    ; wait until status bit 2 (input buffer) is 0
    ; by reading from command port, we read status byte
    in al, KbdControllerCommandPort
    test al, 2
    jnz A20WaitInput
    ret

A20WaitOutput:
    [bits 16]
    ; wait until status bit 1 (output buffer) is 1 so it can be read
    in al, KbdControllerCommandPort
    test al, 1
    jz A20WaitOutput
    ret

LoadGDT:
    [bits 16]
    lgdt [g_GDTDesc]
    ret




KbdControllerDataPort equ 0x60
KbdControllerCommandPort equ 0x64
KbdControllerDisableKeyboard equ 0xAD
KbdControllerEnableKeyboard equ 0xAE
KbdControllerReadCtrlOutputPort equ 0xD0
KbdControllerWriteCtrlOutputPort equ 0xD1

ScreenBuffer equ 0xB8000

g_GDT:
    dq 0 ; NULL descriptor

    ; 32-bit code segment
    dw 0FFFFh ; limit (bits 0-15) = 0xFFFFFFFF for fill 32-bit range
    dw 0 ; base (bits 0-15) = 0x0
    db 0 ; base (bits 16-23)
    db 10011010b ; access (present, ring 0, code segment, executable, directon 0, readable)
    db 11001111b ; granularity (4k pages, 32-bit pmode) + limit (bits 16-20)
    db 0 ; base high

    ; 32-bit data segment
    dw 0FFFFh ; limit (bits 0-15) = 0xFFFFFFFF for fill 32-bit range
    dw 0 ; base (bits 0-15) = 0x0
    db 0 ; base (bits 16-23)
    db 10010010b ; access (present, ring 0, data segment, executable, directon 0, writable)
    db 11001111b ; granularity (4k pages, 32-bit pmode) + limit (bits 16-20)
    db 0 ; base high

    ; 16-bit code segment
    dw 0FFFFh ; limit (bits 0-15) = 0xFFFFFFFF
    dw 0 ; base (bits 0-15) = 0x0
    db 0 ; base (bits 16-23)
    db 10011010b ; access (present, ring 0, code segment, executable, directon 0, readable)
    db 00001111b ; granularity (1b pages, 16-bit pmode) + limit (bits 16-20)
    db 0 ; base high

    ; 16-bit data segment
    dw 0FFFFh ; limit (bits 0-15) = 0xFFFFFFFF
    dw 0 ; base (bits 0-15) = 0x0
    db 0 ; base (bits 16-23)
    db 10010010b ; access (present, ring 0, data segment, executable, directon 0, readable)
    db 00001111b ; granularity (1b pages, 16-bit pmode) + limit (bits 16-20)
    db 0 ; base high

g_GDTDesc:  dw g_GDTDesc - g_GDT - 1 ; limit = size of GDT
            dd g_GDT ; address of GDT

g_Hello db "Hello World", 0

times 510-($-$$) db 0
dw 0AA55h