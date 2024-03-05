const std = @import("std");

pub const Error = error {
    EndOfStream,
} | std.mem.Allocator.Error;

pub fn Parser(comptime Value: type, comptime Reader: type) type {
    return struct {
        const Self = @This();
        _parse: fn(self: *Self, allocator: *std.mem.Allocator, src: *Reader) callconv(.Inline) Error!?Value,

        pub fn parse(self: *Self, allocator: *std.mem.Allocator, src: *Reader) callconv(.Inline) Error!?Value {
            return self._parse(self, allocator, src);
        }
    };
}

pub fn Literal(comptime Reader: type) type {
    return struct {
        parser: Parser([]u8, Reader) = .{
            ._parse = parse
        },
        want: []const u8,
        
        const Self = @This();

        pub fn init(want: []const u8) Self {
            return Self{
                .want = want,
            };
        }

        fn parse(parser: *Parser([]u8, Reader), allocator: *std.mem.Allocator, src: *Reader) callconv(.Inline) Error!?[]u8 {
            const self = @fieldParentPtr(Self, "parser", parser);
            const buf = try allocator.alloc(u8, self.want.len);
            errdefer allocator.free(buf);

            const read = try src.reader().readAll(buf);
            if (read < self.want.len or !std.mem.eql(u8, self.want, buf)) {
                try src.seekableStream().seekBy(-@as(i64, @intCast(read)));
                allocator.free(buf);
                return null;
            }
            return null;
        }
    };
}