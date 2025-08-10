const std = @import("std");

pub const ExprAST = struct {
    const Tag = enum {
        number,
        variable,
        binary,
        call,
    };

    pub const NumberExprAST = struct {
        val: f64,

        pub fn init(val: f64) ExprAST {
            return .{
                .type = .{
                    .number = .{
                        .val = val,
                    },
                },
            };
        }
    };

    pub const VariableExprAST = struct {
        name: []u8,

        pub fn init(name: []u8) ExprAST {
            return .{
                .type = .{
                    .variable = .{
                        .name = name,
                    },
                },
            };
        }
    };

    pub const BinaryExprAST = struct {
        const BinaryOperator = enum { add, subtract, equals, less, greater };

        op: BinaryOperator,
        lhs: *ExprAST,
        rhs: *ExprAST,

        pub fn init(op: BinaryOperator, lhs: ExprAST, rhs: ExprAST) ExprAST {
            return .{
                .type = .{
                    .binary = .{
                        .op = op,
                        .lhs = lhs,
                        .rhs = rhs,
                    },
                },
            };
        }
    };

    pub const CallExprAST = struct {
        callee: []u8,
        args: []*ExprAST,

        pub fn init(callee: []u8, args: []*ExprAST) ExprAST {
            return .{
                .type = .{
                    .call = .{
                        .callee = callee,
                        .args = args,
                    },
                },
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
