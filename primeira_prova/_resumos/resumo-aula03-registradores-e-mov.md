# Resumo – Aula 03: Registradores e Instrução MOV

Disciplina: Linguagens de Montagem (Unioeste) · Profª Gabriela Stein

---

## 1. Hierarquia das memórias

Combina memórias **grandes, baratas e lentas** com memórias **rápidas, caras e pequenas**.

| Nível | Tipo | Latência | Velocidade | Custo | Capacidade |
|---|---|---|---|---|---|
| 1 (topo) | **Registradores** | menor | maior | maior | menor |
| 2 | Cache | | | | |
| 3 | Memória principal (RAM) | | | | |
| 4 | Memória secundária (discos) | | | | |
| 5 (base) | Memória terciária (fitas) | maior | menor | menor | maior |

Aprofundamento em Organização e Arquitetura de Computadores. Para esta disciplina: **registradores são o topo da hierarquia**.

## 2. Registradores

- Tipo de memória **mais rápida** dos sistemas computacionais.
- Fazem parte do **núcleo do processador**.

## 3. Classificação

| Tipo | Característica | Exemplos |
|---|---|---|
| **Visíveis** ao programador | Usados para reduzir acessos à memória e otimizar código | Propósito geral, controle |
| **Não visíveis** | Controlam o fluxo interno; só programas privilegiados do S.O. acessam | **PC**, **MAR**, **MBR** |

Entre os visíveis:

- **Propósito geral:** guardam dados e endereços usados em operações lógicas e aritméticas. Usados diretamente pelo programador.
- **Controle:** *flags* (condicionais) e ponteiros para segmentos/pilha. Normalmente não usados diretamente.

## 4. Registradores de propósito geral

| | x86 (32 bits) | x86_64 (64 bits) |
|---|---|---|
| **Gerais** | EAX, EBX, ECX, EDX | RAX, RBX, RCX, RDX, **R8 a R15** |
| **Segmentos** | ESI, EDI, EBP, ESP | RSI, RDI, RBP, RSP |

**O registrador é um único espaço físico** (4 bytes no x86, 8 bytes no x86_64). O que muda é o **modo de acesso**, em palavras de 1, 2, 4 ou 8 bytes.

### Nomes por tamanho

| Família | 64 bits | 32 bits | 16 bits | 8 bits |
|---|---|---|---|---|
| A, B, C, D | `rax` | `eax` | `ax` | `al` (e `ah`) |
| | `rbx` | `ebx` | `bx` | `bl` (e `bh`) |
| | `rcx` | `ecx` | `cx` | `cl` (e `ch`) |
| | `rdx` | `edx` | `dx` | `dl` (e `dh`) |
| Segmento | `rsi` | `esi` | `si` | `sil` |
| | `rdi` | `edi` | `di` | `dil` |
| | `rbp` | `ebp` | `bp` | `bpl` |
| | `rsp` | `esp` | `sp` | `spl` |
| R8 a R15 | `r8` | `r8d` | `r8w` | `r8b` (use `r8l` no GDB) |

- `r` = 64 bits, `e` = 32 bits, sem prefixo = 16 bits.
- `ah` = 8 bits **mais** significativos de `ax` (bits 8 a 15). Só existe em A, B, C, D.
- `al` = 8 bits **menos** significativos (bits 0 a 7).
- **Escrever em um registrador de 32 bits zera os 32 bits de cima.** Escrever em 16 ou 8 bits **preserva** o resto.

### Registradores de segmento

| Registrador | Papel |
|---|---|
| **RSI e RDI** | Fonte e destino em algumas instruções. Podem ser usados como propósito geral em instruções básicas. |
| **RBP e RSP** | Ponteiros especiais para a estrutura do programa (pilha). |

- `RBP` como propósito geral: **altamente não recomendado**.
- `RSP` como propósito geral: **normalmente fatal** para a aplicação.
- A função deles será vista em aulas futuras.

## 5. Exemplo: acesso ao RAX (`a03e01.asm`)

```nasm
section .data
    num: dq 0x7766554433221101

section .text
    global _start

_start:
    mov rax, [num]

fim:
    mov rax, 60
    mov rdi, 0
    syscall
```

Depois de `mov rax, [num]`:

| Nome | Hexa | Decimal |
|---|---|---|
| `rax` | `0x7766554433221101` | 8.603.657.889.541.918.977 |
| `eax` | `0x33221101` | 857.870.593 |
| `ax` | `0x1101` | 4353 |
| `ah` | `0x11` | 17 |
| `al` | `0x01` | 1 |

No GDB (registradores levam `$`):

```
(gdb) p/x $rax      ← hexadecimal
(gdb) p/d $rax      ← decimal
(gdb) p/x $eax
(gdb) p/x $ax
(gdb) p/x $al
```

## 6. Exemplo: R8 a R15 (`a03e02.asm`)

```nasm
_start:
    mov r8,  [num]     ; 64 bits: r8  = 0x7766554433221101
    mov r9d, [num]     ; 32 bits: r9d = 0x33221101 (r9 fica 0x0000000033221101)
```

## 7. A instrução MOV

```nasm
MOV destino, fonte
```

- **Copia** os dados da fonte para o destino (a fonte não é apagada).
- O **tamanho da cópia é decidido pelo registrador** envolvido.

Notação:

| Símbolo | Significado |
|---|---|
| `reg8/16/32/64` | registrador do tamanho indicado |
| `r/m8/16/32/64` | **r**egistrador **ou** **m**emória |
| `imm8/16/32/64` | valor **imediato** (número escrito no código) |
| `[v1]` | **conteúdo** de `v1` |
| `v1` (sem colchetes) | **endereço** de `v1` |

Nos exemplos: `v1: dq 0x1111111122334455`, `v2: dq 0`, `v3: dq 0`.

### Parte 1: memória → registrador

```nasm
MOV al,  [v1]    ; al  = 0x55
MOV ebx, [v1]    ; ebx = 0x22334455
MOV rcx, [v1]    ; rcx = 0x1111111122334455
```

### Parte 2: registrador → memória

```nasm
MOV [v2], al
MOV [v2], ebx
MOV [v2], rcx
```

### Parte 3: imediato → registrador

```nasm
MOV al,  0x10
MOV ebx, 0x20202020
MOV rcx, 0x3030303030303030
```

### Parte 4: imediato → memória

```nasm
MOV byte  [v3], 0x10
MOV word  [v3], 0x1515
MOV dword [v3], 0x20202020
```

- Sem registrador na instrução, o **identificador de tamanho** (`byte`, `word`, `dword`) é **obrigatório**.
- O processador não tem imediato de 64 bits para memória. Alternativa: passar por um registrador (`mov rax, imm64` e depois `mov [v3], rax`).

### Regras importantes

- **Não existe memória → memória** em uma só instrução. Use um registrador como intermediário:

```nasm
mov ax, [var2]      ; tamanho vem do ax (16 bits)
mov [var1], ax
```

- `mov word [var1], [var2]` é **inválido**.
- Registrador → registrador (`mov rax, rbx`) é válido, pois `r/m` inclui registrador.
- **Colchetes são obrigatórios no NASM** para acessar o conteúdo:

| Quero... | Escrevo |
|---|---|
| Ler o valor de `num1` | `mov rax, [num1]` |
| Gravar em `resultado` | `mov [resultado], rax` |
| Pegar o endereço de `num1` | `lea rax, [num1]` (ou `mov rax, num1`) |

- `mov resultado, rax` é **erro** de montagem.
- `mov rax, num1` monta, mas copia o **endereço**, e não o valor (erro silencioso).
- Em MASM/TASM é o contrário: o nome sozinho já é o conteúdo.

## 8. MOV vs LEA

**LEA** (*Load Effective Address*) calcula um **endereço** e o guarda no destino, **sem acessar o conteúdo** da memória.

| Instrução | O que vai para o registrador |
|---|---|
| `mov r8, [vetorInt]` | o **conteúdo** de `vetorInt` |
| `lea r8, [vetorInt]` | o **endereço** de `vetorInt` (ponteiro) |

```nasm
section .data
    vetorInt: dd 42, 1, 2, 3, 4, 96, 6, 7, 8, 9    ; int vetorInt[10]

section .text
    global _start
_start:
    lea r8, [vetorInt]           ; r8 = endereço do vetor
    lea r9, [vetorInt + 5*4]     ; r9 = endereço do elemento 5
    mov eax, [r9]                ; eax = 96
```

- No x86_64 os endereços têm **8 bytes**: o destino deve ser registrador de 64 bits.
- Útil para vetores, matrizes e estruturas (tópico avançado, muito usado por compiladores).
- O comentário em C do slide (`{42,1,2,3,4,5,...}`) não bate com o `dd` (que tem `96` na posição 5).

## 9. Contas e entrada/saída

**Contas:** variáveis na memória guardam dados, mas a operação acontece nos registradores.

```nasm
mov rax, [num1]        ; memória → registrador
add rax, [num2]        ; rax = rax + num2
mov [resultado], rax   ; registrador → memória
```

**Syscalls:** o kernel só olha em registradores **fixos**.

| O que passar | Registrador |
|---|---|
| Número da syscall | `rax` |
| 1º argumento | `rdi` |
| 2º argumento | `rsi` |
| 3º argumento | `rdx` (ou `edx`) |

```nasm
; imprimir
mov rax, 1
mov rdi, 1
lea rsi, [texto]
mov edx, tamanho
syscall

; ler
mov rax, 0
mov rdi, 0
lea rsi, [buffer]
mov edx, 16
syscall
```

| Situação | Quem escolhe o registrador |
|---|---|
| Contas e armazenamento temporário | **Você** |
| Syscalls | **O kernel** (fixos) |

O `read` precisa de um espaço reservado (`buffer`), assunto da Aula 04.

## 10. Atividade: as 15 formas de MOV

Escrever um código funcional (montável e linkável) com **todas as 15 formas**:

| Parte | Forma | Qtd. | Variáveis |
|---|---|---|---|
| 1 | memória → registrador | 4 (8/16/32/64) | `pt1r8`, `pt1r16`, `pt1r32`, `pt1r64` |
| 2 | registrador → memória | 4 | `pt2m8`, `pt2m16`, `pt2m32`, `pt2m64` |
| 3 | imediato → registrador | 4 | nenhuma |
| 4 | imediato → memória | 3 (8/16/32) | `pt4m8`, `pt4m16`, `pt4m32` |

Total: 4 + 4 + 4 + 3 = **15**. O uso de LEA é opcional.

```nasm
section .data
    pt1r8  : db 0x10
    pt1r16 : dw 0x2020
    pt1r32 : dd 0x30303030
    pt1r64 : dq 0x4040404040404040

    pt2m8  : db 0x00
    pt2m16 : dw 0x0000
    pt2m32 : dd 0x00000000
    pt2m64 : dq 0x0000000000000000

    pt4m8  : db 0x00
    pt4m16 : dw 0x0000
    pt4m32 : dd 0x00000000

section .text
    global _start

_start:
    ; parte 1: memória → registrador
    mov al,  [pt1r8]
    mov bx,  [pt1r16]
    mov ecx, [pt1r32]
    mov rdx, [pt1r64]

    ; parte 2: registrador → memória
    mov [pt2m8],  al
    mov [pt2m16], bx
    mov [pt2m32], ecx
    mov [pt2m64], rdx

    ; parte 3: imediato → registrador
    mov al,  0x10
    mov bx,  0x1515
    mov ecx, 0x20202020
    mov rdx, 0x3030303030303030

    ; parte 4: imediato → memória
    mov byte  [pt4m8],  0x10
    mov word  [pt4m16], 0x1515
    mov dword [pt4m32], 0x20202020

fim:
    mov rax, 60
    mov rdi, 0
    syscall
```

**Debug obrigatório** (confirmar valores em memória e registradores, usando breakpoints):

| Comando | Para quê |
|---|---|
| `p /d $reg` | registrador em decimal |
| `p /x $reg` | registrador em hexadecimal |
| `x /d &end` | memória em decimal |
| `x /[bhwg]d &end` | memória em decimal, escolhendo o tamanho |

## Resumo rápido

- Registradores: topo da hierarquia, únicos espaços físicos de 64 bits com acessos de 8, 16, 32 e 64 bits.
- Nomes: `r` = 64, `e` = 32, sem prefixo = 16, `l` = 8 (e `r8d`/`r8w`/`r8b` para R8 a R15).
- `mov` copia o conteúdo; `lea` carrega o endereço.
- O tamanho da cópia vem do registrador; sem registrador, use `byte`/`word`/`dword`.
- Memória → memória não existe: use um registrador.
- Colchetes `[ ]` = conteúdo; nome sozinho = endereço.
- Contas passam por registradores; syscalls usam `rax`, `rdi`, `rsi`, `rdx`.

## Próxima aula

**Aula 04 – Variáveis não inicializadas e estrutura de programas:** nova seção para declarar espaços de memória e novas pseudo-instruções de reserva de memória.
