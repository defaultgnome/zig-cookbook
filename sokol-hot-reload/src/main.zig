const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const IS_DEV_MODE = build_options.is_dev_mode;
const assert = std.debug.assert;
const HotModule = @import("stdx").HotModule;

const sokol = @import("sokol");
const sapp = sokol.app;
const sglue = sokol.glue;
const slog = sokol.log;

const AppState = @import("./app/app_api.zig").State;
const AppAPI = @import("./app/app_api.zig").API;
const AppHotModule = HotModule(AppAPI, "api");

/// Owned by the engine, passed to the app as a pointer
var app_state: AppState = AppState{};
var app_hot_module: ?AppHotModule = null;
var app_api: ?*const AppAPI = null;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    if (IS_DEV_MODE) {
        app_hot_module = try AppHotModule.initFromExecutableDir(
            allocator,
            build_options.app_dll_rel_path,
        );

        try app_hot_module.?.load();
        app_api = app_hot_module.?.api;
    } else {
        app_api = &@import("./app/app.zig").api_zig;
    }

    defer {
        if (app_hot_module) |*hm| {
            hm.unload() catch {
                std.log.err("Failed to unload app dll - {s}", .{hm.lib_path_working_copy orelse "null"});
            };
            hm.deinit();
        }
    }

    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = input,
        .cleanup_cb = cleanup,
        .width = @intCast(app_state.viewport.width),
        .height = @intCast(app_state.viewport.height),
        .window_title = "sokol-hot-reloading-demo",
        .icon = .{
            .sokol_default = true,
        },
        .logger = .{ .func = slog.func },
    });
}

export fn init() void {
    if (app_api) |api| {
        api.init(&app_state);
    }
}

export fn frame() void {
    if (IS_DEV_MODE) {
        const has_reloaded = app_hot_module.?.reload() catch false;
        if (has_reloaded) {
            if (app_api) |api| {
                api.reinit(&app_state);
            }
            std.log.debug("Reloaded app dll", .{});
        }
    }

    if (app_api) |api| {
        api.update(&app_state);
    }
}

export fn input(ev: ?*const sapp.Event) void {
    if (ev) |event| {
        switch (event.type) {
            .RESIZED => {
                app_state.viewport.width = @intCast(event.window_width);
                app_state.viewport.height = @intCast(event.window_height);
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
    if (app_api) |api| {
        api.cleanup(&app_state);
    }
}
