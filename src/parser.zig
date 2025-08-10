const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;

const zllf = @import("zllf");

const lexer = zllf.lexer;
const Token = lexer.Token;
const TokenTag = lexer.TokenTag;
const TokenIter = lexer.TokenIter;

const ast = zllf.ast;
const ExprAST = ast.ExprAST;

const Parser = struct {
    // This is undefined until next is called the first time.
    curr: Token = undefined,
    iter: TokenIter,
    allocator: mem.Allocator,

    const ParseExprError = ParseNumberError || ParseParenError;
    fn parseExpr(self: *Parser) ParseExprError!ExprAST {
        unreachable;
    }

    const ParseNumberError = error{WrongTokenType} || TokenIter.TokenIterError;
    fn parseNumber(self: *Parser) ParseNumberError!ExprAST {
        const result = try switch (self.curr) {
            .number => |val| ExprAST.NumberExprAST.init(val),
            else => error.WrongTokenType,
        };
        _ = try self.next();
        return result;
    }

    const ParseParenError = error{MissingClosingParen};
    fn parseParenExpr(self: *Parser) ParseParenError!ExprAST {
        // Consume '('
        assert(std.meta.activeTag(self.curr) == TokenTag.open_paren);
        _ = try self.next();
        const expr: ExprAST = try self.parseExpr();

        if (std.meta.activeTag(self.curr) != TokenTag.close_paren) {
            return error.MissingClosingParen;
        }
        _ = try self.next();
        return expr;
    }

    fn ParseIdentifierExpr(self: *Parser) ExprAST {}

    fn next(self: *Parser) TokenIter.TokenIterError!Token {
        self.curr = try self.iter.nextTok();
        return self.curr;
    }

    pub fn init(source: []const u8, allocator: mem.Allocator) Parser {
        return .{
            .iter = .init(source),
            .allocator = allocator,
        };
    }
};

test "Parser.next()" {
    var parser = Parser.init("foo = 42");

    var tok = try parser.next();
    try std.testing.expectEqual(Token.identifier, std.meta.activeTag(tok));
    try std.testing.expectEqualStrings("foo", tok.identifier);
    try std.testing.expectEqual(tok, parser.curr);

    tok = try parser.next();

    try std.testing.expectEqual(Token.equal, std.meta.activeTag(tok));
    try std.testing.expectEqual(tok, parser.curr);

    tok = try parser.next();

    try std.testing.expectEqual(Token.number, std.meta.activeTag(tok));
    try std.testing.expectEqual(42, tok.number);
    try std.testing.expectEqual(tok, parser.curr);
}

test "Parser.parseNumber()" {
    var parser = Parser.init("42");

    const tok = try parser.next();

    try std.testing.expectEqual(Token.number, std.meta.activeTag(tok));
    try std.testing.expectEqual(42, tok.number);
    try std.testing.expectEqual(tok, parser.curr);
    const ast_expr = try parser.parseNumber();
    try std.testing.expectEqual(.number, std.meta.activeTag(ast_expr.type));
    try std.testing.expectEqual(42, ast_expr.type.number.val);
}
