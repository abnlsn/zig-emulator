const std = @import("std");
const Token = @import("./token.zig").Token;
const AnyInstruction = @import("./instruction.zig").AnyInstruction;

pub const Error = error {
    EndOfStream,
} | std.mem.Allocator.Error;

fn Parser(comptime Reader: type) type {
    return struct {
        reader: Reader,
        allocator: std.mem.Allocator,
        tokens: std.ArrayList(Token),

        const Self = @This();

        fn init(reader: Reader, allocator: std.mem.Allocator) Parser {
            return Parser {
                .reader = reader,
                .allocator = allocator,
                .tokens = std.ArrayList(Token).init(allocator),
            };
        }

        fn scanToken(self: *Self) !Token {
            const c = try self.reader.readByte();
            switch (c) {
                // single character
                ':' => return Token {.COLON = .{} },
                '@' => return Token {.AT = .{} },
                ',' => return Token {.COMMA = .{} },
                'a'...'z' => {
                    try self.goBack(1);
                    const instr_result = try self.parseInstruction();
                    if (instr_result != null) {
                        return instr_result;
                    }
                    const label_result = try self.parseLabel();
                    return label_result;
                },
                '0'...'9' => {

                }
            }
        }

        fn parseLabel(self: *Self) Error!?Token {
            var buf: [16]u8 = undefined;
            const fbs = std.io.fixedBufferStream(&buf);
            try self.reader.streamUntilDelimiter(fbs.writer(), ' ', 16);
            return Token{.LABEL = &buf };
        }

        fn parseInstruction(self: *Self) Error!?Token {
            var buf: [16]u8 = undefined;
            const fbs = std.io.fixedBufferStream(&buf);
            try self.reader.streamUntilDelimiter(fbs.writer(), ' ', 16);
            return Token{.INSTRUCTION = AnyInstruction.ADD };
        }

        fn goBack(self: *Self, chars: usize) !void {
            try self.reader.seekableStream().seekBy(-@intCast(chars));
        }

        fn addToken(self: *Parser, token: Token) !void {
            try self.tokens.append(token);
        }

    };
}

const tst = std.testing;

test "singleChars" {

}