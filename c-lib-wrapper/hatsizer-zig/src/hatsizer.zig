const std = @import("std");

// FROM C
const HatFitInfo = extern struct {
    head_cicumference_cm: f32,
};

extern fn hat_sizer_get_size(info: HatFitInfo) HatSize;
extern fn hat_sizer_size_to_string(size: HatSize) [*:0]const u8;
extern fn hat_sizer_roundness_score(info: HatFitInfo) f32;

const HatSize = enum(c_int) {
    XS = 0,
    S,
    M,
    L,
    XL,
    UNKNOWN,

    pub fn name(self: HatSize) []const u8 {
        return std.mem.sliceTo(hat_sizer_size_to_string(self), 0);
    }
};

// Ziggified
pub const HatSizer = struct {
    info: HatFitInfo,

    const Self = @This();

    pub fn init(cm: f32) Self {
        return .{
            .info = .{
                .head_cicumference_cm = cm,
            },
        };
    }

    pub fn size(self: Self) HatSize {
        return hat_sizer_get_size(self.info);
    }

    pub fn roundness(self: Self) f32 {
        return hat_sizer_roundness_score(self.info);
    }
};

test "HatSize" {
    const size = HatSize.M;
    try std.testing.expect(size == HatSize.M);
    try std.testing.expectEqualStrings(size.name(), "Medium");
}

test "HatSizer" {
    const sizer = HatSizer.init(56);
    try std.testing.expect(sizer.size() == HatSize.M);
    try std.testing.expectApproxEqRel(
        0.987,
        sizer.roundness(),
        0.001,
    );
}
