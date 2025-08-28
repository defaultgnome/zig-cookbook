const std = @import("std");
const sokol = @import("sokol");

// TODO: find a way to make shdc recompile with watch mode
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // DEPS
    const stdx_dep = b.dependency("stdx", .{
        .target = target,
        .optimize = optimize,
    });

    const sokol_dep = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
        .dynamic_linkage = true,
    });

    b.installArtifact(sokol_dep.artifact("sokol_clib"));

    const sokol_mod = sokol_dep.module("sokol");

    const shdc_dep = sokol_dep.builder.dependency("shdc", .{});
    const shader_mod = try sokol.shdc.createModule(b, "shader", sokol_mod, .{
        .shdc_dep = shdc_dep,
        .input = "src/shader.glsl",
        .output = "shader.glsl.zig",
        .slang = .{
            .glsl410 = true,
            .hlsl4 = true,
            .metal_macos = true,
        },
    });

    const zmath_dep = b.dependency("zmath", .{
        .target = target,
        .optimize = optimize,
    });

    // APP DynLib
    const app = b.addSharedLibrary(.{
        .name = "app",
        .root_source_file = b.path("src/app/app.zig"),
        .target = target,
        .optimize = optimize,
    });

    app.root_module.addImport("shader", shader_mod);
    app.root_module.addImport("sokol", sokol_mod);
    app.root_module.addImport("stdx", stdx_dep.module("stdx"));
    app.root_module.addImport("zmath", zmath_dep.module("root"));

    const app_dll_rel_path = app_path: {
        if (target.result.os.tag.isDarwin()) {
            break :app_path try std.fs.path.join(b.allocator, &.{ "..", "lib", app.out_filename });
        } else {
            break :app_path app.out_filename;
        }
    };
    b.installArtifact(app);

    const build_dll_step = b.step("build_dll", "Build the app dll");
    build_dll_step.dependOn(&app.step);

    // ENGINE
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "stdx", .module = stdx_dep.module("stdx") },
            .{ .name = "sokol", .module = sokol_mod },
        },
    });

    const engine_options = b.addOptions();
    engine_options.addOption([]const u8, "app_dll_rel_path", app_dll_rel_path);
    exe_mod.addOptions("build_options", engine_options);

    const exe = b.addExecutable(.{
        .name = "sokol_hot_reload",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    // RUN
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    try run_step.addWatchInput(b.path("src/shader.glsl"));
    run_step.dependOn(&run_cmd.step);

    // TEST
    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
