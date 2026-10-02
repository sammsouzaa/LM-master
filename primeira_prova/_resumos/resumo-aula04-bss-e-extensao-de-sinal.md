# Resumo – Aula 04: Variáveis Não Inicializadas e Estrutura de Programas

Disciplina: Linguagens de Montagem (Unioeste) · Profª Gabriela Stein

---

## 1. Revisão: estrutura na memória

Do endereço baixo para o alto:

**Instruções → Dados inicializados → Dados não inicializados → Heap → Memória livre → Pilha**

## 2. Dados não inicializados (`.bss`)

Em vez de **definir um valor**, só se **reserva espaço**:

```nasm
section .bss
    simbolo: tamanho quantidade
```

| Pseudo-instrução | Reserva (por unidade) |
|---|---|
| `resb` | 1 byte |
| `resw` | 2 bytes (word) |
| `resd` | 4 bytes (double word) |
| `resq` | 8 bytes (quad word) |

Comparação com `.data`:

| | `.data` | `.bss` |
|---|---|---|
| Seção | `section .data` | `section .bss` |
| Pseudo-instrução | `db`, `dw`, `dd`, `dq` | `resb`, `resw`, `resd`, `resq` |
| O que vem depois | o **valor** | a **quantidade** de unidades |

- Em `resb 3`, o `3` é a **quantidade** (3 bytes), e não um valor.
- Tamanho total = **quantidade × tamanho da unidade**.
- Em C, `char c;` equivale a `c: resb 1`.
- O `.bss` não ocupa espaço no arquivo executável, só reserva memória ao carregar. Trate como "sem valor pré-definido".
- Uso típico: resultados de contas e *buffers* (por exemplo, para a syscall `read`):

```nasm
section .bss
    buffer: resb 16
```

Exemplos de tamanho:

```nasm
n1: resb 1    ; 1 byte
n3: resb 3    ; 3 bytes
n4: resb 8    ; 8 bytes
n5: resw 1    ; 2 bytes
n6: resw 2    ; 4 bytes
n9: resd 1    ; 4 bytes
na: resd 2    ; 8 bytes
```

## 3. MOV com `.bss`

É **exatamente a mesma** instrução `MOV destino, fonte`. Memória → memória continua não existindo: passa-se por um registrador.

### Exemplo a04e01.asm

```nasm
section .data
    v1: db 0x61
    v2: dd 0x65646362

section .bss
    n1: resb 1
    n2: resd 1
    n3: resb 1

_start:
    mov al,  [v1]       ; al  = 0x61
    mov [n1], al
    mov [n3], al
    mov ebx, [v2]       ; ebx = 0x65646362
    mov [n2], ebx
```

## 4. Endereços na memória

- Dados inicializados ficam em endereços **mais baixos**; não inicializados, **mais altos**.
- Exemplo do slide (valores podem variar conforme máquina/montador):

| Seção | Endereço | Conteúdo |
|---|---|---|
| `.text` | `0x4000b0` | instruções |
| `.data` | `0x6000f8` | `v1` |
| | `0x6000f9` a `0x6000fc` | `v2` |
| `.bss` | `0x600100` | `n1` |
| | `0x600101` a `0x600104` | `n2` |
| | `0x600105` | `n3` |

## 5. Símbolos são endereços

- Cada **símbolo** de variável é uma **referência**, e toda referência é um **endereço de memória** (vale para `.data` e `.bss`).
- `[v1]` = conteúdo; `v1` = endereço.
- Para obter o endereço em tempo de execução: `LEA rax, [v1]`.
- Rótulos de **código** também são endereços.

### Exemplo a04e02.asm

```nasm
_start:
    mov al, [v1]        ; al  = 0x61 (conteúdo)
    lea r8, [v1]        ; r8  = endereço de v1

    lea r9, [v2]        ; r9  = endereço de v2
    mov rbx, [v2]       ; rbx = 8 bytes lidos a partir de v2
    mov rcx, [r9]       ; rcx = 8 bytes lidos no endereço guardado em r9

    lea r10, [_start]   ; endereço da 1ª instrução (ponto de entrada)
    lea r11, [fim]      ; endereço da instrução em "fim"
fim:
    ...
```

- **Registrador entre colchetes** (`[r9]`) = "vá até o endereço guardado nele" (ponteiro, como `*ptr` em C).
- `mov rbx, [v2]` lê 8 bytes mesmo que `v2` tenha 4: o tamanho vem do registrador, e os bytes extras são o que vier depois na memória.

## 6. Bases numéricas

| Base | Formas | Exemplo |
|---|---|---|
| Hexadecimal | `0x61` ou `61h` | `v1: dq 0x61` |
| Decimal | `97d` ou `97` | `v2: dq 97d` |
| Octal | `141o` | `v3: dq 141o` |
| Binário | `1100001b` | `v4: dq 1100001b` |

- Sem sufixo, o NASM assume **decimal**.
- Com sufixo `h`, se o número começar com letra, escreva `0` antes (`0FFh`).
- Todas as linhas acima guardam o **mesmo valor** (97), só escrito em bases diferentes.

No GDB: `x /[bhwg][cduxto] &<nomeVar>`

```
(gdb) x /gx &v1     ← hexadecimal
(gdb) x /gd &v2     ← decimal
(gdb) x /go &v3     ← octal
(gdb) x /gt &v4     ← binário
```

## 7. Números negativos: complemento de dois

Números são representados **sempre em complemento de dois**. Para negar:

1. escrever em binário;
2. **inverter** todos os bits;
3. **somar 1**.

```
 100  =  0110 0100
inverte: 1001 1011
 + 1     1001 1100   →  0x9C  (-100 em 8 bits)
```

Em 64 bits: `-100 = 0xFFFFFFFFFFFFFF9C`.

```nasm
section .data
    v1: dq 100d
    v2: dq -100d
```

```
(gdb) x /gx &v2     → 0xffffffffffffff9c
(gdb) x /gd &v2     → -100
(gdb) x /gu &v2     → 18446744073709551516
```

Os **bits são os mesmos**: `d` (com sinal) e `u` (sem sinal) mudam só a interpretação.

## 8. Copiar para um destino maior (n < p bytes)

### `MOVSX`: com extensão de sinal (valores com sinal)

Replica o **bit de sinal** para preencher o resto, mantendo o valor.

| Forma | Efeito |
|---|---|
| `MOVSX reg16, r/m8` | 1 → 2 bytes |
| `MOVSX reg32, r/m8` | 1 → 4 bytes |
| `MOVSX reg64, r/m8` | 1 → 8 bytes |
| `MOVSX reg32, r/m16` | 2 → 4 bytes |
| `MOVSX reg64, r/m16` | 2 → 8 bytes |
| `MOVSX reg64, r/m32` | 4 → 8 bytes (aparece como `movsxd` em outros manuais) |

(Os comentários do slide têm erros de digitação: com destino `reg64`, são **8 bytes**.)

### `MOVZX`: com extensão de zero (valores sem sinal)

Preenche o restante com **zeros**.

| Forma | Efeito |
|---|---|
| `MOVZX reg16, r/m8` | 1 → 2 bytes |
| `MOVZX reg32, r/m8` | 1 → 4 bytes |
| `MOVZX reg64, r/m8` | 1 → 8 bytes |
| `MOVZX reg32, r/m16` | 2 → 4 bytes |
| `MOVZX reg64, r/m16` | 2 → 8 bytes |

- **Não existe `movzx` com fonte de 32 bits** (`movzx rax, ebx` é erro).
- Motivo: escrever em um registrador de 32 bits **já zera os 32 bits de cima**, então o `mov` comum faz o trabalho.
- Quando a fonte é memória, o identificador `byte`/`word` é obrigatório: `movsx rax, word [var]`.

### Exemplo a04e05.asm

```nasm
mov   eax, -100       ; eax = 0xFFFFFF9C, rax = 0x00000000FFFFFF9C (4294967196)
movsx rcx, eax        ; rcx = 0xFFFFFFFFFFFFFF9C (-100)
```

`mov ecx, eax` daria `rcx = 4294967196`; a diferença é a razão de o `movsx` existir.

## 9. Qual instrução usar?

| Situação | Instrução |
|---|---|
| Mesmo tamanho (fonte e destino) | `mov` |
| 8 ou 16 → maior, **com sinal** | `movsx` |
| 8 ou 16 → maior, **sem sinal** | `movzx` |
| 32 → 64, **com sinal** | `movsx rax, ebx` |
| 32 → 64, **sem sinal** | `mov eax, ebx` |
| Só interessa a parte de baixo | `mov` simples |

Regras importantes:

- `mov rax, ebx` é **inválido**: o `mov` exige operandos de mesmo tamanho, e o processador não pode adivinhar se os bits que sobram devem ser zeros ou o sinal.
- `mov al, [v]` (ou `mov ax, ...`) **não mexe** nos demais bits do registrador, deixando "lixo" se você pretende usar o valor inteiro.
- `movzx ax, al` é válido (8 → 16 bits): zera o `ah` e preserva o resto de `rax`.
- Pergunta-guia: **"esse número pode ser negativo?"** Se sim, `movsx`.

## 10. Atividade a04a01: volume de um hexaedro

`volume = largura × altura × profundidade` (profundidade negativa, para exercitar sinais).

```nasm
section .data
    dimensoes: dw 50, 65, -75      ; largura, altura, profundidade
section .bss
    volume: resq 1
```

O cálculo (linhas 28 a 35) já vem pronto. O aluno deve:

1. Mover as dimensões para registradores (linhas 23 a 25):
   - `r8 ← dimensoes[0]`, `r9 ← dimensoes[1]`, `r10 ← dimensoes[2]`
2. Guardar o resultado em `volume` (linha 41): `volume ← ecx`.

Pontos de atenção:

- Cada elemento é um **word (2 bytes)**: índice 1 em `dimensoes + 2`, índice 2 em `dimensoes + 4`.
- Os registradores têm 64 bits e os dados 16, então é preciso **estender com sinal** (`movsx`), pois -75 é negativo. Com `movzx`, `0xFFB5` viraria 65461.

```nasm
movsx r8,  word [dimensoes]
movsx r9,  word [dimensoes + 2]
movsx r10, word [dimensoes + 4]
```

- **Armadilha na linha 41:** `volume` é `resq` (8 bytes), mas `ecx` tem 4. Só `mov [volume], ecx` escreve 4 bytes, e o `x /gd &volume` (que lê 8) mostraria **4294723546** em vez de **-243750**. Se só o `ecx` estiver correto, estenda o sinal:

```nasm
movsx rcx, ecx
mov   [volume], rcx
```

Verificação: 50 × 65 × -75 = **-243750**.

```
(gdb) b fim
(gdb) r
(gdb) x /gd &volume     → -243750
```

## Resumo rápido

- `.bss` reserva espaço (`resb`/`resw`/`resd`/`resq` + **quantidade**); `.data` define valores.
- Símbolos são endereços: `[v]` conteúdo, `v` endereço, `[reg]` ponteiro.
- Bases: `0x`/`h`, `d`, `o`, `b`; sem sufixo = decimal.
- Negativos em **complemento de dois**; `d` e `u` mudam só a interpretação.
- `movsx` estende o sinal; `movzx` estende com zeros (fonte de 8 ou 16 bits).
- 32 → 64 sem sinal: `mov eax, ebx`; com sinal: `movsx rax, ebx`.
- `mov` exige operandos de mesmo tamanho.

## Próxima aula

**Aula 05: Operações Aritméticas e Lógicas.**
