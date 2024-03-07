const std = @import("std");
pub const instruction = @import("instruction.zig");
pub const tokenizer = @import("tokenizer.zig");
pub const token = @import("token.zig");
pub const ast = @import("ast.zig");

pub fn main() !void {
}
test {
    std.testing.refAllDecls(@This());
}