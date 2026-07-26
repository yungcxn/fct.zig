const std = @import("std");
const builtin = @import("builtin");

const name: []const u8 = "main";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path("include/fct.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const exe_check = b.addExecutable(.{
        .name = name,
        .root_module = exe.root_module,
    });
    const check = b.step("check", "Compile-check the application");
    check.dependOn(&exe_check.step);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_tests.step);
}
