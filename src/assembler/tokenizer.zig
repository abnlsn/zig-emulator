const std = @import("std");
const token = @import("./token.zig");
const Token = token.Token;
const Mode = @import("./instruction.zig").Mode;
const instruction = @import("./instruction.zig");

pub const Error = error {
    EndOfStream,
    InvalidToken,
} || std.mem.Allocator.Error || std.io.AnyReader.Error;

fn Parser(comptime Reader: type) type {
    return struct {
        reader: Reader,
        allocator: std.mem.Allocator,
        tokens: std.ArrayList(Token),

        const Self = @This();

        fn init(reader: Reader, allocator: std.mem.Allocator) Self {
            return Self {
                .reader = reader,
                .allocator = allocator,
                .tokens = std.ArrayList(Token).init(allocator),
            };
        }

        fn scanToken(self: *Self) !Token {
            const c = try self.reader.reader().readByte();
            switch (c) {
                // single character
                ':' => return Token {.COLON = .{} },
                '@' => return Token {.AT = .{} },
                ',' => return Token {.COMMA = .{} },
                'a'...'z', 'A'...'Z' => {
                    try self.goBack(1);

                    var buf: [16]u8 = undefined;
                    var fbs = std.io.fixedBufferStream(&buf);
                    try self.reader.reader().streamUntilDelimiter(fbs.writer(), ' ', 16);

                    const str = buf[0..fbs.pos];

                    const instr_result = try parseInstruction(str);
                    if (instr_result) |instr| {
                        return instr;
                    }
                    if (try parseArgument(str)) |arg| {
                        return arg;
                    }
                    // otherwise interpret as a label
                    const label_result = try parseLabel(str);
                    return label_result.?;
                },
                '0'...'9' => {
                    return Token{.NUMBER = 0};
                },
                else => return error.InvalidToken,
            }
        }

        fn parseLabel(str: []const u8) Error!?Token {
            return Token{.LABEL = str };
        }

        fn parseInstruction(str: []const u8) Error!?Token {
            const instr = instruction.instructionMap.get(str);

            if (instr) |some_instr| {
                return Token{.INSTRUCTION = some_instr};
            } else {
                return null;
            }
        }

        fn parseArgument(str: []const u8) Error!?Token {
            const argument = std.meta.stringToEnum(token.Argument, str);
            if (argument) |arg| {
                return Token{.ARGUMENT = arg};
            } else {
                return null;
            }
        }

        fn goBack(self: *Self, chars: usize) !void {
            try self.reader.seekableStream().seekBy(-@as(i64, @intCast(chars)));
        }

        fn addToken(self: *Parser, t: Token) !void {
            try self.tokens.append(t);
        }

    };
}

const tst = std.testing;

test "singleChars" {
    var data = [_]u8{':', ',', '@'};
    const fbs = std.io.fixedBufferStream(&data);
    var parser = Parser(@TypeOf(fbs)).init(fbs, tst.allocator);
    _ = try parser.scanToken(); // figure out how to test
}

test "instruction" {
    var data = [_]u8{'A', 'D', 'D', ' ', 'S', 'U', 'B', ' '};
    const fbs = std.io.fixedBufferStream(&data);
    var parser = Parser(@TypeOf(fbs)).init(fbs, tst.allocator);

    const res = try parser.scanToken();
    try tst.expectEqual(res, Token{.INSTRUCTION = .{.Arithmetic = .ADD}});
    const res1 = try parser.scanToken();
    try tst.expectEqual(res1, Token{.INSTRUCTION = .{.Arithmetic = .SUB}});
}

test "argument" {
    var data = [_]u8{'p', 'o', 's', ' ', 'S', 'U', 'B', ' '};
    const fbs = std.io.fixedBufferStream(&data);
    var parser = Parser(@TypeOf(fbs)).init(fbs, tst.allocator);

    const res = try parser.scanToken();
    try tst.expectEqual(Token{.ARGUMENT = .pos}, res);
}