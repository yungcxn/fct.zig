const std = @import("std");

fn is_slice(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .pointer => |ptr_info| switch (ptr_info.size) {
            .slice => true,
            else => false,
        },
        else => false,
    };
}

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

// _inplace must always take ptr due to copy-evasion
pub inline fn map_inplace(
    comptime f: anytype,
    xs: anytype,
) void {
    return map(f, if (comptime is_slice(@TypeOf(xs))) xs else xs.*, xs);
}

// no real-world use
pub inline fn map_ret(
    comptime f: anytype,
    xs: anytype,
    ys: anytype,
) @TypeOf(ys) {
    map(f, xs, ys);
    return ys;
}

pub inline fn map_new(
    alloc: std.mem.Allocator,
    comptime f: anytype,
    xs: anytype,
) *YsMapType(f, xs.len) {
    const ys = alloc.create(YsMapType(f, xs.len)) catch @panic("OOM");
    map(f, xs, ys);
    return ys;
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

fn ChildType(comptime T: type) type {
    switch (@typeInfo(T)) {
        .@"struct" => |info| return info.fields[0].type,
        .array => |info| return info.child,
        .vector => |info| return info.child,
        .pointer => |info| switch (info.size) {
            .one => switch (@typeInfo(info.child)) {
                .array => |array_info| return array_info.child,
                .vector => |vector_info| return vector_info.child,
                .@"struct" => |struct_info| return struct_info.fields[0].type,
                else => @compileError("Unsupported: '" ++ @typeName(info.child) ++ "'"),
            },
            .many, .c, .slice => return info.child,
        },
        else => {},
    }
    @compileError("Unsupported: '" ++ @typeName(T) ++ "'");
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
pub inline fn filter(
    comptime pred: anytype,
    xs: anytype,
    ys: anytype,
) usize {
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

inline fn force_slice(ys: anytype) []ChildType(@TypeOf(ys)) {
    return switch (@typeInfo(@TypeOf(ys))) {
        .pointer => |ptr_info| switch (ptr_info.size) {
            .one => ys.*[0..],
            .slice => ys,
            else => @compileError("unsupported ys type"),
        },
        else => @compileError("ys must be slice / pointer-to-array"),
    };
}

pub inline fn filter_ret(
    comptime pred: anytype,
    xs: anytype,
    ys: anytype,
) []ChildType(@TypeOf(ys)) {
    const slice = force_slice(ys);
    const n = filter(pred, xs, ys);
    return slice[0..n];
}

pub fn filter_new(
    alloc: std.mem.Allocator,
    comptime pred: anytype,
    xs: anytype,
) []ChildType(@TypeOf(xs)) {
    const T = ChildType(@TypeOf(xs));
    var ys = alloc.alloc(T, xs.len) catch @panic("OOM");

    const n = filter(pred, xs, ys);

    if (alloc.resize(ys, n)) {
        ys.len = n;
    } else {
        ys = alloc.realloc(ys, n) catch @panic("OOM");
    }

    return ys;
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
        // types could be different -> new tuple
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

pub inline fn take(
    comptime pred: anytype,
    xs: anytype,
    ys: anytype,
) usize {
    var ys_c: usize = 0;
    if (@typeInfo(@TypeOf(xs)) == .@"struct") {
        inline for (xs) |x| {
            if (!pred(x)) return ys_c;
            ys[ys_c] = x;
            ys_c += 1;
        }
    } else {
        for (xs) |x| {
            if (!pred(x)) return ys_c;
            ys[ys_c] = x;
            ys_c += 1;
        }
    }
    return ys_c;
}

pub inline fn take_ret(
    comptime pred: anytype,
    xs: anytype,
    ys: anytype,
) []ChildType(@TypeOf(ys)) {
    const slice = force_slice(ys);
    const n = take(pred, xs, ys);
    return slice[0..n];
}

pub fn take_new(
    alloc: std.mem.Allocator,
    comptime pred: anytype,
    xs: anytype,
) []ChildType(@TypeOf(xs)) {
    const T = ChildType(@TypeOf(xs));
    var ys = alloc.alloc(T, xs.len) catch @panic("OOM");
    const n = take(pred, xs, ys);

    if (alloc.resize(ys, n)) {
        ys.len = n;
    } else {
        ys = alloc.realloc(ys, n) catch @panic("OOM");
    }

    return ys;
}

pub inline fn take_comptimef(
    comptime pred: anytype,
    comptime xs: anytype,
) YsComptimeTakeType(pred, xs) {
    const ys = comptime blk: {
        var tmp: YsComptimeTakeType(pred, xs) = undefined;
        var tmp_c: usize = 0;
        for (xs) |x| {
            if (!pred(x)) break;
            tmp[tmp_c] = x;
            tmp_c += 1;
        }
        break :blk tmp;
    };
    return ys;
}

fn YsComptimeTakeType(
    comptime pred: anytype,
    comptime xs: anytype,
) type {
    var newlen = 0;
    if (@typeInfo(@TypeOf(xs)) == .@"struct") {
        // types could be different -> new tuple
        var types: [xs.len]type = undefined;
        inline for (xs) |x| {
            if (!pred(x)) break;
            types[newlen] = @TypeOf(x);
            newlen += 1;
        }
        return @Tuple(types[0..newlen]);
    } else {
        for (xs) |x| {
            if (!pred(x)) break;
            newlen += 1;
        }
        return [newlen]@TypeOf(xs[0]);
    }
}

pub inline fn partition(
    comptime pred: anytype,
    xs: anytype,
    ys_true: anytype,
    ys_false: anytype,
) struct { usize, usize } {
    var ys_true_c: usize = 0;
    var ys_false_c: usize = 0;
    if (@typeInfo(@TypeOf(xs)) == .@"struct") {
        inline for (xs) |x| if (pred(x)) {
            ys_true[ys_true_c] = x;
            ys_true_c += 1;
        } else {
            ys_false[ys_false_c] = x;
            ys_false_c += 1;
        };
    } else {
        for (xs) |x| if (pred(x)) {
            ys_true[ys_true_c] = x;
            ys_true_c += 1;
        } else {
            ys_false[ys_false_c] = x;
            ys_false_c += 1;
        };
    }

    return .{ ys_true_c, ys_false_c };
}

pub inline fn partition_ret(
    comptime pred: anytype,
    xs: anytype,
    ys_true: anytype,
    ys_false: anytype,
) struct {
    []ChildType(@TypeOf(ys_true)),
    []ChildType(@TypeOf(ys_false)),
} {
    const slice_true = force_slice(ys_true);
    const slice_false = force_slice(ys_false);
    const counts = partition(pred, xs, ys_true, ys_false);
    return .{
        slice_true[0..counts[0]],
        slice_false[0..counts[1]],
    };
}

pub fn partition_new(
    alloc: std.mem.Allocator,
    comptime pred: anytype,
    xs: anytype,
) struct {
    []ChildType(@TypeOf(xs)),
    []ChildType(@TypeOf(xs)),
} {
    const T = ChildType(@TypeOf(xs));

    var ys_true = alloc.alloc(T, xs.len) catch @panic("OOM");
    var ys_false = alloc.alloc(T, xs.len) catch @panic("OOM");

    const counts = partition(pred, xs, ys_true, ys_false);

    if (alloc.resize(ys_true, counts[0])) {
        ys_true.len = counts[0];
    } else {
        ys_true = alloc.realloc(ys_true, counts[0]) catch @panic("OOM");
    }

    if (alloc.resize(ys_false, counts[1])) {
        ys_false.len = counts[1];
    } else {
        ys_false = alloc.realloc(ys_false, counts[1]) catch @panic("OOM");
    }

    return .{ ys_true, ys_false };
}

pub inline fn partition_comptimef(
    comptime pred: anytype,
    comptime xs: anytype,
) YsComptimePartitionType(pred, xs) {
    const ys_true = filter_comptimef(pred, xs);
    const ys_false = filter_comptimef(struct {
        pub fn invpred(x: anytype) bool {
            return !pred(x);
        }
    }.invpred, xs);

    return .{ ys_true, ys_false };
}

fn YsComptimePartitionType(
    comptime pred: anytype,
    comptime xs: anytype,
) type {
    return struct {
        // true type
        YsComptimeFilterType(pred, xs),
        // on-the-fly constructed false type
        YsComptimeFilterType(struct {
            pub fn invpred(x: anytype) bool {
                return !pred(x);
            }
        }.invpred, xs),
    };
}

test {
    std.testing.refAllDecls(@import("test/seq_produce.zig"));
}
