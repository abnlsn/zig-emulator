const Cpu = @import("../cpu.zig").Cpu;
const instruction = @import("../instruction.zig");

const ImmediateOp = enum(u8) {
    LIT = 0x0000,
};

fn get_opcode(instr: u8) ImmediateOp {
    return @enumFromInt(instr & 0b0000_1111);
}

pub fn handleImmediate(cpu: *Cpu, instr: u8) !void {
    const opcode = get_opcode(instr);
    switch (opcode) {
        .LIT => {
            const wst = instruction.get_wst(instr);
            const value = try cpu.fetch();

            try cpu.push_stack(wst, value);
        },
    }
}