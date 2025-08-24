# hatsizer

for this example we are importing our toy `hatsizer` library like that:
```zon
.{
    .dependencies = .{ 
        .hatsizer = .{
            .path = "../hatsizer-zig",
        },
    },
}
```

## Getting started

In your `build.zig` add:

```zig
pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{ ... });

    const hatsizer = b.dependency("hatsizer", .{});
    exe.root_module.addImport("hatsizer", hatsizer.module("root"));
    exe.linkLibrary(hatsizer.artifact("hatsizer"));
}
```

Now in your code you may import and use `hatsizer`:

```zig
const std = @import("std");
const HatSizer = @import("hatsizer").HatSizer;

pub fn main() !void {
    const sizer = HatSizer.init(55);
    std.log.info("a head of 55cm is of {s} size.", .{sizer.size().name()});
}
```
