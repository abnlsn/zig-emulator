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

test "instruction modes" {
    const instr = "ADD";
    const instruction = std.meta.stringToEnum(AllModes, instr);
    std.debug.print("instruction: {any}\n", .{instruction});
}

test "get_instructions" {
    _ = std.meta.fields(AllModes);
    std.debug.print("hello", .{});
}