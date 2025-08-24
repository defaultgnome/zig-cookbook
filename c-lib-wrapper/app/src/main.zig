const std = @import("std");
const HatSizer = @import("hatsizer").HatSizer;

pub fn main() !void {
    const sizer = HatSizer.init(55);
    std.log.info("a head of 55cm is of {s} size.", .{sizer.size().name()});
}
