/// This is the API that the DLL exports. it is here so both parties can import it statically.
pub const API = extern struct {
    add: *const fn (i32, i32) callconv(.C) i32,
    multiply: *const fn (i32, i32) callconv(.C) i32,
    greet: *const fn ([*:0]const u8) callconv(.C) void,
};
