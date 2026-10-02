; ==========================================================
; a07at01.asm - Parrot Code (versão CORRIGIDA)
;
; O programa lê o que o usuário digita e repete na tela.
;
; BUG 1 (corrigido): se o usuário digitar MAIS que maxChars caracteres,
;   o read pega só maxChars e o RESTO fica no buffer do teclado, sendo
;   "despejado" no terminal quando o programa termina.
;   -> CORREÇÃO: depois do read, se o texto veio truncado (sem o Enter no
;      final), continuamos lendo e DESCARTANDO até encontrar o Enter (10).
;
; BUG 2 (corrigido): se o usuário digitar MENOS que maxChars, o Enter (10)
;   já veio dentro do buffer, e o programa ainda imprimia a strLF -> duas
;   quebras de linha.
;   -> CORREÇÃO: olhamos o ÚLTIMO byte lido. Se for 10, a quebra de linha
;      já vai ser impressa junto com o texto e NÃO imprimimos strLF.
;      Se não for 10, imprimimos UMA strLF.
;
; Resultado: sempre exatamente UMA quebra de linha e buffer vazio no fim.
;
; Montar:  nasm -f elf64 a07at01.asm && ld a07at01.o -o a07at01.x
; Teste:   digite poucos caracteres, exatamente 10, e bem mais que 10
; ==========================================================

%define maxChars 10

section .data
    strOla : db "Hello?", 10
    strOlaL: equ $ - strOla              ; constante (equ): tamanho do texto

    strBye : db "Voce digitou: "
    strByeL: equ $ - strBye

    strLF  : db 10                       ; quebra de linha ASCII
    strLFL : equ $ - strLF

section .bss
    texto: resb maxChars                 ; buffer onde o read guarda o que foi digitado
    lixo : resb 1                        ; 1 byte usado para descartar o excesso

section .text
    global _start

_start:
    ; ---------- pergunta ----------
    mov rax, 1                           ; WRITE
    mov rdi, 1                           ; stdout
    lea rsi, [strOla]
    mov edx, strOlaL
    syscall

    ; ---------- leitura ----------
    mov rax, 0                           ; READ
    mov rdi, 0                           ; stdin (teclado)
    lea rsi, [texto]
    mov edx, maxChars                    ; no máximo maxChars bytes
    syscall                              ; RAX = quantidade lida (inclui o Enter, se veio)
    mov r12, rax                         ; guarda a quantidade em R12 (o syscall mexe em RAX)

    cmp r12, 0                           ; 0 = fim de entrada (Ctrl+D): nada a repetir
    jle fim

    ; ---------- resposta: "Voce digitou: " + texto lido ----------
    mov rax, 1
    mov rdi, 1
    lea rsi, [strBye]
    mov edx, strByeL
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [texto]
    mov rdx, r12                         ; imprime só o que foi realmente lido
    syscall

    ; ---------- o último byte lido é o Enter (10)? ----------
    cmp byte [texto + r12 - 1], 10
    je fim                               ; SIM: a quebra de linha já foi impressa junto
                                         ;      com o texto, e o buffer do teclado já está vazio

    ; NÃO: o texto foi truncado. Imprime UMA quebra de linha...
    mov rax, 1
    mov rdi, 1
    lea rsi, [strLF]
    mov edx, strLFL
    syscall

    ; ... e esvazia o buffer do teclado: lê 1 byte por vez e descarta
    ; até encontrar o Enter (ou o fim da entrada).
esvazia:
    mov rax, 0                           ; READ
    mov rdi, 0
    lea rsi, [lixo]
    mov edx, 1                           ; 1 byte por vez
    syscall
    cmp rax, 0                           ; RAX <= 0: fim da entrada ou erro
    jle fim
    cmp byte [lixo], 10                  ; encontrou o Enter?
    jne esvazia                          ; não: continua descartando

fim:
    mov rax, 60                          ; EXIT
    mov rdi, 0
    syscall
