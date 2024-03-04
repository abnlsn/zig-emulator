const std = @import("std");
pub const instruction = @import("instruction.zig");

test {
    std.testing.refAllDecls(@This());
}