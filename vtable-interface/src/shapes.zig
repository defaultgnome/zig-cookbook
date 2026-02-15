pub const Shape = @import("shapes/shape.zig");
pub const Rectangle = @import("shapes/rectangle.zig");
pub const Circle = @import("shapes/circle.zig");

// Re-export init functions for convenience
pub const rectangle = Rectangle.init;
pub const circle = Circle.init;
