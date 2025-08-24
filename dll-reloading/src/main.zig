const std = @import("std");

const GetMessageFn = *const fn () [*:0]const u8;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var lib: ?std.DynLib = null;
    var getMessage: ?GetMessageFn = null;

    // Initial load of the library
    try loadLibrary(&lib, &getMessage);
    defer if (lib) |*l| l.close();

    var buffer: [10]u8 = undefined;

    // Main loop
    while (true) {
        try stdout.writeAll("\n1. Print message from DLL\n2. Reload DLL\n3. Quit\nChoice: ");

        if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |user_input| {
            const choice = std.fmt.parseInt(u8, std.mem.trim(u8, user_input, &std.ascii.whitespace), 10) catch {
                try stdout.writeAll("Invalid choice. Please enter 1, 2, or 3.\n");
                continue;
            };

            switch (choice) {
                1 => {
                    if (getMessage) |fn_ptr| {
                        try stdout.print("Message: {s}\n", .{fn_ptr()});
                    } else {
                        try stdout.writeAll("Error: DLL function not loaded.\n");
                    }
                },
                2 => {
                    try stdout.writeAll("Reloading DLL...\n");
                    if (lib) |*l| l.close();
                    lib = null;
                    getMessage = null;
                    try loadLibrary(&lib, &getMessage);
                    try stdout.writeAll("DLL reloaded successfully.\n");
                },
                3 => {
                    try stdout.writeAll("Exiting...\n");
                    return;
                },
                else => {
                    try stdout.writeAll("Invalid choice. Please enter 1, 2, or 3.\n");
                },
            }
        }
    }
}

fn loadLibrary(lib: *?std.DynLib, getMessage: *?GetMessageFn) !void {
    const lib_path = try std.fmt.allocPrint(
        std.heap.page_allocator,
        "zig-out/lib/libhot_dll{s}",
        .{std.Target.dynamicLibSuffix(@import("builtin").target)},
    );
    lib.* = std.DynLib.open(lib_path) catch |err| {
        std.debug.print("Failed to load library: {}\n", .{err});
        return err;
    };

    getMessage.* = lib.*.?.lookup(GetMessageFn, "getMessage") orelse {
        std.debug.print("Failed to find getMessage function\n", .{});
        return error.SymbolNotFound;
    };
}
