const std = @import("std");
const token = @import("token.zig");
const modes = @import("cpu").modes;

const Instruction = struct {
    instruction: modes.Mode,
    arguments: struct {
        pos: u8 = 0,
        wst: u8 = 0,
        dst: u8 = 0,
        pg: u8 = 0,
        k: u8 = 0,
    },

    const Self = @This();

};

const Literal = union(enum) {
    Value: u8,
    Label: []const u8
};

const LocationItem = union(enum) {
    Instruction: Instruction,
    Literal: Literal,
};

const AST = struct {
    locations: [1024]LocationItem = undefined,
    labels: std.StringHashMap(u16),
    lc: usize = 0,
    tokenIndex: usize = 0,
    allocator: std.mem.Allocator,

    const Self = @This();

    fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .locations = undefined,
            .labels = std.StringHashMap(u16).init(allocator),
            .allocator = allocator,
        };
    }

    fn generate(self: *Self, tokens: []const token.Token) !void {
        while (self.tokenIndex < tokens.len) {
            const t = tokens[self.tokenIndex];
            switch (t) {
                .INSTRUCTION => {
                    // parse instruction
                    const instr = try self.generateInstruction(tokens);
                    self.locations[self.lc] = LocationItem{.Instruction = instr};
                    self.lc += 1;
                },
                .LABEL => |l| {
                    // add to symbol table
                    try self.labels.put(l, @truncate(self.lc));
                },
                else => {
                    // ignore
                }
            }
            self.tokenIndex += 1;
        }
    }

    fn generateInstruction(self: *Self, tokens: []const token.Token) !Instruction {
        const t = tokens[self.tokenIndex];

        const mode = t.INSTRUCTION;

        const isImmediate = switch (mode) {
            .Immediate => true,
            else => false,
        };

        _ = isImmediate;
            
        var instr = Instruction{.instruction = mode, .arguments = .{}};

        while (self.tokenIndex < tokens.len - 1 and tokens[self.tokenIndex + 1] == .ARGUMENT) {
            self.tokenIndex += 1;
            const arg = switch(tokens[self.tokenIndex]) {
                .ARGUMENT => |a| a,
                else => unreachable,
            };

            const value = switch (tokens[self.tokenIndex + 1]) {
                .NUMBER => |n| blk: {
                    self.tokenIndex += 1;
                    break :blk @as(u8, @truncate(n));
                },
                else => unreachable
            };

            switch (arg) {
                .pos => instr.arguments.pos = value,
                .wst => instr.arguments.wst = value,
                .dst => instr.arguments.dst = value,
                .pg => instr.arguments.pg = value,
                .k => instr.arguments.k = value,
            }
        }
        
        return instr;

        // if it is immediate, we need to check for literal after the instruction
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

test "generate function simple" {
    var ast = try AST.init(tst.allocator);
    defer ast.deinit();

    const tokens = [_]token.Token{.{.INSTRUCTION = .{.Arithmetic = .ADD}}};

    try ast.generate(&tokens);

    try tst.expectEqual(Instruction{.instruction=.{.Arithmetic=.ADD}, .arguments=.{}}, ast.locations[0].Instruction);
}

test "generate function with arguments" {
    var ast = try AST.init(tst.allocator);
    defer ast.deinit();

    const tokens = [_]token.Token{
        .{.INSTRUCTION = .{.Arithmetic = .ADD}},
        .{.ARGUMENT = .pos},
        .{.NUMBER = 1},
        .{.INSTRUCTION = .{.Arithmetic = .SUB}},
    };

    try ast.generate(&tokens);

    try tst.expectEqual(1, ast.locations[0].Instruction.arguments.pos);
    try tst.expectEqual(Instruction{.instruction=.{.Arithmetic=.SUB}, .arguments=.{}}, ast.locations[1].Instruction);
}