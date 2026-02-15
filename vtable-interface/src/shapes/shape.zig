const Shape = @import("shape.zig");

/// Vtable containing function pointers for the Shape interface.
/// Following std lib patterns (like Allocator), this is stored as a
/// pointer to static data, avoiding per-instance overhead.
pub const VTable = struct {
    area: *const fn (ctx: *anyopaque) f64,
    perimeter: *const fn (ctx: *anyopaque) f64,
};

/// Shape interface using the vtable pattern.
/// This allows different types (Rectangle, Circle) to share the same interface
/// while having completely different internal data layouts.
pub const Self = @This();

ptr: *anyopaque,

/// Pointer to static vtable data - no per-instance overhead
vtable: *const VTable,

/// Returns the area of the shape.
/// Thin wrapper that dispatches through the vtable.
pub inline fn area(self: Self) f64 {
    return self.vtable.area(self.ptr);
}

/// Returns the perimeter of the shape.
/// Thin wrapper that dispatches through the vtable.
pub inline fn perimeter(self: Self) f64 {
    return self.vtable.perimeter(self.ptr);
}
