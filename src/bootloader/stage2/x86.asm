bits 16

section _TEXT class=CODE

;
; U4D
;
; Operation:      Unsigned 4 byte divide
; Inputs:         DX;AX   Dividend
;                 CX;BX   Divisor
; Outputs:        DX;AX   Quotient
;                 CX;BX   Remainder
; Volatile:       none
;
global __U4D
__U4D:
    shl edx, 16         ; dx to upper half of edx
    mov dx, ax          ; edx - dividend
    mov eax, edx        ; eax - dividend
    xor edx, edx

    shl ecx, 16         ; cx to upper half of ecx
    mov cx, bx          ; ecx - divisor

    div ecx             ; eax - quot, edx - remainder
    mov ebx, edx
    mov ecx, edx
    shr ecx, 16

    mov edx, eax
    shr edx, 16

    ret


;
; U4M
;
; Operation:      Unsigned 4 byte multiply
; Inputs:         DX;AX   interger M1
;                 CX;BX   interger M2
; Outputs:        DX;AX   product
; Volatile:       CX, BX destroyed
;
global __U4M
__U4M:
    shl edx, 16 ; dx to upper half of edx
    mov dx, ax  ; m1 in edx
    mov eax, edx ; m1 in eax

    shl ecx, 16 ; cx to upper half of ecx
    mov cx, bx ; m2 in ecx

    mul ecx ; result in edx:eax (we only need eax)
    mov edx, eax ; move upper half to dx
    shr edx, 16 

    ret


;
; void _cdecl x86_div64_32(uint64_t dividend, uint32_t divisor, uint64_t *quotientOut, uint32_t *remainderOut);
;
global _x86_div64_32
_x86_div64_32:

    ; make new call frame
    push bp
    mov bp, sp

    push bx

    ; [bp + 0] - old call frame
    ; [bp + 2] - return address (small memory model => 2 bytes)
    ; [bp + 4] - dividend (lower 32 bist)
    ; [bp + 8] - dividend (upper 32 bist)
    ; [bp + 12] - divisor
    ; [bp + 16] - quotientOut (address in memory)
    ; [bp + 18] - remainderOut (address in memory)

    ; divide upper 32 bits
    mov eax, [bp + 8]   ; eax <- upper 32 bits of dividend
    mov ecx, [bp + 12]  ; ecx <- divisor
    xor edx, edx
    div ecx             ; eax - quot, edx - remainder

    ; store upper 32 bits of quotient
    mov bx, [bp + 16]
    mov [bx + 4], eax

    ; divide lower 32 bits
    mov eax, [bp + 4]   ; eax <- lower 32 bits of dividend
                        ; edx ,- old remainder
    div ecx

    ; store results
    mov [bx], eax
    mov bx, [bp + 18]
    mov [bx], edx

    pop bx

    mov sp, bp
    pop bp
    ret


;
;   int 10h ah=0Eh
;   args: character, page
;
global _x86_Video_WriteCharTeletype
_x86_Video_WriteCharTeletype:

    ; make new call frame
    push bp     ; save old call frame
    mov bp, sp  ; initialize new call frame

    ; save bx
    push bx

    ; [bp + 0] - old call frame
    ; [bp + 2] - return address (small memory model => 2 bytes)
    ; [bp + 4] - first argument (character)
    ; [bp + 6] - second argument (page)
    ; note: bytes are converted to words (you can't push a single byte on the stack)
    mov ah, 0Eh
    mov al, [bp + 4]
    mov bh, [bp + 6]

    int 10h

    ; restore bx
    pop bx

    ; restore old call frame
    mov sp, bp
    pop bp
    ret


;
; bool _cdecl x86_Disk_Reset(uint8_t drive);
;
global _x86_Disk_Reset
_x86_Disk_Reset:

    ; make new call frame
    push bp     ; save old call frame
    mov bp, sp  ; initialize new call frame

    ; [bp + 0] - old call frame
    ; [bp + 2] - return address (small memory model => 2 bytes)
    ; [bp + 4] - Drive

    mov ah, 0
    mov dl, [bp + 4] ; dl - drive
    stc
    int 13h

    mov ax, 1
    sbb ax, 0 ; 1 = true, 0 = false

    ; restore old call frame
    mov sp, bp
    pop bp
    ret

; bool _cdecl x86_Disk_Read(  uint8_t drive,
;                             uint16_t cylinder,
;                             uint16_t head,
;                             uint16_t sector,
;                             uint8_t count,
;                             uint8_t far * dataOut);
;
global _x86_Disk_Read
_x86_Disk_Read:

    ; make new call frame
    push bp     ; save old call frame
    mov bp, sp  ; initialize new call frame

    ; save registers
    push bx
    push es

    ; [bp + 0] - old call frame
    ; [bp + 2] - return address (small memory model => 2 bytes)
    ; [bp + 4] - Drive
    ; [bp + 6] - cylinder
    ; [bp + 8] - head
    ; [bp + 10] - sector
    ; [bp + 12] - count
    ; [bp + 14] - dataOut (pointer)

    mov dl, [bp + 4] ; dl - drive

    mov ch, [bp + 6] ; ch - cylinder (lower 8 bits)
    mov cl, [bp + 7] ; cl - cylinder to bits 6-7
    shl cl, 6

    mov dh, [bp + 8] ; dh - head

    mov al, [bp + 10]
    and al, 3Fh
    or cl, al ; cl - sector to bits 0-5

    mov al, [bp + 12] ; al - count

    mov bx, [bp + 16] ; es:bx - far pointer to data out
    mov es, bx
    mov bx, [bp + 14]

    ; call
    mov ah, 02h
    stc
    int 13h

    mov ax, 1
    sbb ax, 0 ; 1 = true, 0 = false

    ; restore registers
    pop es
    pop bx

    ; restore old call frame
    mov sp, bp
    pop bp
    ret

; bool _cdecl x86_Disk_GetDriveParams(uint8_t drive,
;                                     uint8_t* driveTypeOut,
;                                     uint16_t* cylindersOut,
;                                     uint16_t* sectorsOut,
;                                     uint16_t* headsOut);
;
global _x86_Disk_GetDriveParams
_x86_Disk_GetDriveParams:

    push bp     ; save old call frame
    mov bp, sp  ; initialize new call frame

    ; [bp + 0] - old call frame
    ; [bp + 2] - return address (small memory model => 2 bytes)
    ; [bp + 4] - Drive
    ; [bp + 6] - DriveTypeOut (Pointer)
    ; [bp + 8] - cylindersOut (Pointer)
    ; [bp + 10] - sectorsOut (Pointer)
    ; [bp + 12] - headsOut (Pointer)

    ; save Registers

    push bx
    push si
    push es
    push di

    mov dl, [bp + 4] ; dl - drive
    mov ah, 08h
    mov di, 0 ; es:di - 0000:0000
    mov es, di
    stc
    int 13h

    ; return
    mov ax, 1
    sbb ax, 0

    ; out params
    mov si, [bp + 6] ; drive type
    mov [si], bl

    mov bl, ch ; cylinders - lower bits in ch
    mov bh, cl ; cylinders - upper bits in cl (6-7)
    shr bh, 6
    mov si, [bp + 8] 
    mov [si], bx

    xor ch, ch  ; secotrs - lower 5 bits in cl
    and cl, 3Fh
    mov si, [bp + 10]
    mov [si], cx

    mov cl, dh  ; heads - dh
    mov si, [bp + 12]
    mov [si], cx


    ; restire Registers
    pop di
    pop es
    pop si
    pop bx

    ; restore old call frame
    mov sp, bp
    pop bp
    ret