const std = @import("std");

fn worker(id: u32, start: u64, end: u64, results: []u64) !void {
    var sum: u64 = 0;
    for (start..end) |i| {
        sum += i;
    }
    results[id] = sum;
    std.debug.print("Worker {} finished: sum = {}\n", .{ id, sum });
}

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Number of threads to use
    const num_threads = std.Thread.getCpuCount() catch 1;
    const numbers_per_thread = 1000000;

    // Array to store thread handles
    var threads = try allocator.alloc(std.Thread, num_threads);
    defer allocator.free(threads);

    // Array to store results from each thread
    const results = try allocator.alloc(u64, num_threads);
    defer allocator.free(results);

    // Spawn threads
    for (0..num_threads) |i| {
        const start = i * numbers_per_thread;
        const end = (i + 1) * numbers_per_thread;
        threads[i] = try std.Thread.spawn(.{}, worker, .{ @as(u32, @intCast(i)), start, end, results });
    }

    // Wait for all threads to complete
    for (threads) |thread| {
        thread.join();
    }

    // Calculate total sum
    var total: u64 = 0;
    for (results) |result| {
        total += result;
    }

    std.debug.print("Total sum: {}\n", .{total});
}
