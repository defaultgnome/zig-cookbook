const std = @import("std");

// TODO: check if we can do this without callconv(.C) just for zig-to-zig dll

fn add(a: i32, b: i32) callconv(.C) i32 {
    return a + b;
}

fn multiply(a: i32, b: i32) callconv(.C) i32 {
    return a * b;
}

fn greet(name: [*:0]const u8) callconv(.C) void {
    std.debug.print("Hello, {s}!\n", .{name});
}

const API = extern struct {
    add: *const fn (i32, i32) callconv(.C) i32,
    multiply: *const fn (i32, i32) callconv(.C) i32,
    greet: *const fn ([*:0]const u8) callconv(.C) void,
};

export const api = API{
    .add = add,
    .multiply = multiply,
    .greet = greet,
};
