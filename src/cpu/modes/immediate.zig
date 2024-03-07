const Cpu = @import("../cpu.zig").Cpu;
const instruction = @import("../instruction.zig");

pub const ImmediateOp = enum(u8) {
    BRK,
    LIT,
};

fn get_opcode(instr: u8) ImmediateOp {
    return @enumFromInt(instr & 0b0000_1111);
}

pub fn handleImmediate(cpu: *Cpu, instr: u8) !void {
    const immediate_value = try cpu.fetch();
    const opcode = get_opcode(instr);
    const wst = instruction.get_wst(instr);

    switch (opcode) {
        .BRK => {
            cpu.halt = true;
        },
        .LIT => {

            try cpu.push_stack(wst, immediate_value);
        },
    }
}