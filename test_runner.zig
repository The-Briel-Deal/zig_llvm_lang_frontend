const std = @import("std");
const builtin = @import("builtin");

const config = @import("config");

const DEFAULT_COLOR = "\x1b[0m";
const BRIGHT_GREEN_FOREGROUND = "\x1b[92m";
const BRIGHT_YELLOW_FOREGROUND = "\x1b[93m";
const BRIGHT_RED_FOREGROUND = "\x1b[101m";

var test_logs_arr: std.ArrayList(u8) = undefined;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    for (builtin.test_functions) |t| {
        var stdout = std.io.getStdOut();
        var stdout_writer = stdout.writer();
        test_logs_arr = .init(gpa.allocator());
        defer {
            stdout_writer.print("{s}", .{test_logs_arr.items}) catch
                @panic("Writing logs to stdout failed!");
            test_logs_arr.clearAndFree();
        }

        t.func() catch |err| {
            try stdout.lock(.exclusive);
            defer stdout.unlock();
            _ = try stdout_writer.write(BRIGHT_RED_FOREGROUND);
            _ = try stdout_writer.write("[fail]");
            _ = try stdout_writer.write(DEFAULT_COLOR);
            try stdout_writer.print(" {s}: {}\n", .{ t.name, err });
            if (@errorReturnTrace()) |st| {
                try st.format("", .{}, &stdout_writer);
            }
            continue;
        };
        try stdout.lock(.exclusive);
        defer stdout.unlock();
        _ = try stdout_writer.write(BRIGHT_GREEN_FOREGROUND);
        _ = try stdout_writer.write("[pass]");
        _ = try stdout_writer.write(DEFAULT_COLOR);
        try stdout_writer.print(" {s}\n", .{t.name});
    }
}

fn logHandler(
    comptime msg_level: std.log.Level,
    comptime _: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    var writer = &test_logs_arr.writer();

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
