const std = @import("std");
const seq_produce = @import("fct/seq_produce.zig");
const sval_produce = @import("fct/sval_produce.zig");
const muldseq_produce = @import("fct/muldseq_produce.zig");
const func_manip = @import("fct/func_manip.zig");

const bind = func_manip.bind;
const bind0 = func_manip.bind0;
const bind_i = func_manip.bind_i;
const curry = func_manip.curry;

pub const map = seq_produce.map;
pub const filter = seq_produce.filter;
pub const take = seq_produce.take;
pub const partition = seq_produce.partition;
pub const map_ret = seq_produce.map_ret;
pub const filter_ret = seq_produce.filter_ret;
pub const take_ret = seq_produce.take_ret;
pub const partition_ret = seq_produce.partition_ret;
pub const map_new = seq_produce.map_new;
pub const filter_new = seq_produce.filter_new;
pub const take_new = seq_produce.take_new;
pub const partition_new = seq_produce.partition_new;
pub const map_comptimef = seq_produce.map_comptimef;
pub const filter_comptimef = seq_produce.filter_comptimef;
pub const take_comptimef = seq_produce.take_comptimef;
pub const partition_comptimef = seq_produce.partition_comptimef;

pub const zip = muldseq_produce.zip;
pub const flat_map = muldseq_produce.flat_map;
pub const zip_ret = muldseq_produce.zip_ret;
pub const flat_map_ret = muldseq_produce.flat_map_ret;
pub const zip_new = muldseq_produce.zip_new;
pub const flat_map_new = muldseq_produce.flat_map_new;
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

test {
    std.testing.refAllDecls(@This());
}
