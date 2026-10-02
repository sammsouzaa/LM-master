; ==========================================================
; a05at02.asm - Correção do bug da a05at01 (OR / AND)
;
; O BUG da a05at01:
;   Se maiuscula = 'a' (0x61) e fizermos "add al, 32", obtemos 0x81,
;   que não é uma letra. O mesmo vale para "sub 32" em um 'B' (0x42 - 0x20 = 0x22).
;   ADD/SUB mudam o valor mesmo quando o caractere JÁ está no formato certo.
;
; A SOLUÇÃO: olhar o bit 5 (valor 0x20), que é o único que difere:
;     'A' = 0100 0001      'a' = 0110 0001
;     'B' = 0100 0010      'b' = 0110 0010
;                 ^ bit 5
;   - Para minúscula: LIGAR o bit 5     -> OR  com 0x20 (0010 0000)
;   - Para maiúscula: DESLIGAR o bit 5  -> AND com 0xDF (1101 1111)
;
; Essas operações são IDEMPOTENTES: aplicar duas vezes dá o mesmo resultado.
; Ou seja, funcionam com 'A' ou 'a' na entrada, sem erro.
;
; Observação: só vale para letras (A-Z / a-z). Em outros caracteres
; (números, símbolos) o resultado seria alterado indevidamente.
; ==========================================================

section .data
    maiuscula: db 'a'           ; propositalmente "errado": já é minúscula
    minuscula: db 'B'           ; propositalmente "errado": já é maiúscula

section .bss
    lowercase: resb 1           ; resultado: minúscula
    uppercase: resb 1           ; resultado: maiúscula

section .text
    global _start

_start:
    ; ---------- lowercase = tolowercase(maiuscula) ----------
    mov al, [maiuscula]         ; al <- 'a' (0x61)
    or  al, 0x20                ; liga o bit 5: 0x61 | 0x20 = 0x61 -> continua 'a'
                                ; (se fosse 'A': 0x41 | 0x20 = 0x61 -> 'a')
    mov [lowercase], al         ; grava em lowercase

    ; ---------- uppercase = touppercase(minuscula) ----------
    mov bl, [minuscula]         ; bl <- 'B' (0x42)
    and bl, 0xDF                ; desliga o bit 5: 0x42 & 0xDF = 0x42 -> continua 'B'
                                ; (se fosse 'b': 0x62 & 0xDF = 0x42 -> 'B')
    mov [uppercase], bl         ; grava em uppercase

fim:
    mov rax, 60                 ; syscall exit
    mov rdi, 0                  ; código de saída 0
    syscall
