const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // TODO: inject the final name `zig-out/lib/libhot_dll` into builtin of the app
    const dll = b.addSharedLibrary(.{
        .name = "hot_dll",
        .root_source_file = b.path("src/dll.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(dll);

    const exe = b.addExecutable(.{
        .name = "hot_reload_demo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Add a step that only compiles and installs the DLL
    const dll_step = b.step("dll", "Compile only the DLL");
    dll_step.dependOn(&b.addInstallArtifact(dll, .{}).step);
}
