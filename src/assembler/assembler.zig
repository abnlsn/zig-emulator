const std = @import("std");
pub const instruction = @import("instruction.zig");
pub const tokenizer = @import("tokenizer.zig");
pub const token = @import("token.zig");
pub const ast = @import("ast.zig");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    defer {
        const deinit_status = general_purpose_allocator.deinit();
        if (deinit_status != .ok) {
            std.debug.print("{any}", .{deinit_status});
        }
    }

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len != 2) unreachable;

    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();

    var parser = tokenizer.Parser(@TypeOf(file.reader())).init(file.reader(), gpa);
    defer parser.deinit();

    const tokens = try parser.parse();

    const outfile = try std.fs.cwd().createFile("a.rom", .{ .truncate = true, });
    defer outfile.close();

    var a = try ast.AST.init(tokens, gpa);
    defer a.deinit();

    try a.writeCode(outfile.writer());


}

test {
    std.testing.refAllDecls(@This());
}