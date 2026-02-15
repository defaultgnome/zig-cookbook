const std = @import("std");
const shapes = @import("shapes.zig");

/// Demonstrates the vtable-based interface pattern in Zig.
///
/// Both Rectangle and Circle implement the Shape interface but have:
/// - Different internal data (width/height vs radius)
/// - Different implementations of area() and perimeter()
/// - Type-specific methods (isSquare, diameter)
///
/// Yet they share the same Shape interface type and can be used polymorphically.
/// NOTE: this should be done WHEN there is a need to be polymorpic - if we just want the
/// same API, just make sure you have the same API...
pub fn main() !void {
    // Create concrete shape instances
    var rect = shapes.Rectangle.init(10.0, 5.0);
    var circle = shapes.Circle.init(7.0);

    // Get Shape interface handles - now they share the same type!
    const shape1 = rect.shape();
    const shape2 = circle.shape();

    // Use them polymorphically through the interface
    std.debug.print("=== Shape Interface Demo ===\n\n", .{});

    printShapeInfo("Rectangle", shape1);
    printShapeInfo("Circle", shape2);

    // Demonstrate heterogeneous collections
    std.debug.print("=== Shape Collection Demo ===\n\n", .{});

    const shape_array = [_]shapes.Shape{ shape1, shape2 };
    var total_area: f64 = 0;
    var total_perimeter: f64 = 0;

    for (shape_array, 0..) |shape, i| {
        const a = shape.area();
        const p = shape.perimeter();
        total_area += a;
        total_perimeter += p;
        std.debug.print("Shape {}: area={d:.2}, perimeter={d:.2}\n", .{ i, a, p });
    }

    std.debug.print("\nTotal area: {d:.2}\n", .{total_area});
    std.debug.print("Total perimeter: {d:.2}\n", .{total_perimeter});

    // Show that concrete types still have their specific methods
    std.debug.print("\n=== Concrete Type Methods ===\n", .{});
    std.debug.print("Rectangle is square: {}\n", .{rect.isSquare()});
    std.debug.print("Circle diameter: {d:.2}\n", .{circle.diameter()});

    // Demonstrate runtime polymorphism
    std.debug.print("\n=== Runtime Polymorphism Demo ===\n", .{});
    try demonstratePolymorphism(&rect, &circle);
}

fn printShapeInfo(name: []const u8, shape: shapes.Shape) void {
    std.debug.print("{s}:\n", .{name});
    std.debug.print("  Area: {d:.2}\n", .{shape.area()});
    std.debug.print("  Perimeter: {d:.2}\n\n", .{shape.perimeter()});
}

test "Shape interface basic functionality" {
    var rect = shapes.Rectangle.init(10.0, 5.0);
    var circle = shapes.Circle.init(7.0);

    const shape1 = rect.shape();
    const shape2 = circle.shape();

    // Test area calculations
    try std.testing.expectApproxEqAbs(@as(f64, 50.0), shape1.area(), 0.0001);
    try std.testing.expectApproxEqAbs(@as(f64, 153.9380), shape2.area(), 0.0001);

    // Test perimeter calculations
    try std.testing.expectApproxEqAbs(@as(f64, 30.0), shape1.perimeter(), 0.0001);
    try std.testing.expectApproxEqAbs(@as(f64, 43.9823), shape2.perimeter(), 0.0001);
}

test "Shape interface in array" {
    var rect = shapes.Rectangle.init(2.0, 3.0);
    var circle = shapes.Circle.init(1.0);

    const shape_array = [_]shapes.Shape{
        rect.shape(),
        circle.shape(),
    };

    try std.testing.expectApproxEqAbs(@as(f64, 6.0), shape_array[0].area(), 0.0001);
    try std.testing.expectApproxEqAbs(@as(f64, 3.1416), shape_array[1].area(), 0.0001);
}

/// Function that accepts any Shape - true runtime polymorphism
fn demonstratePolymorphism(rect: *shapes.Rectangle, circle: *shapes.Circle) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a dynamic list of shapes (heterogeneous collection)
    // Note: In Zig 0.15, ArrayList is unmanaged - allocator passed to methods
    var shape_list: std.ArrayList(shapes.Shape) = .{};
    defer shape_list.deinit(allocator);

    try shape_list.append(allocator, rect.shape());
    try shape_list.append(allocator, circle.shape());
    try shape_list.append(allocator, rect.shape()); // Can add same shape multiple times

    std.debug.print("Processing {} shapes dynamically:\n", .{shape_list.items.len});
    for (shape_list.items, 0..) |shape, i| {
        std.debug.print("  [{}] area={d:.2}, perimeter={d:.2}\n", .{ i, shape.area(), shape.perimeter() });
    }
}
