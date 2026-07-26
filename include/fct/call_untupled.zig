const std = @import("std");
// this is just a helper to turn @call... syntax with tuples into real func calls

pub fn untupled_func(comptime f: anytype) UntupledFuncReturnType(f) {
    const tuple_type = @typeInfo(@TypeOf(f)).@"fn".params[0].type orelse
        @compileError("untupled_func: first param = null");
    const tuple_ti = @typeInfo(tuple_type).@"struct";
    comptime var arg_types: [tuple_ti.fields.len]type = undefined;
    inline for (tuple_ti.fields, 0..) |field, i| {
        arg_types[i] = field.type;
    }

    const argc = arg_types.len;
    if (argc == 0) {
        return UntupledCallFuncs.func_0(f);
    }

    if (argc > 16) {
        @compileError("untupled_func: too many args, max = 16");
    }

    const decl_name = comptime blk: {
        var buf: [10]u8 = undefined;
        break :blk std.fmt.bufPrint(&buf, "func_{d}", .{argc}) catch {};
    };

    return @field(UntupledCallFuncs, decl_name)(f, arg_types);
}

pub fn UntupledFuncReturnType(comptime f: anytype) type {
    const tuple_type = @typeInfo(@TypeOf(f)).@"fn".params[0].type orelse
        @compileError("untupled_func: first param = null");
    const tuple_ti = @typeInfo(tuple_type).@"struct";
    comptime var arg_types: [tuple_ti.fields.len]type = undefined;
    inline for (tuple_ti.fields, 0..) |field, i| {
        arg_types[i] = field.type;
    }

    return @Fn(&arg_types, &@splat(.{}), FuncRetType(f), .{ .@"callconv" = .@"inline" });
}

fn FuncRetType(comptime f: anytype) type {
    const f_info = @typeInfo(@TypeOf(f)).@"fn";
    return f_info.return_type orelse
        @compileError("func_ret_type: return type is null");
}

const UntupledCallFuncs = struct {
    fn func_0(
        comptime func: anytype,
    ) fn () callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call() FuncRetType(func) {
                return @call(.always_inline, func, .{.{}});
            }
        }.call;
    }

    fn func_1(
        comptime func: anytype,
        comptime types: [1]type,
    ) fn (a: types[0]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{a}});
            }
        }.call;
    }

    fn func_2(
        comptime func: anytype,
        comptime types: [2]type,
    ) fn (a: types[0], b: types[1]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b }});
            }
        }.call;
    }

    fn func_3(
        comptime func: anytype,
        comptime types: [3]type,
    ) fn (a: types[0], b: types[1], c: types[2]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1], c: types[2]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b, c }});
            }
        }.call;
    }

    fn func_4(
        comptime func: anytype,
        comptime types: [4]type,
    ) fn (a: types[0], b: types[1], c: types[2], d: types[3]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1], c: types[2], d: types[3]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b, c, d }});
            }
        }.call;
    }

    fn func_5(
        comptime func: anytype,
        comptime types: [5]type,
    ) fn (a: types[0], b: types[1], c: types[2], d: types[3], e: types[4]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1], c: types[2], d: types[3], e: types[4]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b, c, d, e }});
            }
        }.call;
    }

    fn func_6(
        comptime func: anytype,
        comptime types: [6]type,
    ) fn (a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b, c, d, e, f }});
            }
        }.call;
    }

    fn func_7(
        comptime func: anytype,
        comptime types: [7]type,
    ) fn (a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b, c, d, e, f, g }});
            }
        }.call;
    }

    fn func_8(
        comptime func: anytype,
        comptime types: [8]type,
    ) fn (a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b, c, d, e, f, g, h }});
            }
        }.call;
    }

    fn func_9(
        comptime func: anytype,
        comptime types: [9]type,
    ) fn (a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b, c, d, e, f, g, h, i }});
            }
        }.call;
    }

    fn func_10(
        comptime func: anytype,
        comptime types: [10]type,
    ) fn (a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8], j: types[9]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8], j: types[9]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b, c, d, e, f, g, h, i, j }});
            }
        }.call;
    }

    fn func_11(
        comptime func: anytype,
        comptime types: [11]type,
    ) fn (a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8], j: types[9], k: types[10]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8], j: types[9], k: types[10]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b, c, d, e, f, g, h, i, j, k }});
            }
        }.call;
    }

    fn func_12(
        comptime func: anytype,
        comptime types: [12]type,
    ) fn (a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8], j: types[9], k: types[10], l: types[11]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8], j: types[9], k: types[10], l: types[11]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b, c, d, e, f, g, h, i, j, k, l }});
            }
        }.call;
    }

    fn func_13(
        comptime func: anytype,
        comptime types: [13]type,
    ) fn (a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8], j: types[9], k: types[10], l: types[11], m: types[12]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8], j: types[9], k: types[10], l: types[11], m: types[12]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b, c, d, e, f, g, h, i, j, k, l, m }});
            }
        }.call;
    }

    fn func_14(
        comptime func: anytype,
        comptime types: [14]type,
    ) fn (a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8], j: types[9], k: types[10], l: types[11], m: types[12], n: types[13]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8], j: types[9], k: types[10], l: types[11], m: types[12], n: types[13]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b, c, d, e, f, g, h, i, j, k, l, m, n }});
            }
        }.call;
    }

    fn func_15(
        comptime func: anytype,
        comptime types: [15]type,
    ) fn (a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8], j: types[9], k: types[10], l: types[11], m: types[12], n: types[13], o: types[14]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8], j: types[9], k: types[10], l: types[11], m: types[12], n: types[13], o: types[14]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b, c, d, e, f, g, h, i, j, k, l, m, n, o }});
            }
        }.call;
    }

    fn func_16(
        comptime func: anytype,
        comptime types: [16]type,
    ) fn (a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8], j: types[9], k: types[10], l: types[11], m: types[12], n: types[13], o: types[14], p: types[15]) callconv(.@"inline") FuncRetType(func) {
        return struct {
            pub inline fn call(a: types[0], b: types[1], c: types[2], d: types[3], e: types[4], f: types[5], g: types[6], h: types[7], i: types[8], j: types[9], k: types[10], l: types[11], m: types[12], n: types[13], o: types[14], p: types[15]) FuncRetType(func) {
                return @call(.always_inline, func, .{.{ a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p }});
            }
        }.call;
    }
};
