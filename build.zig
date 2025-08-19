const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const zllf_mod = b.createModule(.{
        .root_source_file = b.path("src/zllf.zig"),
        .target = target,
        .optimize = optimize,
    });
    zllf_mod.addImport("zllf", zllf_mod);

    const exe = b.addExecutable(.{
        .name = "zig_llvm_lang_frontend",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zllf", .module = zllf_mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const test_runner: std.Build.Step.Compile.TestRunner = .{
        .path = b.path("test_runner.zig"),
        .mode = .simple,
    };

    const test_filter = b.option([]const u8, "test_filter", "test filter");
    const exe_tests = b.addTest(.{
        .name = "exe_tests",
        .root_module = exe.root_module,
        .test_runner = test_runner,
        .use_llvm = true,
        .filters = if (test_filter != null) &.{test_filter.?} else &.{},
    });
    const zllf_tests = b.addTest(.{
        .name = "zllf_tests",
        .root_module = zllf_mod,
        .test_runner = test_runner,
        .use_llvm = true,
        .filters = if (test_filter != null) &.{test_filter.?} else &.{},
    });

    const enable_debug_logs = b.option(bool, "enable_debug_logs", "enable debug logging") orelse false;

    const options = b.addOptions();
    options.addOption(bool, "enable_debug_logs", enable_debug_logs);
    zllf_tests.root_module.addOptions("config", options);
    exe_tests.root_module.addOptions("config", options);

    const run_exe_tests = b.addRunArtifact(exe_tests);
    const run_zllf_tests = b.addRunArtifact(zllf_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
    test_step.dependOn(&run_zllf_tests.step);

    const zllf_install_artifact = b.addInstallArtifact(zllf_tests, .{});
    const exe_install_artifact = b.addInstallArtifact(exe_tests, .{});
    const build_test_step = b.step("build_test", "Build tests");
    build_test_step.dependOn(&zllf_install_artifact.step);
    build_test_step.dependOn(&exe_install_artifact.step);
}
