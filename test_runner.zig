const std = @import("std");
const builtin = @import("builtin");

const config = @import("config");

const DEFAULT_COLOR = "\x1b[0m";
const BRIGHT_GREEN_FOREGROUND = "\x1b[92m";
const BRIGHT_YELLOW_FOREGROUND = "\x1b[93m";
const BRIGHT_RED_FOREGROUND = "\x1b[101m";

pub fn main() !void {
    for (builtin.test_functions) |t| {
        var buf: [64]u8 = undefined;
        var stdout = std.fs.File.stdout();

        t.func() catch |err| {
            try stdout.lock(.exclusive);
            defer stdout.unlock();
            var stdout_writer = stdout.writer(&buf);
            _ = try stdout_writer.interface.write(BRIGHT_RED_FOREGROUND);
            _ = try stdout_writer.interface.write("[fail]");
            _ = try stdout_writer.interface.write(DEFAULT_COLOR);
            try stdout_writer.interface.print(" {s}: {}\n", .{ t.name, err });
            try stdout_writer.interface.flush();
            continue;
        };
        try stdout.lock(.exclusive);
        defer stdout.unlock();
        var stdout_writer = stdout.writer(&buf);
        _ = try stdout_writer.interface.write(BRIGHT_GREEN_FOREGROUND);
        _ = try stdout_writer.interface.write("[pass]");
        _ = try stdout_writer.interface.write(DEFAULT_COLOR);
        try stdout_writer.interface.print(" {s}\n", .{t.name});
        try stdout_writer.interface.flush();
    }
}
fn logHandler(
    comptime msg_level: std.log.Level,
    comptime _: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    var buf: [64]u8 = undefined;
    var stdout = std.fs.File.stdout();
    stdout.lock(.exclusive) catch return;
    defer stdout.unlock();
    var stdout_writer = stdout.writer(&buf);

    _ = stdout_writer.interface.write("  ") catch return;
    _ = stdout_writer.interface.write(BRIGHT_YELLOW_FOREGROUND) catch return;
    stdout_writer.interface.print("[{s}]", .{msg_level.asText()}) catch return;
    _ = stdout_writer.interface.write(DEFAULT_COLOR) catch return;
    _ = stdout_writer.interface.write(" ") catch return;
    stdout_writer.interface.print(format, args) catch return;
    _ = stdout_writer.interface.write("\n") catch return;
    stdout_writer.interface.flush() catch return;
}

pub const std_options: std.Options = .{
    .log_level = if (config.enable_debug_logs) .debug else .warn,
    .logFn = logHandler,
};
