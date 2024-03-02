const Cpu = @import("../cpu.zig").Cpu;
const instruction = @import("../instruction.zig");

pub const ArithmeticOp = enum {
    GTH,
    LTH,
    EQU,
    NEQ,
    ADD,
    SUB,
    MUL,
    DIV,
    AND,
    ORR,
    EOR,
    NOT,
    SHL,
    SHR
};

fn get_opcode(instr: u8) ArithmeticOp {
    return @enumFromInt(instr);
}

pub fn handle_arithmetic(cpu: *Cpu, instr: u8) !void {
    const op = get_opcode(instr);
    const stack = try cpu.get_stack(instruction.get_wst(instr));
    const keep = instruction.is_keep(instr);

    const a = try stack.get_at_position(0);
    const b = try stack.get_at_position(1);

    if (!keep) {
        try stack.remove(0);
        try stack.remove(0);
    }

    switch (op) {
        .ADD => {
            try stack.push(a + b);
        },
        .SUB => {
            try stack.push(a - b);
        },
        .MUL => {
            try stack.push(a * b);
        },
        .DIV => {
            try stack.push(a / b);
        },
        .AND => {
            try stack.push(a & b);
        },
        .ORR => {
            try stack.push(a | b);
        },
        .EOR => {
            try stack.push(a ^ b);
        },
        .NOT => {
            try stack.push(~a);
        },
        .SHL => {
            try stack.push(a << @intCast(b));
        },
        .SHR => {
            try stack.push(a >> @intCast(b));
        },
        .GTH => {
            try stack.push(@intFromBool(a > b));
        },
        .LTH => {
            try stack.push(@intFromBool(a < b));
        },
        .EQU => {
            try stack.push(@intFromBool(a == b));
        },
        .NEQ => {
            try stack.push(@intFromBool(a != b));
        }
    }
}