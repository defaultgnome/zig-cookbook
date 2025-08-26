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
    });

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

    // .addWatchInput(b.path("src/shader.glsl")) catch |err| {
    //     std.log.err("Failed to add shader watch input: {}", .{err});
    // };

    const zmath_dep = b.dependency("zmath", .{
        .target = target,
        .optimize = optimize,
    });

    // GAME DynLib
    const game = b.addSharedLibrary(.{
        .name = "game",
        .root_source_file = b.path("src/game/game.zig"),
        .target = target,
        .optimize = optimize,
    });
    const game_dll_rel_path = game_path: {
        if (target.result.os.tag.isDarwin()) {
            break :game_path try std.fs.path.join(b.allocator, &.{ "..", "lib", game.out_filename });
        } else {
            break :game_path game.out_filename;
        }
    };
    b.installArtifact(game);

    const build_dll_step = b.step("build_dll", "Build the game dll");
    build_dll_step.dependOn(&game.step);

    // ENGINE
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "stdx", .module = stdx_dep.module("stdx") },
            .{ .name = "zmath", .module = zmath_dep.module("root") },
            .{ .name = "sokol", .module = sokol_mod },
            .{ .name = "shader", .module = shader_mod },
        },
    });

    const engine_options = b.addOptions();
    engine_options.addOption([]const u8, "game_dll_rel_path", game_dll_rel_path);
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
    run_step.dependOn(&run_cmd.step);

    // TEST
    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
