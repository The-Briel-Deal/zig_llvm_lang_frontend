const std = @import("std");
const mem = std.mem;
const isAlpha = std.ascii.isAlphabetic;
const isAlnum = std.ascii.isAlphanumeric;

const ASCII_EOT = 0x04;

const TokenTag = enum {
    eof,
    def,
    @"extern",
    identifier,
    number,

    /// Operators
    add,
    subtract,
    equal,
    equal_equal,
    bang_equal,
    less,
    greater,
};

pub const Token = union(TokenTag) {
    eof: void,
    def: void,
    @"extern": void,
    identifier: []const u8,
    number: f64,

    /// Operators
    add: void,
    subtract: void,
    equal: void,
    equal_equal: void,
    bang_equal: void,
    less: void,
    greater: void,

    fn initIdentifier(str: []const u8) Token {
        std.log.debug("Token.initIdentifier('{s}')", .{str});
        if (str.len == 0)
            return .eof;
        if (mem.eql(u8, str, "def"))
            return .def;
        if (mem.eql(u8, str, "extern"))
            return .@"extern";
        return .{ .identifier = str };
    }

    fn initNumber(str: []const u8) !Token {
        std.log.debug("Token.initNumber('{s}')", .{str});
        return .{ .number = try std.fmt.parseFloat(f64, str) };
    }

    const InitOperatorError = error{UnknownOperator};

    fn initOperator(str: []const u8) InitOperatorError!Token {
        std.log.debug("Token.initOperator('{s}')", .{str});
        switch (str[0]) {
            '+' => return .add,
            '-' => return .subtract,
            '=' => {
                if (str.len == 1) return .equal;
                if (str.len == 2 and str[1] == '=') return .equal_equal;
                return InitOperatorError.UnknownOperator;
            },
            '!' => {
                if (str.len == 2 and str[1] == '=') return .bang_equal;
                return InitOperatorError.UnknownOperator;
            },
            '>' => return .greater,
            '<' => return .less,
            else => return InitOperatorError.UnknownOperator,
        }
    }
};

const TokenIterState = enum {
    start,
    startsWithAlpha,
    startsWithDigit,
    startsWithOperator,
    commentUntilNewLine,
};

pub const TokenIter = struct {
    source: []const u8,
    index: ?u32 = null,
    state: TokenIterState = .start,

    pub fn init(source: []const u8) TokenIter {
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

    pub fn nextTok(self: *TokenIter) !Token {
        var strStart: ?u32 = null;
        self.state = .start;
        while (true) {
            const char = self.nextChar() orelse ASCII_EOT;
            switch (self.state) {
                .start => {
                    switch (char) {
                        ASCII_EOT => return .eof,
                        ' ' => continue,
                        'A'...'Z', 'a'...'z' => {
                            strStart = self.index;
                            self.state = .startsWithAlpha;
                            continue;
                        },
                        '0'...'9' => {
                            strStart = self.index;
                            self.state = .startsWithDigit;
                            continue;
                        },
                        '#' => {
                            self.state = .commentUntilNewLine;
                            continue;
                        },
                        '+', '-', '=', '!', '<', '>' => {
                            strStart = self.index;
                            self.state = .startsWithOperator;
                            continue;
                        },
                        else => unreachable,
                    }
                },
                .startsWithAlpha => {
                    if (char != ASCII_EOT and isAlnum(char)) {
                        continue;
                    } else {
                        const strEnd = self.index.?;
                        const token: Token = .initIdentifier(self.source[strStart.?..strEnd]);
                        return token;
                    }
                },
                .startsWithDigit => {
                    switch (char) {
                        '0'...'9' => continue,
                        '.' => continue,
                        else => {
                            const strEnd = self.index.?;
                            return .initNumber(self.source[strStart.?..strEnd]);
                        },
                    }
                },
                .startsWithOperator => {
                    switch (char) {
                        '=' => {
                            return Token.initOperator(self.source[strStart.? .. self.index.? + 1]);
                        },
                        else => return .initOperator(self.source[strStart.? .. strStart.? + 1]),
                    }
                },
                .commentUntilNewLine => {
                    switch (char) {
                        '\n', '\r', ASCII_EOT => self.state = .start,
                        else => continue,
                    }
                },
            }
        }
    }
};

test "TokenIter" {
    var iter: TokenIter = .init("extern def foo bar");
    try std.testing.expectEqual(.@"extern", try iter.nextTok());
    try std.testing.expectEqual(.def, try iter.nextTok());

    const fooIdentifier = try iter.nextTok();
    const fooTag = std.meta.activeTag(fooIdentifier);
    try std.testing.expectEqual(TokenTag.identifier, fooTag);
    try std.testing.expectEqualStrings(fooIdentifier.identifier, "foo");

    const barIdentifier = try iter.nextTok();
    const barTag = std.meta.activeTag(barIdentifier);
    try std.testing.expectEqual(TokenTag.identifier, barTag);
    try std.testing.expectEqualStrings("bar", barIdentifier.identifier);

    try std.testing.expectEqual(try iter.nextTok(), .eof);
    // eof should keep being returned at end of source
    try std.testing.expectEqual(try iter.nextTok(), .eof);
    try std.testing.expectEqual(try iter.nextTok(), .eof);
}

test "TokenIter with numbers" {
    var iter: TokenIter = .init("extern 16 def foo bar");
    try std.testing.expectEqual(.@"extern", try iter.nextTok());

    try std.testing.expectEqual(Token{ .number = 16 }, try iter.nextTok());

    try std.testing.expectEqual(.def, try iter.nextTok());

    const fooIdentifier = try iter.nextTok();
    const fooTag = std.meta.activeTag(fooIdentifier);
    try std.testing.expectEqual(TokenTag.identifier, fooTag);
    try std.testing.expectEqualStrings(fooIdentifier.identifier, "foo");

    const barIdentifier = try iter.nextTok();
    const barTag = std.meta.activeTag(barIdentifier);
    try std.testing.expectEqual(TokenTag.identifier, barTag);
    try std.testing.expectEqualStrings("bar", barIdentifier.identifier);

    try std.testing.expectEqual(try iter.nextTok(), .eof);
    // eof should keep being returned at end of source
    try std.testing.expectEqual(try iter.nextTok(), .eof);
    try std.testing.expectEqual(try iter.nextTok(), .eof);
}

test "TokenIter with comments" {
    const src =
        \\extern def # I love greasy dogs
        \\def foo # bar
    ;
    var iter: TokenIter = .init(src);
    try std.testing.expectEqual(.@"extern", try iter.nextTok());

    try std.testing.expectEqual(.def, try iter.nextTok());

    try std.testing.expectEqual(.def, try iter.nextTok());

    const fooIdentifier = try iter.nextTok();
    const fooTag = std.meta.activeTag(fooIdentifier);
    try std.testing.expectEqual(TokenTag.identifier, fooTag);
    try std.testing.expectEqualStrings(fooIdentifier.identifier, "foo");

    try std.testing.expectEqual(.eof, try iter.nextTok());
    // eof should keep being returned at end of source
    try std.testing.expectEqual(.eof, try iter.nextTok());
    try std.testing.expectEqual(.eof, try iter.nextTok());
}

test "TokenIter with operators" {
    const src = "1.2 < 3.4";
    var iter: TokenIter = .init(src);

    try std.testing.expectEqual(Token{ .number = 1.2 }, try iter.nextTok());
    try std.testing.expectEqual(.less, try iter.nextTok());
    try std.testing.expectEqual(Token{ .number = 3.4 }, try iter.nextTok());
    try std.testing.expectEqual(.eof, try iter.nextTok());
}
