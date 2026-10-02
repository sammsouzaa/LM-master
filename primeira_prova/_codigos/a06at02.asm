; ==========================================================
; a06at02.asm - Papagali Persistente
;
; Lê uma linha do teclado e a ESCREVE AO FINAL de "papagali.txt".
;   - Se o arquivo não existir, é criado (O_CREAT)
;   - Se existir, o texto é adicionado ao final (O_APPEND)
;
; Fluxo:  write (pergunta) -> read (teclado) -> open -> write (arquivo) -> close
;
; Flags do open (TODOS em OCTAL; sufixo 'o' no NASM):
;   O_CREAT  = 0100o   (cria se não existir; exige o modo em RDX)
;   O_WRONLY = 0001o   (só escrita)
;   O_APPEND = 2000o   (escreve sempre no final)
;   soma     = 2101o
; Modo (permissões) = 0644o -> -rw-r--r-- (dono lê/escreve, outros só leem)
;
; ATENÇÃO aos registradores: o syscall sobrescreve RAX (resultado) e
; também RCX e R11. Por isso guardamos os valores importantes em R12 e R13,
; que o kernel preserva.
; ==========================================================

%define maxChars   100          ; máximo de caracteres lidos (inclui o Enter)
%define flagsOpen  2101o        ; O_CREAT + O_WRONLY + O_APPEND (octal)
%define modoArq    0644o        ; permissões do arquivo criado (octal)

section .data
    strOla  : db "Digite algo: "
    strOlaL : equ $ - strOla            ; tamanho (constante, equ)

    fileName: db "papagali.txt", 0      ; string terminada em zero (obrigatório no open)

section .bss
    texto: resb maxChars                ; buffer onde o read guarda o que foi digitado

section .text
    global _start

_start:
    ; ---------- 1) mostra o pedido na tela ----------
    mov rax, 1                  ; WRITE
    mov rdi, 1                  ; stdout
    lea rsi, [strOla]           ; texto
    mov edx, strOlaL            ; tamanho
    syscall

    ; ---------- 2) lê do teclado ----------
    mov rax, 0                  ; READ
    mov rdi, 0                  ; file descriptor 0 = stdin (teclado)
    lea rsi, [texto]            ; buffer de destino
    mov edx, maxChars           ; máximo de bytes a ler
    syscall                     ; RAX = quantidade lida (inclui o Enter, 10)
    mov r12, rax                ; guarda a quantidade lida em R12 (RAX será sobrescrito)

    ; ---------- 3) abre/cria papagali.txt em modo append ----------
    mov rax, 2                  ; OPEN
    lea rdi, [fileName]         ; caminho do arquivo
    mov esi, flagsOpen          ; flags: criar + só escrita + append
    mov edx, modoArq            ; permissões (usadas quando o arquivo é criado)
    syscall                     ; RAX = file descriptor (ou valor negativo se falhar)
    mov r13, rax                ; guarda o descriptor em R13

    ; ---------- 4) escreve o texto lido no arquivo ----------
    mov rax, 1                  ; WRITE
    mov rdi, r13                ; descriptor do arquivo (e não mais 1 = tela)
    lea rsi, [texto]            ; o mesmo buffer lido do teclado
    mov rdx, r12                ; escreve apenas a quantidade que foi lida
    syscall

    ; ---------- 5) fecha o arquivo ----------
    mov rax, 3                  ; CLOSE
    mov rdi, r13                ; descriptor a fechar
    syscall

fim:
    mov rax, 60                 ; EXIT
    mov rdi, 0                  ; status 0
    syscall

; Observação: não há tratamento de erro (ex.: open falhar). Isso exige
; desvios condicionais (jumps), assunto da Aula 07.
; Para conferir o resultado:  cat papagali.txt
