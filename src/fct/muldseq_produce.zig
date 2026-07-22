const std = @import("std");

fn comptime_len(comptime T: type) ?comptime_int {
    return switch (@typeInfo(T)) {
        .@"struct" => |s| if (s.is_tuple) s.fields.len else null,
        .array => |a| a.len,
        else => null,
    };
}

pub inline fn zip(
    as: anytype,
    bs: anytype,
    ab_s: anytype,
) void {
    const As = @TypeOf(as);
    const Bs = @TypeOf(bs);
    // child, bc. ab_s is passed by reference (pointer):
    const ABs = @typeInfo(@TypeOf(ab_s)).pointer.child;

    const needs_inline = if (@typeInfo(As) == .@"struct" or
        @typeInfo(Bs) == .@"struct" or
        @typeInfo(ABs) == .@"struct") true else false;

    if (comptime needs_inline) {
        const len = comptime blk: {
            for (.{ As, Bs, ABs }) |T| {
                if (comptime_len(T)) |l| break :blk l;
            }
            @compileError("error: tuple + runtime slice");
        };

        inline for (0..len) |i| {
            ab_s[i][0] = as[i];
            ab_s[i][1] = bs[i];
        }
    } else {
        for (0..ab_s.len) |i| {
            ab_s[i][0] = as[i];
            ab_s[i][1] = bs[i];
        }
    }
}

pub inline fn zip_comptimef(
    comptime as: anytype,
    comptime bs: anytype,
) YsComptimeZipType(as, bs) {
    comptime var ab_s: YsComptimeZipType(as, bs) = undefined;
    inline for (ab_s, 0..) |_, i| {
        ab_s[i][0] = as[i];
        ab_s[i][1] = bs[i];
    }
    return ab_s;
}

fn YsComptimeZipType(
    comptime as: anytype,
    comptime bs: anytype,
) type {
    const len = if (@typeInfo(@TypeOf(as)) == .@"struct")
        @typeInfo(@TypeOf(as)).@"struct".fields.len
    else
        as.len;

    var types: [len]type = undefined;
    inline for (0..len) |i| {
        types[i] = struct { @TypeOf(as[i]), @TypeOf(bs[i]) };
    }

    inline for (types) |t| {
        if (t != types[0]) {
            return @Tuple(&types);
        }
    }
    return [len]types[0];
}

pub inline fn flat_map(
    xs: anytype,
    f: anytype,
    ys: anytype,
) void {
    const Xs = @TypeOf(xs);
    const Outp = @typeInfo(@TypeOf(ys)).pointer.child;

    const needs_inline = @typeInfo(Xs) == .@"struct" or @typeInfo(Xs) == .array;

    if (comptime needs_inline) {
        const len = comptime_len(Xs).?;

        comptime var idx: usize = 0;
        inline for (0..len) |i| {
            const r = f(xs[i]);
            inline for (r, 0..) |v, j| {
                ys[idx + j] = v;
            }
            idx += r.len;
        }
    } else {
        if (@typeInfo(Outp) == .@"struct") {
            @compileError("slice -> tuple forbidden");
        }
        var idx: usize = 0;
        for (0..xs.len) |i| {
            const r = f(xs[i]);
            for (r, 0..) |v, j| {
                ys[idx + j] = v;
            }
            idx += r.len;
        }
    }
}

pub fn YsFlatMapType(
    comptime f: anytype,
    comptime xs_c: usize,
) type {
    const ReturnedSeqType = @typeInfo(@TypeOf(f)).@"fn".return_type.?;
    switch (@typeInfo(ReturnedSeqType)) {
        .array => |a| return [xs_c * a.len]a.child,
        .@"struct" => |s| {
            var types: [xs_c * s.fields.len]type = undefined;
            inline for (0..xs_c) |i| {
                for (s.fields, 0..) |field, j| {
                    types[i * s.fields.len + j] = field.field_type;
                }
            }
            return @Tuple(&types);
        },
        else => @compileError("f must return a tuple or array"),
    }
}

pub inline fn flat_map_comptimef(
    comptime xs: anytype,
    comptime f: anytype,
) YsComptimeFlatMapType(xs, f) {
    const len = comptime (comptime_len(@TypeOf(xs)) orelse xs.len);
    comptime var ys: YsComptimeFlatMapType(xs, f) = undefined;
    comptime var idx = 0;
    inline for (0..len) |i| {
        const r = comptime f(xs[i]);
        inline for (r, 0..) |v, j| {
            ys[idx + j] = v;
        }
        idx += r.len;
    }
    return ys;
}

fn YsComptimeFlatMapType(
    comptime xs: anytype,
    comptime f: anytype,
) type {
    const len = comptime_len(@TypeOf(xs)) orelse xs.len;

    var total: usize = 0;
    inline for (0..len) |i| {
        total += f(xs[i]).len;
    }

    var types: [total]type = undefined;
    var idx: usize = 0;
    inline for (0..len) |i| {
        const r = f(xs[i]);
        inline for (r) |v| {
            types[idx] = @TypeOf(v);
            idx += 1;
        }
    }

    inline for (types) |t| {
        if (t != types[0]) {
            return @Tuple(&types);
        }
    }
    return [total]types[0];
}

test "zip: tuples to array" {
    const as = .{ 1, 2, 3 };
    const bs = .{ "a", "b", "c" };
    var ab_s: [3]struct { i32, []const u8 } = undefined;
    zip(as, bs, &ab_s);
    try std.testing.expect(ab_s[0][0] == 1 and
        std.mem.eql(u8, ab_s[0][1], "a"));
    try std.testing.expect(ab_s[1][0] == 2 and
        std.mem.eql(u8, ab_s[1][1], "b"));
    try std.testing.expect(ab_s[2][0] == 3 and
        std.mem.eql(u8, ab_s[2][1], "c"));
}

test "zip: arrays to array" {
    const as = [_]i32{ 1, 2, 3 };
    const bs = [_][]const u8{ "a", "b", "c" };
    var ab_s: [3]struct { i32, []const u8 } = undefined;
    zip(as, bs, &ab_s);
    try std.testing.expect(ab_s[0][0] == 1 and
        std.mem.eql(u8, ab_s[0][1], "a"));
    try std.testing.expect(ab_s[2][0] == 3 and
        std.mem.eql(u8, ab_s[2][1], "c"));
}

test "zip: slices to slice dest" {
    const as = [_]i32{ 1, 2, 3 };
    const bs = [_][]const u8{ "a", "b", "c" };
    var buf: [3]struct { i32, []const u8 } = undefined;
    zip(as[0..], bs[0..], buf[0..]);
    try std.testing.expect(buf[0][0] == 1 and
        std.mem.eql(u8, buf[0][1], "a"));
    try std.testing.expect(buf[2][0] == 3 and
        std.mem.eql(u8, buf[2][1], "c"));
}

test "zip: tuple as, slice bs" {
    const as = .{ 1, 2, 3 };
    const bs = [_][]const u8{ "a", "b", "c" };
    var ab_s: [3]struct { i32, []const u8 } = undefined;
    zip(as, bs[0..], &ab_s);
    try std.testing.expect(ab_s[1][0] == 2 and
        std.mem.eql(u8, ab_s[1][1], "b"));
}

test "zip: slice as, tuple bs" {
    const as = [_]i32{ 1, 2, 3 };
    const bs = .{ "a", "b", "c" };
    var ab_s: [3]struct { i32, []const u8 } = undefined;
    zip(as[0..], bs, &ab_s);
    try std.testing.expect(ab_s[1][0] == 2 and
        std.mem.eql(u8, ab_s[1][1], "b"));
}

test "zip: array as, tuple bs" {
    const as = [_]i32{ 1, 2, 3 };
    const bs = .{ "a", "b", "c" };
    var ab_s: [3]struct { i32, []const u8 } = undefined;
    zip(as, bs, &ab_s);
    try std.testing.expect(ab_s[0][0] == 1 and
        std.mem.eql(u8, ab_s[0][1], "a"));
}

test "zip: tuple as, array bs" {
    const as = .{ 1, 2, 3 };
    const bs = [_][]const u8{ "a", "b", "c" };
    var ab_s: [3]struct { i32, []const u8 } = undefined;
    zip(as, bs, &ab_s);
    try std.testing.expect(ab_s[2][0] == 3 and
        std.mem.eql(u8, ab_s[2][1], "c"));
}

test "zip: single element tuples" {
    const as = .{42};
    const bs = .{"z"};
    var ab_s: [1]struct { i32, []const u8 } = undefined;
    zip(as, bs, &ab_s);
    try std.testing.expect(ab_s[0][0] == 42 and
        std.mem.eql(u8, ab_s[0][1], "z"));
}

test "zip: single element slices" {
    const as = [_]i32{42};
    const bs = [_][]const u8{"z"};
    var ab_s: [1]struct { i32, []const u8 } = undefined;
    zip(as[0..], bs[0..], &ab_s);
    try std.testing.expect(ab_s[0][0] == 42 and
        std.mem.eql(u8, ab_s[0][1], "z"));
}

test "zip: empty slices" {
    const as = [_]i32{};
    const bs = [_][]const u8{};
    var ab_s: [0]struct { i32, []const u8 } = undefined;
    zip(as[0..], bs[0..], &ab_s);
    try std.testing.expect(ab_s.len == 0);
}

test "zip: empty tuples" {
    const as = .{};
    const bs = .{};
    var ab_s: [0]struct { i32, []const u8 } = undefined;
    zip(as, bs, &ab_s);
    try std.testing.expect(ab_s.len == 0);
}

test "zip: dest shorter than source slices" {
    const as = [_]i32{ 1, 2, 3, 4, 5 };
    const bs = [_][]const u8{ "a", "b", "c", "d", "e" };
    var ab_s: [3]struct { i32, []const u8 } = undefined;
    zip(as[0..], bs[0..], &ab_s);
    try std.testing.expect(ab_s[2][0] == 3 and
        std.mem.eql(u8, ab_s[2][1], "c"));
}

test "zip: floats and bools" {
    const as = .{ 1.5, 2.5, 3.5 };
    const bs = .{ true, false, true };
    var ab_s: [3]struct { f64, bool } = undefined;
    zip(as, bs, &ab_s);
    try std.testing.expect(ab_s[0][0] == 1.5 and ab_s[0][1] == true);
    try std.testing.expect(ab_s[2][0] == 3.5 and ab_s[2][1] == true);
}

test "zip: custom struct elements" {
    const Point = struct { x: i32, y: i32 };
    const as = [_]Point{
        .{ .x = 1, .y = 2 },
        .{ .x = 3, .y = 4 },
    };
    const bs = [_][]const u8{ "p1", "p2" };
    var ab_s: [2]struct { Point, []const u8 } = undefined;
    zip(as[0..], bs[0..], &ab_s);
    try std.testing.expect(ab_s[0][0].x == 1 and
        std.mem.eql(u8, ab_s[0][1], "p1"));
    try std.testing.expect(ab_s[1][0].y == 4 and
        std.mem.eql(u8, ab_s[1][1], "p2"));
}

test "zip: dest is a tuple" {
    const as = .{ 1, 2, 3 };
    const bs = .{ "a", "b", "c" };
    var ab_s: struct {
        struct { i32, []const u8 },
        struct { i32, []const u8 },
        struct { i32, []const u8 },
    } = undefined;
    zip(as, bs, &ab_s);
    try std.testing.expect(ab_s[1][0] == 2 and
        std.mem.eql(u8, ab_s[1][1], "b"));
}

test "zip: larger slice sequence" {
    const as = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 };
    const bs = [_]i32{ 10, 20, 30, 40, 50, 60, 70, 80 };
    var ab_s: [8]struct { i32, i32 } = undefined;
    zip(as[0..], bs[0..], &ab_s);
    var sum: i32 = 0;
    for (ab_s) |pair| {
        sum += pair[0] + pair[1];
    }
    try std.testing.expect(sum == 396);
}

test "zip_comptimef: uniform types produce array" {
    const as = .{ 1, 2, 3 };
    const bs = .{ 10, 20, 30 };
    const ab_s = zip_comptimef(as, bs);
    try std.testing.expect(ab_s[0][0] == 1 and ab_s[0][1] == 10);
    try std.testing.expect(ab_s[1][0] == 2 and ab_s[1][1] == 20);
    try std.testing.expect(ab_s[2][0] == 3 and ab_s[2][1] == 30);
}

test "zip_comptimef: mixed types produce tuple" {
    const as = .{ 1, 2, 3 };
    const bs = .{ "a", "b", "c" };
    const ab_s = zip_comptimef(as, bs);
    try std.testing.expect(ab_s[0][0] == 1 and
        std.mem.eql(u8, ab_s[0][1], "a"));
    try std.testing.expect(ab_s[1][0] == 2 and
        std.mem.eql(u8, ab_s[1][1], "b"));
    try std.testing.expect(ab_s[2][0] == 3 and
        std.mem.eql(u8, ab_s[2][1], "c"));
}

test "zip_comptimef: single element" {
    const as = .{@as(i32, 7)};
    const bs = .{"only"};
    const ab_s = zip_comptimef(as, bs);
    try std.testing.expect(ab_s[0][0] == 7 and
        std.mem.eql(u8, ab_s[0][1], "only"));
}

test "zip_comptimef: bool and float mix" {
    const as = .{ true, 2.5, false };
    const bs = .{ 1.5, false, true };
    const ab_s = zip_comptimef(as, bs);
    try std.testing.expect(ab_s[0][0] == true and ab_s[0][1] == 1.5);
    try std.testing.expect(ab_s[1][0] == 2.5 and ab_s[1][1] == false);
    try std.testing.expect(ab_s[2][0] == false and ab_s[2][1] == true);
}

test "zip_comptimef: nested struct values" {
    const Point = struct { x: i32, y: i32 };
    const as = .{
        Point{ .x = 1, .y = 2 },
        Point{ .x = 3, .y = 4 },
    };
    const bs = .{ "a", "b" };
    const ab_s = zip_comptimef(as, bs);
    try std.testing.expect(ab_s[0][0].x == 1 and
        std.mem.eql(u8, ab_s[0][1], "a"));
    try std.testing.expect(ab_s[1][0].y == 4 and
        std.mem.eql(u8, ab_s[1][1], "b"));
}

test "flat_map: array to array, uniform 2-per-element" {
    const as = [_]i32{ 1, 2, 3 };
    var out: [6]i32 = undefined;
    flat_map(as[0..], struct {
        fn f(x: i32) [2]i32 {
            return .{ x, x * 10 };
        }
    }.f, out[0..]);
    try std.testing.expect(out[0] == 1 and out[1] == 10);
    try std.testing.expect(out[2] == 2 and out[3] == 20);
    try std.testing.expect(out[4] == 3 and out[5] == 30);
}

test "flat_map: slice as, slice out" {
    const as = [_]i32{ 1, 2, 3 };
    var out: [6]i32 = undefined;
    flat_map(as[0..], struct {
        fn f(x: i32) [2]i32 {
            return .{ x, -x };
        }
    }.f, out[0..]);
    try std.testing.expect(out[1] == -1 and out[5] == -3);
}

test "flat_map: tuple as, array out" {
    const as = .{ 1, 2, 3 };
    var out: [6]i32 = undefined;
    flat_map(as, struct {
        fn f(x: i32) [2]i32 {
            return .{ x, x + 100 };
        }
    }.f, &out);
    try std.testing.expect(out[0] == 1 and out[1] == 101);
    try std.testing.expect(out[4] == 3 and out[5] == 103);
}

test "flat_map: tuple as, slice out" {
    const as = .{ 1, 2, 3 };
    var out: [6]i32 = undefined;
    flat_map(as, struct {
        fn f(x: i32) [2]i32 {
            return .{ x, x };
        }
    }.f, out[0..]);
    try std.testing.expect(out[4] == 3 and out[5] == 3);
}

test "flat_map: dest is a tuple" {
    const as = [_]i32{ 1, 2 };
    var out: struct { i32, i32, i32, i32 } = undefined;
    flat_map(as, struct {
        fn f(x: i32) [2]i32 {
            return .{ x, x * 2 };
        }
    }.f, &out);
    try std.testing.expect(out[0] == 1 and out[1] == 2);
    try std.testing.expect(out[2] == 2 and out[3] == 4);
}

test "flat_map: single element input" {
    const as = [_]i32{5};
    var out: [3]i32 = undefined;
    flat_map(as[0..], struct {
        fn f(x: i32) [3]i32 {
            return .{ x, x, x };
        }
    }.f, out[0..]);
    try std.testing.expect(out[0] == 5 and out[1] == 5 and out[2] == 5);
}

test "flat_map: single element expands to one" {
    const as = [_]i32{9};
    var out: [1]i32 = undefined;
    flat_map(as[0..], struct {
        fn f(x: i32) [1]i32 {
            return .{x};
        }
    }.f, out[0..]);
    try std.testing.expect(out[0] == 9);
}

test "flat_map: empty input, empty output" {
    const as = [_]i32{};
    var out: [0]i32 = undefined;
    flat_map(as[0..], struct {
        fn f(x: i32) [2]i32 {
            return .{ x, x };
        }
    }.f, out[0..]);
    try std.testing.expect(out.len == 0);
}

test "flat_map: function returns zero-length array" {
    const as = [_]i32{ 1, 2, 3 };
    var out: [0]i32 = undefined;
    flat_map(as[0..], struct {
        fn f(x: i32) [0]i32 {
            _ = x;
            return .{};
        }
    }.f, out[0..]);
    try std.testing.expect(out.len == 0);
}

test "flat_map: custom struct output elements" {
    const Point = struct { x: i32, y: i32 };
    const as = [_]i32{ 1, 2 };
    var out: [4]Point = undefined;
    flat_map(as[0..], struct {
        fn f(v: i32) [2]Point {
            return .{
                .{ .x = v, .y = 0 },
                .{ .x = 0, .y = v },
            };
        }
    }.f, out[0..]);
    try std.testing.expect(out[0].x == 1 and out[1].y == 1);
    try std.testing.expect(out[2].x == 2 and out[3].y == 2);
}

test "flat_map: floats and bools output" {
    const as = [_]f64{ 1.5, 2.5 };
    var out: [4]f64 = undefined;
    flat_map(as[0..], struct {
        fn f(v: f64) [2]f64 {
            return .{ v, v * 2 };
        }
    }.f, out[0..]);
    try std.testing.expect(out[0] == 1.5 and out[1] == 3.0);
    try std.testing.expect(out[2] == 2.5 and out[3] == 5.0);
}

test "flat_map: nested struct input expands to strings" {
    const Point = struct { x: i32, y: i32 };
    const as = [_]Point{
        .{ .x = 1, .y = 2 },
        .{ .x = 3, .y = 4 },
    };
    var out: [4]i32 = undefined;
    flat_map(as[0..], struct {
        fn f(p: Point) [2]i32 {
            return .{ p.x, p.y };
        }
    }.f, out[0..]);
    try std.testing.expect(out[0] == 1 and out[1] == 2);
    try std.testing.expect(out[2] == 3 and out[3] == 4);
}

test "flat_map: larger slice sequence, sum check" {
    const as = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 };
    var out: [16]i32 = undefined;
    flat_map(as[0..], struct {
        fn f(v: i32) [2]i32 {
            return .{ v, v };
        }
    }.f, out[0..]);
    var sum: i32 = 0;
    for (out) |v| {
        sum += v;
    }
    try std.testing.expect(sum == 72);
}

test "flat_map: tuple input, variable-length expansion via comptime f" {
    const as = .{ 1, 2, 3 };
    var out: [6]i32 = undefined;
    flat_map(as, struct {
        fn f(comptime x: comptime_int) [x]i32 {
            var r: [x]i32 = undefined;
            inline for (0..x) |i| r[i] = x;
            return r;
        }
    }.f, out[0..]);
    try std.testing.expect(out[0] == 1);
    try std.testing.expect(out[1] == 2 and out[2] == 2);
    try std.testing.expect(out[3] == 3 and out[4] == 3 and out[5] == 3);
}

test "flat_map: usage of YsFlatMapType" {
    const f = struct {
        fn f(x: u8) [4]u8 {
            return .{ x, x * 2, x * 3, x * 4 };
        }
    }.f;

    const as = [_]u8{ 1, 2, 3 };
    var out: YsFlatMapType(f, as.len) = undefined;
    flat_map(as, f, &out);
    try std.testing.expect(out[0] == 1 and out[1] == 2 and out[2] == 3 and out[3] == 4);
    try std.testing.expect(out[4] == 2 and out[5] == 4 and out[6] == 6 and out[7] == 8);
    try std.testing.expect(out[8] == 3 and out[9] == 6 and out[10] == 9 and out[11] == 12);
}

test "flat_map_comptimef: uniform types produce array" {
    const as = .{ 1, 2, 3 };
    const out = flat_map_comptimef(as, struct {
        fn f(x: i32) [2]i32 {
            return .{ x, x * x };
        }
    }.f);
    try std.testing.expect(out[0] == 1 and out[1] == 1);
    try std.testing.expect(out[2] == 2 and out[3] == 4);
    try std.testing.expect(out[4] == 3 and out[5] == 9);
}

test "flat_map_comptimef: single element" {
    const as = .{@as(i32, 4)};
    const out = flat_map_comptimef(as, struct {
        fn f(x: i32) [2]i32 {
            return .{ x, x + 1 };
        }
    }.f);
    try std.testing.expect(out[0] == 4 and out[1] == 5);
}

test "flat_map_comptimef: bool and float mix" {
    const as = .{ true, false };
    const out = flat_map_comptimef(as, struct {
        fn f(b: bool) [2]f64 {
            return if (b) .{ 1.0, 1.0 } else .{ 0.0, 0.0 };
        }
    }.f);
    try std.testing.expect(out[0] == 1.0 and out[1] == 1.0);
    try std.testing.expect(out[2] == 0.0 and out[3] == 0.0);
}

test "flat_map_comptimef: nested struct values" {
    const Point = struct { x: i32, y: i32 };
    const as = .{
        Point{ .x = 1, .y = 2 },
        Point{ .x = 3, .y = 4 },
    };
    const out = flat_map_comptimef(as, struct {
        fn f(p: Point) [2]i32 {
            return .{ p.x, p.y };
        }
    }.f);
    try std.testing.expect(out[0] == 1 and out[1] == 2);
    try std.testing.expect(out[2] == 3 and out[3] == 4);
}

test "flat_map_comptimef: identity produces mixed tuple types" {
    const as = .{ 1, "a", true };
    const out = flat_map_comptimef(as, struct {
        fn f(comptime x: anytype) [1]@TypeOf(x) {
            return .{x};
        }
    }.f);
    try std.testing.expect(out[0] == 1);
    try std.testing.expect(std.mem.eql(u8, out[1], "a"));
    try std.testing.expect(out[2] == true);
}

test "flat_map_comptimef: variable-length per element" {
    const as = .{ 1, 2, 3 };
    const out = flat_map_comptimef(as, struct {
        fn f(comptime x: comptime_int) [x]i32 {
            var r: [x]i32 = undefined;
            inline for (0..x) |i| r[i] = x;
            return r;
        }
    }.f);
    try std.testing.expect(out[0] == 1);
    try std.testing.expect(out[1] == 2 and out[2] == 2);
    try std.testing.expect(out[3] == 3 and out[4] == 3 and out[5] == 3);
}
