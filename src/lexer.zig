const std = @import("std");
const mem = std.mem;
const isAlpha = std.ascii.isAlphabetic;
const isAlnum = std.ascii.isAlphanumeric;

const ASCII_EOT = 0x04;

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
        std.log.debug("Token.init('{s}')", .{str});
        if (str.len == 0)
            return .eof;
        if (mem.eql(u8, str, "def"))
            return .def;
        if (mem.eql(u8, str, "extern"))
            return .@"extern";
        return .{ .identifier = str };
    }
};

const TokenIterState = enum {
    start,
    startsWithAlpha,
};

pub const TokenIter = struct {
    source: []const u8,
    index: ?u32 = null,
    state: TokenIterState = .start,

    fn init(source: []const u8) TokenIter {
        return .{ .source = source };
    }

    fn nextChar(self: *TokenIter) ?u8 {
        if (self.index == null) {
            self.index = 0;
        } else {
            self.index.? += 1;
            if (self.index.? >= self.source.len) return null;
        }
        const char = self.source[self.index.?];
        return char;
    }

    fn nextTok(self: *TokenIter) Token {
        var strStart: ?u32 = null;
        self.state = .start;
        while (true) {
            const char = self.nextChar() orelse ASCII_EOT;
            switch (self.state) {
                .start => {
                    if (char == ASCII_EOT) return .eof;
                    if (char == ' ') continue;
                    if (isAlpha(char)) {
                        strStart = self.index;
                        self.state = .startsWithAlpha;
                        continue;
                    }
                },
                .startsWithAlpha => {
                    if (char != ASCII_EOT and isAlnum(char)) {
                        continue;
                    } else {
                        const strEnd = self.index.?;
                        const token: Token = .init(self.source[strStart.?..strEnd]);
                        return token;
                    }
                },
            }
        }
    }
};

test "TokenIter" {
    const config = @import("config");

    if (config.enable_debug_logs) {
        std.testing.log_level = .debug;
    }
    var iter: TokenIter = .init("extern def foo bar");
    try std.testing.expectEqual(.@"extern", iter.nextTok());
    try std.testing.expectEqual(.def, iter.nextTok());

    const fooIdentifier = iter.nextTok();
    const fooTag = std.meta.activeTag(fooIdentifier);
    try std.testing.expectEqual(TokenTag.identifier, fooTag);
    try std.testing.expectEqualStrings(fooIdentifier.identifier, "foo");

    const barIdentifier = iter.nextTok();
    const barTag = std.meta.activeTag(barIdentifier);
    try std.testing.expectEqual(TokenTag.identifier, barTag);
    try std.testing.expectEqualStrings("bar", barIdentifier.identifier);

    try std.testing.expectEqual(iter.nextTok(), .eof);
    // eof should keep being returned at end of source
    try std.testing.expectEqual(iter.nextTok(), .eof);
    try std.testing.expectEqual(iter.nextTok(), .eof);
}
