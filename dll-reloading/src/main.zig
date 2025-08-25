const std = @import("std");
const builtin = @import("builtin");
const State = @import("state.zig").State;

var state: State = .{};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var lib = try DynAPI.init(allocator, .{});
    defer lib.deinit();

    var buffer: [10]u8 = undefined;

    // Main loop
    while (true) {
        try stdout.writeAll("\x1B[2J\x1B[H");

        if (try lib.reload()) {
            try stdout.writeAll("DLL reloaded successfully.\n");
        }
        if (lib.api) |api| {
            api.greet("Boss");
        } else {
            try stdout.writeAll("Error: DLL function not loaded.\n");
        }

        try stdout.print("State : {d}\n", .{state.a_number});

        try stdout.writeAll("\n\t1. Increment state\n");
        try stdout.writeAll("\t0. Quit\n");
        try stdout.writeAll("Choice: ");

        if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |user_input| {
            const choice = std.fmt.parseInt(u8, std.mem.trim(u8, user_input, &std.ascii.whitespace), 10) catch {
                try stdout.writeAll("Invalid choice.\n");
                continue;
            };

            switch (choice) {
                0 => {
                    try stdout.writeAll("Exiting...\n");
                    return;
                },
                1 => {
                    if (lib.api) |api| {
                        api.increment(&state);
                    }
                },
                else => {
                    try stdout.writeAll("Invalid choice.\n");
                },
            }
        }
    }
}

const DynAPI = struct {
    const API = @import("dll_api.zig").API;
    const dll_name = @import("build_options").dll_name;
    const Self = @This();

    allocator: std.mem.Allocator,
    lib_path: []const u8,
    lib_tmp_path: []const u8,
    last_loaded_lib_timestamp: i128,
    lib: ?std.DynLib = null,
    api: ?*const API = null,
    options: Options,

    const Options = struct {
        /// If true, the library will be loaded into a temporary copy of the dll
        /// enabling automatic hot reloading
        load_into_temp: bool = true,
    };

    pub fn init(allocator: std.mem.Allocator, options: Options) !Self {
        const exe_dir = std.fs.selfExeDirPathAlloc(allocator) catch {
            std.log.err("Failed to get executable directory", .{});
            return error.ExecutableDirectoryNotFound;
        };
        defer allocator.free(exe_dir);
        const lib_path = std.fs.path.join(allocator, &[_][]const u8{ exe_dir, dll_name }) catch {
            std.log.err("Failed to get library path of: {s} {s}", .{ exe_dir, dll_name });
            return error.LibraryPathNotFound;
        };

        const lib_tmp_path = try allocator.dupe(u8, lib_path);

        var self = Self{
            .allocator = allocator,
            .lib_path = lib_path,
            .lib_tmp_path = lib_tmp_path,
            .last_loaded_lib_timestamp = 0,
            .options = options,
        };
        try self.load();
        return self;
    }

    pub fn load(self: *Self) !void {
        if (self.options.load_into_temp and self.lib != null) {
            try self.createTempCopy();
        }

        var lib = std.DynLib.open(self.lib_tmp_path) catch |err| {
            std.log.err("Failed to load library: {}", .{err});
            return error.LibraryLoadFailed;
        };

        self.last_loaded_lib_timestamp = try self.getLibTimestamp();

        self.api = lib.lookup(*const API, "api") orelse {
            std.log.err("Failed to find 'api' symbol", .{});
            return error.SymbolNotFound;
        };
        self.lib = lib;
    }

    fn getLibTimestamp(self: *Self) !i128 {
        const file = try std.fs.openFileAbsolute(self.lib_path, .{});
        defer file.close();
        const file_stat = try file.stat();
        return file_stat.mtime;
    }

    fn createTempCopy(self: *Self) !void {
        std.debug.assert(self.lib == null); // must be unloaded first

        const timestamp = std.time.timestamp();
        const lib_basename = std.fs.path.basename(self.lib_path);
        const tmp_basename = try std.fmt.allocPrint(
            self.allocator,
            "{d}_{s}",
            .{ timestamp, lib_basename },
        );
        defer self.allocator.free(tmp_basename);

        var dir = try self.getLibDir();
        defer dir.close();
        try dir.copyFile(self.lib_path, dir, tmp_basename, .{});

        try self.deleteTempIfExist();

        const old_path = self.lib_tmp_path;
        defer self.allocator.free(old_path);
        const new_path = try dir.realpathAlloc(self.allocator, tmp_basename);
        self.lib_tmp_path = new_path;
    }

    fn deleteTempIfExist(self: *Self) !void {
        if (!std.mem.eql(u8, self.lib_tmp_path, self.lib_path)) {
            // if not equal mean we created a temp file, so we should delete it
            try std.fs.deleteFileAbsolute(self.lib_tmp_path);
        }
    }

    fn getLibDir(self: Self) !std.fs.Dir {
        const maybe_lib_dir = std.fs.path.dirname(self.lib_path);
        const dir = dir: {
            if (maybe_lib_dir) |dir_path| {
                break :dir try std.fs.cwd().openDir(dir_path, .{});
            } else {
                break :dir std.fs.cwd();
            }
        };
        return dir;
    }

    pub fn unload(self: *Self) !void {
        if (self.lib) |*lib| {
            lib.close();
        }

        try self.deleteTempIfExist();

        self.lib = null;
        self.api = null;
    }

    pub fn reload(self: *Self) !bool {
        const lib_timestamp = try self.getLibTimestamp();
        if (lib_timestamp == self.last_loaded_lib_timestamp) {
            return false;
        }

        try self.unload();
        try self.load();
        return true;
    }

    pub fn deinit(self: *Self) void {
        self.unload() catch {
            std.log.warn("Failed to unload library at: {s}", .{self.lib_tmp_path});
        };
        self.allocator.free(self.lib_path);
        self.allocator.free(self.lib_tmp_path);
    }

    // Can do higher level wrapper here
    pub fn add(self: *Self, a: i32, b: i32) i32 {
        if (self.api) |api| {
            return api.add(a, b);
        } else {
            return 0;
        }
    }
};
