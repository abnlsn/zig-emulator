```
DEFAULT pos 0 ;set defaults...
DEFAULT wst 1
DEFAULT dst 1
DEFAULT pg 0
DEFAULT k 0

label: LIT 0x00
DUP pos0, wst0, dst0
LDP pg0

loop: LIT @loop ;load loop onto stack
JMP ;jump to loop

data: 0x1234
```

I want this to turn into some AST of the form:
```
[
    {type: directive, name: "DEFAULT", arguments: [pos: 0]},
    {type: directive, name: "DEFAULT", arguments: [wst: 0]},
    ... ,
    {type: label, value: "loop"},
    {type: instruction, value: "LIT", arguments: [label: "loop"]}
    {type: instruction, value: "JUMP"},
    {type: label, value: "data"},
    {type: data, value: 0x1234}
]
```