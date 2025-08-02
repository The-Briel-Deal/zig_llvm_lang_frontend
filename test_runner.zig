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
        var stdout_writer = std.fs.File.stdout().writer(&buf);
        t.func() catch |err| {
            _ = stdout_writer.interface.write(BRIGHT_RED_FOREGROUND) catch return;
            try stdout_writer.interface.print("{s} fail: {}\n", .{ t.name, err });
            _ = stdout_writer.interface.write(DEFAULT_COLOR) catch return;
            try stdout_writer.interface.flush();
            continue;
        };
        _ = stdout_writer.interface.write(BRIGHT_GREEN_FOREGROUND) catch return;
        try stdout_writer.interface.print("{s} passed\n", .{t.name});
        _ = stdout_writer.interface.write(DEFAULT_COLOR) catch return;
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
    const stderr_writer = std.debug.lockStderrWriter(&buf);
    defer std.debug.unlockStderrWriter();
    _ = stderr_writer.write("  ") catch return;
    _ = stderr_writer.write(BRIGHT_YELLOW_FOREGROUND) catch return;
    stderr_writer.print("[{s}]", .{msg_level.asText()}) catch return;
    _ = stderr_writer.write(DEFAULT_COLOR) catch return;
    _ = stderr_writer.write(" ") catch return;
    stderr_writer.print(format, args) catch return;
    _ = stderr_writer.write("\n") catch return;
}

pub const std_options: std.Options = .{
    .log_level = if (config.enable_debug_logs) .debug else .warn,
    .logFn = logHandler,
};
