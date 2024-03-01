const std = @import("std");
const stack = @import("stack.zig");
const instruction = @import("instruction.zig");

const MemoryError = error {
    OutOfBounds,
};

const Memory = struct {
    data: [1024]u8,

    const Self = @This();

    fn init() Self {
        return .{ .data = undefined };
    }

    fn load(self: *Self, reader: anytype) !void {
        var bytes = try reader.read(&self.data);
        while (bytes < 1024) {
            self.data[bytes] = 0;
            bytes += 1;
        }
    }

    fn read(self: *const Self, addr: u16) !u8 {
        if (addr >= 1024) return error.OutOfBounds;
        return self.data[addr];
    }

    fn write(self: *Self, addr: u16, value: u8) !void {
        if (addr >= 1024) return error.OutOfBounds;
        self.data[addr] = value;
    }
};

pub const Cpu = struct {
    mem: Memory,
    s0: stack.Stack,
    s1: stack.Stack,
    pc: u16,

    const Self = @This();

    pub fn init(reader: anytype) !Cpu {
        var mem = Memory.init();
        try mem.load(reader);
        return .{
            .mem = mem,
            .s0 = stack.Stack.init(),
            .s1 = stack.Stack.init(),
            .pc = 0,
        };
    }

    pub fn push_stack(self: *Self, wst: u8, value: u8) !void {
        try switch (wst) {
            0 => self.s0.push(value),
            1 => self.s1.push(value),
            else => unreachable,
        };
    }

    pub fn get_stack(self: *Self, wst: u8) !*stack.Stack {
        return switch(wst) {
            0 => &self.s0,
            1 => &self.s1,
            else => unreachable,
        };
    }

    pub fn fetch(self: *Self) !u8 {
        const value = self.mem.read(self.pc);
        self.pc += 1;
        return value;
    }

    pub fn step(self: *Self) !void {
        const instr = try self.fetch();

        const modes = @import("modes/modes.zig");

        switch (instruction.get_mode(instr)) {
            .immediate => {
                try modes.immediate.handleImmediate(self, instr);
            },
            .arithmetic => {
            },
            .stack => {
                try modes.stack.handleStack(self, instr);
            },
            .memory => {

            },
        }
    }


    pub fn print(self: *const Self) !void {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("cpu\ns0:\n", .{});
        try self.s0.print(stdout);
        try stdout.print("\ns1:\n", .{});
        try self.s1.print(stdout);
        try stdout.print("\n", .{});
    }
};

const tst = std.testing;

test "memory load" {
    const instructions = [_]u8{0x01};

    const data: []const u8 = &instructions;

    var fbs = std.io.fixedBufferStream(data);

    var mem = Memory.init();

    try mem.load(fbs.reader());

    try tst.expect(mem.data[0] == 0x01);

}

test "cpu" {
    // LIT 0xFF opcode
    const instructions = [_]u8{0x00, 0xFF};

    const data: []const u8 = &instructions;
    var fbs = std.io.fixedBufferStream(data);

    var cpu = try Cpu.init(fbs.reader());

    try cpu.step();

    try tst.expect(cpu.s0.data[0] == 0xFF);

}