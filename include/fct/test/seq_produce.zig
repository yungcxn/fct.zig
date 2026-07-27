const std = @import("std");

const map = @import("../seq_produce.zig").map;
const map_field = @import("../seq_produce.zig").map_field;
const map_inplace = @import("../seq_produce.zig").map_inplace;
const map_ret = @import("../seq_produce.zig").map_ret;
const map_new = @import("../seq_produce.zig").map_new;
const filter = @import("../seq_produce.zig").filter;
const filter_ret = @import("../seq_produce.zig").filter_ret;
const filter_new = @import("../seq_produce.zig").filter_new;
const take = @import("../seq_produce.zig").take;
const take_ret = @import("../seq_produce.zig").take_ret;
const take_new = @import("../seq_produce.zig").take_new;
const partition = @import("../seq_produce.zig").partition;
const partition_ret = @import("../seq_produce.zig").partition_ret;
const partition_new = @import("../seq_produce.zig").partition_new;
const map_comptimef = @import("../seq_produce.zig").map_comptimef;
const map_field_comptimef = @import("../seq_produce.zig").map_field_comptimef;
const filter_comptimef = @import("../seq_produce.zig").filter_comptimef;
const take_comptimef = @import("../seq_produce.zig").take_comptimef;
const partition_comptimef = @import("../seq_produce.zig").partition_comptimef;

const YsMapType = @import("../seq_produce.zig").YsMapType;

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

test "map_inplace: array" {
    const double = struct {
        fn f(x: i32) i32 {
            return x * 2;
        }
    }.f;

    var xs = [_]i32{ 10, 20, 30 };
    map_inplace(double, &xs);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 20, 40, 60 }, &xs);
}

test "map_inplace: slice" {
    const double = struct {
        fn f(x: i32) i32 {
            return x * 2;
        }
    }.f;

    var xs = try std.heap.smp_allocator.alloc(i32, 3);
    xs[0] = 10;
    xs[1] = 20;
    xs[2] = 30;
    map_inplace(double, xs);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 20, 40, 60 }, xs);
}

test "map_inplace: tuple" {
    const double = struct {
        fn f(x: i32) i32 {
            return x * 2;
        }
    }.f;

    var xs: @Tuple(&[_]type{ i32, i32, i32 }) = .{ 1, 20, 30 };
    xs[0] = 10;
    map_inplace(double, &xs);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 20, 40, 60 }, &xs);
}

test "map_ret" {
    const double = struct {
        fn f(x: i32) i32 {
            return x * 2;
        }
    }.f;

    const xs = [_]i32{ 10, 20, 30 };
    var ys: YsMapType(double, xs.len) = undefined;
    const result = map_ret(double, xs, &ys);
    try std.testing.expect(@TypeOf(result) == *YsMapType(double, xs.len));
    try std.testing.expectEqualSlices(i32, &[_]i32{ 20, 40, 60 }, result);
}

test "map_new" {
    const double = struct {
        fn f(x: i32) i32 {
            return x * 2;
        }
    }.f;

    const xs = [_]i32{ 10, 20, 30 };
    const ys = map_new(std.heap.smp_allocator, double, xs);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 20, 40, 60 }, ys);
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

test "filter_ret" {
    const is_even = struct {
        fn f(x: u32) bool {
            return x % 2 == 0;
        }
    }.f;

    const xs = [_]u32{ 1, 2, 3, 4, 5 };
    var buf: [5]u32 = @splat(0);
    const ys = filter_ret(is_even, xs, &buf);
    try std.testing.expectEqual(@as(usize, 2), ys.len);
    try std.testing.expectEqualSlices(
        u32,
        &[_]u32{ 2, 4 },
        ys,
    );
}

test "filter_ret with slice" {
    const is_even = struct {
        fn f(x: u32) bool {
            return x % 2 == 0;
        }
    }.f;

    const xs = [_]u32{ 1, 2, 3, 4, 5 };
    const buf = try std.heap.smp_allocator.alloc(u32, 5);
    const ys = filter_ret(is_even, xs, buf);
    try std.testing.expectEqual(@as(usize, 2), ys.len);
    try std.testing.expectEqualSlices(
        u32,
        &[_]u32{ 2, 4 },
        ys,
    );
}

test "filter_new" {
    const is_even = struct {
        fn f(x: u32) bool {
            return x % 2 == 0;
        }
    }.f;

    const xs = [_]u32{ 1, 2, 3, 4, 5 };
    const ys = filter_new(std.heap.smp_allocator, is_even, xs);
    try std.testing.expectEqual(@as(usize, 2), ys.len);
    try std.testing.expectEqualSlices(
        u32,
        &[_]u32{ 2, 4 },
        ys,
    );
}

test "take" {
    const is_even = struct {
        fn f(x: u32) bool {
            return x % 2 == 0;
        }
    }.f;

    const xs = [_]u32{ 2, 4, 6, 7, 8 };
    var ys: [5]u32 = @splat(0);
    const count = take(is_even, xs, &ys);
    try std.testing.expectEqual(@as(usize, 3), count);
    try std.testing.expectEqualSlices(
        u32,
        &[_]u32{ 2, 4, 6 },
        ys[0..count],
    );
}

test "take_comptimef" {
    const is_even = struct {
        fn f(x: anytype) bool {
            return @mod(x, @as(@TypeOf(x), 2)) == @as(@TypeOf(x), 0);
        }
    }.f;

    const xs = .{
        @as(u8, 2),
        @as(u16, 4),
        @as(u32, 6),
        @as(u64, 7),
        @as(u8, 8),
    };
    const taken = take_comptimef(is_even, xs);
    try std.testing.expect(@TypeOf(taken) == struct { u8, u16, u32 });
    try std.testing.expectEqual(@as(u8, 2), taken[0]);
    try std.testing.expectEqual(@as(u16, 4), taken[1]);
    try std.testing.expectEqual(@as(u32, 6), taken[2]);
}

test "take_ret" {
    const is_even = struct {
        fn f(x: u32) bool {
            return x % 2 == 0;
        }
    }.f;

    const xs = [_]u32{ 2, 4, 6, 7, 8 };
    var buf: [5]u32 = @splat(0);
    const ys = take_ret(is_even, xs, &buf);
    try std.testing.expectEqual(@as(usize, 3), ys.len);
    try std.testing.expectEqualSlices(
        u32,
        &[_]u32{ 2, 4, 6 },
        ys,
    );
}

test "take_new" {
    const is_even = struct {
        fn f(x: u32) bool {
            return x % 2 == 0;
        }
    }.f;

    const xs = [_]u32{ 2, 4, 6, 7, 8 };
    const ys = take_new(std.heap.smp_allocator, is_even, xs);
    try std.testing.expectEqual(@as(usize, 3), ys.len);
    try std.testing.expectEqualSlices(
        u32,
        &[_]u32{ 2, 4, 6 },
        ys,
    );
}

test "partition" {
    const is_even = struct {
        fn f(x: u32) bool {
            return x % 2 == 0;
        }
    }.f;

    const xs = [_]u32{ 1, 2, 3, 4, 5 };
    var ys_true: [5]u32 = @splat(0);
    var ys_false: [5]u32 = @splat(0);
    const counts = partition(is_even, xs, &ys_true, &ys_false);
    try std.testing.expectEqual(@as(usize, 2), counts[0]);
    try std.testing.expectEqual(@as(usize, 3), counts[1]);
    try std.testing.expectEqualSlices(
        u32,
        &[_]u32{ 2, 4 },
        ys_true[0..counts[0]],
    );
    try std.testing.expectEqualSlices(
        u32,
        &[_]u32{ 1, 3, 5 },
        ys_false[0..counts[1]],
    );
}

test "partition_comptimef" {
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
        @as(u8, 5),
    };
    const partitioned = partition_comptimef(is_even, xs);
    try std.testing.expect(@TypeOf(partitioned) == struct {
        struct { u16, u64 },
        struct { u8, u32, u8 },
    });
    try std.testing.expectEqual(@as(u16, 2), partitioned[0][0]);
    try std.testing.expectEqual(@as(u64, 4), partitioned[0][1]);
    try std.testing.expectEqual(@as(u8, 1), partitioned[1][0]);
    try std.testing.expectEqual(@as(u32, 3), partitioned[1][1]);
    try std.testing.expectEqual(@as(u8, 5), partitioned[1][2]);
}

test "partition_ret" {
    const is_even = struct {
        fn f(x: u32) bool {
            return x % 2 == 0;
        }
    }.f;

    const xs = [_]u32{ 1, 2, 3, 4, 5 };
    var buf_true: [5]u32 = @splat(0);
    var buf_false: [5]u32 = @splat(0);
    const partitioned = partition_ret(is_even, xs, &buf_true, &buf_false);
    try std.testing.expectEqual(@as(usize, 2), partitioned[0].len);
    try std.testing.expectEqual(@as(usize, 3), partitioned[1].len);
    try std.testing.expectEqualSlices(
        u32,
        &[_]u32{ 2, 4 },
        partitioned[0],
    );
    try std.testing.expectEqualSlices(
        u32,
        &[_]u32{ 1, 3, 5 },
        partitioned[1],
    );
}

test "partition_new" {
    const is_even = struct {
        fn f(x: u32) bool {
            return x % 2 == 0;
        }
    }.f;

    const xs = [_]u32{ 1, 2, 3, 4, 5 };
    const partitioned = partition_new(std.heap.smp_allocator, is_even, xs);
    try std.testing.expectEqual(@as(usize, 2), partitioned[0].len);
    try std.testing.expectEqual(@as(usize, 3), partitioned[1].len);
    try std.testing.expectEqualSlices(
        u32,
        &[_]u32{ 2, 4 },
        partitioned[0],
    );
    try std.testing.expectEqualSlices(
        u32,
        &[_]u32{ 1, 3, 5 },
        partitioned[1],
    );
}
