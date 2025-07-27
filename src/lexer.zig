const std = @import("std");
const mem = std.mem;
const isAlpha = std.ascii.isAlphabetic;
const isAlnum = std.ascii.isAlphanumeric;

const TokenTag = enum(i8) {
    eof = -1,

    def = -2,
    @"extern" = -3,

    identifier = -4,
    number = -5,
};

pub const Token = union(TokenTag) {
    eof: void,

    def: void,
    @"extern": void,

    identifier: []const u8,
    number: f64,

    fn init(str: []const u8) Token {
        if (str.len == 0)
            return .eof;
        if (mem.eql(u8, str, "def"))
            return .def;
        if (mem.eql(u8, str, "extern"))
            return .@"extern";
        return .{ .identifier = str };
    }
};

pub const TokenIter = struct {
    source: []const u8,
    index: u32 = 0,

    fn init(source: []const u8) TokenIter {
        return .{ .source = source };
    }

    fn currChar(self: *TokenIter) u8 {
        return self.source[self.index];
    }
    fn nextChar(self: *TokenIter) ?u8 {
        if (self.index + 1 >= self.source.len) return null;
        self.index += 1;
        return self.source[self.index];
    }

    fn nextTok(self: *TokenIter) Token {
        while (self.currChar() == ' ')
            _ = self.nextChar() orelse return .eof;

        if (isAlpha(self.currChar())) {
            const strStart = self.source.ptr + self.index;
            while (isAlnum(self.currChar()))
                _ = self.nextChar() orelse break;
            const strEnd = self.source.ptr + self.index;

            const token: Token = .init(strStart[0 .. strEnd - strStart]);
            return token;
        }
        unreachable;
    }
};

test "TokenIter" {
    var iter: TokenIter = .init("extern def foo");
    try std.testing.expect(iter.nextTok() == .@"extern");
    try std.testing.expect(iter.nextTok() == .def);
    try std.testing.expect(iter.nextTok() == .identifier);
    try std.testing.expect(iter.nextTok() == .eof);
    // eof should keep being returned at end of source
    try std.testing.expect(iter.nextTok() == .eof);
    try std.testing.expect(iter.nextTok() == .eof);
}
