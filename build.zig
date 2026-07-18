const std = @import("std");
const builtin = @import("builtin");

const build_spirv = @import("tools/build_spirv.zig");
const cdep_transl = @import("tools/cdep_transl.zig");
const CDependency = cdep_transl.CDependency;

const name: []const u8 = "fct.zig";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);

    const exe_check = b.addExecutable(.{
        .name = name,
        .root_module = exe.root_module,
    });
    const check = b.step("check", "Compile-check the application");
    check.dependOn(&exe_check.step);
}
