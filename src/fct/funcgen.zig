const std = @import("std");

// a f decl does not have the argument names available, therefore we need index&val
pub fn bind(
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
        const all_args = old_argtypes;
        const reduced_args = new_argtypes;
        const AllArgsTuple = @Tuple(&all_args);
        const ReducedArgsTuple = @Tuple(&reduced_args);

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

    return UntupledFunc(Callable.call, &new_argtypes);
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

fn UntupledFunc(comptime f: anytype, comptime arg_types: anytype) UntupledFuncReturnType(f, arg_types) {
    const argc = arg_types.len;
    if (argc == 0) {
        return UntupledCallFuncs.func_0(f);
    }

    const decl_name = comptime blk: {
        var buf: [10]u8 = undefined;
        break :blk std.fmt.bufPrint(&buf, "func_{d}", .{argc}) catch {};
    };

    return @field(UntupledCallFuncs, decl_name)(f, arg_types.*);
}

fn UntupledFuncReturnType(comptime f: anytype, comptime arg_types: []type) type {
    return @Fn(arg_types, &@splat(.{}), FuncRetType(f), .{ .@"callconv" = .@"inline" });
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

test "bind: 1-param function, bind the only arg (-> func_0)" {
    const f = struct {
        fn f(x: i32) i32 {
            return x * 2;
        }
    }.f;
    const g = bind(f, 0, 5);
    try std.testing.expectEqual(10, g());
}

test "bind: 3-param function, bind first arg (-> func_2)" {
    const f = struct {
        fn f(a: i32, b: i32, c: i32) i32 {
            return a + b + c;
        }
    }.f;
    const g = bind(f, 0, 10);
    try std.testing.expectEqual(18, g(3, 5));
}

test "bind: 3-param function, bind middle arg" {
    const f = struct {
        fn f(a: i32, b: i32, c: i32) i32 {
            return a * b + c;
        }
    }.f;
    const g = bind(f, 1, 7);
    try std.testing.expectEqual(4 * 7 + 9, g(4, 9));
}

test "bind: 3-param function, bind last arg" {
    const f = struct {
        fn f(a: i32, b: i32, c: i32) i32 {
            return a + b - c;
        }
    }.f;
    const g = bind(f, 2, 2);
    try std.testing.expectEqual(10 + 3 - 2, g(10, 3));
}

test "bind: 4-param function, bind each index" {
    const f = struct {
        fn f(a: i32, b: i32, c: i32, d: i32) i32 {
            return a + b + c + d;
        }
    }.f;

    const g0 = bind(f, 0, 1);
    const g1 = bind(f, 1, 2);
    const g2 = bind(f, 2, 3);
    const g3 = bind(f, 3, 4);

    try std.testing.expectEqual(1 + 2 + 3 + 4, g0(2, 3, 4));
    try std.testing.expectEqual(1 + 2 + 3 + 4, g1(1, 3, 4));
    try std.testing.expectEqual(1 + 2 + 3 + 4, g2(1, 2, 4));
    try std.testing.expectEqual(1 + 2 + 3 + 4, g3(1, 2, 3));
}

test "bind: 5-param function, bind each index" {
    const f = struct {
        fn f(a: i32, b: i32, c: i32, d: i32, e: i32) i32 {
            return a + b + c + d + e;
        }
    }.f;

    inline for (0..5) |i| {
        const g = bind(f, i, 100);
        // the reduced function always expects arguments in original order,
        // skipping the bound index. So we pass 1,2,3,4 in that order.
        const args = [_]i32{ 1, 2, 3, 4 };
        const expected: i32 = 100 + 1 + 2 + 3 + 4; // 110
        try std.testing.expectEqual(expected, g(args[0], args[1], args[2], args[3]));
    }
}

test "bind: 6-param function, bind second arg" {
    const f = struct {
        fn f(a: i32, b: i32, c: i32, d: i32, e: i32, f_val: i32) i32 {
            return a + b + c + d + e + f_val;
        }
    }.f;
    const g = bind(f, 1, 50);
    try std.testing.expectEqual(50 + 1 + 2 + 3 + 4 + 5, g(1, 2, 3, 4, 5));
}

test "bind: 7-param function, bind first and last" {
    const f = struct {
        fn f(a: i32, b: i32, c: i32, d: i32, e: i32, f_val: i32, g_val: i32) i32 {
            return a + b + c + d + e + f_val + g_val;
        }
    }.f;
    const g0 = bind(f, 0, 10);
    const g_last = bind(f, 6, 70);
    try std.testing.expectEqual(10 + 2 + 3 + 4 + 5 + 6 + 70, g0(2, 3, 4, 5, 6, 70));
    try std.testing.expectEqual(10 + 2 + 3 + 4 + 5 + 6 + 70, g_last(10, 2, 3, 4, 5, 6));
}

test "bind: 8-param function, bind middle index" {
    const f = struct {
        fn f(a: i32, b: i32, c: i32, d: i32, e: i32, f_val: i32, g_val: i32, h: i32) i32 {
            return a + b + c + d + e + f_val + g_val + h;
        }
    }.f;
    const g = bind(f, 4, 500);
    try std.testing.expectEqual(1 + 2 + 3 + 4 + 500 + 6 + 7 + 8, g(1, 2, 3, 4, 6, 7, 8));
}

test "bind: 9-param function, bind index 4" {
    const f = struct {
        fn f(a: i32, b: i32, c: i32, d: i32, e: i32, f_val: i32, g_val: i32, h: i32, i_val: i32) i32 {
            return a + b + c + d + e + f_val + g_val + h + i_val;
        }
    }.f;
    const g = bind(f, 4, 555);
    try std.testing.expectEqual(1 + 2 + 3 + 4 + 555 + 6 + 7 + 8 + 9, g(1, 2, 3, 4, 6, 7, 8, 9));
}

test "bind: 10-param function, bind index 5 and 9" {
    const f = struct {
        fn f(a: i32, b: i32, c: i32, d: i32, e: i32, f_val: i32, g_val: i32, h: i32, i_val: i32, j: i32) i32 {
            return a + b + c + d + e + f_val + g_val + h + i_val + j;
        }
    }.f;
    const g5 = bind(f, 5, 600);
    const g9 = bind(f, 9, 900);
    try std.testing.expectEqual(1 + 2 + 3 + 4 + 5 + 600 + 7 + 8 + 9 + 900, g5(1, 2, 3, 4, 5, 7, 8, 9, 900));
    try std.testing.expectEqual(1 + 2 + 3 + 4 + 5 + 600 + 7 + 8 + 9 + 900, g9(1, 2, 3, 4, 5, 600, 7, 8, 9));
}

test "bind: 12-param function, bind index 6" {
    const f = struct {
        fn f(
            a: i32,
            b: i32,
            c: i32,
            d: i32,
            e: i32,
            f_val: i32,
            g_val: i32,
            h: i32,
            i_val: i32,
            j: i32,
            k: i32,
            l: i32,
        ) i32 {
            return a + b + c + d + e + f_val + g_val + h + i_val + j + k + l;
        }
    }.f;
    const g = bind(f, 6, 777);
    try std.testing.expectEqual(
        1 + 2 + 3 + 4 + 5 + 6 + 777 + 8 + 9 + 10 + 11 + 12,
        g(1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12),
    );
}

test "bind: 16-param function, bind last index" {
    const f = struct {
        fn f(
            a: i32,
            b: i32,
            c: i32,
            d: i32,
            e: i32,
            f_val: i32,
            g_val: i32,
            h: i32,
            i_val: i32,
            j: i32,
            k: i32,
            l: i32,
            m: i32,
            n: i32,
            o: i32,
            p: i32,
        ) i32 {
            return a + b + c + d + e + f_val + g_val + h + i_val + j + k + l + m + n + o + p;
        }
    }.f;
    const g = bind(f, 15, 1600);
    try std.testing.expectEqual(
        1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + 11 + 12 + 13 + 14 + 15 + 1600,
        g(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15),
    );
}

test "bind: void return with side effect via pointer" {
    const f = struct {
        fn f(a: i32, b: i32, out: *i32) void {
            out.* = a + b;
        }
    }.f;
    var result: i32 = 0;
    const g = bind(f, 0, 10);
    g(5, &result);
    try std.testing.expectEqual(15, result);
}

test "bind: bool parameter" {
    const f = struct {
        fn f(flag: bool, x: i32) i32 {
            return if (flag) x else -x;
        }
    }.f;
    const g_true = bind(f, 0, true);
    const g_false = bind(f, 0, false);
    try std.testing.expectEqual(42, g_true(42));
    try std.testing.expectEqual(-42, g_false(42));
}

test "bind: f64 parameter" {
    const f = struct {
        fn f(a: f64, b: f64) f64 {
            return a * b;
        }
    }.f;
    const g = bind(f, 1, 2.5);
    try std.testing.expectEqual(4.0 * 2.5, g(4.0));
}

test "bind: optional parameter, bind null" {
    const f = struct {
        fn f(opt: ?i32) i32 {
            return opt orelse -1;
        }
    }.f;
    const g = bind(f, 0, null);
    try std.testing.expectEqual(-1, g());
}

test "bind: optional parameter, bind non-null" {
    const f = struct {
        fn f(opt: ?i32) i32 {
            return opt orelse -1;
        }
    }.f;
    const g = bind(f, 0, @as(?i32, 7));
    try std.testing.expectEqual(7, g());
}

const comptime_global_int: i32 = 123;

test "bind: pointer parameter (comptime-known address)" {
    const f = struct {
        fn f(ptr: *const i32, mult: i32) i32 {
            return ptr.* * mult;
        }
    }.f;
    const g = bind(f, 0, &comptime_global_int);
    try std.testing.expectEqual(comptime_global_int * 3, g(3));
}

test "bind: array parameter" {
    const f = struct {
        fn f(arr: [3]i32) i32 {
            return arr[0] + arr[1] + arr[2];
        }
    }.f;
    const g = bind(f, 0, [3]i32{ 1, 2, 3 });
    try std.testing.expectEqual(6, g());
}

test "bind: slice parameter" {
    const f = struct {
        fn f(s: []const u8) usize {
            return s.len;
        }
    }.f;
    const g = bind(f, 0, "hello");
    try std.testing.expectEqual(5, g());
}

test "bind: error union return" {
    const f = struct {
        fn f(x: i32) !i32 {
            if (x < 0) return error.Negative;
            return x * 2;
        }
    }.f;
    const g = bind(f, 0, 21);
    try std.testing.expectEqual(42, try g());
}

test "bind: chained bind down to 0 args" {
    const f = struct {
        fn f(a: i32, b: i32, c: i32) i32 {
            return a + b + c;
        }
    }.f;
    const g = bind(f, 0, 1);
    const h = bind(g, 0, 2);
    const i = bind(h, 0, 3);
    try std.testing.expectEqual(6, i());
}

test "bind: chained bind, different order" {
    const f = struct {
        fn f(a: i32, b: i32, c: i32, d: i32) i32 {
            return a + b + c + d;
        }
    }.f;
    const g = bind(f, 2, 30); // bind c
    const h = bind(g, 1, 20); // now b (original index 1)
    // remaining args: a (idx0) and d (idx3, now idx2)
    try std.testing.expectEqual(10 + 20 + 30 + 40, h(10, 40));
}

test "bind: binding with comptime expression value" {
    const f = struct {
        fn f(a: i32, b: i32) i32 {
            return a + b;
        }
    }.f;
    const comptime_val = 3 + 4;
    const g = bind(f, 0, comptime_val);
    try std.testing.expectEqual(7 + 10, g(10));
}

test "bind: type of bound function matches expected signature" {
    const f = struct {
        fn f(a: i32, b: f64) bool {
            return @as(f64, @floatFromInt(a)) > b;
        }
    }.f;
    const g = bind(f, 1, 3.14);
    try std.testing.expectEqual(true, g(5));
}

test "bind: function with comptime param, bind type" {
    const f = struct {
        fn f(comptime T: type) type {
            return T;
        }
    }.f;
    const g = bind(f, 0, i32);
    comptime {
        if (g() != i32) @compileError("expected i32");
    }
}

test "bind: passed as callback" {
    const f = struct {
        fn f(x: i32, y: i32) i32 {
            return x * y;
        }
    }.f;
    const g = bind(f, 0, 7);

    const apply = struct {
        fn apply(func: fn (i32) callconv(.@"inline") i32, val: i32) i32 {
            return func(val);
        }
    }.apply;

    try std.testing.expectEqual(7 * 9, apply(g, 9));
}

test "bind: very large index (boundary check, should compile)" {
    const f = struct {
        fn f(a0: i32, a1: i32, a2: i32, a3: i32, a4: i32, a5: i32, a6: i32, a7: i32, a8: i32, a9: i32, a10: i32, a11: i32, a12: i32, a13: i32, a14: i32, a15: i32) i32 {
            _ = .{ a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14 };
            return a0 + a15;
        }
    }.f;

    const g_first = bind(f, 0, 100);
    const g_last = bind(f, 15, 200);

    try std.testing.expectEqual(100 + 200, g_first(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 200));

    try std.testing.expectEqual(100 + 200, g_last(100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
}

test "bind: u8 parameter" {
    const f = struct {
        fn f(a: u8, b: u8) u8 {
            return a +% b;
        }
    }.f;
    const g = bind(f, 0, 200);
    try std.testing.expectEqual(@as(u8, 200 +% 55), g(55));
}

test "bind: i64 parameter" {
    const f = struct {
        fn f(x: i64) i64 {
            return x * 2;
        }
    }.f;
    const g = bind(f, 0, -123456789012);
    try std.testing.expectEqual(@as(i64, -246913578024), g());
}

test "bind: f16 parameter" {
    const f = struct {
        fn f(x: f16) f16 {
            return x * 2;
        }
    }.f;
    const g = bind(f, 0, @as(f16, 1.5));
    try std.testing.expectEqual(@as(f16, 3.0), g());
}

test "bind: f128 parameter" {
    const f = struct {
        fn f(x: f128) f128 {
            return x * 3;
        }
    }.f;
    const g = bind(f, 0, @as(f128, 2.5));
    try std.testing.expectEqual(@as(f128, 7.5), g());
}

test "bind: bool parameter with false" {
    const f = struct {
        fn f(flag: bool, a: i32) i32 {
            return if (flag) a else -a;
        }
    }.f;
    const g = bind(f, 0, false);
    try std.testing.expectEqual(-10, g(10));
}

test "bind: void return type" {
    var side: i32 = 0;
    const f = struct {
        fn f(x: i32, out: *i32) void {
            out.* = x;
        }
    }.f;
    const g = bind(f, 0, 42);
    g(&side);
    try std.testing.expectEqual(42, side);
}

test "bind: noreturn function" {
    const f = struct {
        fn f(msg: []const u8) noreturn {
            @panic(msg);
        }
    }.f;
    const g = bind(f, 0, "test panic");
    try std.testing.expect(@typeInfo(@TypeOf(g)).@"fn".return_type.? == noreturn);
}

test "bind: enum parameter" {
    const Color = enum { red, green, blue };
    const f = struct {
        fn f(c: Color) i32 {
            return @intFromEnum(c);
        }
    }.f;
    const g = bind(f, 0, Color.green);
    try std.testing.expectEqual(1, g());
}

test "bind: non-exhaustive enum" {
    const Fruit = enum(u8) { apple = 1, banana, _ };
    const f = struct {
        fn f(fruit: Fruit) u8 {
            return @intFromEnum(fruit);
        }
    }.f;
    const g = bind(f, 0, @as(Fruit, @enumFromInt(2)));
    try std.testing.expectEqual(2, g());
}

test "bind: packed struct parameter" {
    const Packed = packed struct { x: u4, y: u4 };
    const f = struct {
        fn f(p: Packed) u8 {
            return @as(u8, p.x) * 16 + p.y;
        }
    }.f;
    const g = bind(f, 0, Packed{ .x = 3, .y = 14 });
    try std.testing.expectEqual(3 * 16 + 14, g());
}

test "bind: extern struct parameter" {
    const Extern = extern struct { a: i32, b: f64 };
    const f = struct {
        fn f(e: Extern) f64 {
            return @as(f64, @floatFromInt(e.a)) + e.b;
        }
    }.f;
    const g = bind(f, 0, Extern{ .a = 10, .b = 3.14 });
    try std.testing.expectEqual(13.14, g());
}

test "bind: tagged union parameter (using union(enum))" {
    const Tagged = union(enum) { int: i32, float: f64 };
    const f = struct {
        fn f(u: Tagged) f64 {
            return switch (u) {
                .int => @floatFromInt(u.int),
                .float => u.float,
            };
        }
    }.f;
    const g_int = bind(f, 0, Tagged{ .int = 7 });
    const g_float = bind(f, 0, Tagged{ .float = 2.718 });
    try std.testing.expectEqual(7.0, g_int());
    try std.testing.expectEqual(2.718, g_float());
}

test "bind: union(enum) parameter" {
    const Tagged = union(enum) { num: i32, text: []const u8 };
    const f = struct {
        fn f(t: Tagged) i32 {
            return switch (t) {
                .num => t.num,
                .text => @as(i32, @intCast(t.text.len)),
            };
        }
    }.f;
    const g = bind(f, 0, Tagged{ .text = "hello" });
    try std.testing.expectEqual(5, g());
}

test "bind: error union parameter" {
    const f = struct {
        fn f(maybe: anyerror!i32) i32 {
            return maybe catch -1;
        }
    }.f;
    const g_ok = bind(f, 0, @as(anyerror!i32, 42));
    const g_err = bind(f, 0, @as(anyerror!i32, error.OutOfMemory));
    try std.testing.expectEqual(42, g_ok());
    try std.testing.expectEqual(-1, g_err());
}

test "bind: anyerror parameter" {
    const f = struct {
        fn f(e: anyerror) bool {
            return e == error.OutOfMemory;
        }
    }.f;
    const g_true = bind(f, 0, error.OutOfMemory);
    const g_false = bind(f, 0, error.FileNotFound);
    try std.testing.expectEqual(true, g_true());
    try std.testing.expectEqual(false, g_false());
}

const comptime_int_val: i32 = 5;
test "bind: optional pointer parameter" {
    const f = struct {
        fn f(ptr: ?*const i32) i32 {
            return if (ptr) |p| p.* else 0;
        }
    }.f;
    const g_null = bind(f, 0, @as(?*const i32, null));
    const g_val = bind(f, 0, @as(?*const i32, &comptime_int_val));
    try std.testing.expectEqual(0, g_null());
    try std.testing.expectEqual(5, g_val());
}

test "bind: sentinel slice parameter" {
    const f = struct {
        fn f(s: [:0]const u8) usize {
            return s.len;
        }
    }.f;
    const g = bind(f, 0, "ziggy");
    try std.testing.expectEqual(5, g());
}

test "bind: many indirection (pointer to pointer to const)" {
    const value: i32 = 99;
    const ptr: *const i32 = &value;
    const ptr2: *const *const i32 = &ptr;
    const f = struct {
        fn f(p: *const *const i32) i32 {
            return p.*.*;
        }
    }.f;
    const g = bind(f, 0, ptr2);
    try std.testing.expectEqual(99, g());
}

test "bind: vector parameter" {
    const f = struct {
        fn f(v: @Vector(4, i32)) i32 {
            return v[0] + v[1] + v[2] + v[3];
        }
    }.f;
    const g = bind(f, 0, @Vector(4, i32){ 1, 2, 3, 4 });
    try std.testing.expectEqual(10, g());
}

test "bind: function pointer parameter" {
    const f = struct {
        fn f(callback: *const fn (i32) i32, x: i32) i32 {
            return callback(x);
        }
    }.f;
    const double = struct {
        fn double(x: i32) i32 {
            return x * 2;
        }
    }.double;
    const g = bind(f, 0, &double);
    try std.testing.expectEqual(84, g(42));
}

const Inner = struct { val: i32 };
test "bind: nested struct (named)" {
    const f = struct {
        fn f(inner: Inner, outer: i32) i32 {
            return inner.val * outer;
        }
    }.f;
    const g = bind(f, 0, Inner{ .val = 10 });
    try std.testing.expectEqual(50, g(5));
}

test "bind: array of arrays" {
    const f = struct {
        fn f(arr: [2][3]i32) i32 {
            return arr[0][0] + arr[1][2];
        }
    }.f;
    const g = bind(f, 0, [2][3]i32{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
    });
    try std.testing.expectEqual(1 + 6, g());
}

test "bind: slice of slices" {
    const f = struct {
        fn f(slices: []const []const u8) usize {
            var total: usize = 0;
            for (slices) |s| total += s.len;
            return total;
        }
    }.f;
    const s1: []const u8 = "ab";
    const s2: []const u8 = "cde";
    const slices: []const []const u8 = &[_][]const u8{ s1, s2 };
    const g = bind(f, 0, slices);
    try std.testing.expectEqual(5, g());
}

test "bind: optional slice" {
    const f = struct {
        fn f(opt: ?[]const u8) usize {
            return if (opt) |s| s.len else 0;
        }
    }.f;
    const g_null = bind(f, 0, @as(?[]const u8, null));
    const g_some = bind(f, 0, @as(?[]const u8, "hello"));
    try std.testing.expectEqual(0, g_null());
    try std.testing.expectEqual(5, g_some());
}

test "bind: null-terminated pointer" {
    const f = struct {
        fn f(ptr: [*:0]const u8) usize {
            return std.mem.len(ptr);
        }
    }.f;
    const g = bind(f, 0, @as([*:0]const u8, "zig"));
    try std.testing.expectEqual(3, g());
}

const opaque_val: i32 = 123;
test "bind: anyopaque pointer" {
    const f = struct {
        fn f(ptr: *const anyopaque) i32 {
            const p: *const i32 = @ptrCast(@alignCast(ptr));
            return p.*;
        }
    }.f;
    const g = bind(f, 0, @as(*const anyopaque, &opaque_val));
    try std.testing.expectEqual(123, g());
}

test "bind: chained binds with mixed types" {
    const f = struct {
        fn f(a: i32, b: f64, c: bool, d: []const u8) i32 {
            _ = b;
            return a + @as(i32, @intCast(d.len)) + @intFromBool(c);
        }
    }.f;
    const g1 = bind(f, 1, @as(f64, 3.14));
    const g2 = bind(g1, 0, 10);
    const g3 = bind(g2, 1, "test");
    try std.testing.expectEqual(10 + 4 + 1, g3(true));
}
