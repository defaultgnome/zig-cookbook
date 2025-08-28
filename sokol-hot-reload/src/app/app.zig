const std = @import("std");
const State = @import("./app_api.zig").State;
const zmath = @import("zmath");

const sokol = @import("sokol");
const sg = sokol.gfx;
const slog = sokol.log;
const sglue = sokol.glue;
const shaders = @import("shader");

pub fn init(state: *State) callconv(.C) void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    { // PASS ACTION
        state.gfx.pass_action.colors[0] = sg.ColorAttachmentAction{
            .load_action = .CLEAR,
            .clear_value = .{ .r = 0, .g = 0, .b = 0, .a = 1.0 },
        };
    }
    { // VBUFS
        const quad_verts = [_]f32{ 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0 };
        state.gfx.vbufs.quad = sg.makeBuffer(.{
            .data = sg.asRange(&quad_verts),
        });
        state.gfx.display.bindings.vertex_buffers[0] = state.gfx.vbufs.quad;
    }
    createPipeline(state);
}

fn createPipeline(state: *State) void {
    { // PIPELINE
        var pip_desc: sg.PipelineDesc = .{
            .shader = sg.makeShader(shaders.displayShaderDesc(sg.queryBackend())),
            .primitive_type = .TRIANGLE_STRIP,
        };
        pip_desc.layout.attrs[shaders.ATTR_display_position].format = .FLOAT2;
        state.gfx.display.pipeline = sg.makePipeline(pip_desc);
    }
}

pub fn reinit(state: *State) callconv(.C) void {
    // TODO: delete the pipeline and recreate it
    sg.destroyPipeline(state.gfx.display.pipeline);
    createPipeline(state);
}

pub fn update(state: *State) callconv(.C) void {
    // DRAW
    sg.beginPass(.{
        .action = state.gfx.pass_action,
        .swapchain = sglue.swapchain(),
    });

    sg.applyPipeline(state.gfx.display.pipeline);
    sg.applyBindings(state.gfx.display.bindings);

    sg.applyViewport(
        0,
        0,
        @intCast(state.viewport.width),
        @intCast(state.viewport.height),
        true,
    );

    const display_vs_uniforms = .{
        .mvp = zmath.translation(-0.5, -0.5, 0),
    };
    sg.applyUniforms(shaders.UB_display_vs_uniforms, sg.asRange(&display_vs_uniforms));

    sg.draw(0, 4, 1);

    sg.endPass();
    sg.commit();
}

pub fn cleanup(state: *State) callconv(.C) void {
    _ = state;
    sg.shutdown();
}

const API = @import("app_api.zig").API;
export const api: API = .{
    .init = init,
    .reinit = reinit,
    .update = update,
    .cleanup = cleanup,
};

pub const api_zig = api;
