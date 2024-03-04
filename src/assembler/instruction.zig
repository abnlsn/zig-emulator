const std = @import("std");
const meta = std.meta;
const modes = @import("cpu").modes;

const instructionModes = .{modes.immediate.ImmediateOp, modes.arithmetic.ArithmeticOp, modes.memory.MemoryOp, modes.stack.StackOp};

const AllModes = blk: {
    var size = 0;
    for (instructionModes) |mode| {
        size += meta.fields(mode).len;
    }

    var index = 0;
    var fields: [size]std.builtin.Type.EnumField = undefined;

    for (instructionModes, 0..) |mode, i| {
        const modeBits = @as(u8, i) << 6;
        for (meta.fields(mode)) |field| {
            fields[index] = .{.name = field.name, .value = modeBits | field.value};
            index += 1;
        }
    }

    const enumInfo = std.builtin.Type.Enum {
        .tag_type = u8,
        .fields = &fields,
        .is_exhaustive = true,
        .decls = &[0]std.builtin.Type.Declaration{},
    };

    break :blk @Type(std.builtin.Type{ .Enum  = enumInfo });
};

fn stringToMode(instr: []const u8) !modes.Mode {
    const operation = std.meta.stringToEnum(AllModes, instr) orelse return error.InvalidInstruction;
    const mode = (@intFromEnum(operation) >> 6) & 0b11;
    const opcode = @intFromEnum(operation) & 0b00111111;

    // const Mode = modes.Mode;
    const ImmediateOp = modes.immediate.ImmediateOp;
    const ArithmeticOp = modes.arithmetic.ArithmeticOp;
    const MemoryOp = modes.memory.MemoryOp;
    const StackOp = modes.stack.StackOp;

    switch (mode) {
        0 => {
            const op: ImmediateOp = @enumFromInt(opcode);
            return .{ .Immediate = op };
        },
        1 => {
            const op: ArithmeticOp = @enumFromInt(opcode);
            return .{ .Arithmetic = op };
        },
        2 => {
            const op: MemoryOp = @enumFromInt(opcode);
            return .{ .Memory = op};
        },
        3 => {
            const op: StackOp = @enumFromInt(opcode);
            return .{ .Stack = op };
        },
        else => {
            return error.InvalidMode;
        },
    }
    
}

fn constructOpcode(instr: []const u8) !u8 {
    const operation = try stringToMode(instr);
    const keep = 0b0;
    const wst: u8 = 0b0;

    switch (operation) {
        .Immediate => {
            const op = operation.Immediate;
            return (keep << 7) | (wst << 6) | 0b00 << 4 | @intFromEnum(op);
        },
        .Arithmetic => {
            const op = operation.Arithmetic;
            return (keep << 7) | (wst << 6) | 0b01 << 4 | @intFromEnum(op);
        },
        .Stack => {
            const op = operation.Stack;
            const dst: u8 = 0b0;
            const pos: u8 = 0b00;
            return (keep << 7) | (wst << 6) | 0b11 << 4 | dst << 3 | pos << 1 | @intFromEnum(op);
        },
        .Memory => {
            const op = operation.Memory;
            const page: u8 = 0b00;
            return (keep << 7) | (wst << 6) | 0b11 << 4 | page << 2 | @intFromEnum(op);
        },
    }
}

test "constructOpcode" {
    const instr = "ADD";
    const opcode = try constructOpcode(instr);
    try std.testing.expect(opcode == 0b00010100);
}