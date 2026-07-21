const std = @import("std");

pub inline fn zip(
    comptime as: anytype,
    comptime bs: anytype,
    comptime ab_s: anytype,
) void {
    if (@typeInfo(@TypeOf(ab_s)) == .@"struct") {
        inline for (ab_s, 0..) |_, i| {
            ab_s[i] = .{ as[i], bs[i] };
        }
    } else {
        for (ab_s, 0..) |_, i| {
            ab_s[i] = .{ as[i], bs[i] };
        }
    }
}

pub inline fn zip_comptimef(
    comptime as: anytype,
    comptime bs: anytype,
) YsComptimeZipType(as, bs) {
    const ab_s = YsComptimeZipType(as, bs);
    inline for (ab_s, 0..) |_, i| {
        ab_s[i] = .{ as[i], bs[i] };
    }
    return ab_s;
}

fn YsComptimeZipType(
    comptime as: anytype,
    comptime bs: anytype,
) type {
    const len = if (@typeInfo(@TypeOf(as)) == .@"struct") {
        @TypeOf(as).@"struct".fields.len;
    } else if (@typeInfo(@TypeOf(bs)) == .@"struct") {
        @TypeOf(bs).@"struct".fields.len;
    } else {
        as.len;
    };

    var types: [len]type = undefined;
    inline for (0..len) |i| {
        types[i] = @Tuple(&.{ @TypeOf(as[i]), @TypeOf(bs[i]) });
    }
    return @TypeOf(types);
}

test "zip" {
    const as = .{ 1, 2, 3 };
    const bs = .{ "a", "b", "c" };
    var ab_s: [3]struct { a: i32, b: []const u8 } = undefined;
    zip(as, bs, &ab_s);
    std.testing.expect(ab_s[0].a == 1 and std.mem.eql(u8, ab_s[0].b, "a"));
    std.testing.expect(ab_s[1].a == 2 and std.mem.eql(u8, ab_s[1].b, "b"));
    std.testing.expect(ab_s[2].a == 3 and std.mem.eql(u8, ab_s[2].b, "c"));
}

test "zip_comptimef" {
    const as = .{ 1, "b", 3 };
    const bs = .{ "a", 2, "c" };
    const ab_s = zip_comptimef(as, bs);
    std.testing.expect(ab_s[0][0] == 1 and std.mem.eql(u8, ab_s[0][1], "a"));
    std.testing.expect(ab_s[1][0] == 2 and std.mem.eql(u8, ab_s[1][1], "b"));
    std.testing.expect(ab_s[2][0] == 3 and std.mem.eql(u8, ab_s[2][1], "c"));
}
