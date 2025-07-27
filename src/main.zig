const std = @import("std");

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
}

test "foo" {
    try std.testing.expect(1 == 1);
}
