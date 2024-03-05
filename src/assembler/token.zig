const directive = @import("./directive.zig");
const instruction = @import("./instruction.zig");

const TokenType = enum {
    // single-char tokens
    COLON, AT, COMMA, SEMICOLON,

    // instructions
    INSTRUCTION, DIRECTIVE,

    // literals
    LITERAL, NUMBER
};

const Token = union(TokenType) {
    DIRECTIVE: directive.Directive,
    INSTRUCTION: instruction.AnyInstruction,
    LITERAL: []const u8,
    NUMBER: u64
};
