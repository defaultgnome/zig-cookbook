/// This is the API that the DLL exports. it is here so both parties can import it statically.
const State = @import("state.zig").State;
pub const API = extern struct {
    add: *const fn (i32, i32) callconv(.C) i32,
    increment: *const fn (*State) callconv(.C) void,
    greet: *const fn ([*:0]const u8) callconv(.C) void,
};
