# Resumo - Aula 05: Instruções Básicas Aritméticas e Lógicas

**Disciplina:** Linguagens de Montagem (NASM x86-64)
**Professora:** Gabriela Stein

---

## 1. Revisão das aulas anteriores

| Aula | Conteúdo |
|---|---|
| 01 | Montar, linkar e executar: `nasm -f elf64 nome.asm` → `ld nome.o -o nome.x` → `./nome.x` |
| 02 | Estrutura dos programas e dados inicializados (`section .data`) |
| 03 | Registradores e instrução de movimentação (`MOV reg64, r/m64`) |
| 04 | Dados não inicializados (`section .bss`) |

---

## 2. Soma e subtração

```nasm
ADD Destino, Fonte    ; Destino = Destino + Fonte
SUB Destino, Fonte    ; Destino = Destino - Fonte
```

- O destino funciona como **acumulador**.
- Formatos válidos: `reg, r/m` | `mem, reg` | `r/m, imm`. **Não existe `mem, mem`.**
- Tamanhos: 8, 16, 32 e 64 bits (imediato de até 32 bits).
- São operações **sinalizadas**: geram a flag **OF** (e também a CF).

**Exemplo a05e01:** `eax=10, ebx=20, ecx=30, edx=-2` → após as operações: `ebx=30`, `edx=8`, `ecx=20`, `eax=-10`.

---

## 3. Registrador FLAGS / EFLAGS

- Registrador especial de **estado** do processador.
- É alterado **indiretamente** por instruções aritméticas e lógicas.
- `FLAGS` = 16 bits (máquinas antigas); `EFLAGS` = 32 bits (retrocompatível).

| Flag | Significado | Importa para |
|---|---|---|
| **OF** (Overflow) | A operação estourou o intervalo **com sinal** | Aritmética sinalizada |
| **CF** (Carry) | Houve "vai um" para fora do operando | Aritmética não sinalizada |

**GDB:** `info register eflags` ou `i r eflags` (mostra só as flags ativas).

**Exemplo a05e02:**
- `ax = 0x7FFF` (32767) + 1 → `0x8000` (-32768) → **OF = 1**
- `bx = 0xFFFF` (65535) + 1 → `0` → **CF = 1**

> O processador calcula as duas flags; quem decide qual olhar é o programador, conforme trate o número com ou sem sinal.

---

## 4. INC e DEC

```nasm
INC Destino    ; Destino++
DEC Destino    ; Destino--
```

> Detalhe extra: `INC` e `DEC` **não alteram a CF**.

---

## 5. Instruções lógicas

### AND, OR, XOR (bit a bit)

```nasm
AND reg, r/m/i        AND mem, r/i
OR  reg, r/m/i        OR  mem, r/i
XOR reg, r/m/i        XOR mem, r/i
```

| Operação | Uso típico |
|---|---|
| `AND` | **Zerar** bits (máscara) |
| `OR` | **Ligar** bits |
| `XOR` | **Inverter** bits |

### NOT vs NEG

| Instrução | O que faz | Flags |
|---|---|---|
| `NOT r/m` | Inverte todos os bits (complemento de 1) | **Não** altera EFLAGS |
| `NEG r/m` | Negação em **complemento de 2** (`x → -x`) | Altera |

---

## 6. Deslocamentos

```nasm
SHL r/m, i    SHR r/m, i    ; lógicos
SAL r/m, i    SAR r/m, i    ; aritméticos
```

Em todos, o **último bit expurgado** vai para a **CF**.

| Instrução | Direção | Bit que entra | Uso |
|---|---|---|---|
| `SHL` | esquerda | `0` à direita | Não sinalizada (×2) |
| `SHR` | direita | `0` à esquerda | Não sinalizada (÷2) |
| `SAL` | esquerda | `0` à direita (**sinônimo de SHL**) | Sinalizada |
| `SAR` | direita | **mantém o bit de sinal** | Sinalizada (÷2 correto) |

**Exemplos com `0xEE01` (1110 1110 0000 0001):**

| Operação | Resultado | CF |
|---|---|---|
| `shl ax, 1` / `sal` | `0xDC02` | 1 |
| `shl ax, 4` (depois do anterior) | `0xC020` | 1 |
| `shr bx, 1` | `0x7700` | 1 |
| `shr bx, 4` (depois do anterior) | `0x0770` | 0 |
| `sar bx, 1` | `0xF700` | 1 |
| `sar bx, 4` (depois do anterior) | `0xFF70` | 0 |

> Diferença-chave: `shr` zera o bit de sinal (o número fica positivo), `sar` o preserva.

### Outros deslocamentos

- **ROL / ROR** (rotate left/right): o bit que sai **volta pelo outro lado** e também vai para a CF.
- **RCL / RCR** (rotate through carry): a **CF participa como um bit extra**; o bit que entra é a CF anterior.
- **SARX / SHLX / SHRX**: deslocam **sem afetar as flags**.

---

## 7. Multiplicação de inteiros

```nasm
MUL  r/m           ; sem sinal
IMUL r/m           ; com sinal
IMUL reg, r/m      ; 16, 32 ou 64 bits apenas
```

**Forma com 1 operando (MUL / IMUL):**

| | 64 bits | 32 bits | 16 bits |
|---|---|---|---|
| Operando implícito | `RAX` | `EAX` | `AX` |
| Resultado (dobro de bits) | `RDX:RAX` | `EDX:EAX` | `DX:AX` |

Operação (64 bits): `RDX:RAX = RAX * r64/m64`

**Forma com 2 operandos (IMUL):** `r = r * r/m` → o resultado cabe no próprio registrador, sem usar RDX.

---

## 8. Divisão de inteiros

```nasm
DIV  r/m           ; sem sinal
IDIV r/m           ; com sinal
```

- Dividendo **implícito**: `RDX:RAX` (`EDX:EAX` | `DX:AX`).
- Divisor **explícito**: `r/m`.
- Resultado: **quociente em `RAX`**, **resto em `RDX`**.

### Preparando o RDX (extensão de sinal)

| Instrução | Efeito |
|---|---|
| `CWD` | `DX:AX` = extensão de sinal de `AX` |
| `CDQ` | `EDX:EAX` = extensão de sinal de `EAX` |
| `CQO` | `RDX:RAX` = extensão de sinal de `RAX` |

**Cuidados:**
- `IDIV` (com sinal) → use `CWD`/`CDQ`/`CQO`.
- `DIV` (sem sinal) → o correto é **zerar o RDX** (`xor edx, edx`).
- Divisão por zero ou quociente grande demais para o registrador gera exceção (`#DE`) e o programa é encerrado.

**Exemplo a05e06 (32 bits):**

```nasm
; multiplicação
mov eax, [multiplicando1]
mul dword [multiplicador1]     ; EDX:EAX = EAX * multiplicador

; divisão
mov eax, [dividendo1]
cdq
div dword [divisor1]           ; EAX = quociente, EDX = resto
```

O `dword` é necessário porque o operando está na memória e o tamanho precisa ser informado.

---

## 9. Atividades

| Atividade | Objetivo | Ideia central | Resultado esperado |
|---|---|---|---|
| **a05at01** | Converter maiúscula ↔ minúscula usando só `ADD`/`SUB` | Diferença ASCII de **32** (`'A'`=0x41, `'a'`=0x61) | `'a'` e `'B'` |
| **a05at02** | Corrigir o bug da at01 usando só `OR`/`XOR`/`AND` | `OR 0x20` liga o bit 5 (minúscula); `AND 0xDF` desliga (maiúscula) | `'a'` e `'B'`, mesmo com entrada "errada" |
| **a05at03** | Somatório de vetor `dd` sem laço | `LEA` calcula `base + índice*4`; `ADD` acumula; `INC` avança o índice | **84** |
| **a05at04** | N-ésimo número triangular | `T(n) = n*(n+1)/2` com `MUL` e `DIV` (ou `SHR`) | **820** para n = 40 |

**Por que a at02 elimina o bug:** `OR` e `AND` com máscara são **idempotentes**: aplicar duas vezes dá o mesmo resultado, ao contrário de `ADD`/`SUB`, que alteram o valor mesmo quando a letra já está no formato certo.

---

## 10. Cola rápida

| Quero... | Use |
|---|---|
| Somar / subtrair | `ADD` / `SUB` |
| Somar / subtrair 1 | `INC` / `DEC` (não alteram CF) |
| Zerar / ligar / inverter bits | `AND` / `OR` / `XOR` |
| Inverter todos os bits | `NOT` |
| Trocar o sinal | `NEG` |
| ×2 / ÷2 sem sinal | `SHL` / `SHR` |
| ×2 / ÷2 com sinal | `SAL` / `SAR` |
| Girar bits | `ROL` / `ROR` / `RCL` / `RCR` |
| Multiplicar sem / com sinal | `MUL` / `IMUL` |
| Dividir sem / com sinal | `DIV` / `IDIV` |
| Preparar RDX para `IDIV` | `CWD` / `CDQ` / `CQO` |
| Saber se estourou | **OF** (com sinal) / **CF** (sem sinal) |

---

**Próxima aula (06):** Chamadas de sistema: escrever no terminal, ler do teclado, encerrar o programa e arquivos.
