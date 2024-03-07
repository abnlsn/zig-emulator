const std = @import("std");
const Cpu = @import("cpu").Cpu;

pub fn main() !void {

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len != 2) unreachable;

    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();

    var cpu = try Cpu.init(file.reader());

    try cpu.run();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
