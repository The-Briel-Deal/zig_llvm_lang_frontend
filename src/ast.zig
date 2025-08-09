const std = @import("std");

const ExprAST = struct {
    const Tag = enum {
        number,
        variable,
    };

    const NumberExprAST = struct {
        val: f64,

        fn init(val: f64) NumberExprAST {
            return .{ .val = val };
        }
    };

    const VariableExprAST = struct {
        name: []u8,

        fn init(name: []u8) VariableExprAST {
            return .{ .name = name };
        }
    };

    const BinaryExprAST = struct {
        const BinaryOperator = enum { add, subtract, equals, less, greater };

        op: BinaryOperator,
        lhs: *ExprAST,
        rhs: *ExprAST,

        fn init(op: BinaryOperator, lhs: ExprAST, rhs: ExprAST) BinaryExprAST {
            return .{ .op = op, .lhs = lhs, .rhs = rhs };
        }
    };

    const CallExprAST = struct {
        callee: []u8,
        args: []*ExprAST,

        fn init(callee: []u8, args: []*ExprAST) CallExprAST {
            return .{ .callee = callee, .args = args };
        }
    };

    const Type = union(Tag) {
        number: NumberExprAST,
        variable: VariableExprAST,
    };
    fn init() ExprAST {}
};
