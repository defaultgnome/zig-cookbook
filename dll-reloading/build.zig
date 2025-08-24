const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dll = b.addSharedLibrary(.{
        .name = "mydll",
        .root_source_file = b.path("src/dll.zig"),
        .target = target,
        .optimize = optimize,
    });
    const dll_name = if (target.result.os.tag.isDarwin()) dll.install_name.? else dll.name;
    b.installArtifact(dll);

    const exe_mod = b.addModule("exe_mod", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const options = b.addOptions();
    options.addOption([]const u8, "dll_name", dll_name);
    exe_mod.addOptions("build_options", options);

    const exe = b.addExecutable(.{
        .name = "hot_reload_demo",
        .root_module = exe_mod,
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
