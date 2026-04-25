const std = @import("std");

pub fn build(build_program: *std.Build) void {
    const target = build_program.standardTargetOptions(.{});
    const optimize = build_program.standardOptimizeOption(.{});

    const exe = build_program.addExecutable(.{
        .name = "hn_filelock_zig",
        .root_module = build_program.createModule(.{
            .root_source_file = build_program.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    build_program.installArtifact(exe);

    const run_exe = build_program.addRunArtifact(exe);
    run_exe.step.dependOn(build_program.getInstallStep());

    if (build_program.args) |args| {
        run_exe.addArgs(args);
    }

    const run_step = build_program.step("run", "Run the app");
    run_step.dependOn(&run_exe.step);
}
