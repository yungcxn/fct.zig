const std = @import("std");
const untupled_func = @import("call_untupled.zig").untupled_func;

pub fn bind0(comptime f: anytype, comptime argval: anytype) ReducedFuncType(f, 0) {
    return bind_i(f, 0, argval);
}

pub fn bind(
    comptime f: anytype,
    comptime arg_i_val_tup: anytype,
) ReducedFuncType(f, arg_i_val_tup[0][0]) {
    const i, const val = arg_i_val_tup[0];
    const newfunc = bind_i(f, i, val);
    if (arg_i_val_tup.len == 1) {
        return newfunc;
    } else {
        const rest = arg_i_val_tup[1..];
        inline for (rest) |*r| {
            r.*[0] -= 1; // reduced index
            if (r.*[0] < 0) @compileError("bind: invalid index in arg_i_val_tup");
        }
        return bind(newfunc, rest);
    }
}

// a f decl does not have the argument names available, therefore we need index&val
pub fn bind_i(
    comptime f: anytype,
    comptime argi: comptime_int,
    comptime argval: anytype,
) ReducedFuncType(f, argi) {
    const f_info = @typeInfo(@TypeOf(f)).@"fn";
    const ret_type = f_info.return_type orelse @compileError("bind: return type is null");
    comptime var old_argtypes: [f_info.params.len]type = undefined;
    comptime var new_argtypes: [f_info.params.len - 1]type = undefined;
    var new_i: usize = 0;

    inline for (f_info.params, 0..) |param, i| {
        const pt = param.type orelse @compileError("bind: param type is null");

        old_argtypes[i] = pt;

        if (i == argi) continue;

        new_argtypes[new_i] = pt;
        new_i += 1;
    }

    const Callable = struct {
        const all_argtypes = old_argtypes;
        const reduced_argtypes = new_argtypes;
        const AllArgsTuple = @Tuple(&all_argtypes);
        const ReducedArgsTuple = @Tuple(&reduced_argtypes);

        pub fn call(r_args: ReducedArgsTuple) ret_type {
            var args: AllArgsTuple = undefined;

            comptime var ri: usize = 0;
            inline for (0..args.len) |ai| {
                if (ai == argi) {
                    args[ai] = argval;
                } else {
                    args[ai] = r_args[ri];
                    ri += 1;
                }
            }

            return @call(.always_inline, f, args);
        }
    };

    return untupled_func(Callable.call);
}

fn ReducedFuncType(comptime f: anytype, comptime argi: comptime_int) type {
    const f_info = @typeInfo(@TypeOf(f)).@"fn";
    comptime var new_argtypes: [f_info.params.len - 1]type = undefined;
    inline for (f_info.params, 0..) |param, i| {
        const pt = param.type orelse @compileError("bind: param type is null");
        if (i < argi) {
            new_argtypes[i] = pt;
        } else if (i > argi) {
            new_argtypes[i - 1] = pt;
        }
    }

    return @Fn(&new_argtypes, &@splat(.{}), f_info.return_type orelse
        @compileError("bind: return type is null"), .{ .@"callconv" = .@"inline" });
}

pub fn curry(comptime f: anytype) CurryRetType(f, param_types(f), 0) {
    return curry_step(f, param_types(f), 0, .{});
}

fn curry_step(
    comptime func: anytype,
    comptime types: anytype,
    comptime idx: usize,
    args: anytype,
) CurryRetType(func, types, idx) {
    return struct {
        pub inline fn call(a: types[idx]) CurryRetType(func, types, idx + 1) {
            const next_args = args ++ .{a};
            if (idx + 1 == types.len) {
                return @call(.auto, func, next_args);
            } else {
                return curry_step(func, types, idx + 1, next_args);
            }
        }
    }.call;
}

fn CurryRetType(comptime func: anytype, comptime types: anytype, comptime idx: usize) type {
    if (idx == types.len) return FuncRetType(func);
    return CurryRetSingle(types[idx], CurryRetType(func, types, idx + 1));
}

fn CurryRetSingle(comptime lasttype: type, comptime ret: anytype) type {
    return @Fn(&[_]type{lasttype}, &@splat(.{}), ret, .{ .@"callconv" = .@"inline" });
}

fn param_types(comptime f: anytype) [@typeInfo(@TypeOf(f)).@"fn".params.len]type {
    const params = @typeInfo(@TypeOf(f)).@"fn".params;
    if (params.len == 0) {
        @compileError("Why would you curry zero-arg func?!");
    }
    comptime var types: [params.len]type = undefined;
    inline for (params, 0..) |param, i| {
        if (param.type == null) @compileError("CurriedFunc: param type is null");
        types[i] = param.type.?;
    }
    return types;
}

fn FuncRetType(comptime f: anytype) type {
    const f_info = @typeInfo(@TypeOf(f)).@"fn";
    return f_info.return_type orelse
        @compileError("func_ret_type: return type is null");
}

test {
    std.testing.refAllDecls(@import("test/func_manip.zig"));
}
