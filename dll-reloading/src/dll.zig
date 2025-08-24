const std = @import("std");
const API = @import("dll_api.zig").API;

fn add(a: i32, b: i32) callconv(.C) i32 {
    return a + b;
}

fn multiply(a: i32, b: i32) callconv(.C) i32 {
    return a * b;
}

fn greet(name: [*:0]const u8) callconv(.C) void {
    std.debug.print("Hello, {s}!\n", .{name});
}

export const api = API{
    .add = add,
    .multiply = multiply,
    .greet = greet,
};
