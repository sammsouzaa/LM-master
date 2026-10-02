# FRENTE

## 1. Montar / ligar / executar ★
```
nasm -f elf64 x.asm        # gera x.o
ld x.o -o x.x              # liga
./x.x                      # executa
echo $?                    # código de retorno (RDI do exit)
gdb x.x                    # depurar
```
Intel: `mov DESTINO, FONTE`.

## 2. Seções e dados ★
| seção | conteúdo | exemplo |
|---|---|---|
| `.text` | instruções (`global _start`, `_start:`) | |
| `.data` | inicializados: `nome: tam valor` | `v: dd 12, -3` |
| `.bss` | não inicializados: `nome: res? qtd` | `r: resd 8` |

- `db`=1B `dw`=2B `dd`=4B `dq`=8B  |  `resb`=1 `resw`=2 `resd`=4 `resq`=8 (bytes × quantidade)
- `resd 8` = 32 B. `dw 2048,4096` = 4 B. `db "87",0` = 3 B (0x38 0x37 0x00).
- `strL: equ $ - str` (tamanho em bytes) · `%define N 10` (substituição de texto)
- Símbolo = **endereço**. `[v]` = **conteúdo**. Não existe "tipo": o **registrador/`byte`/`dword`** define o tamanho.
- Bases: `0x61` `61h` hex · `97` `97d` dec · `141o` oct · `1100001b` bin. Negativo = complemento de 2.
- Little-endian: `dd 0x12345678` → `78 56 34 12`. `dw 'ab'` → `61 62`. `dw 'a'` → `61 00`.

## 3. Registradores ★
| 64 | 32 | 16 | 8 |
|---|---|---|---|
| rax rbx rcx rdx | eax ebx ecx edx | ax bx cx dx | al/ah bl/bh cl/ch dl/dh |
| rsi rdi rbp rsp | esi edi ebp esp | si di bp sp | sil dil bpl spl |
| r8 … r15 | r8d … r15d | r8w … r15w | r8b … r15b |

- GP em 64 b = **16** (os da tabela). Todos acessíveis em 64, 32, 16 e 8 bits.
- Tamanhos ★ (bytes): dado = tamanho do registrador/`byte,word,dword`. **Endereço em x86-64 = 8 B** (`lea rsi,[x]` = 8). `mov ax,[v]`=2 · `add r15d,[n]`=4 · `or cl,0x20`=1 · `shl r8b,1`=1 · `idiv ebx`=4.
- Registrador no gdb (MSb à esquerda): 1º byte da memória = byte menos significativo. `v1: db 'Kart_'`: `mov eax,[v1]` → `0x7472614B` ('K'=4B 'a'=61 'r'=72 't'=74); `bx` → 0x614B; `cl` → 0x4B; `mov r8,[v1]` lê 8 bytes. `mov eax` zera a metade alta de RAX; `bx/cl` não alteram o resto.

## 4. MOV e cópias ★
```
mov reg, [mem]     mov [mem], reg     mov reg, imm     mov reg, reg
mov byte [m], 5    mov word [m], 5    mov dword [m], 5   ; tamanho obrigatório
```
- **Não existe mem→mem** (passa por registrador). Não existe imediato de 64 b → memória.
- `movsx rdx, dword [n]` estende **com sinal**; `movzx` com zero. `movzx edx, byte [p+rcx]` lê 1 char.
- `lea rsi, [v]` = endereço de v (ponteiros, `char*`). `lea r8,[v + i*4]`.
- Vetor: `[vet + esi*4]` (4 = tamanho do elemento: 1,2,4,8).
- Exemplo ★: `n4:dd -2147483648` → `v4:resq 1` ⇒ `movsx rdx, dword [n4]` · `mov [v4], rdx`

## 5. Aritmética e lógica ★
| instr | efeito |
|---|---|
| `add d,s` · `sub d,s` | d = d ± s (sinal e carry: OF/CF) |
| `neg d` | d = −d (compl. 2) · `not d` = inverte bits |
| `and/or/xor d,s` | bit a bit · `xor eax,eax` zera |
| `shl/sal d,n` · `shr d,n` | esq/dir lógico (entra 0) · CF = bit expulso |
| `sar d,n` | dir **aritmético** (mantém sinal) = ÷2ⁿ com sinal (arredonda p/ −∞) |
| `mul r/m` · `imul r/m` | RDX:RAX = RAX × r/m (EDX:EAX, DX:AX). `mul`=sem sinal, `imul`=com sinal |
| `imul r, r/m` · `imul r, imm` | r = r × op (16/32/64) |
| `div r/m` · `idiv r/m` | dividendo = **EDX:EAX** ÷ r/m → **EAX = quociente, EDX = resto** |
| `cwd` / `cdq` / `cqo` | estende sinal AX→DX:AX / EAX→EDX:EAX / RAX→RDX:RAX |

**Divisão ★ (receita):**
```
; com sinal               ; sem sinal
mov eax,[dividendo]       mov eax,[dividendo]
cdq                       xor edx,edx
idiv dword [divisor]      div dword [divisor]
mov [resto],edx           ; EAX=quoc  EDX=resto
```
`-7 ÷ 4` → quoc `-1`, resto **`-3`** (idiv trunca p/ 0).

**Flags:** `CF` carry (sem sinal) · `OF` overflow (com sinal) · `ZF` resultado 0 · `SF` negativo.
Overflow: soma de **mesmo sinal** dá sinal contrário. Nunca ocorre somando sinais diferentes.

## 6. ASCII
`'0'`=0x30 … `'9'`=0x39 · `'A'`=0x41 · `'a'`=0x61 · minúscula = maiúscula + 0x20 · LF=10=0x0A · NUL=0.

---
# VERSO

## 7. Chamadas de sistema ★ (`syscall`)
Nº em **RAX**; args em **RDI, RSI, RDX, R10, R8, R9**; retorno em **RAX** (negativo = erro). `syscall` destrói RCX e R11.

| nº | nome | assinatura |
|---|---|---|
| 0 | read | `rdi=fd, rsi=*buf, rdx=count` → nº lidos (inclui `\n`) |
| 1 | write | `rdi=fd, rsi=*buf, rdx=count` → nº escritos |
| 2 | open | `rdi=*path, esi=flags, edx=mode` → fd / −1 |
| 3 | close | `edi=fd` |
| 39 / 62 | getpid / kill | `kill(edi=pid, esi=sinal)` (9=SIGKILL) |
| **82 (0x52)** | **rename** | **`rdi=*oldpath, rsi=*newpath`** → 0 / −1 |
| 83 | mkdir | `rdi=*path, esi=mode` (ex. `775o`) |
| **60** | **exit** | **`rdi=status`** ← RDI, não RSI |

fd: 0=stdin 1=stdout 2=stderr · **flags open (OCTAL):** `O_RDONLY`=0 `O_WRONLY`=1 `O_RDWR`=2 `O_CREAT`=100 `O_APPEND`=2000 · append+criar = `2101o`, criar+gravar = `101o` · modo `0644o`.

```nasm
; rename ★ (1º=rdi, 2º=rsi)         ; write                  ; read (rax=0, rdi=0)
mov rax,0x52                        mov rax,1                mov rax,0
lea rdi,[oldpath]                   mov rdi,1                mov rdi,0
lea rsi,[newpath]                   lea rsi,[str]            lea rsi,[buf]
syscall                             mov edx,strL             mov edx,max
cmp rax,0                          syscall                  syscall   ; rax=nº lidos
jne falhou
; open: rax=2, rdi=nome, esi=2101o, edx=0644o, syscall, depois mov [fd],eax (usar: mov edi,[fd])
; mkdir: rax=83, rdi=path, esi=modo, syscall, mov [error],eax
; exit:  rax=60, rdi=status, syscall
```
`char*`/`int*` → `lea` (string com `,0`) · valor `int` → `mov edx,[var]` · constante → `mov esi,775o`.

## 8. Fluxo ★
`cmp a,b` (= a−b, só flags) e depois `jcc`: `je/jz` = · `jne/jnz` ≠ · **com sinal:** `jg` > `jge` ≥ `jl` < `jle` ≤ · **sem sinal:** `ja` `jae` `jb` `jbe` · `jmp` sempre. `dec r8` + `jnz laco` repete até 0.
```nasm
; for (i=0;i<n;i++)              ; while (*p != 0)
    xor ecx,ecx                  laco:
laco:                                cmp byte [p],0
    cmp ecx,[n]                      je fim
    jge fora                         ...corpo...
    ...corpo...                      jmp laco
    inc ecx
    jmp laco
fora:
```

## 9. Moldes ★

**9.1 Percorrer vetor (soma)**
```nasm
    mov ecx,[vetS]            ; ecx = nº de elementos
    xor esi,esi               ; i = 0
    xor eax,eax               ; soma = 0
laco:
    cmp esi,ecx               ; compara i com n
    je fim                    ; i == n: terminou
    add eax,[vet+esi*4]       ; soma += vet[i]  (dd *4, dw *2, db *1)
                              ; cópia ÷4: mov edx,[vet+esi*4] / sar edx,2 / mov [vetor+esi*4],edx
                              ; produtório dw: mov ax,1 antes; imul ax,[vet+esi*2]
    inc esi                   ; i++
    jmp laco                  ; volta ao teste
```

**9.2 Texto → inteiro**
```nasm
    xor eax,eax               ; acc = 0
    xor ecx,ecx               ; i = 0
conv:
    movzx edx,byte [texto+rcx] ; lê 1 caractere
    cmp edx,0                 ; fim da string? (teclado: 10)
    je grava                  ; sim: sai
    sub edx,0x30              ; ASCII -> dígito
    imul eax,10               ; acc *= 10
    add eax,edx               ; acc += dígito
    inc ecx                   ; i++
    jmp conv                  ; próximo caractere
grava:
    mov [resultado],eax       ; guarda o inteiro
```

**9.3 Inteiro → texto** (n ≥ 0, `buf: resb TAM`)
```nasm
    mov eax,[n]               ; eax = número
    mov ebx,10                ; divisor
    mov ecx,TAM               ; posição de escrita (fim do buffer)
c:
    xor edx,edx               ; zera parte alta p/ div
    div ebx                   ; eax = n/10, edx = último dígito
    add dl,0x30               ; dígito -> ASCII
    dec ecx                   ; recua 1 posição
    mov [buf+ecx],dl          ; grava o caractere
    cmp eax,0                 ; acabou?
    jne c                     ; não: próximo dígito
                              ; texto em [buf+ecx], tamanho = TAM - ecx
```

**9.4 Esvaziar buffer do teclado** (após `read` de 5; `lixo: resb 1`)
```nasm
    cmp rax,5                 ; leu o máximo?
    jne ok                    ; não: nada sobrou
    cmp byte [buf+4],10       ; último lido é Enter?
    je ok                     ; sim: nada sobrou
lim:
    mov rax,0                 ; read
    mov rdi,0                 ; stdin
    lea rsi,[lixo]            ; buffer de descarte
    mov edx,1                 ; 1 byte
    syscall                   ; lê e descarta
    cmp byte [lixo],10        ; chegou no Enter?
    jne lim                   ; não: repete
ok:
```

**9.5 Comparar com "quit"** (`quit` + Enter)
```nasm
    cmp dword [buf],'quit'    ; compara 4 bytes de uma vez
    jne nao                   ; diferente: não é quit
    cmp byte [buf+4],10       ; 5º byte é Enter?
    jne nao                   ; não: não é quit
    ...                       ; é "quit": encerrar
```

**9.6 Caixa**
```nasm
    or al,0x20                ; maiúscula -> minúscula (liga bit 5)
    and al,0xDF               ; minúscula -> maiúscula (desliga bit 5)
```

## 10. GDB ★
```
b label    r    c    q                 # breakpoint, run, continue, quit
p/x $rax   p/d $eax   p/c var   p/x &var     # reg/var/endereço
x /[b h w g][c d u x t o] &var              # memória: tam + formato
i r eflags                                  # flags ativas
```
`b`=1B `h`=2B `w`=4B `g`=8B · `c`=char `d`=sinal `u`=sem `x`=hex `t`=bin `o`=oct.
