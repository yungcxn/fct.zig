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

test {
    std.testing.refAllDecls(@import("test/sval_produce.zig"));
}
