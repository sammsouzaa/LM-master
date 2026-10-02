section .data
    ; Define uma variável chamada "strNome".
    ; db = "define bytes", ou seja, reserva/escreve bytes na memória.
    ;
    ; Aqui estamos armazenando:
    ; "Hello World!" + 10
    ;
    ; O número 10 é o código ASCII de '\n' (quebra de linha).
    strNome : db "Hello World!", 10

    ; "equ" cria uma constante.
    ;
    ; "$" representa a posição atual dentro da seção.
    ; "$ - strNome" calcula quantos bytes existem desde o início
    ; de strNome até a posição atual.
    ;
    ; Resultado:
    ; "Hello World!" = 12 caracteres
    ; "\n"           = 1 byte
    ; -----------------------
    ; total          = 13 bytes
    strNomeL: equ $ - strNome


section .text

    ; Torna "_start" visível para o linker.
    ;
    ; "_start" será o ponto de entrada do programa.
    ; É onde o Linux começará a executar nosso código.
    global _start


_start:

    ; ==========================================================
    ; SYSCALL write()
    ; ==========================================================
    ;
    ; Queremos executar:
    ;
    ; write(1, strNome, strNomeL);
    ;
    ; No Linux x86-64, a syscall write possui número 1.
    ;
    ; rax = número da syscall
    mov rax, 1

    ; rdi = primeiro argumento da syscall
    ;
    ; Para write(), o primeiro argumento é:
    ; fd (file descriptor)
    ;
    ; 0 = stdin  -> entrada
    ; 1 = stdout -> saída padrão (terminal)
    ; 2 = stderr -> saída de erro
    ;
    ; Portanto:
    ; rdi = 1 -> vamos escrever no terminal.
    mov rdi, 1

    ; rsi = segundo argumento da syscall
    ;
    ; Para write(), o segundo argumento é:
    ; endereço do conteúdo que será escrito.
    ;
    ; "strNome" representa o endereço onde
    ; "Hello World!\n" está armazenado.
    mov rsi, strNome

    ; rdx = terceiro argumento da syscall
    ;
    ; Para write(), o terceiro argumento é:
    ; quantidade de bytes que devem ser escritos.
    ;
    ; strNomeL = 13
    mov edx, strNomeL

    ; Executa a syscall.
    ;
    ; Neste momento o Linux recebe:
    ;
    ; rax = 1  -> write
    ; rdi = 1  -> stdout
    ; rsi = endereço de "Hello World!\n"
    ; rdx = 13 -> quantidade de bytes
    ;
    ; Equivalente em C:
    ;
    ; write(1, "Hello World!\n", 13);
    syscall


    ; ==========================================================
    ; SYSCALL exit()
    ; ==========================================================
    ;
    ; Agora precisamos encerrar o programa.
    ;
    ; No Linux x86-64:
    ; syscall 60 = exit
    ;
    ; Equivalente em C:
    ;
    ; exit(0);

    mov rax, 60

    ; rdi = código de saída do programa.
    ;
    ; 0 normalmente significa:
    ; execução terminou com sucesso.
    mov rdi, 0

    ; Executa a syscall exit.
    ;
    ; Depois dessa instrução, o programa termina.
    syscall