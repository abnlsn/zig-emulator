const std = @import("std");
pub const instruction = @import("instruction.zig");
pub const tokenizer = @import("tokenizer.zig");
pub const token = @import("token.zig");
pub const ast = @import("ast.zig");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len != 2) unreachable;

    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();

    var parser = tokenizer.Parser(@TypeOf(file.reader())).init(file.reader(), gpa);
    // defer parser.deinit(); // TODO
    std.debug.print("Parsing", .{});
    const tokens = try parser.parse();
    std.debug.print("done parsing: {any}", .{tokens});

    const outfile = try std.fs.cwd().createFile("a.rom", .{ .truncate = true, });
    defer file.close();

    var a = try ast.AST.init(gpa);
    try a.writeCode(tokens, outfile.writer());

    defer a.deinit();

    for (args, 0..) |arg, i| {
        std.debug.print("{}: {s}\n", .{ i, arg });
    }
}

test {
    std.testing.refAllDecls(@This());
}