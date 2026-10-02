; ==========================================================
; a05at01.asm - Conversão de maiúscula <-> minúscula (ADD/SUB)
;
; Ideia: na tabela ASCII, 'A' = 0x41 (65) e 'a' = 0x61 (97).
; A diferença entre uma letra minúscula e sua maiúscula é 32 (0x20).
;   minúscula = maiúscula + 32
;   maiúscula = minúscula - 32
;
; Montar:  nasm -f elf64 a05at01.asm
; Linkar:  ld a05at01.o -o a05at01.x
; Rodar:   ./a05at01.x   (use o GDB para ver os resultados)
; ==========================================================

section .data
    maiuscula: db 'A'           ; 1 byte com o caractere 'A' (0x41)
    minuscula: db 'b'           ; 1 byte com o caractere 'b' (0x62)

section .bss
    lowercase: resb 1           ; reserva 1 byte (resultado: minúscula de 'A')
    uppercase: resb 1           ; reserva 1 byte (resultado: maiúscula de 'b')

section .text
    global _start

_start:
    ; ---------- lowercase = tolowercase(maiuscula) ----------
    mov al, [maiuscula]         ; al <- 'A' (0x41). Usamos 'al' porque o dado tem 8 bits
    add al, 32                  ; 0x41 + 0x20 = 0x61 -> 'a'
    mov [lowercase], al         ; grava o resultado na variável lowercase

    ; ---------- uppercase = touppercase(minuscula) ----------
    mov bl, [minuscula]         ; bl <- 'b' (0x62)
    sub bl, 32                  ; 0x62 - 0x20 = 0x42 -> 'B'
    mov [uppercase], bl         ; grava o resultado na variável uppercase

fim:
    ; ---------- encerra o programa (syscall exit) ----------
    mov rax, 60                 ; número da syscall exit
    mov rdi, 0                  ; código de saída 0 (sucesso)
    syscall
