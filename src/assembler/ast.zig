const std = @import("std");
const token = @import("token.zig");
const modes = @import("cpu").modes;

const ArgumentUnion = union(token.Argument) {
    pos: u8,
    wst: u8,
    dst: u8,
    pg: u8,
    k: u8,
};

const Instruction = struct {
    instruction: modes.Mode,
    arguments: []ArgumentUnion
};

const Literal = union(enum) {
    Value: u8,
    Label: []const u8
};

const LocationItem = union(enum) {
    Instruction: Instruction,
    Literal: Literal
};

const AST = struct {
    locations: [1024]LocationItem = undefined,
    labels: std.StringHashMap(u16),

    const Self = @This();

    fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .locations = undefined,
            .labels = std.StringHashMap(u16).init(allocator),
        };
    }

    fn generate(self: *Self, tokens: []const token.Token) !void {
        var lc: u16 = 0;
        for (tokens) |t| {
            switch (t) {
                .INSTRUCTION => |i| {
                    // parse instruction
                    self.locations[lc] = .{
                        .Instruction = .{
                            .instruction = i,
                            .arguments = &.{},
                        }
                    };
                    lc += 1;
                },
                .LABEL => |l| {
                    // add to symbol table
                    try self.labels.put(l, lc);
                },
                else => {
                    // ignore
                }
            }
        }
    }

    fn deinit(self: *Self) void {
        self.labels.deinit();
    }
};

const tst = std.testing;
test "init" {
    var ast = try AST.init(tst.allocator);
    defer ast.deinit();
}

test "generate" {
    var ast = try AST.init(tst.allocator);
    defer ast.deinit();

    const tokens = [_]token.Token{token.Token{.LABEL = "hello"}, .{.INSTRUCTION = .{.Arithmetic = .ADD}}};

    try ast.generate(&tokens);

    try tst.expectEqual(1, ast.labels.count());
    try tst.expectEqual(Instruction{.instruction=.{.Arithmetic=.ADD}, .arguments=&.{}}, ast.locations[0].Instruction);
}