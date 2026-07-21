const std = @import("std");
const seq_produce = @import("fct/seq_produce.zig");
const sval_produce = @import("fct/sval_produce.zig");

pub const map = seq_produce.map;
pub const filter = seq_produce.filter;

pub const map_comptimef = seq_produce.map_comptimef;
pub const filter_comptimef = seq_produce.filter_comptimef;

pub const reduce = sval_produce.reduce;
pub const any = sval_produce.any;
pub const all = sval_produce.all;
pub const find = sval_produce.find;

pub const find_comptimef = sval_produce.find_comptimef;
pub const reduce_comptimef = sval_produce.reduce_comptimef;

// helpers
pub const YsMapType = seq_produce.YsMapType;

test {
    std.testing.refAllDecls(@This());
    _ = .{ sval_produce, seq_produce };
}
