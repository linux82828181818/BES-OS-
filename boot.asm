[org 0x7c00]                                        ; адреса завантажувача
[bits 16]
call _start
_reb:
    mov al, 0
    mov di, buffer
    mov cx, 10
    cld
    rep stosb
    mov si, bes                                     ; вказівник si вказує на початок bes db "bes_os@root-#", 10, 13, 0
    mov ah, 00001110b                               ; 0x0E, 0Eh, 0000 0000 0000 1110
    jmp _print                                      ; стрибаємо на мітку _print
_rebsec:
    mov di, buffer                                  ; запхали в di адресу від buffer times 10 db 0
    mov cx, 10
    jmp _reb2                                       ; стрибаємо на мітку _reb2
_reb2:
    mov ah, 00000000b                               ; я чиебу чтоли запхати в в регістр ah 0x00 = read keystroke
    int 16h                                         ; ввід з клавіатури
    cmp ax, 1C0Dh                                   ; перевіряємо чи це клавіша enter
    je _reb3                                        ; якщо да стрибаємо в _reb3 якщо не то йдемо далі по циклу
    jcxz _reb2
    mov ah, 0x0e
    int 10h
    mov [di], al                                    ; біос кидає число або букву яку ввів користувач в регістр al і кидаємо його в буфер
    inc di                                          ; наступна ячейка
    dec cx
    jmp _reb2                                       ; і так по колу поки не буде enter
_reb3:
    mov si, bit32_cmd                               ; si - має вказувати на те що ми будемо порівнювати
    mov di, buffer                                  ; di - вказує з чим порівнювати а саме буфер ми записували те що вводив користувач
    mov cx, 7                                       ; cx - треба записувати скільки букв чи байтів треба порівняти
    cld                                             ; для того щоб процесор не почав рахувати з права на ліво
    repe cmpsb                                      ; repe cmpsb - repe крутить на місці cmpsb а cmpsb перевіряє текст поки cx не стукне 0
    je _bit32                                       ; якщо да то сктрибаємо на мітку _bit32
    mov si, reboot_cmd                              ; далі йде теж саме
    mov di, buffer
    mov cx, 7
    cld
    repe cmpsb
    je _reboot
    jmp _reb                                        ; якщо це не bit 32 ні reboot тоді він стрибає назад в _reb
_print:
    mov al, [si]
    cmp al, 0
    je _rebsec
    inc si
    mov ah, 00001110b
    int 10h
    jmp _print
_reboot:
    int 19h
kernel_error:                                       ; виводить помилку та зависає якщо проблема не можливо знайти диск/сектор з ядром
    mov ah, 0x0e                                    ; білий на чорному
    mov al, "E"
    int 10h
    mov al, "r"
    int 10h
    mov al, "r"
    int 10h
    mov al, "o"
    int 10h
    mov al, "r"
    int 10h
    cli
    hlt
_start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov [BOOTDRIVER], dl

    mov bx, 0x1000
    mov al, 1
    mov ah, 0x02
    mov dl, [BOOTDRIVER]
    mov cl, 2
    mov ch, 0
    mov dh, 0
    int 13h
    jc kernel_error
    ret
_bit32:
    in al, 0x92
    or al, 2
    out 0x92, al                                     ; включаємо лінію A20 для того щоб ос бачила більше чим 1мб
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    lgdt [GDT_pointer]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp 0x08:init_start
[bits 32]
init_start:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000
    jmp 0x1000
GDT_start:
    dq 0x0
GDT_code:
    dw 0xFFFF
    dw 0x0
    db 0x0
    db 10011010b
    db 11001111b
    db 0x0
GDT_data:
    dw 0xFFFF
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0
GDT_end:

GDT_pointer:
    dw GDT_end - GDT_start - 1
    dd GDT_start
bes db 10, 13, "bes_os@root-#", 0
buffer times 10 db 0
reboot_cmd db "reboot", 0
bit32_cmd db "bit 32", 0
BOOTDRIVER db 0
times 510 - ($ - $$) db 0
dw 0xAA55
; Well well well if it isn't us
