const Shape = @import("shape.zig");

/// Rectangle implementation of the Shape interface.
/// Has its own internal data: width and height.
pub const Self = @This();

width: f64,
height: f64,

/// Create a new Rectangle
pub fn init(width: f64, height: f64) Self {
    return .{
        .width = width,
        .height = height,
    };
}

/// Return a Shape interface to this Rectangle
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
    return self.width * self.height;
}

/// Calculate perimeter - implementation takes ctx pointer
fn perimeter(ctx: *anyopaque) f64 {
    const self: *Self = @ptrCast(@alignCast(ctx));
    return 2 * (self.width + self.height);
}

/// Rectangle-specific method (not part of Shape interface)
pub fn isSquare(self: Self) bool {
    return @abs(self.width - self.height) < 0.0001;
}
