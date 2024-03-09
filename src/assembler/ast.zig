const std = @import("std");
const token = @import("token.zig");
const modes = @import("cpu").modes;
const Instruction = @import("instruction.zig").Instruction;

pub const TokenReader = struct {
    tokens: []const token.Token,
    pos: usize = 0,

    const Self = @This();

    pub fn init(tokens: []const token.Token) Self {
        return Self{
            .tokens = tokens,
        };
    }

    pub fn next(self: *Self) ?token.Token {
        if (self.peek()) |t| {
            self.pos += 1;
            return t;
        }
        return null;
    }

    pub fn peek(self: *Self) ?token.Token {
        if (self.pos >= self.tokens.len) {
            return null;
        }
        return self.tokens[self.pos];
    }
};

const Literal = union(enum) {
    Value: u8,
    Label: []const u8
};

fn freeLabel(allocator: std.mem.Allocator, label: []const u8) void {
    const ptr = label.ptr;
    allocator.free(ptr[0..16]);
}

const LocationItem = union(enum) {
    Instruction: Instruction,
    Literal: Literal,
};

pub const AST = struct {
    locations: [1024]?LocationItem,
    labels: std.StringHashMap(u16),
    lc: usize = 0,
    tokens: TokenReader,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(tokens: []const token.Token, allocator: std.mem.Allocator) !Self {
        return Self{
            .locations = [_]?LocationItem{null} ** 1024,
            .labels = std.StringHashMap(u16).init(allocator),
            .allocator = allocator,
            .tokens = TokenReader.init(tokens),
        };
    }

    fn appendLocation(self: *Self, location: LocationItem) !void {
        self.locations[self.lc] = location;
        self.lc += 1;
    }

    fn putLabels(self: *Self) !void {
        var i: usize = 0;
        while(i < 1024) : (i += 1) {
            const loc = self.locations[i] orelse continue;
            switch(loc) {
                .Literal => |lit| {
                    switch (lit) {
                        .Label => |l| {
                            defer freeLabel(self.allocator, l); // we won't be needing label anymore, so free it

                            const value = self.labels.get(l) orelse unreachable;
                            const page = self.lc / 256;
                            const addr: u8 = @truncate(value - page * 256);
                            self.locations[i] = LocationItem{.Literal = .{.Value = addr}};
                        },
                        else => {},
                    }
                },
                else => {},
            }
        }
    }

    fn generate(self: *Self) !void {
        while (self.tokens.peek()) |nextToken| {
            switch (nextToken) {
                .INSTRUCTION => {
                    // parse instruction
                    const instr = try Instruction.fromTokens(&self.tokens);
                    try self.appendLocation(.{.Instruction = instr});

                    const isImmediate = instr.instruction == .Immediate;
                    if (isImmediate) {
                        const lit = try self.generateLiteral();
                        try self.appendLocation(.{.Literal = lit});
                    }
                },
                .LABEL => |l| {
                    // add to symbol table
                    _ = self.tokens.next();
                    try self.labels.put(l, @truncate(self.lc));

                    if (self.tokens.next().? != .COLON) {
                        return error.InvalidSyntax;
                    }
                },
                else => |v| {
                    std.debug.print("{any}", .{v});
                    // ignore
                    unreachable;
                }
            }
        }
    }

    fn generateLiteral(self: *Self) !Literal {
        if (self.tokens.next()) |t| {
            switch (t) {
                .HASH => {},
                else => return error.InvalidLiteral
            }
        }
        return switch (self.tokens.next().?) {
            .NUMBER => |n| Literal{.Value = @truncate(n)},
            .LABEL => |l| Literal{.Label = l},
            else => unreachable,
        };
    }

    pub fn writeCode(self: *Self, writer: anytype) !void {
        try self.generate();
        try self.putLabels();
        var i: usize = 0;
        while (i < 1024) : (i += 1) {
            const loc = self.locations[i];
            if (loc == null) {
                try writer.writeByte(0);
                continue;
            }
            switch (loc.?) {
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
        var iter = self.labels.keyIterator();
        while (iter.next()) |label| {
            freeLabel(self.allocator, label.*);
        }
        self.labels.deinit();
    }
};

const tst = std.testing;
test "init" {
    var ast = try AST.init(&[_]token.Token{}, tst.allocator);
    defer ast.deinit();
}

test "generate function simple" {

    const tokens = [_]token.Token{.{.INSTRUCTION = .{.Arithmetic = .ADD}}};
    
    var ast = try AST.init(&tokens, tst.allocator);
    defer ast.deinit();

    try ast.generate();

    try tst.expectEqual(Instruction{.instruction=.{.Arithmetic=.ADD}, .arguments=.{}}, ast.locations[0].?.Instruction);
}

test "generate function with arguments" {

    const tokens = [_]token.Token{
        .{.INSTRUCTION = .{.Arithmetic = .ADD}},
        .{.ARGUMENT = .pos},
        .{.NUMBER = 1},
        .{.INSTRUCTION = .{.Arithmetic = .SUB}},
    };

    var ast = try AST.init(&tokens, tst.allocator);
    defer ast.deinit();

    try ast.generate();

    try tst.expectEqual(1, ast.locations[0].?.Instruction.arguments.pos);
    try tst.expectEqual(Instruction{.instruction=.{.Arithmetic=.SUB}, .arguments=.{}}, ast.locations[1].?.Instruction);
}

test "immediate instruction" {

    const tokens = [_]token.Token{
        .{.INSTRUCTION = .{.Immediate = .LIT}},
        .{.NUMBER = 3},
    };
    var ast = try AST.init(&tokens, tst.allocator);
    defer ast.deinit();

    try ast.generate();
    try tst.expectEqual(Instruction{.instruction=.{.Immediate=.LIT}, .arguments=.{}}, ast.locations[0].?.Instruction);
    try tst.expectEqual(Literal{.Value = 3}, ast.locations[1].?.Literal);
}

test "immediate label" {

    const tokens = [_]token.Token{
        .{.INSTRUCTION = .{.Immediate = .LIT}},
        .{.LABEL = "label"},
        .{.INSTRUCTION = .{.Stack = .MOV}},
        .{.ARGUMENT = .k},
        .{.NUMBER = 1},
        .{.LABEL = "label"},
        .{.COLON = {} },
        .{.INSTRUCTION = .{.Immediate = .LIT}},
        .{.NUMBER = 17},
    };
    
    var ast = try AST.init(&tokens, tst.allocator);
    defer ast.deinit();

    try ast.generate();
    try tst.expectEqualStrings("label", ast.locations[1].?.Literal.Label);
    try ast.putLabels();
    try tst.expectEqual(3, ast.locations[1].?.Literal.Value);
}