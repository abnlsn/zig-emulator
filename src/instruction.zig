const std = @import("std");

pub fn is_keep(instr: u8) bool {
    return (instr & 0b1000_0000) != 0;
}

pub fn get_wst(instr: u8) u8 {
    return (instr & 0b0100_0000) >> 6;
}

pub const mode = enum(u8) {
    immediate = 0,
    arithmetic = 1,
    stack = 2,
    memory = 3,
};

pub fn get_mode(instr: u8) mode {
    return @enumFromInt((instr & 0b0011_0000) >> 4);
}

const testing = std.testing;

test "keep" {
    const instr = 0b0000_0000;
    try testing.expect(!is_keep(instr));

    const instr1 = 0b1000_0000;
    try testing.expect(is_keep(instr1));
}

test "wst" {
    const instr = 0b0000_0000;
    try testing.expect(get_wst(instr) == 0);

    const instr1 = 0b0100_0000;
    try testing.expect(get_wst(instr1) == 1);
}

test "get mode" {
    var i: u8 = 0;
    while (i < 4) {
        const instr = i << 4;
        try testing.expect(get_mode(instr) == @as(mode, @enumFromInt(i)));
        i += 1;
    }
}