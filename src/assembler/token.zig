const directive = @import("./directive.zig");
const instruction = @import("./instruction.zig");
const std = @import("std");

pub const Argument = enum {
    pos,
    wst,
    dst,
    pg,
    k
};

pub const TokenType = enum {
    // single-char tokens
    COLON, AT, COMMA,

    // instructions
    INSTRUCTION, DIRECTIVE, ARGUMENT,

    // literals
    LABEL, NUMBER
};

pub const Token = union(TokenType) {
    COLON,
    AT,
    COMMA,
    INSTRUCTION: instruction.Mode,
    DIRECTIVE: directive.Directive,
    ARGUMENT: Argument,
    LABEL: []const u8,
    NUMBER: u64,
};