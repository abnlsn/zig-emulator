const std = @import("std");
const Cpu = @import("cpu.zig").Cpu;

pub fn main() !void {

    const file = try std.fs.cwd().openFile("bytes.rom", .{});
    defer file.close();

    var cpu = try Cpu.init(file.reader());

    try cpu.print();

    for (0..7) |_| {
        try cpu.step();
        try cpu.print();
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
