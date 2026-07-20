const std = @import("std");

const fct = @import("fct.zig");

// 1.1

fn add_u3(a: u32, b: u32, c: u32) u32 {
    return a + b + c;
}

fn sub_u3(a: u32, b: u32, c: u32) u32 {
    return a - b - c;
}

const functable = [_]fn (u32, u32, u32) u32{
    add_u3,
    sub_u3,
};

// 1.2

fn get_add_u3() fn (u32, u32, u32) u32 {
    return add_u3;
}

fn apply_u3(f: fn (u32, u32, u32) u32, a: u32, b: u32, c: u32) u32 {
    return f(a, b, c);
}

fn generic_apply_3(f: anytype, a: anytype, b: anytype, c: anytype) @TypeOf(f(a, b, c)) {
    return f(a, b, c);
}

// 1.3

fn alternative_add_u3(a: u32, b: u32, c: u32) u32 {
    return struct {
        pub fn inner(x: u32, y: u32, z: u32) u32 {
            // a,b,c are not accessible here
            return x + y + z;
        }
    }.inner(a, b, c);
}

pub fn main(init: std.process.Init) void {
    const io = init.io;
    const alloc = init.gpa;

    _ = .{ io, alloc };

    { // Demo 1.1: Functions as first-class citizens

        // Alias + calling through it
        const f0 = add_u3;
        const result1 = f0(1, 2, 3);
        std.debug.assert(result1 == 6); // OK

        // Array of funcs
        const result2 = functable[1](10, 3, 2);
        std.debug.assert(result2 == 5); // OK

        // Type definition of a function
        const OpU3Type = fn (u32, u32, u32) u32;
        std.debug.assert(@TypeOf(add_u3) == OpU3Type);
    }

    { // Demo 1.2: Higher order functions
        // Return func from func
        const result1 = get_add_u3()(1, 2, 3);
        std.debug.assert(result1 == 6); // OK

        // Pass func in func as arg - typed and untyped
        const result2 = apply_u3(add_u3, 1, 2, 3);
        const result3 = generic_apply_3(add_u3, 1, 2, 3);
        std.debug.assert(result2 == result3); // OK
    }

    { // Demo 1.3: Closures (inner functions) and anonymous functions
        // func through anonymous struct
        const anon_mul_u3 = struct {
            pub fn f(a: u32, b: u32, c: u32) u32 {
                return a * b * c;
            }
        }.f;
        const result1 = anon_mul_u3(2, 3, 4);
        std.debug.assert(result1 == 24); // OK

        // run func with closure
        const result2 = alternative_add_u3(1, 2, 3);
        std.debug.assert(result2 == 6); // OK

        // pass on-the-fly-defined func through anon. struct as arg
        const result3 = generic_apply_3(struct {
            pub fn f(a: u32, b: u32, c: u32) u32 {
                return a * b * c;
            }
        }.f, 2, 3, 4);
        std.debug.assert(result3 == 24); // OK
    }
}

test {
    std.testing.refAllDecls(@This());
    _ = .{fct};
}
