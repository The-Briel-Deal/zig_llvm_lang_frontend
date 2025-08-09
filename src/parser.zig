const std = @import("std");
const zllf = @import("zllf");

const lexer = zllf.lexer;
const ast = zllf.ast;

const Parser = struct {
    // This is undefined until next is called the first time.
    curr: lexer.Token = undefined,
    iter: lexer.TokenIter,

    fn next(self: Parser) lexer.Token {
        self.curr = try self.iter.nextTok();
        return self.curr;
    }

    pub fn init(source: []const u8) Parser {
        return .{ .iter = .init(source) };
    }
};

test "Parser.next()" {
    var parser = Parser.init("foo = 42");

    const tok = parser.next();
    try std.testing.expectEqual(tok.identifier, "foo");
}
