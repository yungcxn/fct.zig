const std = @import("std");

// for f with a fixed return type
pub inline fn reduce(
    comptime f: anytype,
    init: anytype,
    xs: anytype,
) @typeInfo(@TypeOf(f)).@"fn".return_type.? {
    var acc: @TypeOf(init) = init;
    if (@typeInfo(@TypeOf(xs)) == .@"struct") {
        inline for (xs) |x| acc = f(acc, x);
    } else {
        for (xs) |x| acc = f(acc, x);
    }
    return acc;
}

// if f has a comptime-evaluated return type
//   based on xs
pub inline fn reduce_comptimef(
    comptime f: anytype,
    comptime init: anytype,
    comptime xs: anytype,
) YsComptimeReduceType(f, init, xs) {
    var acc = init;
    inline for (xs) |x| acc = f(acc, x);
    return acc;
}

fn YsComptimeReduceType(
    comptime f: anytype,
    comptime init: anytype,
    comptime xs: anytype,
) type {
    var acc = init;
    inline for (xs) |x| acc = f(acc, x);
    return @TypeOf(acc);
}

pub inline fn any(comptime pred: anytype, xs: anytype) bool {
    if (@typeInfo(@TypeOf(xs)) == .@"struct") {
        inline for (xs) |x| if (pred(x)) return true;
    } else {
        for (xs) |x| if (pred(x)) return true;
    }
    return false;
}

pub inline fn all(comptime pred: anytype, xs: anytype) bool {
    if (@typeInfo(@TypeOf(xs)) == .@"struct") {
        inline for (xs) |x| if (!pred(x)) return false;
    } else {
        for (xs) |x| if (!pred(x)) return false;
    }
    return true;
}

// this is for a homogeneously typed seq
pub inline fn find(
    comptime pred: anytype,
    xs: anytype,
) ?@TypeOf(xs[0]) {
    if (@typeInfo(@TypeOf(xs)) == .@"struct") {
        inline for (xs) |x| if (pred(x)) return x;
    } else {
        for (xs) |x| if (pred(x)) return x;
    }
    return null;
}
// this is for a heterogeneously typed tuple
pub inline fn find_comptimef(
    comptime pred: anytype,
    xs: anytype,
) YsComptimeFindType(pred, xs) {
    inline for (xs) |x| if (pred(x)) return x;
    return null;
}

fn YsComptimeFindType(
    comptime pred: anytype,
    comptime xs: anytype,
) type {
    inline for (xs) |x| if (pred(x)) return ?@TypeOf(x);
    return @TypeOf(null);
}

test "reduce" {
    const add = struct {
        fn f(x: i32, y: i32) i32 {
            return x + y;
        }
    }.f;

    const xs = [_]i32{ 1, 2, 3 };
    const sum = reduce(add, @as(i32, 0), xs);
    try std.testing.expectEqual(@as(i32, 6), sum);

    const ys = .{ @as(i32, 1), @as(i32, 2), @as(i32, 3) };
    const sum_ys = reduce(add, @as(i32, 0), ys);
    try std.testing.expectEqual(@as(i32, 6), sum_ys);
}

test "reduce_comptimef" {
    const add = struct {
        fn f(a: anytype, b: anytype) @TypeOf(b) {
            return @intCast(a + b);
        }
    }.f;

    const xs = .{ @as(i32, 1), @as(u8, 2), @as(i64, 3) };
    const sum = reduce_comptimef(add, @as(i64, 0), xs);
    try std.testing.expectEqual(@as(i64, 6), sum);
}

test "any, all" {
    const is_even = struct {
        fn f(x: u32) bool {
            return x % 2 == 0;
        }
    }.f;

    const xs = [_]u32{ 1, 2, 3 };
    try std.testing.expect(any(is_even, xs));
    try std.testing.expect(!all(is_even, xs));

    const ys = [_]u32{ 2, 4, 6 };
    try std.testing.expect(all(is_even, ys));
    try std.testing.expect(any(is_even, ys));
}

test "find_comptimef" {
    const above_3 = struct {
        fn f(x: anytype) bool {
            return x > @as(@TypeOf(x), 3);
        }
    }.f;

    const het_tup = .{ @as(i32, 1), @as(f32, 2.0), @as(i64, 4) };
    const found = find_comptimef(above_3, het_tup);
    try std.testing.expect(@TypeOf(found) == ?i64);
    try std.testing.expectEqual(@as(i64, 4), found.?);
}

test "find" {
    const is_even = struct {
        fn f(x: u32) bool {
            return x % 2 == 0;
        }
    }.f;

    const xs = [_]u32{ 1, 2, 3 };
    const found = find(is_even, xs);
    try std.testing.expect(@TypeOf(found) == ?u32);
    try std.testing.expectEqual(@as(u32, 2), found.?);
}
