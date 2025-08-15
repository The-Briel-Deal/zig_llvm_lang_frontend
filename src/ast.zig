const std = @import("std");
const AllocError = std.mem.Allocator.Error;

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

    pub fn create(allocator: *std.mem.Allocator, expr_type: Type) AllocError!*ExprAST {
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
        const BinaryOperator = enum { add, subtract, equals, less, greater };

        op: BinaryOperator,
        lhs: *ExprAST,
        rhs: *ExprAST,

        pub fn init(op: BinaryOperator, lhs: ExprAST, rhs: ExprAST) BinaryExprAST {
            return .{ .op = op, .lhs = lhs, .rhs = rhs };
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

    const Type = union(Tag) {
        number: NumberExprAST,
        variable: VariableExprAST,
        binary: BinaryExprAST,
        call: CallExprAST,
    };

    type: Type,
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

test "Create FunctionAST" {
    const function: FunctionAST = .init(
        &.{ .name = "foo", .args = &.{ "boogie", "woogie" } },
        &.{ .type = .{ .number = .{ .val = 42.63 } } },
    );

    try std.testing.expectEqualStrings("foo", function.proto.getName());
}
