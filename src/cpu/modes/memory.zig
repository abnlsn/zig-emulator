const Cpu = @import("../cpu.zig").Cpu;
const instruction = @import("../instruction.zig");

pub const MemoryOp = enum(u8) {
    LDP = 0,
    STP = 1,
    JMP = 2,
    JCP = 3,
};

fn get_opcode(instr: u8) MemoryOp {
    return @enumFromInt(instr & 0b11);
}

fn get_page(instr: u8) !u8 {
    const page = (instr & 0b1100) >> 2;
    if (page > 3) return error.OutOfBounds;
    return page;
}

pub fn handle_memory(cpu: *Cpu, instr: u8) !void {
    const op = get_opcode(instr);

    const keep = instruction.is_keep(instr);
    const wst = instruction.get_wst(instr);
    const page = try get_page(instr);

    const stack = try cpu.get_stack(wst);

    const addr = try stack.get_at_position(0);
    if (!keep) try stack.remove(0);

    const absolute_addr: u16 = (@as(u16, page) * 256) + addr;

    switch (op) {
        MemoryOp.LDP => {
            const value = try cpu.mem.read(absolute_addr);
            try stack.push(value);
        },
        MemoryOp.STP => {
            const value = try stack.get_at_position(0);
            if (!keep) try stack.remove(0);

            try cpu.mem.write(absolute_addr, value);
        },
        MemoryOp.JMP => {
            cpu.pc = absolute_addr;
        },
        MemoryOp.JCP => {
            const value = try stack.get_at_position(0);
            if (value != 0) {
                cpu.pc = absolute_addr;
            }
            unreachable;
        },
    }
}