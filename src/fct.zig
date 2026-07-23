const std = @import("std");
const seq_produce = @import("fct/seq_produce.zig");
const sval_produce = @import("fct/sval_produce.zig");
const muldseq_produce = @import("fct/muldseq_produce.zig");

pub const map = seq_produce.map;
pub const filter = seq_produce.filter;
pub const take = seq_produce.take;
pub const partition = seq_produce.partition;
pub const map_comptimef = seq_produce.map_comptimef;
pub const filter_comptimef = seq_produce.filter_comptimef;
pub const take_comptimef = seq_produce.take_comptimef;
pub const partition_comptimef = seq_produce.partition_comptimef;

pub const zip = muldseq_produce.zip;
pub const flat_map = muldseq_produce.flat_map;
pub const zip_comptimef = muldseq_produce.zip_comptimef;
pub const flat_map_comptimef = muldseq_produce.flat_map_comptimef;

pub const reduce = sval_produce.reduce;
pub const any = sval_produce.any;
pub const all = sval_produce.all;
pub const find = sval_produce.find;
pub const find_comptimef = sval_produce.find_comptimef;
pub const reduce_comptimef = sval_produce.reduce_comptimef;

// helpers
pub const YsMapType = seq_produce.YsMapType;
pub const YsFlatMapType = muldseq_produce.YsFlatMapType;

pub fn bind(
    comptime f: anytype,
    comptime argi: comptime_int,
    comptime argval: anytype,
) type {
    // a f decl does not have the argument names
    //   available, therefore we need indx+val
    const f_info = @typeInfo(@TypeOf(f)).@"fn";
    comptime var old_argtypes: [f_info.params.len]type = undefined;
    comptime var new_argtypes: [f_info.params.len - 1]type = undefined;
    inline for (f_info.params, 0..) |param, i| {
        const pt = param.type orelse
            @compileError("bind: param type is null");

        if (i < argi) {
            new_argtypes[i] = pt;
        } else {
            new_argtypes[i - 1] = pt;
        }
        old_argtypes[i] = pt;
    }

    const OldArgsTuple = @Tuple(&old_argtypes);
    const NewArgsTuple = @Tuple(&new_argtypes);

    return struct {
        const argi_ = argi;
        const argval_ = argval;

        const OldArgsTuple_ = OldArgsTuple;
        const NewArgsTuple_ = NewArgsTuple;
        const f_ = f;
        const ret_type = f_info.return_type orelse
            @compileError("bind: return type is null");

        pub fn call(args: NewArgsTuple_) ret_type {
            var old_args: OldArgsTuple_ = undefined;
            inline for (args, 0..) |arg, i| {
                if (i < argi_) {
                    old_args[i] = arg;
                } else {
                    old_args[i + 1] = arg;
                }
            }

            old_args[argi_] = argval_;

            return @call(.auto, f_, old_args);
        }
    };
}

test {
    std.testing.refAllDecls(@This());
    _ = .{
        sval_produce,
        seq_produce,
        muldseq_produce,
    };
}

test "bind" {
    const f = struct {
        pub fn f(a: i32, b: i32, c: i32) i32 {
            return a + b + c;
        }
    }.f;

    const bound_f = bind(f, 1, 2);

    try std.testing.expectEqual(15, bound_f.call(.{ 3, 10 }));
}
