# Resumo - Aula 06: Chamadas de Sistema

**Disciplina:** Linguagens de Montagem (NASM x86-64)
**Professora:** Gabriela Stein

---

## 1. Hello World

```nasm
section .data
    strOla : db "Ola", 10          ; texto + quebra de linha (10 = LF)
    strOlaL: equ $ - strOla        ; tamanho em bytes

section .text
    global _start
_start:
    mov rax, 1                     ; syscall WRITE
    mov rdi, 1                     ; saída padrão
    lea rsi, [strOla]              ; endereço do texto
    mov edx, strOlaL               ; quantidade de bytes
    syscall
fim:
    mov rax, 60                    ; syscall EXIT
    mov rdi, 0                     ; status
    syscall
```

**`equ`, `$`:**
- `equ` é uma pseudo-instrução de **equivalência** (constante definida na montagem).
- `$` significa "aqui" (posição atual).
- `$ - strOla` = tamanho em bytes do texto.
- Uma constante `equ` **não ocupa memória**: usa-se `mov edx, strOlaL` (imediato), nunca `[strOlaL]`.

---

## 2. Syscall e Kernel

- `syscall` é a chamada de sistema padrão dos S.O.s x86/Unix de 64 bits.
- Serve para **pedir serviços ao kernel**.
- **Kernel:** componente central do S.O.; gerencia os recursos de hardware para os programas: **processador**, **entrada/saída** (monitor/teclado) e **memória**.
- Camadas (de baixo para cima): **hardware → firmware → kernel → sistema operacional → softwares**.

### Convenção de registradores

| Registrador | Papel |
|---|---|
| `rax` | **Número** da syscall (na ida) e **retorno** (na volta) |
| `rdi` | 1º argumento |
| `rsi` | 2º argumento |
| `rdx` | 3º argumento |
| `r10` | 4º argumento (**não** é `rcx`) |
| `r8` | 5º argumento |
| `r9` | 6º argumento |

---

## 3. Syscalls estudadas

| Syscall | `rax` | `rdi` | `rsi` | `rdx` | Retorno em `rax` |
|---|---|---|---|---|---|
| **read** | 0 | fd (0 = teclado) | buffer | máx. de bytes | bytes lidos (inclui o Enter) |
| **write** | 1 | fd (1 = tela) | buffer | nº de bytes | bytes escritos |
| **open** | 2 | caminho (termina em `0`) | flags | modo (permissões) | file descriptor ou -1 |
| **close** | 3 | fd | - | - | 0 ou -1 |
| **getpid** | 39 | - | - | - | PID do processo |
| **exit** | 60 | status | - | - | (não retorna) |
| **kill** | 62 | PID | sinal | - | 0 ou erro |

**File descriptors padrão:** `0` = stdin (entrada), `1` = stdout (saída), `2` = stderr (erro).

### WRITE
```c
ssize_t write(int fd, const void *buf, size_t count);   // rdi, rsi, rdx
```

### READ
```c
ssize_t read(int fd, void *buf, size_t count);          // rdi, rsi, rdx
```
- `rdx` é o **máximo** de caracteres lidos.
- O **Enter** termina a entrada e **conta como caractere** (valor 10).
- Se digitar mais que o máximo, o excedente fica pendente no terminal.

### EXIT
```c
void _exit(int status);                                  // rdi
```
- O status volta ao S.O.; veja com `echo $?` depois da execução.

### OPEN e CLOSE
```c
int open(const char *pathname, int flags, mode_t mode); // rdi, esi, edx
int close(int fd);                                       // edi
```
- O nome do arquivo precisa ser **string terminada em zero** (`db "arq.txt", 0`).
- O descriptor devolvido em `rax` é usado nas chamadas seguintes (`read`, `write`, `close`).

---

## 4. Flags do `open()` (Anexo)

**Todos os valores estão em OCTAL.**

| Flag | Valor (octal) | Significado |
|---|---|---|
| `O_RDONLY` | 0 | Só leitura |
| `O_WRONLY` | 1 | Só escrita |
| `O_RDWR` | 2 | Leitura e escrita |
| `O_CREAT` | 100 | Cria o arquivo se não existir (exige o modo em `rdx`) |
| `O_APPEND` | 2000 | Adiciona ao final do arquivo existente |

- As flags se combinam somando (ou `OR`): `O_CREAT + O_WRONLY + O_APPEND` = **`2101`**.
- Modo padrão `0644` = `-rw-r--r--` (dono lê/escreve, os outros só leem).
- No NASM, octal se escreve com sufixo `o` ou `q` (`2101o`, `0644o`) ou prefixo `0o`. Sem marcação, o NASM lê como **decimal**.

---

## 5. Pré-processador (`%define`)

```nasm
%define maxChars 10
```

- Avaliador léxico que **substitui texto** antes da montagem.
- Toda ocorrência de `maxChars` a partir da linha do `%define` vira `10`.
- Não ocupa memória e não existe durante a execução (similar ao `#define` do C).

---

## 6. Exemplos

### a06e01.asm: "repeater"
Lê o que o usuário digita e mostra de volta ("Voce digitou: ...").
- Usa `strOlaL: equ ...` (constante) e `strLFL: db 1` (variável real na memória).
- No debugger (breakpoints em **leitura**, **resposta** e **fim**), o valor de `RAX` mostra os bytes lidos/escritos.

### a06e02.asm: abrir arquivo
Abre `a06e02.txt` com `open` (rax = 2), passando nome, flags (`openrw`) e modo (`userWR`).

---

## 7. Registradores "clobbered" (sobrescritos pelo syscall)

Segundo a ABI x86-64 (Seção A.2, págs. 142 e 143):
1. Argumentos: `rdi, rsi, rdx, r10, r8, r9`.
2. O `syscall` **destrói `rcx` e `r11`**; preserva os outros, **exceto `rax`**.
3. O número da syscall vai em `rax`.
4. No máximo **6 argumentos**, todos em registradores.
5. Retorno em `rax`; valor entre **-4095 e -1** indica **erro** (`-errno`).

O `nolibc.h` (linha 268) é mais cauteloso: `rcx` e `r8..r11` **podem** ser sobrescritos.

**Na prática:** não deixe valores importantes em `rcx`/`r11` através de um `syscall`. Guarde em `rbx`, `r12`, `r13` etc., e copie o que precisar de `rax` antes da próxima chamada.

---

## 8. Atividades

### a06at01: o programa mata a si mesmo
1. `getpid` (39) → PID em `rax`.
2. `mov rdi, rax` (PID), `mov rsi, 9` (SIGKILL), `mov rax, 62` → `syscall`.
3. Depois do `kill`, um `write` com `"this isn't working!"`: se a frase aparecer, o kill falhou.
4. `echo $?` mostra **137** (128 + 9).

### a06at02: Papagali Persistente
1. `write` do pedido na tela.
2. `read` do teclado (`rdi = 0`); guardar `rax` (bytes lidos) em outro registrador.
3. `open` de `papagali.txt` com flags **`2101o`** e modo **`0644o`**; guardar o descriptor.
4. `write` no descriptor do arquivo, usando como tamanho os bytes lidos.
5. `close` do descriptor.

---

## 9. Pontos de atenção (imprecisões nos slides)

- No exemplo do `read`, o slide usa `mov rdi, 1`; o correto para ler do teclado é **`0` (stdin)**.
- O protótipo do `read` aparece com `const void *buf`; o buffer é **escrito** pelo kernel, então seria `void *buf`.
- Na flag `O_CREAT`, a permissão "-rx-r–r" é erro de digitação: `0644` é **`-rw-r--r--`**.
- O slide não informa o número do `close` (**3**).

---

## 10. Cola rápida

| Quero... | Faço |
|---|---|
| Escrever na tela | `rax=1`, `rdi=1`, `rsi=buffer`, `rdx=tamanho` |
| Ler do teclado | `rax=0`, `rdi=0`, `rsi=buffer`, `rdx=máximo` |
| Abrir/criar arquivo | `rax=2`, `rdi=nome`, `rsi=flags (octal)`, `rdx=modo` |
| Fechar arquivo | `rax=3`, `rdi=fd` |
| Descobrir o PID | `rax=39` |
| Enviar sinal a um processo | `rax=62`, `rdi=PID`, `rsi=sinal` |
| Encerrar o programa | `rax=60`, `rdi=status` |
| Ver o status de saída | `echo $?` |
| Saber o tamanho de um texto | `nome: equ $ - texto` |
| Constante do pré-processador | `%define NOME valor` |

---

**Próxima aula (07):** Controle de Fluxo de Execução: fluxo de execução, labels e laços de repetição.
