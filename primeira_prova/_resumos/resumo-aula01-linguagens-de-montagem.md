# Resumo – Aula 01: Introdução a Linguagens de Montagem

Disciplina: Linguagens de Montagem (Unioeste) · Profª Gabriela Stein

---

## 1. Níveis de linguagem

| Nível | Característica |
|---|---|
| **Linguagem de máquina** (baixo nível) | Única que o computador realmente entende e executa. Composta por *strings* binárias. |
| **Linguagem de montagem** (código intermediário) | Transcrição de primeiro nível da linguagem de máquina, normalmente **1 para 1**. Usa textos e números para compreensão humana. |
| **Linguagem de alto nível** | Alto nível de abstração em relação à linguagem de montagem. |

**Comparação com o "Ola" (slide 3):**

| Versão | Tamanho |
|---|---|
| C (alto nível) | 43 bytes |
| Assembly | 341 bytes |
| Executável (máquina) | 8,9 KiB |

O executável é grande por causa dos cabeçalhos, tabelas e símbolos do formato **ELF**, e não só das instruções.

## 2. Por que estudar linguagem de montagem?

- Como as instruções são executadas?
- Como os dados são representados em memória?
- Como um programa interage com o S.O. e outros programas?
- Como o alto nível é traduzido para baixo nível? (ajuda a ser um melhor programador)
- Como é a arquitetura x86_64?

## 3. Arquitetura de Von Neumann

Quatro partes:

1. **Armazenamento** (memória)
2. **Unidade de processamento** (CPU)
3. **Movimentação de dados** (E/S)
4. **Controle do fluxo de dados** (conexões)

Programas e dados ficam na mesma memória.

## 4. Memória

- Guarda o sistema operacional e os programas e dados do usuário.
- Formada por "espaços" de **capacidade fixa: 8 bits (1 byte)**.
- Cada espaço tem um **endereço único**.
- Os bits de um byte são numerados de **7 a 0** (7 = mais significativo).

## 5. Unidade de processamento (CPU)

**Função:** ler instruções da memória (uma a uma) e executá-las.

**Componentes:**

| Sigla | Nome | Função |
|---|---|---|
| **PC** | Program Counter | Guarda o endereço da próxima instrução |
| **ID** | Instruction Decoder | Decodifica a instrução |
| **GP** | Registradores de propósito geral | Guardam dados de trabalho (`rax`, `rbx`...) |
| **MAR** | Memory Address Register | Guarda o endereço a ser acessado na memória |
| **MBR** | Memory Buffer Register | Guarda o dado lido/escrito na memória |
| **ULA** | Unidade Lógica e Aritmética | Faz as operações |

**Ciclo (slide 9):**

1. PC → MAR
2. MAR envia o endereço à memória
3. A instrução volta para o MBR
4. MBR → ID (decodifica)
5. ID coloca no MAR o endereço de um dado
6. MAR envia o endereço à memória
7. O dado volta para o MBR
8. MBR → registradores GP
9. Registradores → ULA
10. Resultado da ULA → registradores

Resumo: **buscar → decodificar → buscar operandos → executar → guardar resultado**.

## 6. Montador NASM

- *Netwide Assembler*, com sintaxe Intel simplificada e legível.
- Compatível com Windows e Linux.
- Gera programas x86 (32 bits) e x64 (64 bits).
- Para saber a arquitetura da máquina: `uname -m`
  - `i686` ou `i386` → 32 bits (x86)
  - `x86_64` → 64 bits (x64)

## 7. Sintaxe Intel vs AT&T

| | Intel | AT&T |
|---|---|---|
| Formato | `mnemônico destino, fonte` | `mnemônico fonte, destino` |
| Exemplo | `mov eax, 4` | `mov $4, %eax` |
| Montadores | NASM, TASM, MASM | GAS (`as`), nativo no Linux |

Na AT&T, imediatos levam `$`, registradores levam `%` e as instruções têm sufixo de tamanho (`movl` = 32 bits, `movq` = 64 bits).

> **Atenção:** no slide 12, o código AT&T termina com `movq $0, %rsi`. Pelo equivalente em Intel (`mov rdi, 0`), deveria ser `%rdi`. Provável erro de digitação do slide.

## 8. Hello World em NASM (Intel)

```nasm
section .data
    strOla : db "Ola", 10          ; "Ola" + quebra de linha (10 = \n)
    strOlaL: equ $ - strOla        ; tamanho da string

section .text
    global _start                  ; ponto de entrada visível ao linkador

_start:
    mov rax, 1                     ; syscall write
    mov rdi, 1                     ; fd 1 = saída padrão (tela)
    lea rsi, [strOla]              ; endereço da string
    mov edx, strOlaL               ; quantidade de bytes
    syscall

    mov rax, 60                    ; syscall exit
    mov rdi, 0                     ; código de retorno 0
    syscall
```

| Elemento | Significado |
|---|---|
| `section .data` | Dados inicializados |
| `section .text` | Código (instruções) |
| `db` | *define byte*: reserva e preenche bytes |
| `equ` | Define uma constante em tempo de montagem |
| `$` | Endereço atual |
| `$ - strOla` | Tamanho da string (endereço atual − início) |
| `lea` | Carrega o **endereço**, não o conteúdo |
| `global _start` | Torna `_start` visível ao `ld` como ponto de entrada |
| `syscall` | Passa o controle ao kernel |

O `exit` é obrigatório: sem ele, a CPU continuaria executando bytes após o fim do código (*segmentation fault*).

## 9. Registradores x86_64

Registradores ficam **dentro da CPU**, guardam 64 bits e são muito mais rápidos que a RAM. Seus **nomes são fixos** pela arquitetura.

| 64 bits | 32 bits | 16 bits | 8 bits (baixo) |
|---|---|---|---|
| `rax` | `eax` | `ax` | `al` |
| `rbx` | `ebx` | `bx` | `bl` |
| `rcx` | `ecx` | `cx` | `cl` |
| `rdx` | `edx` | `dx` | `dl` |
| `rsi` | `esi` | `si` | `sil` |
| `rdi` | `edi` | `di` | `dil` |

Além desses, existem `rbp`, `rsp` (pilha) e `r8` a `r15`.

- `eax` é a **metade inferior de `rax`**, o mesmo registrador físico, só com outro tamanho.
- **Escrever em um registrador de 32 bits (`eax`) zera os 32 bits de cima.** Escrever em `ax` ou `al` **não** zera o resto.
- `rsp` e `rbp` merecem cuidado, pois o programa depende deles.
- **Rótulos** (`strOla`, `_start`...) são nomes que você escolhe. **Registradores** têm nomes fixos.

## 10. Syscalls no Linux x86_64

Convenção do kernel (não dá para trocar os registradores):

| O que passar | Registrador |
|---|---|
| Número da syscall | `rax` (ou `eax`) |
| 1º argumento | `rdi` |
| 2º argumento | `rsi` |
| 3º argumento | `rdx` |
| 4º argumento | `r10` |
| 5º argumento | `r8` |
| 6º argumento | `r9` |
| Valor de retorno | `rax` |

**Syscalls mais comuns:**

| Nº | Syscall | Argumentos |
|---|---|---|
| 0 | `read` | fd, buffer, tamanho |
| 1 | `write` | fd, buffer, tamanho |
| 2 | `open` | caminho, flags, modo |
| 3 | `close` | fd |
| 60 | `exit` | código de retorno |

- Os números **não precisam ser decorados**: consulte `man 2 write` ou o arquivo `unistd_64.h`.
- Mudam conforme a arquitetura (em x86 de 32 bits, `write` = 4 e `exit` = 1, via `int 0x80`).
- A instrução `syscall` **altera `rcx` e `r11`**, e o retorno vem em `rax`.
- Para guardar valores através de syscalls, use `rbx` ou `r12` a `r15`.
- Para o número da syscall, use `rax` ou `eax`, evite `ax` e `al`.

**Dica:** dê nomes aos números com `equ`:

```nasm
SYS_WRITE equ 1
SYS_EXIT  equ 60
STDOUT    equ 1

mov rax, SYS_WRITE
mov rdi, STDOUT
```

## 11. Compilar / Montar / Linkar / Executar

```bash
# C
gcc hello.c -o helloC.x

# Assembly (dois passos)
nasm -f elf64 hello.asm        # monta → hello.o
ld hello.o -o helloS.x         # linka → executável

# Executar
./helloC.x
./helloS.x

# Ver o código de retorno
echo $?
```

- `-f elf64`: gera objeto no formato ELF de 64 bits.
- `./`: indica ao Linux que o programa está no diretório atual.
- Compare os tamanhos com `ls -l`: o assembly costuma ficar bem menor (*Fast, Powerful and Small*).

## 12. Atividade AP0101

Elaborar um executável que **imprima seu nome** no terminal:

1. Partir do código Intel do Hello World.
2. Trocar a string de `.data` pelo nome (mantendo o `10` no final).
3. Montar, linkar e executar.
4. Se der erro: **anotar, avaliar e corrigir**.

```nasm
section .data
    strNome : db "Seu Nome Aqui", 10
    strNomeL: equ $ - strNome

section .text
    global _start

_start:
    mov rax, 1
    mov rdi, 1
    lea rsi, [strNome]
    mov edx, strNomeL
    syscall

    mov rax, 60
    mov rdi, 0
    syscall
```

## Próxima aula

**Aula 02 – Estrutura dos Programas:** como programas são armazenados em disco e carregados na memória (formato **ELF**), dados inicializados, montar/ligar/executar e debugger (**GDB**).
