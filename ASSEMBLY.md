# Linguagem de Montagem (LM) — Guia de Compilação/Execução

Baseado na Aula 01 (Introdução). Curso usa **NASM** (sintaxe Intel), arquitetura **x86_64**, Linux, com syscalls diretas (sem libc).

## Toolchain necessária

| Ferramenta | Função | Status neste ambiente |
|---|---|---|
| `nasm` | Montador (assembler) | instalado — 2.16.01 |
| `ld` | Linkador (GNU Binutils) | instalado — 2.42 |
| `gcc` | Compilador C (para os exemplos comparativos em C) | instalado — 13.3.0 |
| `gdb` | Debugger (usado a partir da Aula 02) | instalado — 15.1 |

Nada precisou ser instalado — ambiente já pronto para uso.

Caso falte algo no futuro (ex.: outra máquina), instale com:

```bash
sudo apt update
sudo apt install -y nasm binutils gcc gdb
```

## Atalho: `run.sh`

Script na raiz do repo automatiza montar + linkar + executar em um comando:

```bash
./run.sh primeira_prova/aula01/codes/hello.asm
```

Gera `.o` e `.x` na mesma pasta do `.asm` e mostra o exit code no final.

### Usar de qualquer diretório

Existe um symlink `~/.local/bin/asmrun` apontando para este `run.sh` (`~/.local/bin` já está no PATH). Assim, de qualquer lugar:

```bash
asmrun /caminho/completo/ou/relativo/arquivo.asm
```

Se o symlink não existir (ex.: outra máquina), recrie com:

```bash
ln -sf "$(pwd)/run.sh" ~/.local/bin/asmrun
```

## Fluxo manual: Montar → Linkar → Executar

Um `.asm` vira executável em dois passos: **montagem** (assembler gera `.o`) e **linkagem** (linker gera o binário final).

```bash
# 1. Montar (assembler): gera o arquivo objeto .o
nasm -f elf64 hello.asm

# 2. Linkar: gera o executável a partir do .o
ld hello.o -o hello.x

# 3. Executar
./hello.x

# 4. Ver código de retorno do programa
echo $?
```

Atalho (montar + linkar em um comando):

```bash
nasm -f elf64 hello.asm && ld hello.o -o hello.x
```

- `-f elf64`: formato de saída ELF de 64 bits (necessário para x86_64 Linux; use `elf32` só para código x86 de 32 bits).
- `./` indica ao S.O. que o executável está no diretório atual.
- Programa precisa do label `_start` marcado como `global _start` (ponto de entrada, equivalente ao `main` em C, mas sem runtime da libc).

## Exemplo de referência (`hello.asm`, Aula 01)

```asm
section .data
   strOla :  db "Ola", 10
   strOlaL:  equ $ - strOla

section .text
	global _start

_start:
   mov rax, 1          ; syscall write
   mov rdi, 1          ; fd 1 = stdout
   lea rsi, [strOla]   ; ponteiro pro buffer
   mov edx, strOlaL    ; tamanho do buffer
   syscall

   mov rax, 60         ; syscall exit
   mov rdi, 0          ; código de saída 0
   syscall
```

Já presente no repo em [primeira_prova/aula01/codes/hello.asm](primeira_prova/aula01/codes/hello.asm).

## Comparação: compilando a versão em C

A Aula 01 compara o mesmo "Hello" em C vs Assembly. Para compilar a versão C:

```bash
gcc hello.c -o helloC.x
./helloC.x
```

## Sintaxe Intel vs AT&T (nota)

Curso usa **sintaxe Intel** (NASM): `mnemônico destino, fonte` — ex. `mov eax, 4`.
Sintaxe AT&T (GAS/GNU `as`, não usada no curso): `mnemônico fonte, destino` — ex. `mov $4, %eax`.

## Debug (a partir da Aula 02)

```bash
gdb ./hello.x
```

## Referência rápida de syscalls usadas nos exemplos

| rax | syscall | rdi | rsi | rdx |
|---|---|---|---|---|
| 1 | write | fd | ponteiro buffer | tamanho |
| 60 | exit | código de saída | — | — |
