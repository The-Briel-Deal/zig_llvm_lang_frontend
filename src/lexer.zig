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
    eof: bool = false,

    fn init(source: []const u8) TokenIter {
        return .{ .source = source };
    }

    fn currChar(self: *TokenIter) u8 {
        if (self.eof)
            return self.source[self.index]
        else
            return 0x03;
    }

    fn nextChar(self: *TokenIter) bool {
        if (self.eof) return false;
        if (self.index + 1 >= self.source.len) self.eof = true;
        self.index += 1;
        return true;
    }

    fn nextTok(self: *TokenIter) Token {
        while (self.currChar() == ' ')
            if (!self.nextChar()) return .eof;

        if (isAlpha(self.currChar())) {
            const strStart = self.source.ptr + self.index;
            while (isAlnum(self.currChar()))
                if (!self.nextChar()) break;
            const strEnd = self.source.ptr + self.index;

            const token: Token = .init(strStart[0 .. strEnd - strStart]);
            return token;
        }
        if (self.currChar() == 0x03) return .eof;
        unreachable;
    }
};

test "TokenIter" {
    var iter: TokenIter = .init("extern def foo bar");
    try std.testing.expectEqual(.@"extern", iter.nextTok());
    try std.testing.expectEqual(.def, iter.nextTok());

    const fooIdentifier = iter.nextTok();
    try std.testing.expectEqual(Token{ .identifier = "foo" }, fooIdentifier);
    try std.testing.expectEqualStrings(fooIdentifier.identifier, "foo");

    const barIdentifier = iter.nextTok();
    try std.testing.expectEqual(barIdentifier, Token{ .identifier = "bar" });
    try std.testing.expectEqualStrings("bar", barIdentifier.identifier);

    try std.testing.expectEqual(iter.nextTok(), .eof);
    // eof should keep being returned at end of source
    try std.testing.expectEqual(iter.nextTok(), .eof);
    try std.testing.expectEqual(iter.nextTok(), .eof);
}
