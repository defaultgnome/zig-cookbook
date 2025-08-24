const std = @import("std");
const API = @import("dll_api.zig").API;
const State = @import("state.zig").State;

fn add(a: i32, b: i32) callconv(.C) i32 {
    return a + b;
}

fn increment(state: *State) callconv(.C) void {
    state.a_number += 5;
}

fn greet(name: [*:0]const u8) callconv(.C) void {
    std.debug.print("Hello, {s}!\n", .{name});
}

export const api = API{
    .add = add,
    .increment = increment,
    .greet = greet,
};
