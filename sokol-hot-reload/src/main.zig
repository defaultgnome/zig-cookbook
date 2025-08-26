const std = @import("std");
const builtin = @import("builtin");
const IS_DEV = builtin.mode == .Debug;
const build_options = @import("build_options");
const assert = std.debug.assert;
const HotModule = @import("stdx").HotModule;

const zmath = @import("zmath");
const sokol = @import("sokol");
const shaders = @import("shader");
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const slog = sokol.log;

const GameState = @import("./game/game_api.zig").State;
const GameAPI = @import("./game/game_api.zig").API;
const GameHotModule = HotModule(GameAPI, "api");

const EngineState = struct {
    viewport: struct {
        width: u32 = 1080,
        height: u32 = 720,
    } = .{},
    gfx: struct {
        pass_action: sg.PassAction = .{},
        display: struct {
            pipeline: sg.Pipeline = .{},
            bindings: sg.Bindings = .{},
        } = .{},
        vbufs: struct {
            quad: sg.Buffer = .{},
        } = .{},
    } = .{},
};
var engine_state: EngineState = EngineState{};
/// Owned by the engine, passed to the game as a pointer
var game_state: GameState = GameState{};
var game_api: GameHotModule = undefined;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    game_api = try GameHotModule.initFromExecutableDir(
        allocator,
        build_options.game_dll_rel_path,
    );
    defer game_api.deinit();

    try game_api.load();
    defer game_api.unload() catch {
        std.log.err("Failed to unload game dll - {s}", .{game_api.lib_path_working_copy orelse "null"});
    };

    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = input,
        .cleanup_cb = cleanup,
        .width = @intCast(engine_state.viewport.width),
        .height = @intCast(engine_state.viewport.height),
        .window_title = "sokol-hot-reloading-demo",
        .icon = .{
            .sokol_default = true,
        },
        .logger = .{ .func = slog.func },
    });
}

export fn init() void {
    // GAME
    if (game_api.api) |api| {
        api.init(&game_state);
    }

    // GRAPHICS
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    { // PASS ACTION
        engine_state.gfx.pass_action.colors[0] = sg.ColorAttachmentAction{
            .load_action = .CLEAR,
            .clear_value = .{ .r = 0, .g = 0, .b = 0, .a = 1.0 },
        };
    }
    { // VBUFS
        const quad_verts = [_]f32{ 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0 };
        engine_state.gfx.vbufs.quad = sg.makeBuffer(.{
            .data = sg.asRange(&quad_verts),
        });
        engine_state.gfx.display.bindings.vertex_buffers[0] = engine_state.gfx.vbufs.quad;
    }

    { // PIPELINE
        var pip_desc: sg.PipelineDesc = .{
            .shader = sg.makeShader(shaders.displayShaderDesc(sg.queryBackend())),
            .primitive_type = .TRIANGLE_STRIP,
        };
        pip_desc.layout.attrs[shaders.ATTR_display_position].format = .FLOAT2;
        engine_state.gfx.display.pipeline = sg.makePipeline(pip_desc);
    }
}

export fn frame() void {
    if (game_api.reload() catch false) {
        std.log.debug("Reloaded game dll", .{});
    }
    // UPDATE
    if (game_api.api) |api| {
        api.update(&game_state);
        std.log.debug("Updated game state: {d}", .{game_state.data});
    }

    // DRAW
    sg.beginPass(.{
        .action = engine_state.gfx.pass_action,
        .swapchain = sglue.swapchain(),
    });

    sg.applyPipeline(engine_state.gfx.display.pipeline);
    sg.applyBindings(engine_state.gfx.display.bindings);

    sg.applyViewport(
        0,
        0,
        @intCast(engine_state.viewport.width),
        @intCast(engine_state.viewport.height),
        true,
    );

    sg.draw(0, 4, 1);

    sg.endPass();
    sg.commit();
}

export fn input(ev: ?*const sapp.Event) void {
    if (ev) |event| {
        switch (event.type) {
            .RESIZED => {
                engine_state.viewport.width = @intCast(event.window_width);
                engine_state.viewport.height = @intCast(event.window_height);
            },
            .KEY_DOWN => {
                switch (event.key_code) {
                    .ESCAPE => {
                        sapp.requestQuit();
                    },
                    else => {},
                }
            },
            else => {},
        }
    }
}

export fn cleanup() void {
    sg.shutdown();
}
