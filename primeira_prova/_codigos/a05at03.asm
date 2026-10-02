; ==========================================================
; a05at03.asm - Somatório de um vetor de inteiros (sem laço)
;
; Vetor: triangularNum = 0, 1, 3, 6, 10, 15, 21, 28   (8 elementos dd)
; Cada 'dd' ocupa 4 bytes, então o endereço do elemento i é:
;       endereço = triangularNum + i * 4
;
; Como ainda não temos laços, somamos um a um:
;   - LEA calcula o endereço do elemento (sem acessar a memória)
;   - ADD acumula o valor apontado em EAX
;   - INC avança o indexador
;
; Resultado esperado: 0+1+3+6+10+15+21+28 = 84
; ==========================================================

section .data
    triangularNum: dd 0, 1, 3, 6, 10, 15, 21, 28

section .bss
    somatorio: resd 1           ; reserva 1 dword (4 bytes) para o resultado

section .text
    global _start

_start:
    mov eax, 0                  ; eax = acumulador da soma
    mov ecx, 0                  ; ecx = indexador (posição no vetor)

    ; ---------- elemento 0 ----------
    lea rbx, [triangularNum + rcx*4]   ; rbx <- endereço do elemento [ecx]
    add eax, [rbx]                     ; eax += valor guardado nesse endereço
    inc ecx                            ; próximo índice

    ; ---------- elemento 1 ----------
    lea rbx, [triangularNum + rcx*4]
    add eax, [rbx]
    inc ecx

    ; ---------- elemento 2 ----------
    lea rbx, [triangularNum + rcx*4]
    add eax, [rbx]
    inc ecx

    ; ---------- elemento 3 ----------
    lea rbx, [triangularNum + rcx*4]
    add eax, [rbx]
    inc ecx

    ; ---------- elemento 4 ----------
    lea rbx, [triangularNum + rcx*4]
    add eax, [rbx]
    inc ecx

    ; ---------- elemento 5 ----------
    lea rbx, [triangularNum + rcx*4]
    add eax, [rbx]
    inc ecx

    ; ---------- elemento 6 ----------
    lea rbx, [triangularNum + rcx*4]
    add eax, [rbx]
    inc ecx

    ; ---------- elemento 7 (último) ----------
    lea rbx, [triangularNum + rcx*4]
    add eax, [rbx]

    mov [somatorio], eax        ; grava o total (84) na variável somatorio

fim:
    mov rax, 60                 ; syscall exit
    mov rdi, 0                  ; código de saída 0
    syscall
