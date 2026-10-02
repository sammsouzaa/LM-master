#!/usr/bin/env bash
# Monta, linka e executa um .asm (NASM, x86_64)
# Uso: ./run.sh caminho/para/arquivo.asm

set -e

if [ -z "$1" ]; then
    echo "Uso: ./run.sh arquivo.asm"
    exit 1
fi

ASM="$1"
DIR=$(dirname "$ASM")
BASE=$(basename "$ASM" .asm)
OBJ="$DIR/$BASE.o"
BIN="$DIR/$BASE.x"

if [ ! -f "$ASM" ]; then
    echo "Arquivo nao encontrado: $ASM"
    exit 1
fi

nasm -f elf64 "$ASM" -o "$OBJ"
ld "$OBJ" -o "$BIN"

echo "--- executando $BIN ---"
"$BIN"
CODE=$?

echo "--- exit code: $CODE ---"
