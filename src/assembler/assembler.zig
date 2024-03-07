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

    const tokens = try parser.parse();

    const outfile = try std.fs.cwd().createFile("a.rom", .{ .truncate = true, });
    defer outfile.close();

    var a = try ast.AST.init(gpa);
    try a.writeCode(tokens, outfile.writer());

    defer a.deinit();

}

test {
    std.testing.refAllDecls(@This());
}