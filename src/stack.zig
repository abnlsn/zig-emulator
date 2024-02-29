const std = @import("std");

const StackError = error {
    Overflow,
    Underflow
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

    pub fn print(self: *const Self, writer: anytype) !void {
        for (self.data) |value| {
            try writer.print("| {x:0>2} ", .{value});
        }
    }
};