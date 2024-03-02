const Cpu = @import("../cpu.zig").Cpu;
const instruction = @import("../instruction.zig");

pub const StackOp = enum(u8) {
    REM = 0b0,
    MOV = 0b1,
};

fn get_opcode(instr: u8) StackOp {
    return @enumFromInt(instr & 0x01);
}

fn get_pos(instr: u8) u8 {
    return (instr & 0b0000_0110) >> 1;
}

pub fn handleStack(cpu: *Cpu, instr: u8) !void {
    const op = get_opcode(instr);
    const keep = instruction.is_keep(instr);
    const wst = instruction.get_wst(instr);
    const pos = get_pos(instr);

    var stack = try cpu.get_stack(wst);

    switch (op) {
        StackOp.REM => {
            try stack.remove(pos);
        },
        StackOp.MOV => {
            const val = try stack.get_at_position(pos);
            if (!keep) {
                try stack.remove(pos);
            }
            try stack.push(val);
        },
    }
    return;
}