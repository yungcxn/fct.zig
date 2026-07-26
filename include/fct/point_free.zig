const std = @import("std");

pub inline fn compose_manual(
    comptime InputType: type,
    comptime OutputType: type,
    comptime f: anytype,
    comptime g: anytype,
) fn (InputType) OutputType {
    return struct {
        pub inline fn composed(in: InputType) OutputType {
            return g(f(in));
        }
    }.composed;
}

pub inline fn compose_auto(
    comptime f: anytype,
    comptime g: anytype,
) fn (Param0Type(@TypeOf(f))) RetType(@TypeOf(g)) {
    return compose_manual(Param0Type(@TypeOf(f)), RetType(@TypeOf(g)), g, f);
}

pub inline fn compose_n_manual(
    comptime input_types: []type,
    comptime output_types: []type,
    comptime fs: anytype,
) fn (input_types[0]) output_types[output_types.len - 1] {
    const compose_step = struct {
        pub inline fn step(
            comptime current_f: anytype,
            comptime fs_queue: anytype,
            comptime input_types_queue: []type,
            comptime output_types_queue: []type,
        ) fn (input_types_queue[0]) output_types_queue[0] {
            if (fs_queue.len == 0) return current_f;
            return step(
                compose_manual(input_types_queue[0], output_types_queue[0], fs_queue[0], current_f),
                fs_queue[1..],
                input_types_queue[1..],
                output_types_queue[1..],
            );
        }
    }.step;

    return compose_step(fs[0], fs[1..], input_types[1..], output_types[1..]);
}

pub inline fn compose_n_auto(
    comptime fs: anytype,
) fn (Param0Type(fs[0])) RetType(fs[fs.len - 1]) {
    const compose_step = struct {
        pub inline fn step(
            comptime current_f: anytype,
            comptime fs_queue: anytype,
        ) fn (Param0Type(@TypeOf(current_f))) RetType(@TypeOf(fs_queue[0])) {
            if (fs_queue.len == 0) return current_f;
            return step(compose_auto(current_f, fs_queue[0]), fs_queue[1..]);
        }
    }.step;

    return compose_step(fs[0], fs[1..]);
}

// TODO
pub const FunctionalTrace = struct {};

// fully comptime func
pub fn traced_functions(comptime fs: anytype) void {
    // return fs but with each function wrapped in a
    _ = fs;
}

pub inline fn id(in: anytype) @TypeOf(in) {
    return in;
}

pub inline fn tap(
    in: anytype,
    comptime side_effect_f: anytype,
) @TypeOf(in) {
    side_effect_f(in);
    return in;
}

pub inline fn field(
    in: anytype,
    comptime f: std.meta.FieldEnum(@TypeOf(in)),
) @TypeOf(@field(in, @tagName(f))) {
    return @field(in, @tagName(f));
}

pub inline fn fix_rettype(
    comptime rettype: type,
    comptime f: anytype,
) fn (Param0Type(f)) rettype {
    return struct {
        pub inline fn fixed(in: Param0Type(f)) rettype {
            return f(in);
        }
    }.fixed;
}

inline fn Param0Type(comptime FType: anytype) type {
    return @typeInfo(@TypeOf(FType)).@"fn".params[0].type.?;
}

inline fn RetType(comptime FType: anytype) type {
    return @typeInfo(@TypeOf(FType)).@"fn".return_type.?;
}

test {
    std.testing.refAllDecls(@import("test/point_free.zig"));
}
