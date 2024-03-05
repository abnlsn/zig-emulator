const directive = @import("./directive.zig");
const instruction = @import("./instruction.zig");

const Argument = enum {
    pos,
    wst,
    dst,
    pg,
    k
};

const TokenType = enum {
    // single-char tokens
    COLON, AT, COMMA,

    // instructions
    INSTRUCTION, DIRECTIVE, ARGUMENT,

    // literals
    LABEL, NUMBER
};

const Token = union(TokenType) {
    DIRECTIVE: directive.Directive,
    INSTRUCTION: instruction.AnyInstruction,
    LITERAL: []const u8,
    NUMBER: u64,
    ARGUMENT: Argument,
};