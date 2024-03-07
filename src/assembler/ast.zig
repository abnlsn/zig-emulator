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
    arguments: std.ArrayList(ArgumentUnion),

    const Self = @This();

    fn init(instruction: modes.Mode, allocator: std.mem.Allocator) Self {
        return Self{
            .instruction = instruction,
            .arguments = std.ArrayList(ArgumentUnion).init(allocator),
        };

    }
    fn deinit(self: *Self) void {
        self.arguments.deinit();
    }

    fn addArgument(self: *Self, arg: ArgumentUnion) void {
        self.arguments.append(arg);
    }
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
                    try self.generateInstruction(tokens);
                    self.lc += 1;
                },
                .LABEL => |l| {
                    // add to symbol table
                    try self.labels.put(l, self.lc);
                },
                else => {
                    // ignore
                }
            }
            self.tokenIndex += 1;
        }
    }

    fn generateInstruction(self: *Self, tokens: []const token.Token) !void {
        const t = tokens[self.tokenIndex];

        const mode = t.INSTRUCTION;

        const isImmediate = switch (mode) {
            .Immediate => true,
            else => false,
        };

        _ = isImmediate;
            
        var instr = Instruction.init(mode, self.allocator);

        while (tokens[self.tokenIndex + 1] == .ARGUMENT) {
            self.tokenIndex += 1;
            const arg = tokens[self.tokenIndex].ARGUMENT;
            instr.addArgument(.{.Argument = arg});
        }

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

test "generate" {
    var ast = try AST.init(tst.allocator);
    defer ast.deinit();

    const tokens = [_]token.Token{token.Token{.LABEL = "hello"}, .{.INSTRUCTION = .{.Arithmetic = .ADD}}};

    try ast.generate(&tokens);

    try tst.expectEqual(1, ast.labels.count());
    try tst.expectEqual(Instruction{.instruction=.{.Arithmetic=.ADD}, .arguments=&.{}}, ast.locations[0].Instruction);
}