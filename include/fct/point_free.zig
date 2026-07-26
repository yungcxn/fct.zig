const std = @import("std");

pub inline fn compose_manual(
    comptime InputType: type,
    comptime OutputType: type,
    comptime fs: anytype,
) fn (InputType) OutputType {
    return struct {
        pub fn composed(in: InputType) OutputType {
            var acc = in;
            inline for (fs) |f| {
                acc = f(acc);
            }
            return acc;
        }
    }.composed;
}

inline fn Param0Type(comptime f: anytype) type {
    return @typeInfo(@TypeOf(f)).@"fn".params[0].type.?;
}

inline fn RetType(comptime f: anytype) type {
    return @typeInfo(@TypeOf(f)).@"fn".return_type.?;
}

pub inline fn compose_auto(
    comptime fs: anytype,
) fn (Param0Type(fs[0])) RetType(fs[fs.len - 1]) {
    return compose_manual(Param0Type(fs[0]), RetType(fs[fs.len - 1]), fs);
}

pub inline fn flow_manual(
    in: anytype,
    comptime InputType: type,
    comptime OutputType: type,
    comptime fs: anytype,
) OutputType {
    return compose_manual(InputType, OutputType, fs)(in);
}

pub inline fn flow_auto(
    in: anytype,
    comptime fs: anytype,
) void {
    return compose_auto(fs)(in);
}

// TODO and TODO festlegetn return type zu comptime static für e.g. map
pub inline fn trace() void {}

pub inline fn id(in: anytype) @TypeOf(in) {
    return in;
}

pub inline fn tap(
    in: anytype,
    comptime side_effect_f: anytype,
) void {
    side_effect_f(in);
    return in;
}

pub inline fn field(
    in: anytype,
    comptime f: std.meta.FieldEnum(@TypeOf(in)),
) @TypeOf(@field(in, @tagName(f))) {
    return @field(in, @tagName(f));
}

test {
    std.testing.refAllDecls(@import("test/point_free.zig"));
}
