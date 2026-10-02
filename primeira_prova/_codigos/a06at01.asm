; ==========================================================
; a06at01.asm - Aplicação "sem sentido": o programa mata a si mesmo
;
; Passos:
;   1) sys_getpid (39): devolve em RAX o PID do próprio processo
;   2) sys_kill   (62): rdi = PID alvo, rsi = número do sinal
;                       sinal 9 = SIGKILL (encerra o processo à força)
;   3) Se o kill funcionar, o programa morre ali e NUNCA chega
;      ao write final. Se a frase "this isn't working!" aparecer,
;      significa que o kill falhou.
;
; Teste:
;   nasm -f elf64 a06at01.asm && ld a06at01.o -o a06at01.x
;   ./a06at01.x        -> deve imprimir "Killed" (ou nada) e NÃO a frase
;   echo $?            -> deve mostrar 137 (128 + sinal 9)
; ==========================================================

section .data
    strFalha : db "this isn't working!", 10    ; só aparece se o kill falhar
    strFalhaL: equ $ - strFalha                ; tamanho (constante, equ)

section .text
    global _start

_start:
    ; ---------- 1) pid = getpid() ----------
    mov rax, 39                 ; número da syscall sys_getpid
    syscall                     ; retorno: RAX = PID deste processo

    ; ---------- 2) kill(pid, 9) ----------
    mov rdi, rax                ; 1º argumento (rdi) = PID. Copiamos ANTES de
                                ; mexer em rax, que vai receber o número da próxima syscall
    mov rsi, 9                  ; 2º argumento (rsi) = sinal 9 (SIGKILL)
    mov rax, 62                 ; número da syscall sys_kill
    syscall                     ; o processo deve morrer aqui

    ; ---------- 3) só executa se o kill NÃO funcionou ----------
    mov rax, 1                  ; syscall WRITE
    mov rdi, 1                  ; saída padrão
    lea rsi, [strFalha]         ; endereço do texto
    mov edx, strFalhaL          ; quantidade de bytes
    syscall

fim:
    mov rax, 60                 ; syscall EXIT
    mov rdi, 0                  ; status 0
    syscall
