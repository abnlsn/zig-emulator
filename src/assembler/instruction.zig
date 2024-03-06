const std = @import("std");
const meta = std.meta;
const modes = @import("cpu").modes;
pub const Mode = modes.Mode;

const Arithmetic = modes.arithmetic.ArithmeticOp;
const Immediate = modes.immediate.ImmediateOp;
const Stack = modes.stack.StackOp;
const Memory = modes.memory.MemoryOp;

pub const instructionMap = std.ComptimeStringMapWithEql(modes.Mode, .{
    .{ "ADD", .{.Arithmetic = .ADD}},
    .{ "SUB", .{.Arithmetic = .SUB}},
}, std.comptime_string_map.eqlAsciiIgnoreCase
);

test "instruction map ADD" {
    try std.testing.expectEqual(instructionMap.get("add"), Mode{.Arithmetic = .ADD});
    try std.testing.expectEqual(instructionMap.get("ADD"), Mode{.Arithmetic = .ADD});
}