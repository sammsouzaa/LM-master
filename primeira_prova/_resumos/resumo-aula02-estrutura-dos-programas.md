# Resumo – Aula 02: Estrutura dos Programas

Disciplina: Linguagens de Montagem (Unioeste) · Profª Gabriela Stein

---

## 1. Estrutura básica de um programa

O formato de executável usado no Linux é o **ELF**.

**Visão do arquivo** (de endereço baixo para alto):

1. Cabeçalho ELF
2. Cabeçalho de Programa
3. Programa (conteúdo)
4. Cabeçalho de Seção

**Visão do programa na memória** (de endereço baixo para alto):

| Região | O que guarda |
|---|---|
| **Instruções** | O código (`section .text`) |
| **Dados inicializados** | Variáveis com valor definido (`section .data`) |
| **Dados não inicializados** | Variáveis só reservadas, sem valor inicial (próxima aula) |
| **Heap** (memória dinâmica) | `malloc`/`calloc`, cresce **para cima** |
| **Memória livre** | Espaço entre heap e pilha |
| **Stack** (pilha) | Parâmetros e armazenamento temporário, cresce **para baixo** |

Heap e pilha crescem um em direção ao outro, usando a memória livre do meio.

## 2. Formato ELF em geral

| Parte | Conteúdo |
|---|---|
| **Cabeçalho ELF** | Assinatura `0x7F E L F`, arquitetura (x86 ou x64), **ponto de entrada**, tamanho dos cabeçalhos, entre outros |
| **Cabeçalho de Programa** | Informações para o S.O. montar a "imagem do programa" na memória |
| **Programa** | Instruções e dados |
| **Cabeçalho de Seção** | Tamanho, deslocamento e nomes das seções |

Para ver esses cabeçalhos: `readelf -e a02e01.x`

## 3. O programa no ELF

- **Instruções (`section .text`):** a execução começa nesse ponto e segue **top-down**.
- **Dados inicializados (`section .data`):** variáveis com valores pré-definidos, normalmente usadas para constantes. **Podem ser alteradas** durante a execução.
- **Dados não inicializados:** só se reserva espaço em bytes (próxima aula).
- **Memória dinâmica (heap):** variáveis criadas em tempo de execução (`calloc`/`malloc`). Será visto no futuro.
- **Área livre:** espaço entre a memória dinâmica e a pilha.
- **Pilha:** passagem de parâmetros e armazenamento temporário. Será vista no futuro.

## 4. Conceito central: dados

- **Não existem "tipos de dados" em memória**, só bytes.
- É a **instrução** que determina como aqueles bytes são interpretados (inteiro, caractere, endereço...).
- Normalmente se faz uma de duas coisas:
  - **definir** o valor em memória (dados inicializados), ou
  - **reservar** espaço em memória (dados não inicializados).

## 5. Dados inicializados (`.data`)

Sintaxe:

```nasm
section .data
    simbolo: tamanho valor
```

- **Uma linha = uma variável.**
- O **símbolo** (*label*) é o nome da variável, ou seja, a referência ao seu endereço. (Em `char c = 10;`, `c` é o símbolo e `10` o valor.)
- O **tamanho** é dado por uma pseudo-instrução (ordem para o montador, não instrução da CPU):

| Pseudo-instrução | Nome | Tamanho |
|---|---|---|
| `db` | byte | 1 byte |
| `dw` | word | 2 bytes |
| `dd` | double word | 4 bytes |
| `dq` | quad word | 8 bytes |

## 6. Exemplos e o que vai para a memória

```nasm
section .data
    v1: db 0x55                  ; 55
    v2: db 0x55,0x56,0x57        ; 55 56 57
    v3: db 'a',0x55              ; 61 55
    v4: db 'hello',13,10,'$'     ; 68 65 6c 6c 6f 0d 0a 24
    v5: dw 0x1234                ; 34 12
    v6: dw 'a'                   ; 61 00
    v7: dw 'ab'                  ; 61 62
    v8: dw 'abc'                 ; 61 62 63 00
    v9: dd 0x12345678            ; 78 56 34 12
```

- Caracteres entre aspas viram o código **ASCII** (`'a'` = `0x61`).
- `13` = *carriage return* (`\r`) e `10` = *line feed* (`\n`).
- `dw 'a'` completa com `00` (o word tem 2 bytes).
- `dw 'abc'` ocupa 2 words (4 bytes), completando com `00`.

### Little-endian

O x86 é **little-endian**: o byte **menos significativo** fica no **menor endereço**.

```
dw 0x1234      →  34 12
dd 0x12345678  →  78 56 34 12
```

Strings seguem a ordem do texto, pois cada letra é um byte separado.

## 7. Debugger

- **História:** a Almirante **Grace Hopper** (Marinha dos EUA) popularizou o termo *bug* em 1947, quando colegas encontraram uma mariposa impedindo o funcionamento do **Mark II**. Os termos *bug* e *debug* são mais antigos (registros de 1878, Thomas Edison).
- **GDB (GNU Debugger):** nativo na maioria das distros Linux, permite depurar programas para encontrar *bugs* ou validá-los.

**Ideia:** o debugger é um "botão de pause com microscópio". Você pausa o programa onde quiser e olha a memória e os registradores.

## 8. Usando o GDB

### Receita básica

| Passo | O que fazer | Comando |
|---|---|---|
| 1 | Abrir o programa | `gdb nome.x` |
| 2 | Escolher onde pausar | `b rotulo` |
| 3 | Executar até o breakpoint | `r` |
| 4 | Inspecionar | `p/x`, `p/c`, `x` |
| 5 | Continuar / sair | `c` / `q` |

### Comandos

| Comando | Atalho | Função |
|---|---|---|
| `quit` | `q` | Sair |
| `break rotulo` | `b` | Criar breakpoint |
| `run args` | `r` | Executar o programa **do início** |
| `continue` | `c` | Continuar até o próximo breakpoint ou o fim |
| `print/x var` | `p/x` | Mostrar valor em hexadecimal |
| `print/c var` | `p/c` | Mostrar valor como caractere |
| `print/x &var` | `p/x &` | Mostrar o **endereço** da variável |
| `info breakpoints` | `i b` | Listar breakpoints |
| `delete N` | | Remover o breakpoint N |

### Rótulos x breakpoints

- No **código** você declara só **rótulos** (`fim:`, `teste:`...). Um rótulo apenas dá nome a um endereço e não pára nada.
- No **GDB** você cria os **breakpoints** apontando para esses rótulos (`b fim`, `b teste`...), quantos quiser.
- `r` inicia o programa e ele para no primeiro breakpoint que o código alcançar. `c` avança até o próximo.
- Os breakpoints são atingidos na ordem em que o **código** chega neles, e não na ordem em que foram criados.

### Exemplo (a02e01.x)

```
$ gdb a02e01.x
(gdb) b fim
(gdb) r
(gdb) p/x (int) v1       → 0x57565555
(gdb) p/c (char) v1      → 85 'U'
(gdb) p/x &v1            → 0x6000bc
(gdb) c
(gdb) q
```

**Por que `0x57565555`?** `v1` e `v2` ficam grudadas na memória (`55 | 55 56 57`). Pedindo 4 bytes a partir de `v1`, o GDB lê `55 55 56 57` e, em little-endian, monta `0x57565555`. A memória não tem fronteira entre variáveis: quem define o tamanho é você.

### Type-casting

O executável não guarda tipos, então o **casting** informa ao GDB o **tamanho** a ler:

```
(gdb) p/x (int) v1     ← 4 bytes
(gdb) p/x (char) v1    ← 1 byte
```

Dependendo da versão do GDB, `p/x v1` sem cast pode dar erro de tipo desconhecido.

> **Nota:** o slide diz que `p/c` mostra "1 byte em hexadecimal", mas ele mostra o valor em **decimal e como caractere** (`85 'U'`). O hexadecimal é o `p/x`.

### Comando `x` (examinar memória)

```
x /[quantidade][formato][tamanho] endereço
```

| Tamanho | Significado |
|---|---|
| `b` | 1 byte |
| `h` | 2 bytes |
| `w` | 4 bytes |
| `g` | 8 bytes |

| Formato | Significado |
|---|---|
| `c` | caractere (só 1 byte) |
| `d` | inteiro com sinal |
| `u` | inteiro sem sinal |
| `t` | binário |
| `x` | hexadecimal |
| `o` | octal |

Exemplos:

```
(gdb) x/8xb &v1      ← 8 bytes em hexa a partir de v1
(gdb) x/28xb &v1     ← os 28 bytes todos do exemplo
(gdb) x/s &v4        ← interpreta como string
```

| Comando | Para que serve |
|---|---|
| `p` | mostrar **um valor** (tamanho controlado pelo cast) |
| `x` | mostrar **uma região da memória**, byte a byte |

## 9. Atividade AT0201

**Tarefa:** debugar as outras variáveis do `a02e01.asm` e criar um **diagrama da memória**, com cada variável no seu endereço, em nível de byte. O total é de **28 bytes**.

Para conferir (a partir de `v1` em `0x6000bc`, como no slide; na sua máquina o endereço inicial pode variar):

| Variável | Endereços | Bytes |
|---|---|---|
| `v1` | `bc` | 55 |
| `v2` | `bd`–`bf` | 55 56 57 |
| `v3` | `c0`–`c1` | 61 55 |
| `v4` | `c2`–`c9` | 68 65 6c 6c 6f 0d 0a 24 |
| `v5` | `ca`–`cb` | 34 12 |
| `v6` | `cc`–`cd` | 61 00 |
| `v7` | `ce`–`cf` | 61 62 |
| `v8` | `d0`–`d3` | 61 62 63 00 |
| `v9` | `d4`–`d7` | 78 56 34 12 |

Passo a passo:

1. Montar, linkar e abrir no GDB.
2. `b fim` e `r`.
3. `p/x &v1` para anotar o endereço inicial.
4. `x/28xb &v1` para ver os 28 bytes.
5. Desenhar uma caixa por byte (endereço em cima, valor embaixo), agrupando por variável.

## Código completo para testar

```nasm
section .data
    v1: db 0x55
    v2: db 0x55,0x56,0x57
    v3: db 'a',0x55
    v4: db 'hello',13,10,'$'
    v5: dw 0x1234
    v6: dw 'a'
    v7: dw 'ab'
    v8: dw 'abc'
    v9: dd 0x12345678

section .text
    global _start

_start:
    nop
fim:
    mov rax, 60
    mov rdi, 0
    syscall
```

```bash
nasm -f elf64 a02e01.asm
ld a02e01.o -o a02e01.x
gdb a02e01.x
```

## Próxima aula

**Aula 03 – Registradores e instrução MOV:**
- Registradores: topo da hierarquia de memórias, visíveis e não visíveis, modos de acesso.
- Transferência de dados: memória → registrador, registrador → memória e registrador → registrador.
