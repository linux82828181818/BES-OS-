[bits 32]
[org 0x1000]
%macro vga 2
    mov esi, %1
vga_jmp:
    mov al, [esi]
    mov ah, 0x0F
    cmp al, 0
    je %2
    mov [edi], ax
    inc esi
    add edi, 2
    jmp vga_jmp
%endmacro
jmp _start
a db "a", 0
msg db "BES-OS 0.0.8!(x86)", 0
msg2 db "Well, well, well. If it isn't us.", 0
cmd db "bes_os@BES-OS-$", 0
cmd_shutdown db "shutdown", 0
clear db "clear", 0
section .data
    keyboard_buffer times 30 db 0
    scancode_table:
        db 0,  0, '1','2','3','4','5','6','7','8','9','0','-','=', 0, 0  ; 0x00 - 0x0F
        db 'q','w','e','r','t','y','u','i','o','p','[',']', 0,  0, 'a','s' ; 0x10 - 0x1F
        db 'd','f','g','h','j','k','l', '.', "'",'`', 0, '\','z','x','c','v' ; 0x20 - 0x2F
        db 'b','n','m',',','.','/', 0, '*', 0, ' ', 0,  0,  0,  0,  0,  0  ; 0x30 - 0x3F
_start:
    mov edi, 0x000B8000
    mov ecx, 1000
    mov eax, 0x07200720
    cld
    rep stosd
    mov edi, 0x000B8000
    mov esi, msg
    mov ah, 0x0F
    jmp _loop
_loop:
    mov al, [esi]
    cmp al, 0
    je _start2
    mov [edi], ax
    inc esi
    add edi, 2
    jmp _loop
_loop2:
    mov al, [esi]
    cmp al, 0
    je _hlt
    mov [edi], ax
    inc esi
    add edi, 2
    jmp _loop2
_loop3:
    mov al, [esi]
    cmp al, 0
    je _hlt2
    mov [edi], ax
    inc esi
    add edi, 2
    jmp _loop3
_pisk:
    mov al, 0xB6
    out 0x43, al
    mov ah, 0x04
    mov al, 0xA9
    out 0x42, al
    mov al, ah
    out 0x42, al
    in al, 0x61
    or al, 3
    out 0x61, al
    call _sleep
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    ret
_sleep:
    mov ecx, 1000
    imul ecx, ecx, 1000
    call _sleep2
    ret
_sleep2:
    pause
    dec ecx
    cmp ecx, 0
    jne _sleep2
    ret
_start2:
    mov esi, msg2
    add edi, 128
    jmp _loop2
_hlt:
    add edi, 94
    jmp _sechlt
_sechlt:
    mov esi, cmd
    mov ah, 0Fh
    jmp _loop3
_hlt2:
    ;call _pisk

    mov ecx, 30
    mov esi, keyboard_buffer
    mov ax, 0xdb
    add [edi], ax
    jmp _hlt3
_func:
    mov ah, 0Fh
    mov eax, edi
    xor edx, edx
    mov ecx, 160
    div ecx
    inc eax
    imul edi, eax, 160
    ret
_shutdown:
    pop edi
    mov dx, 0x0604
    mov ax, 0x2000
    out dx, ax
_hlt3:
    in al, 0x64
    test al, 1
    jz _hlt3
    in al, 0x60
    test al, 0x80
    jnz _hlt3
    cmp al, 0x1C
    je _cmd

    cmp ecx, 0
    je _hlt3

    xor ebx, ebx
    movzx ebx, al
    mov al, [scancode_table + ebx]
    mov ah, 0x0f
    mov [edi], ax
    add edi, 2
    mov [esi], al
    inc esi
    dec ecx
    jmp _hlt3
_cmd:
    call _func
    add edi, 64
    push edi
    mov edi, keyboard_buffer
    mov esi, cmd_shutdown
    mov ecx, 9
    cld
    repe cmpsb
    je _shutdown

    ;mov edi, keyboard_buffer
    ;mov esi, clear
    ;mov ecx, 6
    ;cld
    ;repe cmpsb
    ;je _clear

    mov ecx, 30
    mov al, 0
    mov edi, keyboard_buffer
    cld
    rep stosb
    pop edi
    jmp _sechlt
_clear:
    mov edi, 0x000B8000
    mov al, a
    mov ah, 0x0F
    mov [edi], ax
    cli
    hlt
_clear2:
    mov ecx, 30
    mov al, 0
    mov edi, keyboard_buffer
    cld
    rep stosb
    mov edi, 0x000B8000
    mov ecx, 1000
    mov eax, 0x07200720
    cld
    rep stosd
    mov edi, 0x000B8000
    pop edi
    jmp _sechlt
