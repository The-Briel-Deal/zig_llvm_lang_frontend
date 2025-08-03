const std = @import("std");
const builtin = @import("builtin");

const config = @import("config");

const DEFAULT_COLOR = "\x1b[0m";
const BRIGHT_GREEN_FOREGROUND = "\x1b[92m";
const BRIGHT_YELLOW_FOREGROUND = "\x1b[93m";
const BRIGHT_RED_FOREGROUND = "\x1b[101m";

var log_buffer: std.ArrayList(u8) = undefined;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    for (builtin.test_functions) |t| {
        var buf: [64]u8 = undefined;
        var stdout = std.fs.File.stdout();
        var stdout_writer = stdout.writer(&buf);
        log_buffer = .init(gpa.allocator());
        defer {
            stdout_writer.interface.print("{s}", .{log_buffer.items}) catch @panic("Writing logs to stdout failed!");
            log_buffer.clearRetainingCapacity();
            stdout_writer.interface.flush() catch @panic("Flushing to stdout failed");
        }

        t.func() catch |err| {
            try stdout.lock(.exclusive);
            defer stdout.unlock();
            _ = try stdout_writer.interface.write(BRIGHT_RED_FOREGROUND);
            _ = try stdout_writer.interface.write("[fail]");
            _ = try stdout_writer.interface.write(DEFAULT_COLOR);
            try stdout_writer.interface.print(" {s}: {}\n", .{ t.name, err });
            continue;
        };
        try stdout.lock(.exclusive);
        defer stdout.unlock();
        _ = try stdout_writer.interface.write(BRIGHT_GREEN_FOREGROUND);
        _ = try stdout_writer.interface.write("[pass]");
        _ = try stdout_writer.interface.write(DEFAULT_COLOR);
        try stdout_writer.interface.print(" {s}\n", .{t.name});
    }
}

fn logHandler(
    comptime msg_level: std.log.Level,
    comptime _: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    var writer = log_buffer.writer();

    _ = writer.write("  ") catch return;
    _ = writer.write(BRIGHT_YELLOW_FOREGROUND) catch return;
    writer.print("[{s}]", .{msg_level.asText()}) catch return;
    _ = writer.write(DEFAULT_COLOR) catch return;
    _ = writer.write(" ") catch return;
    writer.print(format, args) catch return;
    _ = writer.write("\n") catch return;
}

pub const std_options: std.Options = .{
    .log_level = if (config.enable_debug_logs) .debug else .warn,
    .logFn = logHandler,
};
