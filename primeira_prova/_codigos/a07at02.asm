; ==========================================================
; a07at02.asm - Endless Stamina Parrot Code
;
; Pede para o usuário digitar algo:
;   - se for diferente de "quit": repete o que foi digitado e pede de novo
;   - se for igual a "quit": encerra o programa
;
; Mantém as correções da a07at01 (uma só quebra de linha e buffer do
; teclado esvaziado a cada leitura).
;
; Ideia da comparação: uma string em C/assembly é um vetor de caracteres
; TERMINADO EM 0. O read NÃO coloca o 0 no fim e INCLUI o Enter (10).
; Então, depois de ler, nós:
;   1) descobrimos o tamanho do texto sem o Enter;
;   2) colocamos um 0 logo depois do texto (no lugar do Enter, se houver);
;   3) comparamos byte a byte com "quit", que também termina em 0.
; ==========================================================

%define maxChars 20

section .data
    strPedido: db "Digite algo (quit para sair): "
    strPedidoL: equ $ - strPedido

    strBye : db "Voce digitou: "
    strByeL: equ $ - strBye

    strLF  : db 10
    strLFL : equ $ - strLF

    strQuit: db "quit", 0                ; string terminada em 0

section .bss
    texto: resb maxChars + 1             ; +1 para sempre caber o 0 final
    lixo : resb 1

section .text
    global _start

_start:
inicio:
    ; ---------- pede o texto ----------
    mov rax, 1
    mov rdi, 1
    lea rsi, [strPedido]
    mov edx, strPedidoL
    syscall

    ; ---------- leitura ----------
    mov rax, 0
    mov rdi, 0
    lea rsi, [texto]
    mov edx, maxChars
    syscall                              ; RAX = bytes lidos
    mov r12, rax                         ; R12 = bytes lidos

    cmp r12, 0                           ; fim da entrada (Ctrl+D): encerra
    jle fim

    ; ---------- termina a string com 0 e acerta o tamanho ----------
    cmp byte [texto + r12 - 1], 10       ; o último byte lido é o Enter?
    jne truncado                         ; não: o texto foi cortado

    dec r12                              ; sim: o tamanho não conta o Enter
    mov byte [texto + r12], 0            ; troca o Enter por 0 (fim da string)
    jmp compara

truncado:
    mov byte [texto + r12], 0            ; coloca o 0 depois do último caractere
                                         ; (por isso o buffer tem maxChars + 1)
esvazia:                                 ; descarta o resto da linha no teclado
    mov rax, 0
    mov rdi, 0
    lea rsi, [lixo]
    mov edx, 1
    syscall
    cmp rax, 0
    jle compara                          ; fim da entrada
    cmp byte [lixo], 10
    jne esvazia

compara:
    ; ---------- texto == "quit" ? (comparação byte a byte) ----------
    mov rbx, 0                           ; RBX = índice (não usamos RCX: o syscall o altera)
cmpQuit:
    mov al, [texto + rbx]                ; caractere do texto digitado
    cmp al, [strQuit + rbx]              ; caractere correspondente de "quit"
    jne repete                           ; diferentes: não é "quit"
    cmp al, 0                            ; iguais; chegamos ao 0 final das duas strings?
    je fim                               ; sim: o texto é exatamente "quit"
    inc rbx                              ; não: próximo caractere
    jmp cmpQuit

repete:
    ; ---------- "Voce digitou: " + texto + quebra de linha ----------
    mov rax, 1
    mov rdi, 1
    lea rsi, [strBye]
    mov edx, strByeL
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [texto]
    mov rdx, r12                         ; tamanho SEM o Enter
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [strLF]                     ; a única quebra de linha da saída
    mov edx, strLFL
    syscall

    jmp inicio                           ; pede de novo (laço "infinito" até digitar quit)

fim:
    mov rax, 60
    mov rdi, 0
    syscall
