const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var lib = try DynAPI.init(allocator, "zig-out/lib/libhot_dll");
    defer lib.deinit();

    var buffer: [10]u8 = undefined;

    // Main loop
    while (true) {
        try stdout.writeAll("\n1. Print message from DLL\n2. Reload DLL\n3. Unload\n4. Quit\nChoice: ");

        if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |user_input| {
            const choice = std.fmt.parseInt(u8, std.mem.trim(u8, user_input, &std.ascii.whitespace), 10) catch {
                try stdout.writeAll("Invalid choice. Please enter 1, 2, 3 or 4.\n");
                continue;
            };

            switch (choice) {
                1 => {
                    if (lib.api) |api| {
                        api.greet("Boss");
                    } else {
                        try stdout.writeAll("Error: DLL function not loaded.\n");
                    }

                    try stdout.print("API::get::5+3={d}\n", .{lib.add(5, 3)});
                },
                2 => {
                    try stdout.writeAll("Reloading DLL...\n");
                    try lib.reload();
                    try stdout.writeAll("DLL reloaded successfully.\n");
                },
                3 => {
                    try stdout.writeAll("Unloading DLL...\n");
                    lib.unload();
                    try stdout.writeAll("DLL unloaded successfully.\n");
                },
                4 => {
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

const DynAPI = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    path: []const u8,
    lib: ?std.DynLib = null,
    api: ?*const API = null,

    const API = extern struct {
        add: *const fn (i32, i32) callconv(.C) i32,
        multiply: *const fn (i32, i32) callconv(.C) i32,
        greet: *const fn ([*:0]const u8) callconv(.C) void,
    };

    pub fn init(allocator: std.mem.Allocator, path: []const u8) !Self {
        const pathWithExt = try std.fmt.allocPrint(
            allocator,
            "{s}{s}",
            .{ path, std.Target.dynamicLibSuffix(builtin.target) },
        );
        var self = Self{
            .allocator = allocator,
            .path = pathWithExt,
        };
        try self.load();
        return self;
    }

    fn load(self: *Self) !void {
        var lib = std.DynLib.open(self.path) catch |err| {
            std.log.err("Failed to load library: {}", .{err});
            return error.LibraryLoadFailed;
        };

        self.api = lib.lookup(*const API, "api") orelse {
            std.log.err("Failed to find 'api' symbol", .{});
            return error.SymbolNotFound;
        };
        self.lib = lib;
    }

    pub fn unload(self: *Self) void {
        if (self.lib) |*lib| {
            lib.close();
        }
        self.lib = null;
        self.api = null;
    }

    pub fn reload(self: *Self) !void {
        self.unload();
        try self.load();
    }

    pub fn deinit(self: *Self) void {
        if (self.lib) |*lib| {
            lib.close();
        }
        self.allocator.free(self.path);
    }

    // Can do higher wrapper for safer cases
    pub fn add(self: *Self, a: i32, b: i32) i32 {
        if (self.api) |api| {
            return api.add(a, b);
        } else {
            return 0;
        }
    }
};
