const std = @import("std");
const zllf = @import("zllf");
const Token = zllf.lexer.Token;

pub fn main() !void {
    const token: Token = .{ .number = 42 };
    const token2: Token = .{ .identifier = "fooby" };
    std.debug.print("Hello World {any}, {any}\n", .{ token, token2 });
}

test "foo" {
    try std.testing.expect(1 == 1);
}
