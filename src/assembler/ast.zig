const std = @import("std");
const token = @import("token.zig");
const modes = @import("cpu").modes;
const Instruction = @import("instruction.zig").Instruction;

const Literal = union(enum) {
    Value: u8,
    Label: []const u8
};

const LocationItem = union(enum) {
    Instruction: Instruction,
    Literal: Literal,
};

pub const AST = struct {
    locations: [1024]LocationItem = undefined,
    labels: std.StringHashMap(u16),
    lc: usize = 0,
    tokenIndex: usize = 0,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .locations = undefined,
            .labels = std.StringHashMap(u16).init(allocator),
            .allocator = allocator,
        };
    }

    fn putLabels(self: *Self) !void {
        var i: usize = 0;
        while(i < 1024) {
            const loc = self.locations[i];
            switch(loc) {
                .Literal => |lit| {
                    switch (lit) {
                        .Label => |l| {
                            const value = if (self.labels.get(l)) |v| v else unreachable;
                            const page = self.lc / 256;
                            const addr: u8 = @truncate(value - page * 256);
                            self.locations[i] = LocationItem{.Literal = .{.Value = addr}};
                        },
                        else => {},
                    }
                },
                else => {},
            }
            i += 1;
        }
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

                    const isImmediate = switch(instr.instruction) {
                        .Immediate => true,
                        else => false,
                    };
                    if (isImmediate) {
                        const lit = try self.generateLiteral(tokens);
                        self.locations[self.lc] = LocationItem{.Literal = lit};
                        self.lc += 1;
                    }
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
    }

    fn generateLiteral(self: *Self,  tokens: []const token.Token) !Literal {
        const t = switch (tokens[self.tokenIndex + 1]) {
            .NUMBER => |n| Literal{.Value = @truncate(n)},
            .LABEL => |l| Literal{.Label = l},
            else => unreachable,
        };

        self.tokenIndex += 1;
        return t;
    }

    pub fn writeCode(self: *Self, tokens: []const token.Token, writer: anytype) !void {
        try self.generate(tokens);
        for (self.locations) |loc| {
            switch (loc) {
                .Instruction => |instr| {
                    try writer.writeByte(instr.toOpcode());
                },
                .Literal => |lit| {
                    switch (lit) {
                        .Value => |v| {
                            try writer.writeByte(v);
                        },
                        .Label => unreachable,
                    }
                }
            }
        }
    }

    pub fn deinit(self: *Self) void {
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

test "immediate instruction" {
    var ast = try AST.init(tst.allocator);
    defer ast.deinit();

    const tokens = [_]token.Token{
        .{.INSTRUCTION = .{.Immediate = .LIT}},
        .{.NUMBER = 3},
    };

    try ast.generate(&tokens);
    try tst.expectEqual(Instruction{.instruction=.{.Immediate=.LIT}, .arguments=.{}}, ast.locations[0].Instruction);
    try tst.expectEqual(Literal{.Value = 3}, ast.locations[1].Literal);
}

test "immediate label" {
    var ast = try AST.init(tst.allocator);
    defer ast.deinit();

    const tokens = [_]token.Token{
        .{.INSTRUCTION = .{.Immediate = .LIT}},
        .{.LABEL = "label"},
        .{.INSTRUCTION = .{.Stack = .MOV}},
        .{.ARGUMENT = .k},
        .{.NUMBER = 1},
        .{.LABEL = "label"},
        .{.NUMBER = 17},
    };

    try ast.generate(&tokens);
    try tst.expectEqualStrings("label", ast.locations[1].Literal.Label);
    try ast.putLabels();
    try tst.expectEqual(3, ast.locations[1].Literal.Value);
}