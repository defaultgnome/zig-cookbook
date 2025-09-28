const std = @import("std");
const sokol = @import("sokol");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // SOKOL DEPENDENCY
    const sokol_dep = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });

    const sokol_mod = sokol_dep.module("sokol");

    // SHADER COMPILATION
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

    // ZMATH DEPENDENCY
    const zmath_dep = b.dependency("zmath", .{
        .target = target,
        .optimize = optimize,
    });

    // CREATE ROOT MODULE
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    root_module.addImport("sokol", sokol_mod);
    root_module.addImport("zmath", zmath_dep.module("root"));
    root_module.addImport("shader", shader_mod);

    // EXECUTABLE
    const exe = b.addExecutable(.{
        .name = "sokol_starter",
        .root_module = root_module,
    });

    b.installArtifact(exe);

    // RUN COMMAND
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the triangle demo");
    run_step.dependOn(&run_cmd.step);
}
