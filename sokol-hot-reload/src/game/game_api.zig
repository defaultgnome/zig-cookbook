pub const State = extern struct {
    data: u32 = 0,
};

pub const API = extern struct {
    init: *const fn (state: *State) callconv(.C) void,
    update: *const fn (state: *State) callconv(.C) void,
    cleanup: *const fn (state: *State) callconv(.C) void,
};
