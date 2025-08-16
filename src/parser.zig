const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const AllocError = mem.Allocator.Error;

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
    const Error = error{
        UnknownTokenForExpr,
        OutOfMemory,
        InvalidCharacter,
        UnknownOperator,
        WrongTokenType,
        UnexpectedArgListToken,
        MissingClosingParen,
    };

    pub fn parseExpr(self: *Parser) Error!*ExprAST {
        return self.parsePrimaryExpr();
    }

    fn parsePrimaryExpr(self: *Parser) !*ExprAST {
        std.log.debug("Parser.parsePrimaryExpr(): self.curr = {any}", .{self.curr});
        return switch (self.curr) {
            .identifier => self.ParseIdentifierExpr(),
            .number => self.parseNumber(),
            .open_paren => self.parseParenExpr(),
            else => error.UnknownTokenForExpr,
        };
    }

    fn parseNumber(self: *Parser) !*ExprAST {
        const result = try switch (self.curr) {
            .number => |val| ExprAST.create(
                &self.allocator,
                .{ .number = .init(val) },
            ),
            else => error.WrongTokenType,
        };
        _ = try self.next();
        return result;
    }

    fn parseParenExpr(self: *Parser) !*ExprAST {
        // Consume '('
        assert(self.curr.tag() == TokenTag.open_paren);
        _ = try self.next();
        const expr: *ExprAST = try self.parseExpr();

        if (self.curr.tag() != TokenTag.close_paren) {
            return error.MissingClosingParen;
        }
        _ = try self.next();
        return expr;
    }

    fn ParseIdentifierExpr(self: *Parser) !*ExprAST {
        assert(self.curr.tag() == TokenTag.identifier);
        const name = self.curr.identifier;
        _ = try self.next(); // Consume identifier

        switch (self.curr) {
            .open_paren => {
                _ = try self.next(); // Consume '('
                var args: std.ArrayList(*ExprAST) = .init(self.allocator);
                while (true) {
                    const arg = try self.parseExpr();
                    try args.append(arg);

                    if (self.curr.tag() == TokenTag.close_paren)
                        break;
                    if (self.curr.tag() == TokenTag.comma) {
                        _ = try self.next();
                        continue;
                    }
                    return error.UnexpectedArgListToken;
                }
                // Consume ')'
                assert(self.curr == TokenTag.close_paren);
                _ = try self.next();
                return ExprAST.create(&self.allocator, .{ .call = .init(name, args.items) });
            },
            else => {
                return ExprAST.create(
                    &self.allocator,
                    .{ .variable = .init(name) },
                );
            },
        }
    }

    fn next(self: *Parser) TokenIter.Error!Token {
        self.curr = try self.iter.nextTok();
        return self.curr;
    }

    pub fn init(allocator: mem.Allocator, source: []const u8) Parser {
        return .{
            .iter = .init(source),
            .allocator = allocator,
        };
    }
};

test "Parser.next()" {
    var dbg_allocator: std.heap.DebugAllocator(.{ .safety = true }) = .init;
    var parser = Parser.init(dbg_allocator.allocator(), "foo = 42");

    var tok = try parser.next();
    try std.testing.expectEqual(Token.identifier, tok.tag());
    try std.testing.expectEqualStrings("foo", tok.identifier);
    try std.testing.expectEqual(tok, parser.curr);

    tok = try parser.next();

    try std.testing.expectEqual(Token.equal, tok.tag());
    try std.testing.expectEqual(tok, parser.curr);

    tok = try parser.next();

    try std.testing.expectEqual(Token.number, tok.tag());
    try std.testing.expectEqual(42, tok.number);
    try std.testing.expectEqual(tok, parser.curr);
}

test "Parser.parseNumber()" {
    var dbg_allocator: std.heap.DebugAllocator(.{ .safety = true }) = .init;
    defer {
        const check = dbg_allocator.deinit();
        assert(check == std.heap.Check.ok);
    }
    var arena: std.heap.ArenaAllocator = .init(dbg_allocator.allocator());
    defer arena.deinit();

    var parser = Parser.init(arena.allocator(), "42");

    const tok = try parser.next();

    try std.testing.expectEqual(Token.number, tok.tag());
    try std.testing.expectEqual(42, tok.number);
    try std.testing.expectEqual(tok, parser.curr);
    const ast_expr = try parser.parseNumber();
    try std.testing.expectEqual(.number, std.meta.activeTag(ast_expr.type));
    try std.testing.expectEqual(42, ast_expr.type.number.val);
}

test "Parser.parseExpr()" {
    var dbg_allocator: std.heap.DebugAllocator(.{ .safety = true }) = .init;
    defer {
        const check = dbg_allocator.deinit();
        assert(check == std.heap.Check.ok);
    }
    var arena: std.heap.ArenaAllocator = .init(dbg_allocator.allocator());
    defer arena.deinit();

    var parser = Parser.init(arena.allocator(), "42");

    const expr: *ExprAST = try parser.parseExpr();

    try std.testing.expectEqual(.number, expr.tag());
}
