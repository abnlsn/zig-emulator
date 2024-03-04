pub const arithmetic = @import("arithmetic.zig");
pub const immediate = @import("immediate.zig");
pub const memory = @import("memory.zig");
pub const stack = @import("stack.zig");

pub const Mode = union(enum) {
    Arithmetic: arithmetic.ArithmeticOp,
    Immediate: immediate.ImmediateOp,
    Memory: memory.MemoryOp,
    Stack: stack.StackOp,
};