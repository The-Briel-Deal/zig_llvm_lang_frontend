const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    var buf: [64]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buf);

    for (builtin.test_functions) |t| {
        t.func() catch |err| {
            try stdout_writer.interface.print("{s} fail: {}\n", .{ t.name, err });
            try stdout_writer.interface.flush();
            continue;
        };
        try stdout_writer.interface.print("{s} passed\n", .{t.name});
        try stdout_writer.interface.flush();
    }
}
