const std = @import("std");
const AllocError = std.mem.Allocator.Error;

const zllf = @import("zllf");
const lexer = zllf.lexer;

pub const ExprAST = struct {
    const Tag = enum {
        number,
        variable,
        binary,
        call,
    };

    pub fn tag(self: *const ExprAST) Tag {
        return std.meta.activeTag(self.type);
    }

    pub fn create(allocator: std.mem.Allocator, expr_type: Type) AllocError!*ExprAST {
        var expr = try allocator.create(ExprAST);
        expr.type = expr_type;

        return expr;
    }

    pub const NumberExprAST = struct {
        val: f64,

        pub fn init(val: f64) NumberExprAST {
            return .{ .val = val };
        }
    };

    pub const VariableExprAST = struct {
        name: []const u8,

        pub fn init(name: []const u8) VariableExprAST {
            return .{ .name = name };
        }
    };

    pub const BinaryExprAST = struct {
        op: lexer.Token,
        lhs: *ExprAST,
        rhs: *ExprAST,

        pub const Error = error{TokenIsNotOperator};

        pub fn init(op: lexer.Token, lhs: *ExprAST, rhs: *ExprAST) Error!BinaryExprAST {
            if (op.isOperator())
                return .{ .op = op, .lhs = lhs, .rhs = rhs };
            return Error.TokenIsNotOperator;
        }
    };

    pub const CallExprAST = struct {
        callee: []const u8,
        args: []*ExprAST,

        pub fn init(callee: []const u8, args: []*ExprAST) CallExprAST {
            return .{
                .callee = callee,
                .args = args,
            };
        }
    };

    pub const Type = union(Tag) {
        number: NumberExprAST,
        variable: VariableExprAST,
        binary: BinaryExprAST,
        call: CallExprAST,
    };

    type: Type,
    fn printIndent(writer: *std.io.Writer, depth: u32) !void {
        for (0..depth) |_|
            try writer.print("  ", .{});
    }

    pub fn printNode(self: *ExprAST, writer: *std.Io.Writer, depth: u32) !void {
        switch (self.type) {
            .binary => |val| {
                try printIndent(writer, depth);
                try writer.print("BinaryExpr:\n", .{});

                try val.lhs.printNode(writer, depth + 1);

                try printIndent(writer, depth + 1);
                try writer.print("op({s})\n", .{@tagName(val.op)});

                try val.rhs.printNode(writer, depth + 1);
            },
            .number => |val| {
                try printIndent(writer, depth);
                try writer.print("NumberExpr({d})\n", .{val.val});
            },
            .variable => |val| {
                try printIndent(writer, depth);
                try writer.print("VariableExpr({s})\n", .{val.name});
            },
            .call => |val| {
                try printIndent(writer, depth);
                try writer.print("CallExpr: {s}(\n", .{val.callee});
                for (val.args) |arg| {
                    try arg.printNode(writer, depth + 1);
                }
            },
        }
    }
};

/// Represents the interface of a function.
const PrototypeAST = struct {
    name: []const u8,
    args: []const []const u8,

    fn init(name: []const u8, args: []const []const u8) PrototypeAST {
        return .{ .name = name, .args = args };
    }

    fn getName(self: PrototypeAST) []const u8 {
        return self.name;
    }
};

const FunctionAST = struct {
    proto: *const PrototypeAST,
    body: *const ExprAST,

    fn init(proto: *const PrototypeAST, body: *const ExprAST) FunctionAST {
        return .{ .proto = proto, .body = body };
    }
};

test "FunctionAST.init()" {
    const function: FunctionAST = .init(
        &.{ .name = "foo", .args = &.{ "boogie", "woogie" } },
        &.{ .type = .{ .number = .{ .val = 42.63 } } },
    );

    try std.testing.expectEqualStrings("foo", function.proto.getName());
}

test "ExprAST.printNode()" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;

    const TestCase = struct {
        case: *ExprAST,
        expect: []const u8,
    };

    const cases = [_]TestCase{
        .{
            .case = try ExprAST.create(
                gpa.allocator(),
                .{
                    .number = .init(46),
                },
            ),
            .expect = (
                \\NumberExpr(46)
                \\
            ),
        },
        .{
            .case = try ExprAST.create(
                gpa.allocator(),
                .{
                    .binary = try .init(
                        .add,
                        try ExprAST.create(
                            gpa.allocator(),
                            .{
                                .number = .init(46),
                            },
                        ),
                        try ExprAST.create(
                            gpa.allocator(),
                            .{
                                .number = .init(102),
                            },
                        ),
                    ),
                },
            ),
            .expect = (
                \\BinaryExpr:
                \\  NumberExpr(46)
                \\  op(add)
                \\  NumberExpr(102)
                \\
            ),
        },
    };
    for (cases) |case| {
        var writer: std.Io.Writer.Allocating = .init(gpa.allocator());
        try case.case.printNode(&writer.writer, 0);
        try std.testing.expectEqualStrings(case.expect, writer.written());
    }
}
