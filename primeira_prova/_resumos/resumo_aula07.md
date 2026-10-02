# Resumo - Aula 07: Controle de Fluxo de Execução

**Disciplina:** Linguagens de Montagem (NASM x86-64)
**Professora:** Gabriela Stein

---

## 1. Fluxo de execução

É a **ordem em que as instruções são executadas**.

| Tipo | Como funciona |
|---|---|
| **Sequencial (TOP → DOWN)** | `PC ← PC + 1` (o "+1" é o tamanho da instrução atual). Executa na ordem em que as instruções aparecem, de `_start` até o fim |
| **Com desvios** | Uma instrução de desvio faz `PC ← DESTINO` e a execução continua de outro ponto |

- **PC** = *Program Counter* (`RIP` em x86-64): aponta para a próxima instrução.
- Sem desvios, repetir uma operação exigiria copiar o código várias vezes (como na a05at03).
- Cores do diagrama do slide: **vermelho** = instrução de desvio, **verde** = instrução-destino, **cinza** = instrução comum.

---

## 2. Labels

- São **rótulos/apelidos para posições de memória**.
- Marcam **variáveis** e **trechos de código**: `_start:`, `leitura:`, `escrita:`, `fecha:`, `fim:`.
- Não geram instrução: só dão nome a um endereço, usado como alvo dos desvios.

As instruções de controle de fluxo são: **desvios incondicionais** e **desvios condicionais** (que dependem das flags).

---

## 3. Desvio incondicional: JMP

```nasm
JMP l/r64/m64        ; o destino deve conter um endereço
```

- Altera o PC para o destino **sempre**, sem depender de flag, resultado ou estado.
- Destino: **label** (`l`), **registrador** com o endereço (`r64`) ou **memória** com o endereço (`m64`).

**Laço infinito** (equivalente ao `while (1) {}` do C):

```nasm
_start:
    ; play dead!
    jmp _start
fim:                 ; nunca é alcançado
    mov rax, 60
    mov rdi, 0
    syscall
```

| Exemplo | O que faz |
|---|---|
| **a07e01a** | `jmp _start` em laço infinito; declara `destino: resq 1` (8 bytes para guardar um endereço) |
| **a07e01b** | `jmp fim` logo no início: **pula o `write`**, e a mensagem nunca aparece |

---

## 4. Registrador de flags

- Existe **um único registrador** de flags. A ALU o atualiza como **efeito colateral** de cada operação.
- A próxima instrução que altera flags **sobrescreve** o que havia.
- Tamanhos: **FLAGS** (16 bits), **EFLAGS** (32 bits), **RFLAGS** (64 bits).

### Flags de status

| Bit | Flag | Fica em 1 quando... |
|---|---|---|
| 0 | **CF** (Carry) | Há *carry-out* (soma) ou *borrow-in* (subtração): estouro **sem sinal** |
| 2 | **PF** (Parity) | O nº de bits `1` no **byte baixo** do resultado é par |
| 4 | **AF** (Adjust) | Há *carry/borrow* no nibble baixo (BCD) |
| 6 | **ZF** (Zero) | O resultado é **zero** |
| 7 | **SF** (Sign) | O resultado é **negativo** (bit mais significativo = 1) |
| 11 | **OF** (Overflow) | Estouro em aritmética **com sinal** |

- Os bits 1, 3 e 5 são reservados; as flags de controle (bits 9 e 10) não são usadas nesta aula.
- No GDB: `info registers eflags` (ou `i r eflags`) mostra só as flags **ativas**.

### Exemplos de flags (8 bits)

O processador calcula **CF e OF sempre, os dois**. Quem decide qual importa é o programador, conforme o tipo de número.

| Operação | Resultado | ZF | SF | CF | OF |
|---|---|---|---|---|---|
| `0x7F + 1` (127 + 1) | `0x80` | 0 | 1 | 0 | **1** |
| `0xFF + 1` (255 + 1) | `0x00` | 1 | 0 | **1** | 0 |
| `0x80 + 0x80` | `0x00` | 1 | 0 | **1** | **1** |
| `5 - 5` | `0x00` | **1** | 0 | 0 | 0 |
| `3 - 5` | `0xFE` | 0 | 1 | **1** | 0 |
| `0x80 - 1` (-128 - 1) | `0x7F` | 0 | 0 | 0 | **1** |

### Quem altera as flags

| Instrução | Efeito |
|---|---|
| `ADD`, `SUB`, `CMP` | Alteram **todas** as flags de status |
| `INC`, `DEC` | Alteram tudo **menos a CF** |
| `NEG` | Altera tudo (`CF = 1` se o operando não era 0) |
| `AND`, `OR`, `XOR` | `CF = 0` e `OF = 0`; ZF, SF e PF refletem o resultado |
| `NOT` | **Não altera** flags |
| `MOV`, `LEA` | **Não alteram** flags |
| `SHL/SAL`, `SHR`, `SAR` | `CF` = último bit que saiu; ZF, SF, PF refletem o resultado |
| `ROL/ROR/RCL/RCR` | Só `CF` (e `OF` em 1 bit); não mexem em ZF/SF |
| `MUL`, `IMUL` | `CF = OF = 1` se a metade alta do produto é relevante; demais indefinidas |
| `DIV`, `IDIV` | Todas **indefinidas** |
| `JMP` e `Jcc` | **Não alteram** flags |
| `syscall` | Não conte com as flags depois dele (usa `rcx` e `r11`) |

> **Regra de ouro:** vale a flag da **última** instrução que a escreveu. Entre o `cmp` e o jump, só coloque instruções que não alterem flags (`mov`, `lea`, `not`).

```nasm
cmp al, 5
add ebx, 1        ; ERRO: sobrescreve as flags do cmp
je  igual         ; agora lê as flags do ADD
```

---

## 5. Desvio condicional

- Decide entre **saltar** para o alvo ou **seguir o fluxo TOP-DOWN**, conforme as flags.
- **Os jumps só LEEM as flags; nunca as alteram.** Por isso um único `cmp` serve para vários jumps seguidos.
- O jump **não "volta"** sozinho: ele só troca o PC. Label **acima** do jump forma um **laço**; label **abaixo** forma um **salto para a frente** (como um `if`).

### JNZ e DEC (exemplo a07e02)

```nasm
DEC r/m          ; destino = destino - 1
JNZ l            ; Jump if Not Zero: salta se ZF = 0
```

```nasm
_start:
    mov r8, 5                 ; nº de execuções
repete:
    mov [passo], r8b          ; passo = contador
    add byte [passo], 0x30    ; 0x30 = '0': converte o dígito em caractere ASCII
    mov rax, 1                ; WRITE
    mov rdi, 1
    lea rsi, [passo]
    mov rdx, 2                ; dígito + quebra de linha
    syscall
    dec r8                    ; r8--
    jnz repete                ; se r8 != 0, volta
```

| Volta | `dec r8` | ZF | `jnz repete` |
|---|---|---|---|
| 1 | 5 → 4 | 0 | salta |
| ... | ... | 0 | salta |
| 5 | 1 → 0 | **1** | **não salta** (sai) |

Saída: `5 4 3 2 1`. É um laço **do-while** (executa ao menos uma vez). Se `r8` começasse em 0, o `dec` daria -1 e o laço quase não terminaria.

### Os JConditions (30 instruções gerais + 2 com CX/ECX)

| Grupo | Instruções | Condição de salto |
|---|---|---|
| Igualdade | `JE` (= `JZ`) / `JNE` (= `JNZ`) | `ZF = 1` / `ZF = 0` |
| **Sem sinal** | `JA` | `CF = 0` e `ZF = 0` |
| | `JAE` (= `JNB`, `JNC`) | `CF = 0` |
| | `JB` (= `JNAE`, `JC`) | `CF = 1` |
| | `JBE` (= `JNA`) | `CF = 1` ou `ZF = 1` |
| **Com sinal** | `JG` (= `JNLE`) | `ZF = 0` e `SF = OF` |
| | `JGE` (= `JNL`) | `SF = OF` |
| | `JL` (= `JNGE`) | `SF ≠ OF` |
| | `JLE` (= `JNG`) | `ZF = 1` ou `SF ≠ OF` |
| Uma flag | `JS/JNS`, `JC/JNC`, `JO/JNO`, `JP/JNP` | SF, CF, OF, PF |
| Paridade | `JPE` (par) / `JPO` (ímpar) | `PF = 1` / `PF = 0` |
| Contador | `JCXZ`, `JECXZ` | CX / ECX = 0 |

> **Regra mais importante:** *Above/Below* (`JA`, `JB`...) é para números **SEM sinal**; *Greater/Less* (`JG`, `JL`...) é para números **COM sinal**.

Exemplo: `al = 0xFF` comparado com 1. `ja` salta (255 > 1), `jg` **não** salta, `jl` salta (-1 < 1).

---

## 6. CMP: a instrução de comparação

```nasm
cmp r, r/m/i
cmp m, r/i          ; não existe mem, mem
```

- É uma **subtração implícita**: faz `operando1 - operando2`, **descarta o resultado** e só ajusta as flags.
- Depois, o `JCondition` pergunta sobre o **primeiro operando em relação ao segundo**: *"se operando1 for [condição] operando2, salte"*.
- Os jumps **não conhecem** as variáveis: a ligação com elas é o **`cmp` imediatamente anterior**.
- A ordem dos operandos importa: `cmp a, b` e `cmp b, a` invertem o sentido de `jl`/`jg`.
- Os operandos podem ser registrador, memória ou **número** (`cmp ecx, 5`); não é preciso ter "duas variáveis".
- Nem sempre é preciso `cmp`: `dec`, `inc`, `add`, `sub`, `and`, `or` também ajustam flags.

### Exemplo a07e03 (if / else if)

```nasm
mov al, [v1]
cmp al, [v2]
je  lIguais        ; v1 = v2   (ZF = 1)
jl  lMenor         ; v1 < v2   (SF ≠ OF)
jg  lMaior         ; v1 > v2   (ZF = 0 e SF = OF)
```

| v1 | v2 | v1 - v2 | ZF | SF | OF | Salta |
|---|---|---|---|---|---|---|
| 5 | 5 | 0 | 1 | 0 | 0 | `je` |
| 3 | 5 | -2 | 0 | 1 | 0 | `jl` |
| 7 | 2 | 5 | 0 | 0 | 0 | `jg` |

- O `cmp` é feito **uma vez**; os três jumps reaproveitam as mesmas flags.
- O último `jg` é redundante (se não é igual nem menor, é maior).
- `jl` usa `SF ≠ OF` (e não só `SF`) porque o `OF` corrige o sinal quando a subtração estoura.
- Para bytes sem sinal (letras ASCII), o correto seria `jb`/`ja`.

---

## 7. Laços com CMP

### Molde "testa no início" (`for` / `while`)

### Exemplo a07e04

```c
for (ecx = 0; ecx < strLidaL-1; ecx++) { ...comandos... }
```

```nasm
entradaFor:
    mov ecx, 0              ; inicialização
    mov r8d, [strLidaL]
    dec r8d                 ; limite = strLidaL - 1
preBloco:
    cmp ecx, r8d            ; testa a condição
    jge saidaFor            ; se ecx >= limite, sai
blocoFor:
    ...comandos...
    inc ecx                 ; ecx++
    jmp preBloco            ; volta ao teste
saidaFor:
```

A condição do C (`<`) vira o **contrário** no assembly (`jge`), porque o desvio serve para **sair** do laço. `strLidaL` é lido com `[ ]`: é uma variável na memória, e não um `equ`.

### Exemplo a07e05: multiplicação por somas sucessivas

```c
for (int i = multiplicador; i > 0; i--) resultado += multiplicando;
```

```nasm
entradaFOR:
    cmp ecx, 0
    jle saidaFOR            ; se ecx <= 0, sai
corpoFOR:
    add eax, edx            ; resultado += multiplicando
    dec ecx                 ; i--
    jmp entradaFOR
saidaFOR:
```

`ecx` = multiplicador, `edx` = multiplicando, `eax` = resultado (começa em 0). Exemplo: 4 × 3 soma 4 três vezes = 12.

### Comparação dos moldes

| Molde | Estrutura | Exemplo |
|---|---|---|
| **Testa no início** | `cmp` + salto de saída no topo, `jmp` de volta no fim | a07e04, a07e05 |
| **Testa no fim** (do-while) | corpo, `dec` e `jnz` de volta | a07e02 |

---

## 8. Atividades

### a07at01: *Parrot Code* (corrigir dois bugs)

Código semelhante ao a06e01, com dois bugs:
1. **Texto maior que `maxChars`:** o excedente fica no buffer do teclado e é "lançado" no terminal quando o programa termina.
2. **Texto menor que `maxChars`:** saem **duas** quebras de linha (o Enter lido + a `strLF` impressa).

**Objetivo:** imprimir **sempre uma só** quebra de linha e **esvaziar o buffer** do teclado antes de encerrar.

*Dica:* após o `read`, olhe o **último byte lido** (`rax` diz quantos foram). Se for `10`, já veio a quebra de linha: não imprima `strLF`. Se não for, o texto foi truncado: imprima `strLF` e **continue lendo** (descartando) até aparecer o `10`.

### a07at02: *Endless Stamina Parrot Code*

Em laço: pede texto; se **não** for `"quit"`, repete o que foi digitado e pede de novo; se for `"quit"`, encerra. Manter as correções da at01.

*Dicas:* o buffer do `read` **não termina em 0** e **contém o `10`**: troque o `10` por `0` antes de comparar. Compare com `"quit"` **byte a byte** (`cmp byte`), parando no primeiro byte diferente ou no `0` final.

### a07at03: desafio *Persistent Endless Stamina Parrot Code*

Acrescenta persistência em arquivo ao a07at02:
- Grava **todas as entradas** em arquivo, e continua mostrando na tela. O arquivo é criado se não existir, com **O_APPEND** (Aula 06).
- A cada **execução**, escreve a marcação **`====`**.
- Texto de encerramento: **`q!`**.
- **Entradas vazias** (só Enter) **não** são gravadas.
- Duas entradas **iguais seguidas**: a segunda é gravada como **`*`**.

*Dicas:* guarde a **entrada anterior** em outro buffer para comparar com a atual (reaproveite a rotina de comparação da at02). Escreva o `====` logo depois do `open`. No exemplo do slide, o `q!` não aparece gravado.

---

## 9. Pontos de atenção (imprecisões nos slides)

- Os desvios condicionais (`Jcc`) só aceitam **label**; o slide diz `l/r64/m64`, mas registrador e memória valem só para o `JMP`.
- `JPE` é "Jump if Parity **Even**" (e não "Parity or Equal").
- `JCXZ` não existe em 64 bits; o equivalente é `JRCXZ` (ou `JECXZ`).
- No a07e01b, o `%$` em `equ $-msg %$` parece defeito de formatação do slide.
- **PF** considera só os 8 bits menos significativos do resultado.
- O a07e02 usa `r8` como contador através de um `syscall`; na prática o kernel Linux o preserva, mas o `nolibc.h` (Aula 06) avisa que pode ser sobrescrito. Para ficar seguro, prefira `rbx` ou `r12`-`r15`.

---

## 10. Cola rápida

| Quero... | Uso |
|---|---|
| Pular sempre | `jmp label` |
| Comparar dois valores | `cmp a, b` e depois um `Jcc` |
| Igual / diferente | `je` / `jne` |
| Menor / maior **sem sinal** | `jb` / `ja` (`jbe`, `jae`) |
| Menor / maior **com sinal** | `jl` / `jg` (`jle`, `jge`) |
| Laço de N vezes (do-while) | `mov r, N` ... `dec r` / `jnz label` |
| Laço `for` (testa no início) | `cmp` + `jge/jle` de saída, corpo, `inc`/`dec`, `jmp` de volta |
| Testar se é zero sem `cmp` | `and al, al` / `or al, al`, depois `jz` |
| Estouro **sem sinal** | flag `CF` (`jc` / `jnc`) |
| Estouro **com sinal** | flag `OF` (`jo` / `jno`) |
| Resultado zero / negativo | flag `ZF` / `SF` (`jz` / `js`) |
| Ver as flags no GDB | `stepi` e `info registers eflags` |

---

**Encerramento da Etapa 01.** Próximas aulas: **tira-dúvidas** e **avaliação**.
