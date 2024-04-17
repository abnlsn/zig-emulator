# Layout
```
| k | wst | mode | mode sp.|
| _ |  _  | _ _  | _ _ _ _ |
```

## Keep
keep mode allows you to read values off the stack without popping them. Useful for certain operations.

## Working Stack
There are 2 working stacks. One can be used as a return stack, or you can use them for general purpose tasks.
The working stack specified in the instruction is the one to be used.

Both are 16 bytes.

## Modes
```
00: immediate
01: ALU operations
10: stack operations
11: memory operations
```

Note: both immediate and ALU have 4 bits for opcodes, and they share the MSB being 0. This will make logic design easier.

## Mode Specific
The last 4 bytes are mode specific. For the `0x` modes (immediate, and ALU), all 4 bytes are used for different opcodes.

### immediate
For now, there is only one immediate

```
LIT: push the following literal to the stack
```

### ALU

The following operations are done with the ALU:
```
GTH
LTH
EQU
NEQ

ADD
SUB
MUL
DIV

AND
ORR
EOR
NOT

SHL
SHR
```

### stack
in addition to a working stack specification, the stack mode also needs a destination stack
```
| k | wst | mode | dst | pos | op  |
| _ |  _  | _ _  |  _  | _ _ |  _  |
```

stack mode is the most complex. in addition to a working stack, you must specify a destination stack.
this allows you to move values between stacks as necessary.

There are two operations:
Each operation can operate on the top 4 elements of the stack, specified by the 2-bit position in the instruction.
```
0: POP - removes specified position from stack
1: MOV - moves specified position to top of stack
```


In addition, you can duplicate a value by using `MOV` in keep mode.


### memory

Memory instructions are made up of a page and an operation.
The page designates which 256-byte chunk of memory you are working with.
There are 4 pages, so 1028 total bytes of memory.

```
| k | wst | mode | page | op  |
| _ |  _  | _ _  | _  _ | _ _ |
```

There are 4 memory operations
```
LDA: load the data at the address on the top of the wst
STA: store the data at the top of the stack into the address at the 2nd stack position
JMP: PC=top of stack
JCN: PC=top of stack if 2nd stack position != 0
```
