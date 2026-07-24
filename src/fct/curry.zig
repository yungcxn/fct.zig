const std = @import("std");

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

test "curry: basic currying with 2 parameters" {
    const f = struct {
        fn f(a: i32, b: i32, c: i32, d: i32) i32 {
            return a + b + c + d;
        }
    }.f;
    try std.testing.expectEqual(10, curry(f)(1)(2)(3)(4));
}

test "curry: complex parameter types + last arg is runtime" {
    const f = struct {
        fn f(a: []const u8, b: ?i32, c: *const f64) f64 {
            const b_val = b orelse 0;
            return @as(f64, b_val) + @as(f64, @floatFromInt(a.len)) + c.*;
        }
    }.f;
    var c_val: f64 = 2.5;
    c_val = 2.4;
    try std.testing.expectEqual(4.4, curry(f)("hi")(@as(?i32, null))(&c_val));
}
