; ==========================================================
; a05at04.asm - N-ésimo número triangular
;
; Fórmula:  T(n) = n * (n + 1) / 2
; Para n = 40:  40 * 41 / 2 = 1640 / 2 = 820
;
; Instruções usadas (32 bits, sem sinal):
;   MUL r/m32 -> EDX:EAX = EAX * r/m32   (EAX é o operando implícito)
;   DIV r/m32 -> EAX = EDX:EAX / r/m32   (quociente em EAX, resto em EDX)
;
; Detalhe: o DIV usa EDX:EAX como dividendo. Como acabamos de executar
; o MUL, o produto JÁ está em EDX:EAX, então o dividendo está correto
; e não precisamos zerar EDX nem usar CDQ.
; ==========================================================

section .data
    n: dd 40                    ; posição desejada (dword = 4 bytes)

section .bss
    enessimotrinumero: resd 1   ; resultado T(n) (4 bytes)

section .text
    global _start

_start:
    mov eax, [n]                ; eax <- n = 40
    mov ebx, eax                ; ebx <- n (cópia)
    inc ebx                     ; ebx <- n + 1 = 41

    mul ebx                     ; EDX:EAX <- EAX * EBX = 40 * 41 = 1640
                                ; (parte alta em EDX = 0, parte baixa em EAX = 1640)

    mov ebx, 2                  ; divisor = 2
    div ebx                     ; EAX <- 1640 / 2 = 820 (quociente)
                                ; EDX <- resto = 0 (n*(n+1) é sempre par)

    mov [enessimotrinumero], eax ; grava T(40) = 820

    ; Alternativa: dividir por 2 equivale a deslocar 1 bit à direita:
    ;     shr eax, 1            ; (sem sinal) no lugar de "mov ebx,2 / div ebx"

fim:
    mov rax, 60                 ; syscall exit
    mov rdi, 0                  ; código de saída 0
    syscall
