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

fn ChildType(comptime T: type) type {
    switch (@typeInfo(T)) {
        .@"struct" => |info| return info.fields[0].type,
        .array => |info| return info.child,
        .vector => |info| return info.child,
        .pointer => |info| switch (info.size) {
            .one => switch (@typeInfo(info.child)) {
                .array => |array_info| return array_info.child,
                .vector => |vector_info| return vector_info.child,
                else => {},
            },
            .many, .c, .slice => return info.child,
        },
        else => {},
    }
    @compileError("Unsupported: '" ++ @typeName(T) ++ "'");
}

pub inline fn zip_ret(
    as: anytype,
    bs: anytype,
    ab_s: anytype,
) @TypeOf(ab_s) {
    zip(as, bs, ab_s);
    return ab_s;
}

pub inline fn zip_new(
    alloc: std.mem.Allocator,
    as: anytype,
    bs: anytype,
) []struct { ChildType(@TypeOf(as)), ChildType(@TypeOf(bs)) } {
    const Pair = struct { ChildType(@TypeOf(as)), ChildType(@TypeOf(bs)) };
    const ab_s = alloc.alloc(Pair, as.len) catch @panic("OOM");
    zip(as, bs, ab_s);
    return ab_s;
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

pub inline fn flat_map_ret(
    xs: anytype,
    f: anytype,
    ys: anytype,
) @TypeOf(ys) {
    flat_map(xs, f, ys);
    return ys;
}

pub inline fn flat_map_new(
    alloc: std.mem.Allocator,
    xs: anytype,
    f: anytype,
) *YsFlatMapType(f, comptime_len(@TypeOf(xs)) orelse xs.len) {
    const len = comptime_len(@TypeOf(xs)) orelse xs.len;
    const ys = alloc.create(YsFlatMapType(f, len)) catch @panic("OOM");
    flat_map(xs, f, ys);
    return ys;
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

test {
    std.testing.refAllDecls(@import("test/muldseq_produce.zig"));
}
