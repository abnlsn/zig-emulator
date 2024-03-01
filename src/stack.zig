const std = @import("std");

const StackError = error {
    Overflow,
    Underflow,
    InvalidPosition,
};

pub const Stack = struct {
    data: [16]u8,
    ptr: u8,

    const Self = @This();

    pub fn init() Self {
        return .{
            .data = undefined,
            .ptr = 0,
        };
    }

    pub fn push(self: *Self, value: u8) !void {
        if (self.ptr >= 16)  return error.Overflow;

        self.data[self.ptr] = value;
        self.ptr += 1;
    }

    pub fn get_at_position(self: *Self, pos: u8) !u8 {
        if (pos > 3) return error.InvalidPosition;
        return self.data[self.ptr - pos - 1];
    }

    pub fn remove(self: *Self, pos: u8) !void {
        var idx = self.ptr - pos - 1;

        while (idx < self.ptr - 1) {
            self.data[idx] = self.data[idx + 1];
            idx += 1;
        }

        self.ptr -= 1;
    }

    pub fn print(self: *const Self, writer: anytype) !void {
        for (self.data, 0..) |value, i| {
            var val = value;
            if (i >= self.ptr) val = 0;
            try writer.print("| {x:0>2} ", .{val});
        }
    }
};

const tst = @import("std").testing;

test "remove" {
    var stack = Stack.init();
    
    try stack.push(1);
    try stack.push(2);
    try stack.push(3);

    try stack.remove(1);
    try tst.expectEqual(stack.get_at_position(1), 1);
    try tst.expectEqual(stack.get_at_position(0), 3);
    try stack.remove(0);
    try tst.expectEqual(stack.get_at_position(0), 1);
    
}