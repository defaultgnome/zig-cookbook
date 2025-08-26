const std = @import("std");
const State = @import("./game_api.zig").State;

pub fn init(state: *State) void {
    state.data = 100;
}

pub fn update(state: *State) void {
    if (state.data >= std.math.maxInt(@TypeOf(state.data)) / 2) {
        state.data = 1;
    }
    state.data *= 2;
}

pub fn cleanup(state: *State) void {
    _ = state;
}

// DLL LAYER - C ABI

fn initC(state: *State) callconv(.C) void {
    init(state);
}

fn updateC(state: *State) callconv(.C) void {
    update(state);
}

fn cleanupC(state: *State) callconv(.C) void {
    cleanup(state);
}

const API = @import("game_api.zig").API;
export const api: API = .{
    .init = initC,
    .update = updateC,
    .cleanup = cleanupC,
};
