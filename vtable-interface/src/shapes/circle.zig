const std = @import("std");
const Shape = @import("shape.zig");

/// Circle implementation of the Shape interface.
/// Has its own internal data: radius only (different from Rectangle!)
pub const Self = @This();

radius: f64,

/// Create a new Circle
pub fn init(radius: f64) Self {
    return .{
        .radius = radius,
    };
}

/// Return a Shape interface to this Circle
pub fn shape(self: *Self) Shape {
    return .{
        .ptr = self,
        .vtable = &.{
            .area = area,
            .perimeter = perimeter,
        },
    };
}

/// Calculate area - implementation takes ctx pointer
fn area(ctx: *anyopaque) f64 {
    const self: *Self = @ptrCast(@alignCast(ctx));
    return std.math.pi * self.radius * self.radius;
}

/// Calculate perimeter (circumference) - implementation takes ctx pointer
fn perimeter(ctx: *anyopaque) f64 {
    const self: *Self = @ptrCast(@alignCast(ctx));
    return 2 * std.math.pi * self.radius;
}

/// Circle-specific method (not part of Shape interface)
pub fn diameter(self: Self) f64 {
    return 2 * self.radius;
}
