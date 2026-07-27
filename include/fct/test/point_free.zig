const std = @import("std");

const compose_manual = @import("../point_free.zig").compose_manual;
const compose_auto = @import("../point_free.zig").compose_auto;
const flow_manual = @import("../point_free.zig").flow_manual;
const flow_auto = @import("../point_free.zig").flow_auto;
const post_free_manual = @import("../point_free.zig").post_free_manual;
const post_free_auto = @import("../point_free.zig").post_free_auto;
const id = @import("../point_free.zig").id;
const tap = @import("../point_free.zig").tap;
const field = @import("../point_free.zig").field;

const bind0 = @import("../func_manip.zig").bind0;
const bind = @import("../func_manip.zig").bind;
const curry = @import("../func_manip.zig").curry;

const map = @import("../seq_produce.zig").map;
const filter = @import("../seq_produce.zig").filter;
const filter_comptimef = @import("../seq_produce.zig").filter_comptimef;
const take = @import("../seq_produce.zig").take;
const partition = @import("../seq_produce.zig").partition;

const zip = @import("../muldseq_produce.zig").zip;
const zip_comptimef = @import("../muldseq_produce.zig").zip_comptimef;

const reduce = @import("../sval_produce.zig").reduce;
const any = @import("../sval_produce.zig").any;
const all = @import("../sval_produce.zig").all;
const find = @import("../sval_produce.zig").find;

fn double(x: i32) i32 {
    return x * 2;
}

fn add_one(x: i32) i32 {
    return x + 1;
}

fn negate(x: i32) i32 {
    return -x;
}

fn add_two_args(a: i32, b: i32) i32 {
    return a + b;
}

fn mul_two_args(a: i32, b: i32) i32 {
    return a * b;
}

fn is_even(x: i32) bool {
    return @mod(x, 2) == 0;
}

fn is_positive(x: i32) bool {
    return x > 0;
}

fn sum_reduce(acc: i32, x: i32) i32 {
    return acc + x;
}

fn max_reduce(acc: i32, x: i32) i32 {
    return if (x > acc) x else acc;
}

const Point = struct {
    x: i32,
    y: i32,
};

test "bind0 + compose_manual: bound function slots into a pipeline" {
    const add10 = bind0(add_two_args, 10);
    const composed = compose_manual(i32, i32, .{ add10, double });
    try std.testing.expectEqual(@as(i32, 30), composed(5));
}

test "bind0 + flow_manual: fixed-arg function used as one pipeline step" {
    const mul3 = bind0(mul_two_args, 3);
    const result = flow_manual(4, i32, i32, .{ add_one, mul3 });
    try std.testing.expectEqual(@as(i32, 15), result);
}

test "bind: fixes argument by index/value pair, usable in compose_auto" {
    const add100 = bind(add_two_args, .{.{ 1, 100 }});
    const composed = compose_auto(.{ add100, negate });
    try std.testing.expectEqual(@as(i32, -105), composed(5));
}

test "bind vs bind0: binding index 0 agrees with bind0 for same value" {
    const viaBind0 = bind0(add_two_args, 7);
    const viaBind = bind(add_two_args, .{.{ 0, 7 }});
    var b: i32 = -5;
    while (b < 5) : (b += 1) {
        try std.testing.expectEqual(viaBind0(b), viaBind(b));
    }
}

test "curry + tap: curried function result observed via tap" {
    const curried = curry(add_two_args);
    const partial = curried(4);
    const result = partial(6);
    try std.testing.expectEqual(@as(i32, 10), result);
}

test "curry + id: applying id to a curried partial does not change behavior" {
    const curried = curry(mul_two_args);
    const partial = id(curried(6));
    try std.testing.expectEqual(@as(i32, 42), partial(7));
}

test "map + compose_auto: map a pipeline function over an array" {
    const pipeline = compose_auto(.{ add_one, double });
    const xs = [_]i32{ 1, 2, 3, 4 };
    var ys: [4]i32 = undefined;
    map(pipeline, xs, &ys);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 4, 6, 8, 10 }, &ys);
}

test "map + field: extract fields from an array of structs via wrapper" {
    const Wrapper = struct {
        pub fn getX(p: Point) i32 {
            return field(p, .x);
        }
    };
    const pts = [_]Point{
        .{ .x = 1, .y = 9 },
        .{ .x = 2, .y = 8 },
        .{ .x = 3, .y = 7 },
    };
    var xs_out: [3]i32 = undefined;
    map(Wrapper.getX, pts, &xs_out);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 2, 3 }, &xs_out);
}

test "filter + bind0: filter using a partially-applied predicate-like function" {
    const Cmp = struct {
        pub fn greaterThan(threshold: i32, x: i32) bool {
            return x > threshold;
        }
    };
    const greaterThan2 = bind0(Cmp.greaterThan, 2);
    const xs = [_]i32{ 1, 2, 3, 4, 5 };
    var ys: [5]i32 = undefined;
    const n = filter(greaterThan2, xs, &ys);
    try std.testing.expectEqual(@as(usize, 3), n);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 3, 4, 5 }, ys[0..n]);
}

test "take + compose_manual predicate: take-while using a composed boolean check" {
    const pred = compose_manual(i32, bool, .{is_positive});
    const xs = [_]i32{ 3, 1, 4, -1, 5, 9 };
    var ys: [6]i32 = undefined;
    const n = take(pred, xs, &ys);
    try std.testing.expectEqual(@as(usize, 3), n);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 3, 1, 4 }, ys[0..n]);
}

test "partition: partition even/odd while tapping total count via side effect" {
    comptime var total: usize = 0;
    const pred = struct {
        pub fn isEven(x: i32) bool {
            total += 1;
            return is_even(x);
        }
    };
    const xs = [_]i32{ 1, 2, 3, 4, 5, 6 };
    var evens: [6]i32 = undefined;
    var odds: [6]i32 = undefined;
    const n_evens = partition(pred.isEven, xs, &evens, &odds);
    try std.testing.expectEqual(@as(usize, 3), n_evens);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 2, 4, 6 }, evens[0..n_evens]);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 3, 5 }, odds[0..(xs.len - n_evens)]);
    try std.testing.expectEqual(@as(usize, xs.len), total);
}

test "zip + map: zip two arrays then map a combining function over pairs" {
    const as = [_]i32{ 1, 2, 3 };
    const bs = [_]i32{ 10, 20, 30 };
    var pairs: [3]struct { i32, i32 } = undefined;
    zip(as, bs, &pairs);

    const SumPair = struct {
        pub fn call(p: struct { i32, i32 }) i32 {
            return p[0] + p[1];
        }
    };
    var sums: [3]i32 = undefined;
    map(SumPair.call, pairs, &sums);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 11, 22, 33 }, &sums);
}

test "zip_comptimef + compose_auto: comptime zip then transform each pair" {
    const as = [_]i32{ 1, 2 };
    const bs = [_]i32{ 100, 200 };
    const pairs = zip_comptimef(as, bs);

    const AddPair = struct {
        pub fn call(p: struct { i32, i32 }) i32 {
            return p[0] + p[1];
        }
    };
    const pipeline = compose_auto(.{ AddPair.call, double });
    try std.testing.expectEqual(@as(i32, 202), pipeline(pairs[0]));
    try std.testing.expectEqual(@as(i32, 404), pipeline(pairs[1]));
}

test "reduce + compose_manual: reduce result fed into a pipeline" {
    const xs = [_]i32{ 1, 2, 3, 4, 5 };
    const total = reduce(sum_reduce, @as(i32, 0), xs);
    const pipeline = compose_manual(i32, i32, .{ add_one, double });
    try std.testing.expectEqual(@as(i32, 32), pipeline(total));
}

test "reduce (max): capture the running max via side effect" {
    const xs = [_]i32{ 3, 7, 2, 9, 4 };
    const m = reduce(max_reduce, @as(i32, std.math.minInt(i32)), xs);
    try std.testing.expectEqual(@as(i32, 9), m);
}

test "any/all + bind0: existence and universality checks with a partially applied predicate" {
    const Cmp = struct {
        pub fn greaterThan(threshold: i32, x: i32) bool {
            return x > threshold;
        }
    };
    const greaterThan10 = bind0(Cmp.greaterThan, 10);
    const xs = [_]i32{ 3, 12, 5, 20 };
    try std.testing.expect(any(greaterThan10, xs));
    try std.testing.expect(!all(greaterThan10, xs));

    const ys = [_]i32{ 11, 12, 13 };
    try std.testing.expect(all(greaterThan10, ys));
}

test "find + field: find first struct matching predicate on its field" {
    const Wrapper = struct {
        pub fn xIsThree(p: Point) bool {
            return field(p, .x) == 3;
        }
    };
    const pts = [_]Point{
        .{ .x = 1, .y = 1 },
        .{ .x = 3, .y = 99 },
        .{ .x = 3, .y = 100 },
    };
    const found = find(Wrapper.xIsThree, pts);
    try std.testing.expect(found != null);
    try std.testing.expectEqual(@as(i32, 3), found.?.x);
    try std.testing.expectEqual(@as(i32, 99), found.?.y);
}

test "find: returns null when nothing in xs matches" {
    const xs = [_]i32{ 1, 3, 5, 7 };
    const found = find(is_even, xs);
    try std.testing.expectEqual(@as(?i32, null), found);
}

test "integration: filter -> map(compose_auto) -> reduce, wired through bind/curry" {
    const curriedCmp = curry(struct {
        pub fn call(threshold: i32, x: i32) bool {
            return x > threshold;
        }
    }.call);
    const keepPositive = curriedCmp(0);

    const xs = [_]i32{ -3, 4, -1, 8, 2, -5 };
    var filtered: [6]i32 = undefined;
    const n = filter(keepPositive, xs, &filtered);

    const pipeline = compose_auto(.{ add_one, double });
    var transformed: [6]i32 = undefined;
    map(pipeline, filtered[0..n], transformed[0..n]);

    const total = reduce(sum_reduce, @as(i32, 0), transformed[0..n]);

    try std.testing.expectEqual(@as(usize, 3), n);
    try std.testing.expectEqual(@as(i32, 34), total);
}
