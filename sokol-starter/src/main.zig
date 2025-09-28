const std = @import("std");
const zmath = @import("zmath");
const sokol = @import("sokol");
const shaders = @import("shader");

const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const slog = sokol.log;

const State = struct {
    pipeline: sg.Pipeline = .{},
    bindings: sg.Bindings = .{},
    pass_action: sg.PassAction = .{},
    viewport: struct {
        width: i32 = 800,
        height: i32 = 600,
    } = .{},
};

var state: State = .{};

pub fn main() !void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = event,
        .cleanup_cb = cleanup,
        .width = state.viewport.width,
        .height = state.viewport.height,
        .window_title = "Sokol Triangle",
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = slog.func },
    });
}

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    // Triangle vertices (NDC coordinates)
    const vertices = [_]f32{
        // positions
        0.0, 0.5, // top
        -0.5, -0.5, // bottom left
        0.5, -0.5, // bottom right
    };

    // Create vertex buffer
    state.bindings.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&vertices),
    });

    // Create shader and pipeline
    var pipeline_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shaders.triangleShaderDesc(sg.queryBackend())),
        .primitive_type = .TRIANGLES,
    };
    pipeline_desc.layout.attrs[shaders.ATTR_triangle_position].format = .FLOAT2;
    state.pipeline = sg.makePipeline(pipeline_desc);

    // Setup pass action
    state.pass_action.colors[0] = sg.ColorAttachmentAction{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1.0 },
    };
}

export fn frame() void {
    // Calculate viewport for proper scaling
    const vw = calculateViewport();

    // Create MVP matrix (identity for this simple case)
    const mvp = zmath.identity();
    var mvp_raw: [16]f32 = undefined;
    zmath.storeMat(&mvp_raw, mvp);

    // Begin rendering
    sg.beginPass(.{
        .action = state.pass_action,
        .swapchain = sglue.swapchain(),
    });

    // Apply viewport for proper scaling
    sg.applyViewport(
        vw.offset_x,
        vw.offset_y,
        vw.width,
        vw.height,
        true,
    );

    // Apply pipeline and bindings
    sg.applyPipeline(state.pipeline);
    sg.applyBindings(state.bindings);

    // Set uniforms
    const vs_params = shaders.VsParams{
        .mvp = mvp_raw,
    };
    sg.applyUniforms(shaders.UB_vs_params, sg.asRange(&vs_params));

    // Draw triangle
    sg.draw(0, 3, 1);

    sg.endPass();
    sg.commit();
}

export fn event(ev: ?*const sapp.Event) void {
    if (ev) |e| {
        switch (e.type) {
            .RESIZED => {
                state.viewport.width = e.window_width;
                state.viewport.height = e.window_height;
            },
            .KEY_DOWN => {
                switch (e.key_code) {
                    .ESCAPE => sapp.requestQuit(),
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

fn calculateViewport() struct {
    offset_x: i32,
    offset_y: i32,
    width: i32,
    height: i32,
} {
    // Calculate aspect ratio-preserving viewport
    const target_aspect_ratio: f32 = 4.0 / 3.0; // 4:3 aspect ratio
    const window_aspect_ratio: f32 = @as(f32, @floatFromInt(state.viewport.width)) / @as(f32, @floatFromInt(state.viewport.height));

    var scaled_width: i32 = undefined;
    var scaled_height: i32 = undefined;

    if (window_aspect_ratio > target_aspect_ratio) {
        // Window is wider than target, constrain by height
        scaled_height = state.viewport.height;
        scaled_width = @as(i32, @intFromFloat(@as(f32, @floatFromInt(scaled_height)) * target_aspect_ratio));
    } else {
        // Window is taller than target, constrain by width
        scaled_width = state.viewport.width;
        scaled_height = @as(i32, @intFromFloat(@as(f32, @floatFromInt(scaled_width)) / target_aspect_ratio));
    }

    const offset_x = @divTrunc(state.viewport.width - scaled_width, 2);
    const offset_y = @divTrunc(state.viewport.height - scaled_height, 2);

    return .{
        .offset_x = offset_x,
        .offset_y = offset_y,
        .width = scaled_width,
        .height = scaled_height,
    };
}
