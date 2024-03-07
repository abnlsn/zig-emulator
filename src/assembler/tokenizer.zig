const std = @import("std");
const token = @import("./token.zig");
const Token = token.Token;
const Mode = @import("./instruction.zig").Mode;
const instruction = @import("./instruction.zig");

pub const Error = error {
    EndOfStream,
    InvalidToken,
} || std.mem.Allocator.Error || std.io.AnyReader.Error;

pub fn Parser(comptime Reader: type) type {
    return struct {
        peekStream: std.io.PeekStream(.{.Static = 2 }, Reader ), // todo could benefit from std.io.peekStream
        allocator: std.mem.Allocator,
        tokens: std.ArrayList(Token),

        const Self = @This();

        pub fn init(reader: Reader, allocator: std.mem.Allocator) Self {
            return Self {
                .peekStream = std.io.peekStream(2, reader),
                .allocator = allocator,
                .tokens = std.ArrayList(Token).init(allocator),
            };
        }

        pub fn parse(self: *Self) ![]Token {
            while (true) {
                const t = try self.scanToken();
                try self.addToken(t);
            }
            return self.tokens.items;
        }

        fn peek(self: *Self) !u8 {
            const c = try self.peekStream.reader().readByte();
            try self.peekStream.putBackByte(c);
            return c;
        }

        fn read(self: *Self) !u8 {
            return try self.peekStream.reader().readByte();
        }

        fn streamUntilNonAlphaNum(self: *Self, writer: anytype) !void {
            while (std.ascii.isAlphanumeric(try self.peek())) {
                const c = try self.read();
                try writer.writeByte(c);
            }
        }

        fn scanToken(self: *Self) !Token {
            const c = try self.peek();
            switch (c) {
                // single character
                ':' => return Token.COLON,
                '@' => return Token.AT,
                ',' => return Token.COMMA,
                'a'...'z', 'A'...'Z' => {
                    var buf: [16]u8 = undefined;
                    var fbs = std.io.fixedBufferStream(&buf);
                    try self.streamUntilNonAlphaNum(fbs.writer());

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
                else => {
                    _ = try self.read();
                    return self.scanToken();
                },
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

        fn addToken(self: *Self, t: Token) !void {
            try self.tokens.append(t);
        }

    };
}

const tst = std.testing;

test "singleChars" {
    var data = [_]u8{':', ',', '@'};
    var fbs = std.io.fixedBufferStream(&data);
    const reader = fbs.reader();
    var parser = Parser(@TypeOf(reader)).init(reader, tst.allocator);
    _ = try parser.scanToken(); // figure out how to test
}

test "streamUntilNonAlphaNum" {
    const data = "hello ";
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    var parser = Parser(@TypeOf(reader)).init(reader, tst.allocator);

    var buf: [16]u8 = undefined;
    var fbs2 = std.io.fixedBufferStream(&buf);
    try parser.streamUntilNonAlphaNum(fbs2.writer());
    try tst.expectEqualStrings("hello", buf[0..fbs2.pos]);
}

test "instruction" {
    var data = [_]u8{'A', 'D', 'D', ' ', 'S', 'U', 'B', ' '};
    var fbs = std.io.fixedBufferStream(&data);
    const reader = fbs.reader();
    var parser = Parser(@TypeOf(reader)).init(reader, tst.allocator);

    const res = try parser.scanToken();
    try tst.expectEqual(res, Token{.INSTRUCTION = .{.Arithmetic = .ADD}});
    const res1 = try parser.scanToken();
    try tst.expectEqual(res1, Token{.INSTRUCTION = .{.Arithmetic = .SUB}});
}

test "argument" {
    var data = [_]u8{'p', 'o', 's', ' ', 'S', 'U', 'B', ' '};
    var fbs = std.io.fixedBufferStream(&data);
    const reader = fbs.reader();
    var parser = Parser(@TypeOf(reader)).init(reader, tst.allocator);

    const res = try parser.scanToken();
    try tst.expectEqual(Token{.ARGUMENT = .pos}, res);
}