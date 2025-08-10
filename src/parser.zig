const std = @import("std");
const zllf = @import("zllf");

const lexer = zllf.lexer;
const ast = zllf.ast;

const Parser = struct {
    // This is undefined until next is called the first time.
    curr: lexer.Token = undefined,
    iter: lexer.TokenIter,

    fn parseNumber(self: *Parser) !ast.ExprAST {
        switch (self.curr) {
            .number => |val| {
                return ast.ExprAST.NumberExprAST.init(val);
            },
        }
    }

    fn next(self: *Parser) !lexer.Token {
        self.curr = try self.iter.nextTok();
        return self.curr;
    }

    pub fn init(source: []const u8) Parser {
        return .{ .iter = .init(source) };
    }
};

test "Parser.next()" {
    var parser = Parser.init("foo = 42");

    var tok = try parser.next();
    try std.testing.expectEqual(lexer.Token.identifier, std.meta.activeTag(tok));
    try std.testing.expectEqualStrings("foo", tok.identifier);
    try std.testing.expectEqual(tok, parser.curr);

    tok = try parser.next();

    try std.testing.expectEqual(lexer.Token.equal, std.meta.activeTag(tok));
    try std.testing.expectEqual(tok, parser.curr);

    tok = try parser.next();

    try std.testing.expectEqual(lexer.Token.number, std.meta.activeTag(tok));
    try std.testing.expectEqual(42, tok.number);
    try std.testing.expectEqual(tok, parser.curr);
}
