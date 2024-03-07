const std = @import("std");
const meta = std.meta;
const modes = @import("cpu").modes;
pub const Mode = modes.Mode;

const Arithmetic = modes.arithmetic.ArithmeticOp;
const Immediate = modes.immediate.ImmediateOp;
const Stack = modes.stack.StackOp;
const Memory = modes.memory.MemoryOp;

const instructionMappings = blk: {
    // const instructionModes = .{Arithmetic, Immediate, Stack, Memory};

    var size = 0;
    for (meta.fields(Mode)) |mode| {
        size += meta.fields(mode.type).len;
    }

    var mappings: [size]std.meta.Tuple(&[_]type{[]const u8, Mode}) = undefined;
    var index = 0;

    for (meta.fields(Mode)) |mode| {
        for (meta.fields(mode.type)) |instr| {
            const m = @unionInit(Mode, mode.name, @as(mode.type, @enumFromInt(instr.value))); // try switching type of enum, using instr.value to set enum value
            mappings[index] = .{instr.name, m};
            index += 1;
        }
    }
break :blk mappings;
};

pub const instructionMap = std.ComptimeStringMapWithEql(modes.Mode, instructionMappings, std.comptime_string_map.eqlAsciiIgnoreCase);

pub const Instruction = struct {
    instruction: modes.Mode,
    arguments: struct {
        pos: u8 = 0,
        wst: u8 = 0,
        dst: u8 = 0,
        pg: u8 = 0,
        k: u8 = 0,
    },

    const Self = @This();
    pub fn toOpcode(self: *const Self) u8 {
        var opcode: u8 = 0;
        opcode |= self.arguments.k << 7;
        opcode |= self.arguments.wst << 6;

        switch (self.instruction) {
            .Immediate => |i| {
                opcode |= 0b00 << 4;
                opcode |= @intFromEnum(i);
            },
            .Arithmetic => |i| {
                opcode |= 0b01 << 4;
                opcode |= @intFromEnum(i);
            },
            .Stack => |i| {
                opcode |= 0b10 << 4;
                opcode |= self.arguments.dst << 3; 
                opcode |= self.arguments.pos << 1;
                opcode |= @intFromEnum(i);
            },
            .Memory => |i| {
                opcode |= 0b11 << 4;
                opcode |= self.arguments.pg << 2;
                opcode |= @intFromEnum(i);
            },
        }
        return opcode;
    }
};

test "instruction map ADD" {
    try std.testing.expectEqual(instructionMap.get("add"), Mode{.Arithmetic = .ADD});
    try std.testing.expectEqual(instructionMap.get("ADD"), Mode{.Arithmetic = .ADD});
}

test "opcode generation" {
    const instr = Instruction{.instruction = .{.Arithmetic = .ADD}, .arguments = .{.k = 1}};
    try std.testing.expectEqual(0b10010100, instr.toOpcode());
}