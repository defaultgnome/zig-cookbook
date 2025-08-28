const sokol = @import("sokol");
const sg = sokol.gfx;

pub const State = extern struct {
    viewport: extern struct {
        width: u32 = 1080,
        height: u32 = 720,
    } = .{},
    gfx: extern struct {
        pass_action: sg.PassAction = .{},
        display: extern struct {
            pipeline: sg.Pipeline = .{},
            bindings: sg.Bindings = .{},
        } = .{},
        vbufs: extern struct {
            quad: sg.Buffer = .{},
        } = .{},
    } = .{},
};

pub const API = extern struct {
    init: *const fn (state: *State) callconv(.C) void,
    reinit: *const fn (state: *State) callconv(.C) void,
    update: *const fn (state: *State) callconv(.C) void,
    cleanup: *const fn (state: *State) callconv(.C) void,
};
