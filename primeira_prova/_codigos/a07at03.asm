; ==========================================================
; a07at03.asm - Persistent Endless Stamina Parrot Code (desafio)
;
; Acrescenta ao a07at02 a persistência em arquivo ("parrot.txt"):
;   - o arquivo é criado se não existir e aberto com O_APPEND
;   - a cada EXECUÇÃO é gravada a marcação "===="
;   - cada entrada digitada é gravada no arquivo e também repetida na tela
;   - o texto de encerramento é "q!" (ele NÃO é gravado)
;   - entradas vazias (só Enter) NÃO são gravadas
;   - se a entrada for IGUAL à anterior gravada, grava "*" no lugar
;
; Exemplo do arquivo depois de duas execuções:
;   ====
;   Parrot
;   Code
;   *
;   ====
;   com
;   3
;
; Decisões (o slide não detalha):
;   - uma entrada vazia não altera a "anterior" (como não é gravada,
;     a próxima é comparada com a última entrada que foi gravada);
;   - a primeira entrada de cada execução nunca vira "*", pois a "anterior"
;     começa vazia e entradas vazias nunca são gravadas.
;
; Registradores que atravessam os syscalls (o kernel só altera RAX, RCX e R11):
;   R12 = file descriptor do arquivo
;   R13 = tamanho do texto digitado (sem o Enter)
;   RBX = índice dos laços de comparação/cópia
; ==========================================================

%define maxChars  20
%define flagsOpen 2101o           ; O_CREAT + O_WRONLY + O_APPEND (octal)
%define modoArq   0644o           ; permissões do arquivo criado (octal)

; Macro: escreve(fd, buffer, tamanho) -> chama a syscall WRITE
; (evita repetir as 5 linhas do write a cada uso)
%macro escreve 3
    mov rax, 1                    ; syscall WRITE
    mov rdi, %1                   ; fd
    lea rsi, [%2]                 ; endereço do buffer
    mov rdx, %3                   ; quantidade de bytes
    syscall
%endmacro

section .data
    fileName : db "parrot.txt", 0         ; string terminada em 0 (exigência do open)

    strPedido : db "Digite algo (q! para sair): "
    strPedidoL: equ $ - strPedido
    strBye    : db "Voce digitou: "
    strByeL   : equ $ - strBye
    strLF     : db 10
    strLFL    : equ $ - strLF
    strMarca  : db "====", 10             ; marcação de início de execução
    strMarcaL : equ $ - strMarca
    strAst    : db "*", 10                ; no lugar de uma entrada repetida
    strAstL   : equ $ - strAst
    strSair   : db "q!", 0                ; texto de encerramento
    strErro   : db "Erro ao abrir o arquivo", 10
    strErroL  : equ $ - strErro

section .bss
    texto   : resb maxChars + 1           ; entrada atual (+1 para o 0 final)
    anterior: resb maxChars + 1           ; última entrada gravada
    lixo    : resb 1

section .text
    global _start

_start:
    ; ---------- abre (ou cria) o arquivo em modo append ----------
    mov rax, 2                            ; OPEN
    lea rdi, [fileName]
    mov esi, flagsOpen
    mov edx, modoArq
    syscall                               ; RAX = fd, ou valor negativo se falhar
    cmp rax, 0
    jl erroAbrir                          ; negativo: falhou
    mov r12, rax                          ; guarda o fd

    escreve r12, strMarca, strMarcaL      ; grava "====" (início desta execução)

inicio:
    ; ---------- pede e lê o texto ----------
    escreve 1, strPedido, strPedidoL

    mov rax, 0                            ; READ
    mov rdi, 0
    lea rsi, [texto]
    mov edx, maxChars
    syscall
    mov r13, rax                          ; R13 = bytes lidos
    cmp r13, 0                            ; fim da entrada (Ctrl+D): encerra
    jle fecha

    ; ---------- termina a string com 0 e esvazia o teclado (como na at02) ----------
    cmp byte [texto + r13 - 1], 10
    jne truncado
    dec r13                               ; tamanho sem o Enter
    mov byte [texto + r13], 0             ; Enter -> 0
    jmp testaSair

truncado:
    mov byte [texto + r13], 0
esvazia:
    mov rax, 0
    mov rdi, 0
    lea rsi, [lixo]
    mov edx, 1
    syscall
    cmp rax, 0
    jle testaSair
    cmp byte [lixo], 10
    jne esvazia

testaSair:
    ; ---------- texto == "q!" ? ----------
    mov rbx, 0
cmpSair:
    mov al, [texto + rbx]
    cmp al, [strSair + rbx]
    jne naoSair
    cmp al, 0
    je fecha                              ; é "q!": encerra (sem gravar)
    inc rbx
    jmp cmpSair

naoSair:
    ; ---------- repete na tela ----------
    escreve 1, strBye, strByeL
    escreve 1, texto, r13
    escreve 1, strLF, strLFL

    ; ---------- entrada vazia: não grava ----------
    cmp r13, 0
    je inicio

    ; ---------- texto == anterior ? ----------
    mov rbx, 0
cmpAnt:
    mov al, [texto + rbx]
    cmp al, [anterior + rbx]
    jne diferente
    cmp al, 0
    je repetida                           ; iguais até o 0 final
    inc rbx
    jmp cmpAnt

repetida:
    escreve r12, strAst, strAstL          ; grava "*" no lugar do texto repetido
    jmp inicio

diferente:
    ; guarda o texto atual como "anterior" (copia até o 0, inclusive)
    mov rbx, 0
copia:
    mov al, [texto + rbx]
    mov [anterior + rbx], al
    inc rbx
    cmp al, 0
    jne copia

    escreve r12, texto, r13               ; grava o texto no arquivo
    escreve r12, strLF, strLFL            ; e a quebra de linha
    jmp inicio

fecha:
    mov rax, 3                            ; CLOSE
    mov rdi, r12
    syscall
    jmp fim

erroAbrir:
    escreve 1, strErro, strErroL
    mov rax, 60                           ; EXIT com status 1 (erro)
    mov rdi, 1
    syscall

fim:
    mov rax, 60                           ; EXIT com status 0
    mov rdi, 0
    syscall
