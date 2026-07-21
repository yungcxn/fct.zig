const std = @import("std");

pub inline fn map(
    comptime f: anytype,
    xs: anytype,
    ys: anytype,
) void {
    if (@typeInfo(@TypeOf(xs)) == .@"struct") {
        inline for (xs, 0..) |x, i| ys[i] = f(x);
    } else {
        for (xs, 0..) |x, i| ys[i] = f(x);
    }
}

// helper for ys buffer definition
pub fn YsMapType(
    comptime f: anytype,
    comptime xs_c: usize,
) type {
    return [xs_c]@typeInfo(@TypeOf(f)).@"fn".return_type.?;
}

// this is for a function f, that has a comptime-evaluated return type.
// - through this, f can return different types for different xs
// - for xs as array/slice, it returns [_]f(xs[0])
// - for xs as a tuple, it constructs a tuple out of everything f returns
//     for every element in xs
pub inline fn map_comptimef(
    comptime f: anytype,
    comptime xs: anytype,
) YsComptimeMapType(f, xs) {
    var ys: YsComptimeMapType(f, xs) = undefined;
    inline for (xs, 0..) |x, i| ys[i] = f(x);
    return ys;
}

fn YsComptimeMapType(comptime f: anytype, comptime xs: anytype) type {
    switch (@typeInfo(@TypeOf(xs))) {
        .@"struct" => {
            const fields = @typeInfo(@TypeOf(xs)).@"struct".fields;
            var types: [fields.len]type = undefined;
            inline for (fields, 0..) |field, i| {
                types[i] = @TypeOf(f(@field(xs, field.name)));
            }
            return @Tuple(&types);
        },
        else => return [xs.len]@TypeOf(f(xs[0])),
    }
}

pub inline fn map_field(
    xs: anytype,
    comptime field: std.meta.FieldEnum(ChildType(@TypeOf(xs))),
    ys: anytype,
) void {
    if (@typeInfo(@TypeOf(xs)) == .@"struct") {
        inline for (xs, 0..) |x, i| ys[i] = @field(x, @tagName(field));
    } else {
        for (xs, 0..) |x, i| ys[i] = @field(x, @tagName(field));
    }
}

pub inline fn map_field_comptimef(
    comptime xs: anytype,
    comptime field: std.meta.FieldEnum(ChildType(@TypeOf(xs))),
) YsMapFieldType(@TypeOf(xs), field) {
    var ys: YsMapFieldType(@TypeOf(xs), field) = undefined;
    inline for (xs, 0..) |x, i| ys[i] = @field(x, @tagName(field));
    return ys;
}

fn ChildType(comptime SeqType: type) type {
    return switch (@typeInfo(SeqType)) {
        .pointer => |p| p.child,
        .array => |a| a.child,
        .@"struct" => @typeInfo(SeqType).@"struct".fields[0].type,
        else => @compileError("Unsupported type"),
    };
}

// We assume here, that XsType is either []SomeStructType, or
//   .{SomeStructType, SomeStructType, ...} (tuple of struct), where all the
//   struct types are the same.
fn YsMapFieldType(
    comptime XsType: type,
    comptime fieldenumval: std.meta.FieldEnum(ChildType(XsType)),
) type {
    const len = switch (@typeInfo(XsType)) {
        .array => |a| a.len,
        .@"struct" => @typeInfo(XsType).@"struct".fields.len,
        else => @compileError("Unsupported type"),
    };

    return [len]@FieldType(
        ChildType(XsType),
        @tagName(fieldenumval),
    );
}

// runtime version
pub inline fn filter(comptime pred: anytype, xs: anytype, ys: anytype) usize {
    var ys_c: usize = 0;
    if (@typeInfo(@TypeOf(xs)) == .@"struct") {
        inline for (xs) |x| if (pred(x)) {
            ys[ys_c] = x;
            ys_c += 1;
        };
    } else {
        for (xs) |x| if (pred(x)) {
            ys[ys_c] = x;
            ys_c += 1;
        };
    }
    return ys_c;
}

// if you have comptime-known xs, and do not want
//   an outbuf.
pub inline fn filter_comptimef(
    comptime pred: anytype,
    comptime xs: anytype,
) YsComptimeFilterType(pred, xs) {
    const ys = comptime blk: {
        var tmp: YsComptimeFilterType(pred, xs) = undefined;
        var tmp_c: usize = 0;
        for (xs) |x| if (pred(x)) {
            tmp[tmp_c] = x;
            tmp_c += 1;
        };
        break :blk tmp;
    };
    return ys;
}

fn YsComptimeFilterType(
    comptime pred: anytype,
    comptime xs: anytype,
) type {
    var newlen = 0;
    if (@typeInfo(@TypeOf(xs)) == .@"struct") {
        // types could be different, so we construct a tuple
        var types: [xs.len]type = undefined;
        inline for (xs) |x| if (pred(x)) {
            types[newlen] = @TypeOf(x);
            newlen += 1;
        };
        return @Tuple(types[0..newlen]);
    } else {
        for (xs) |x| if (pred(x)) {
            newlen += 1;
        };
        return [newlen]@TypeOf(xs[0]);
    }
}

test "map_comptimef" {
    // for array
    {
        const to_array = struct {
            fn f(x: anytype) [1]@TypeOf(x) {
                return .{x};
            }
        }.f;
        const xs = [_]i32{42};
        const ys = map_comptimef(to_array, xs); // Check: map should not work.
        try std.testing.expect(@TypeOf(ys) == [1][1]i32);
        try std.testing.expectEqualSlices(i32, &[_]i32{42}, &ys[0]);
    }

    // for differently typed elements in a tuple
    {
        const to_array = struct {
            fn f(x: anytype) [1]@TypeOf(x) {
                return .{x};
            }
        }.f;
        const xs = .{ @as(i32, 42), @as(f32, 3.14) };
        const ys = map_comptimef(to_array, xs);
        try std.testing.expect(@TypeOf(ys) == struct { [1]i32, [1]f32 });
        try std.testing.expectEqualSlices(i32, &[_]i32{42}, &ys[0]);
        try std.testing.expectEqualSlices(f32, &[_]f32{3.14}, &ys[1]);
    }
}

test "map, comptime map" {
    const double = struct {
        fn f(x: i32) i32 {
            return x * 2;
        }
    }.f;

    // map (inline and no inline): const array at runtime?
    // uses YsMapType helper to declare the output buffer
    {
        const xs = [_]i32{ 10, 20, 30 };
        var ys: YsMapType(double, xs.len) = undefined;
        var zs: YsMapType(double, xs.len) = undefined;
        map(double, xs, &ys);
        map(double, xs, &zs);
        try std.testing.expectEqualSlices(i32, &[_]i32{ 20, 40, 60 }, &ys);
        try std.testing.expectEqualSlices(i32, &[_]i32{ 20, 40, 60 }, &zs);
    }

    // map (inline and no inline): var array at runtime?
    {
        var later_mut_xs = [_]i32{ 10, 20, 30 };
        var ys: YsMapType(double, later_mut_xs.len) = undefined;
        map(double, later_mut_xs, &ys);
        try std.testing.expectEqualSlices(i32, &[_]i32{ 20, 40, 60 }, &ys);
        later_mut_xs[1] = 99; // meaningless; for compiler warning

        var xs = [_]i32{ 1, 2, 3 };
        xs[1] = 99;
        var zs: [3]i32 = undefined; // plain declaration also works
        map(double, xs, &zs);
        try std.testing.expectEqualSlices(i32, &[_]i32{ 2, 198, 6 }, &zs);
    }

    // map for slice
    {
        var xs = try std.heap.smp_allocator.alloc(i32, 3);
        defer std.heap.smp_allocator.free(xs);
        xs[0] = 10;
        xs[1] = 20;
        xs[2] = 30;
        var ys: [3]i32 = undefined;
        map(double, xs, &ys);
        try std.testing.expectEqualSlices(i32, &[_]i32{ 20, 40, 60 }, &ys);
    }

    // map: array with comptime-known values
    {
        const xs = [_]i32{ 1, 2, 3 };
        const ys = comptime blk: {
            var tmp: YsMapType(double, xs.len) = undefined;
            map(double, xs, &tmp);
            break :blk tmp;
        };
        try std.testing.expectEqualSlices(i32, &[_]i32{ 2, 4, 6 }, &ys);
    }

    // map: tuple with comptime-known values (homogeneous)
    {
        const xs = .{ @as(i32, 1), @as(i32, 2), @as(i32, 3) };
        const ys = comptime blk: {
            var tmp: [3]i32 = undefined;
            map(double, xs, &tmp);
            break :blk tmp;
        };
        try std.testing.expectEqualSlices(i32, &[_]i32{ 2, 4, 6 }, &ys);
    }

    // map: tuple with heterogeneous types, for comptime-const and runtime var
    {
        const to_f32 = struct {
            fn f(x: anytype) f32 {
                return @floatFromInt(x);
            }
        }.f;
        const xs = .{ @as(i32, 1), @as(u8, 2), @as(i64, 3) };
        // here we must inline map since xs is heterogeneous
        const ys = comptime blk: {
            var tmp: [3]f32 = undefined;
            map(to_f32, xs, &tmp);
            break :blk tmp;
        };
        // comptime is not needed tho. e.g.
        var ys2: [3]f32 = undefined;
        map(to_f32, xs, &ys2);
        // mutate ys2 for compiler warning only
        ys2[0] += 1.0;
        // attention! since this map is not comptimef, it has a function that
        //   returns the same type for all xs, so its not { f32, f32, f32 },
        //   but [3]f32
        try std.testing.expect(@TypeOf(ys) == [3]f32);
        try std.testing.expectEqual(@as(f32, 1.0), ys[0]);
        try std.testing.expectEqual(@as(f32, 2.0), ys[1]);
        try std.testing.expectEqual(@as(f32, 3.0), ys[2]);

        try std.testing.expect(@TypeOf(ys2) == [3]f32);
        try std.testing.expectEqual(@as(f32, 2.0), ys2[0]); // mutated val
        try std.testing.expectEqual(@as(f32, 2.0), ys2[1]);
        try std.testing.expectEqual(@as(f32, 3.0), ys2[2]);
    }
}

test "map_field" {
    // for xs as tuple
    {
        const Inner = struct { a: i32, b: f64 };
        const outer = .{
            Inner{ .a = 1, .b = 2.0 },
            Inner{ .a = 3, .b = 4.0 },
        };
        var ys_a: [2]i32 = undefined;
        var ys_b: [2]f64 = undefined;
        map_field(outer, .a, &ys_a);
        map_field(outer, .b, &ys_b);
        try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 3 }, &ys_a);
        try std.testing.expectEqualSlices(f64, &[_]f64{ 2.0, 4.0 }, &ys_b);
    }

    // for xs as array
    {
        const Inner = struct { a: i32, b: f64 };
        const outer = [_]Inner{
            Inner{ .a = 1, .b = 2.0 },
            Inner{ .a = 3, .b = 4.0 },
        };
        var ys_a: [2]i32 = undefined;
        var ys_b: [2]f64 = undefined;
        map_field(outer, .a, &ys_a);
        map_field(outer, .b, &ys_b);
        try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 3 }, &ys_a);
        try std.testing.expectEqualSlices(f64, &[_]f64{ 2.0, 4.0 }, &ys_b);
    }

    // for xs as slice
    {
        const Inner = struct { a: i32, b: f64 };
        var outer: []Inner = try std.heap.smp_allocator.alloc(Inner, 2);
        defer std.heap.smp_allocator.free(outer);
        outer[0] = Inner{ .a = 1, .b = 2.0 };
        outer[1] = Inner{ .a = 3, .b = 4.0 };
        var ys_a: [2]i32 = undefined;
        var ys_b: [2]f64 = undefined;
        map_field(outer, .a, &ys_a);
        map_field(outer, .b, &ys_b);
        try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 3 }, &ys_a);
        try std.testing.expectEqualSlices(f64, &[_]f64{ 2.0, 4.0 }, &ys_b);
    }
}

test "map_field_comptimef" {
    // for xs as tuple
    {
        const Inner = struct { a: i32, b: f64 };
        const outer = .{
            Inner{ .a = 1, .b = 2.0 },
            Inner{ .a = 3, .b = 4.0 },
        };
        const ys_a = map_field_comptimef(outer, .a);
        const ys_b = map_field_comptimef(outer, .b);
        try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 3 }, &ys_a);
        try std.testing.expectEqualSlices(f64, &[_]f64{ 2.0, 4.0 }, &ys_b);
    }

    // for xs as array
    {
        const Inner = struct { a: i32, b: f64 };
        const outer = [_]Inner{
            Inner{ .a = 1, .b = 2.0 },
            Inner{ .a = 3, .b = 4.0 },
        };
        const ys_a = map_field_comptimef(outer, .a);
        const ys_b = map_field_comptimef(outer, .b);
        try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 3 }, &ys_a);
        try std.testing.expectEqualSlices(f64, &[_]f64{ 2.0, 4.0 }, &ys_b);
    }
}

test "filter" {
    const is_even = struct {
        fn f(x: u32) bool {
            return x % 2 == 0;
        }
    }.f;

    // filter for array
    {
        const xs = [_]u32{ 1, 2, 3, 4, 5 };
        var ys: [5]u32 = @splat(0);
        const count = filter(is_even, xs, &ys);
        try std.testing.expectEqual(@as(usize, 2), count);
        try std.testing.expectEqualSlices(
            u32,
            &[_]u32{ 2, 4 },
            ys[0..count],
        );
    }

    // filter for tuple
    {
        const xs = .{ @as(u8, 1), @as(u16, 2), @as(u32, 3), @as(u64, 4), @as(u8, 5) };
        var ys: [5]u64 = @splat(0);
        const count = filter(is_even, xs, &ys);
        try std.testing.expectEqual(@as(usize, 2), count);
        try std.testing.expectEqualSlices(
            u64,
            &[_]u64{ 2, 4 },
            ys[0..count],
        );
    }

    // filter for slice
    {
        var xs = try std.heap.smp_allocator.alloc(u32, 5);
        defer std.heap.smp_allocator.free(xs);
        xs[0] = 1;
        xs[1] = 2;
        xs[2] = 3;
        xs[3] = 4;
        xs[4] = 5;
        var ys: [5]u32 = @splat(0);
        const count = filter(is_even, xs, &ys);
        try std.testing.expectEqual(@as(usize, 2), count);
        try std.testing.expectEqualSlices(
            u32,
            &[_]u32{ 2, 4 },
            ys[0..count],
        );
    }
}

test "filter_comptimef" {
    const is_even = struct {
        fn f(x: anytype) bool {
            return @mod(x, @as(@TypeOf(x), 2)) == @as(@TypeOf(x), 0);
        }
    }.f;

    const xs = .{
        @as(u8, 1),
        @as(u16, 2),
        @as(u32, 3),
        @as(u64, 4),
    };
    const filtered = filter_comptimef(is_even, xs);
    try std.testing.expect(@TypeOf(filtered) == struct { u16, u64 });
    try std.testing.expectEqual(@as(u16, 2), filtered[0]);
    try std.testing.expectEqual(@as(u64, 4), filtered[1]);
}
