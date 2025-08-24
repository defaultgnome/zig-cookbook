const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Here "root" could be anything, that how the app add get this module: `hatsizer.module("root")`
    _ = b.addModule("root", .{
        .root_source_file = b.path("src/hatsizer.zig"),
    });

    const hatsizer = b.addStaticLibrary(.{
        .name = "hatsizer",
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(hatsizer);

    hatsizer.addIncludePath(b.path("libs/hatsizer"));
    // TODO: DO I NEED THIS???
    // hatsizer.linkLibC();
    hatsizer.addCSourceFile(.{
        .file = b.path("libs/hatsizer/hatsizer.c"),
        .flags = &.{"-std=c99"},
    });

    // TESTS STEP
    const test_step = b.step("test", "Run unit tests");
    const lib_unit_tests = b.addTest(.{
        .name = "hatsizer-tests",
        .root_source_file = b.path("src/hatsizer.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib_unit_tests);
    lib_unit_tests.linkLibrary(hatsizer);
    test_step.dependOn(&b.addRunArtifact(lib_unit_tests).step);
}
